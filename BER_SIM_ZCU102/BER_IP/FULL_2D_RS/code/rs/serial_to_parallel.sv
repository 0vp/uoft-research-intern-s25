`timescale 1ns / 1ps

// Serial-to-Parallel Converter with FIFO Buffer
// Collects serial bit stream into parallel blocks for ZGC RS IP
// Features: 2-deep FIFO, continuous bit collection, overflow detection

module serial_to_parallel #(
    parameter N = 69,                    // Total RS symbols
    parameter K = 65,                    // Information symbols  
    parameter SYMBOL_WIDTH = 8,           // Bits per symbol
    parameter MODE = "ENCODE",            // "ENCODE" or "DECODE"
    parameter FIFO_DEPTH = 1,             // Number of frames to buffer
    // Calculate output width at parameter level for port declaration
    parameter OUTPUT_WIDTH = (MODE == "ENCODE") ? (N * SYMBOL_WIDTH) :        // 1D encoder expects N*8 bits with padding
                            (MODE == "DECODE") ? (N * SYMBOL_WIDTH) :        // 1D decoder expects N*8 bits
                            (MODE == "ENCODE_2D") ? (K * K * SYMBOL_WIDTH) : // 2D encoder expects K*K*8 bits
                            (MODE == "DECODE_2D") ? (N * N * SYMBOL_WIDTH) : // 2D decoder expects N*N*8 bits
                                                     (N * SYMBOL_WIDTH)        // Default
) (
    input  wire clk,
    input  wire rstn,
    
    // Serial input (from current streaming system)
    input  wire serial_data_in,
    input  wire serial_data_valid,
    
    // Parallel output (to ZGC wrapper)
    output reg  [OUTPUT_WIDTH-1:0] parallel_data_out,
    output reg  parallel_data_valid,
    input  wire parallel_data_ready,     // From ZGC wrapper (encode_en/ready signal)
    
    // Status outputs for debugging
    output wire collecting,               // Currently collecting bits
    output wire [15:0] bits_collected,    // Current bit count
    output wire buffer_full,              // Buffer overflow warning
    output wire [3:0] frames_buffered,    // Number of complete frames waiting
    output reg [31:0] bits_dropped        // Count of dropped bits due to overflow
);

// Automatic width calculation based on mode
localparam FRAME_BITS = (MODE == "ENCODE") ? (K * SYMBOL_WIDTH) :        // 1344 bits for 1D encoder input
                        (MODE == "DECODE") ? (N * SYMBOL_WIDTH) :        // 1600 bits for 1D decoder input
                        (MODE == "ENCODE_2D") ? (K * K * SYMBOL_WIDTH) : // 968 bits for 2D encoder input
                        (MODE == "DECODE_2D") ? (N * N * SYMBOL_WIDTH) : // 1800 bits for 2D decoder input
                                                (N * SYMBOL_WIDTH);       // Default
localparam BIT_COUNT_WIDTH = $clog2(FRAME_BITS + 1);

// FIFO storage for frames
reg [FRAME_BITS-1:0] frame_fifo [0:FIFO_DEPTH-1];

// Dynamic pointer width based on FIFO_DEPTH for robust design
localparam PTR_WIDTH = $clog2(FIFO_DEPTH);
reg [PTR_WIDTH-1:0] fifo_wr_ptr;
reg [PTR_WIDTH-1:0] fifo_rd_ptr;
reg [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;  // Can count from 0 to FIFO_DEPTH

// Block RAM architecture for shift register replacement
localparam MEMORY_DEPTH = (FRAME_BITS + 7) / 8;  // Ceiling division for byte addressing
localparam ADDR_WIDTH = $clog2(MEMORY_DEPTH);

// Block RAM for frame collection (replaces massive shift_register)
(* ram_style = "block" *) reg [7:0] frame_memory [0:MEMORY_DEPTH-1];

// Byte-level addressing for Block RAM
reg [ADDR_WIDTH-1:0] write_byte_addr;  // Current byte being written
reg [2:0] write_bit_offset;             // Bit position within current byte (0-7)

// Input collection state (preserved interface)
reg [BIT_COUNT_WIDTH-1:0] bit_counter;
reg frame_ready;  // Internal signal when a frame is complete

// Completed frame buffer (much smaller now - just addressing)
reg frame_complete_flag;
reg [ADDR_WIDTH-1:0] completed_frame_bytes;  // Number of bytes in completed frame

// Integer for initialization loops  
integer init_idx, mem_idx;

// Status outputs
assign collecting = (bit_counter > 0) || serial_data_valid;
assign bits_collected = bit_counter;
assign buffer_full = (fifo_count >= FIFO_DEPTH);
assign frames_buffered = {{2{1'b0}}, fifo_count};

// Debug signals
reg first_bit_seen;
reg [31:0] total_bits_received;
reg [31:0] instance_id;

// Generate unique instance ID on reset
initial begin
    instance_id = $random;
    // $display("S2P[%s] Instance ID: %08h, FRAME_BITS=%d, K=%d, N=%d", MODE, instance_id, FRAME_BITS, K, N);
end

// Input collection - Block RAM based bit collection
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bit_counter <= 0;
        write_byte_addr <= 0;
        write_bit_offset <= 0;
        frame_ready <= 0;
        frame_complete_flag <= 0;
        completed_frame_bytes <= 0;
        bits_dropped <= 0;
        first_bit_seen <= 0;
        total_bits_received <= 0;
        // Initialize Block RAM to prevent X propagation
        for (mem_idx = 0; mem_idx < MEMORY_DEPTH; mem_idx = mem_idx + 1) begin
            frame_memory[mem_idx] <= 8'h00;
        end
    end else begin
        frame_ready <= 0;  // Default to not ready
        
        // ALWAYS collect bits when valid input arrives
        if (serial_data_valid) begin
            // Debug: Track first bit and total bits
            if (!first_bit_seen) begin
                // $display("  [%0t] S2P[%s:%08h]: First bit received! Value=%b, FRAME_BITS=%d", 
                //          $time, MODE, instance_id, serial_data_in, FRAME_BITS);
                first_bit_seen <= 1;
            end
            total_bits_received <= total_bits_received + 1;
            
            // Write current bit to Block RAM at current byte and bit position
            // LSB first: bit 0 → byte[0][0], bit 1 → byte[0][1], ..., bit 8 → byte[1][0]
            frame_memory[write_byte_addr][write_bit_offset] <= serial_data_in;
            
            // Check for frame completion
            if (bit_counter == FRAME_BITS - 1) begin
                // $display("  [%0t] S2P[%s:%08h]: FRAME COMPLETION CHECK - bit_counter=%d == FRAME_BITS-1=%d", 
                //          $time, MODE, instance_id, bit_counter, FRAME_BITS-1);
                
                // Frame complete - mark it ready for FIFO storage
                frame_complete_flag <= 1;
                completed_frame_bytes <= write_byte_addr + 1; // +1 because addr is 0-based
                
                // Frame complete - check if we can store it
                if (!buffer_full) begin
                    // Set frame_ready to signal the FIFO write logic
                    frame_ready <= 1;  // Signal to FIFO logic
                    
                    // $display("  [%0t] S2P[%s:%08h]: Frame complete! Storing to FIFO[%d]. First 32 bits in memory.", 
                    //          $time, MODE, instance_id, fifo_wr_ptr);
                end else begin
                    // Buffer full - drop this frame and count it
                    bits_dropped <= bits_dropped + FRAME_BITS;
                    // $display("  [%0t] S2P[%s:%08h]: ERROR - Buffer full! Dropping frame", $time, MODE, instance_id);
                end

                // Reset for next frame collection
                bit_counter <= 0;
                write_byte_addr <= 0;
                write_bit_offset <= 0;
            end else begin
                // Advance bit and byte addressing
                bit_counter <= bit_counter + 1;
                
                if (write_bit_offset == 7) begin
                    // Current byte is full, move to next byte
                    write_byte_addr <= write_byte_addr + 1;
                    write_bit_offset <= 0;
                end else begin
                    // Stay in same byte, advance bit position
                    write_bit_offset <= write_bit_offset + 1;
                end
                
                // Debug counter increment
                if (bit_counter < 5) begin
                    // $display("  [%0t] S2P[%s:%08h]: Counter incremented to %d, byte_addr=%d, bit_offset=%d", 
                    //          $time, MODE, instance_id, bit_counter + 1, write_byte_addr, write_bit_offset + 1);
                end
            end

            // // Debug every 100 bits
            // if (bit_counter % 100 == 0 && bit_counter > 0) begin
            //     $display("  [%0t] S2P[%s:%08h]: Collected %d/%d bits", $time, MODE, instance_id, bit_counter, FRAME_BITS);
            // end
            
            // Debug near frame completion
            if (bit_counter >= FRAME_BITS - 5) begin
                // $display("  [%0t] S2P[%s:%08h]: Near completion - bit_counter=%d, FRAME_BITS-1=%d, buffer_full=%b", 
                //          $time, MODE, instance_id, bit_counter, FRAME_BITS-1, buffer_full);
            end
        end
    end
end

// FIFO write logic - Pack Block RAM data into wide FIFO format
// Temporary register to reconstruct frame from Block RAM
reg [FRAME_BITS-1:0] reconstructed_frame;
integer byte_idx, bit_idx;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        fifo_wr_ptr <= 0;
        // Initialize all FIFO entries to prevent X propagation
        // Use a loop for robust initialization regardless of FIFO_DEPTH
        for (init_idx = 0; init_idx < FIFO_DEPTH; init_idx = init_idx + 1) begin
            frame_fifo[init_idx] <= 0;
        end
    end else begin
        if (frame_ready && !buffer_full) begin
            // Reconstruct frame from Block RAM bytes
            // Pack bytes back into wide format: byte 0 contains bits [7:0], byte 1 contains bits [15:8], etc.
            for (byte_idx = 0; byte_idx < MEMORY_DEPTH; byte_idx = byte_idx + 1) begin
                for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                    if (byte_idx * 8 + bit_idx < FRAME_BITS) begin
                        reconstructed_frame[byte_idx * 8 + bit_idx] = frame_memory[byte_idx][bit_idx];
                    end
                end
            end
            
            // Store the reconstructed frame in FIFO
            frame_fifo[fifo_wr_ptr] <= reconstructed_frame;
            // Update the write pointer with natural bit wrapping
            fifo_wr_ptr <= fifo_wr_ptr + 1'b1;  // Naturally wraps for PTR_WIDTH bits
        end
    end
end

// FIFO read logic - output frames when downstream ready
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        fifo_rd_ptr <= 0;
        parallel_data_out <= 0;
        parallel_data_valid <= 0;
    end else begin
        // Clear valid when frame accepted
        if (parallel_data_valid && parallel_data_ready) begin
            parallel_data_valid <= 0;
            fifo_rd_ptr <= fifo_rd_ptr + 1'b1;  // Natural bit wrapping for PTR_WIDTH bits
            // $display("  [%0t] S2P[%s:%08h]: Frame accepted by downstream, rd_ptr=%d", $time, MODE, instance_id, fifo_rd_ptr + 1'b1);
        end
        
        // Output new frame if available and not currently outputting
        if (!parallel_data_valid && fifo_count > 0) begin
            // Output the appropriate number of bits based on MODE
            if (MODE == "ENCODE") begin
                // For 1D ENCODE mode, output K*SYMBOL_WIDTH bits, pad the rest with zeros
                // OUTPUT_WIDTH = N*SYMBOL_WIDTH, FRAME_BITS = K*SYMBOL_WIDTH
                parallel_data_out <= {{(N-K)*SYMBOL_WIDTH{1'b0}}, frame_fifo[fifo_rd_ptr]};
            end else if (MODE == "ENCODE_2D") begin
                // For 2D ENCODE mode, output K*K*SYMBOL_WIDTH bits
                // OUTPUT_WIDTH = K*K*SYMBOL_WIDTH, FRAME_BITS = K*K*SYMBOL_WIDTH
                parallel_data_out <= frame_fifo[fifo_rd_ptr];
            end else if (MODE == "DECODE_2D") begin
                // For 2D DECODE mode, output N*N*SYMBOL_WIDTH bits
                // OUTPUT_WIDTH = N*N*SYMBOL_WIDTH, FRAME_BITS = N*N*SYMBOL_WIDTH
                parallel_data_out <= frame_fifo[fifo_rd_ptr];
            end else begin
                // For 1D DECODE mode, output all N*SYMBOL_WIDTH bits
                // OUTPUT_WIDTH = N*SYMBOL_WIDTH, FRAME_BITS = N*SYMBOL_WIDTH
                parallel_data_out <= frame_fifo[fifo_rd_ptr];
            end
            parallel_data_valid <= 1;
            // $display("  [%0t] S2P[%s:%08h]: Outputting frame from FIFO[%d], count=%d, First 32 bits: %08h, downstream_ready=%b", 
            //          $time, MODE, instance_id, fifo_rd_ptr, fifo_count, frame_fifo[fifo_rd_ptr][31:0], parallel_data_ready);
        end
    end
end

// FIFO count management
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        fifo_count <= 0;
    end else begin
        case ({frame_ready && !buffer_full, parallel_data_valid && parallel_data_ready})
            2'b10: fifo_count <= fifo_count + 1;  // Write only
            2'b01: fifo_count <= fifo_count - 1;  // Read only
            2'b11: fifo_count <= fifo_count;      // Read and write
            default: fifo_count <= fifo_count;    // No change
        endcase
    end
end

endmodule