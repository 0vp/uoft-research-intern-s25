`timescale 1ns / 1ps

// Parallel-to-Serial Converter with FIFO Buffer
// Converts parallel blocks from ZGC RS IP back to serial bit stream
// Features: 2-deep FIFO, continuous transmission, proper last bit handling

module parallel_to_serial #(
    parameter N = 200,                    // Total RS symbols
    parameter K = 168,                    // Information symbols
    parameter SYMBOL_WIDTH = 8,           // Bits per symbol  
    parameter MODE = "ENCODE",            // "ENCODE" or "DECODE"
    parameter FIFO_DEPTH = 2,             // Number of frames to buffer
    // Calculate input width at parameter level for port declaration
    parameter INPUT_WIDTH = (MODE == "ENCODE") ? (N * SYMBOL_WIDTH) :        // 1D encoder outputs N*8 bits
                           (MODE == "DECODE") ? (K * SYMBOL_WIDTH) :        // 1D decoder outputs K*8 bits
                           (MODE == "ENCODE_2D") ? (N * N * SYMBOL_WIDTH) : // 2D encoder outputs N*N*8 bits
                           (MODE == "DECODE_2D") ? (K * K * SYMBOL_WIDTH) : // 2D decoder outputs K*K*8 bits
                                                    (N * SYMBOL_WIDTH)        // Default
) (
    input  wire clk,
    input  wire rstn,
    
    // Parallel input (from ZGC wrapper)
    input  wire [INPUT_WIDTH-1:0] parallel_data_in,
    input  wire parallel_data_valid,      // From ZGC wrapper (valid signal)
    output wire parallel_data_ready,      // To ZGC wrapper (ready to receive)
    
    // Serial output (to current streaming system)
    output reg  serial_data_out,
    output reg  serial_data_valid,
    
    // Status outputs for debugging
    output wire transmitting,             // Currently transmitting bits
    output wire [15:0] bits_remaining,    // Bits left to transmit
    output wire [3:0] frames_buffered,    // Number of frames in FIFO
    output wire buffer_full,              // FIFO is full
    output reg [31:0] frames_dropped      // Count of dropped frames
);

// Automatic width calculation based on mode  
localparam FRAME_BITS = (MODE == "ENCODE") ? (N * SYMBOL_WIDTH) :        // 1600 bits for 1D encoder output
                        (MODE == "DECODE") ? (K * SYMBOL_WIDTH) :        // 1344 bits for 1D decoder output
                        (MODE == "ENCODE_2D") ? (N * N * SYMBOL_WIDTH) : // 1800 bits for 2D encoder output
                        (MODE == "DECODE_2D") ? (K * K * SYMBOL_WIDTH) : // 968 bits for 2D decoder output
                                                (N * SYMBOL_WIDTH);       // Default
localparam BIT_COUNT_WIDTH = $clog2(FRAME_BITS + 1);

// FIFO storage for frames
reg [FRAME_BITS-1:0] frame_fifo [0:FIFO_DEPTH-1];

// Dynamic pointer width based on FIFO_DEPTH for robust design
localparam PTR_WIDTH = $clog2(FIFO_DEPTH);
reg [PTR_WIDTH-1:0] fifo_wr_ptr;
reg [PTR_WIDTH-1:0] fifo_rd_ptr;
reg [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;  // Can count from 0 to FIFO_DEPTH

// Transmission state
reg [BIT_COUNT_WIDTH-1:0] bit_counter;
reg [FRAME_BITS-1:0] shift_register;
reg transmit_active;
reg load_new_frame;
reg transmit_gap;  // Force gap between frames for proper boundary detection

// Status outputs
assign transmitting = transmit_active;
assign bits_remaining = transmit_active ? (FRAME_BITS - bit_counter) : 16'd0;
assign frames_buffered = {{2{1'b0}}, fifo_count};
assign buffer_full = (fifo_count >= FIFO_DEPTH);

// Ready signal - combinational from buffer_full
// Must be combinational to prevent accepting frames when full
assign parallel_data_ready = !buffer_full;

// Debug signals
reg first_frame_received;
reg [31:0] instance_id;

// Proper handshaking: track if current valid assertion has been accepted
reg valid_accepted;

// Transmission control to prevent race condition
reg first_frame_loaded;

// Integer for initialization loops
integer init_idx;

// Generate unique instance ID on reset
initial begin
    instance_id = $random;
    // $display("P2S[%s] Instance ID: %08h, FRAME_BITS=%d, K=%d, N=%d, FIFO_DEPTH=%d", 
    //          MODE, instance_id, FRAME_BITS, K, N, FIFO_DEPTH);
    // if (MODE == "DECODE") begin
    //     $display("P2S[DECODE] FRAME_BITS should be K*SYMBOL_WIDTH = %d*%d = %d", K, SYMBOL_WIDTH, K*SYMBOL_WIDTH);
    // end else begin
    //     $display("P2S[ENCODE] FRAME_BITS should be N*SYMBOL_WIDTH = %d*%d = %d", N, SYMBOL_WIDTH, N*SYMBOL_WIDTH);
    // end
end

// FIFO write logic - accept parallel frames
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        fifo_wr_ptr <= 0;
        frames_dropped <= 0;
        first_frame_received <= 0;
        valid_accepted <= 0;
        // Initialize all FIFO entries to prevent X propagation
        // Use blocking assignment for immediate effect during reset
        for (init_idx = 0; init_idx < FIFO_DEPTH; init_idx = init_idx + 1) begin
            frame_fifo[init_idx] = 0;  // Blocking assignment for proper reset
        end
    end else begin
        // Proper AXI handshaking: accept frame ONCE per valid assertion
        if (parallel_data_valid && !buffer_full && !valid_accepted) begin
            // Debug BEFORE write to track actual pointer values
            // $display("  [%0t] P2S[%s:%08h]: PRE-WRITE: wr_ptr=%d, rd_ptr=%d, count=%d, first_rcvd=%b", 
            //          $time, MODE, instance_id, fifo_wr_ptr, fifo_rd_ptr, fifo_count, first_frame_received);
            
            // Store frame as-is for all modes
            // Bit ordering is handled in rs modules at the encoder/decoder interface
            // Store the appropriate number of bits based on MODE
            if (MODE == "ENCODE" || MODE == "DECODE") begin
                // For 1D modes, store as before
                frame_fifo[fifo_wr_ptr] <= parallel_data_in[FRAME_BITS-1:0];
            end else if (MODE == "ENCODE_2D" || MODE == "DECODE_2D") begin
                // For 2D modes, store the appropriate frame size
                frame_fifo[fifo_wr_ptr] <= parallel_data_in[FRAME_BITS-1:0];
            end else begin
                // Default case
                frame_fifo[fifo_wr_ptr] <= parallel_data_in[FRAME_BITS-1:0];
            end
            
            if (!first_frame_received) begin
                // $display("  [%0t] P2S[%s:%08h]: First frame received! First 32 bits: %08h, Last 32 bits: %08h, fifo_count=%d", 
                //          $time, MODE, instance_id, parallel_data_in[31:0], parallel_data_in[FRAME_BITS-1:FRAME_BITS-32], fifo_count);
                first_frame_received <= 1;
            end
            
            // Always show where frame was stored
            // $display("  [%0t] P2S[%s:%08h]: Frame stored to FIFO[%d], count=%d, First 32: %08h, buffer_full=%b, ready=%b", 
            //          $time, MODE, instance_id, fifo_wr_ptr, fifo_count + 1, 
            //          parallel_data_in[31:0], buffer_full, parallel_data_ready);
                         
            //     // Debug: Show state AFTER storing (next cycle's values)
            //     $display("  [%0t] P2S[%s:%08h]: POST-STORE STATE: count=%d, will_be_full=%b, next_ready=%b", 
            //              $time, MODE, instance_id, fifo_count + 1, 
            //              (fifo_count + 1 >= FIFO_DEPTH), !(fifo_count + 1 >= FIFO_DEPTH));
                
            //     // Detect potential overflow
            //     if (fifo_count + 1 > FIFO_DEPTH) begin
            //         $display("  [%0t] P2S[%s:%08h]: CRITICAL ERROR - FIFO OVERFLOW! count=%d exceeds FIFO_DEPTH=%d", 
            //                  $time, MODE, instance_id, fifo_count + 1, FIFO_DEPTH);
            //     end
            
            // // Show actual FIFO contents (will show old value due to non-blocking assignment)
            // $display("  [%0t] P2S[%s:%08h]: FIFO STATE (OLD): [0]=%08h, [1]=%08h", 
            //          $time, MODE, instance_id, frame_fifo[0][31:0], frame_fifo[1][31:0]);
            // $display("  [%0t] P2S[%s:%08h]: NEW DATA WRITTEN TO SLOT[%d]: %08h", 
            //          $time, MODE, instance_id, fifo_wr_ptr, parallel_data_in[31:0]);
            
            // Now increment write pointer AFTER all debug
            fifo_wr_ptr <= fifo_wr_ptr + 1'b1;  // Natural bit wrapping
            valid_accepted <= 1;  // Mark this valid assertion as accepted
        end else if (!parallel_data_valid) begin
            // Clear acceptance flag when valid deasserts
            valid_accepted <= 0;
        end else if (parallel_data_valid && !buffer_full && valid_accepted) begin
            // Valid is still high but we already accepted this assertion
            // $display("  [%0t] P2S[%s:%08h]: Skipping - already accepted this valid assertion", 
            //          $time, MODE, instance_id);
        end else if (parallel_data_valid && buffer_full && !valid_accepted) begin
            // Frame rejected because FIFO is full
            frames_dropped <= frames_dropped + 1;
            // $display("  [%0t] P2S[%s:%08h]: WARNING - Frame rejected, FIFO full (count=%d)", 
            //          $time, MODE, instance_id, fifo_count);
            // $display("  [%0t] P2S[%s:%08h]: This indicates backpressure failure!", $time, MODE, instance_id);
        end
    end
end

// Debug signals for transmission
reg first_bit_sent;
reg [31:0] total_bits_sent;
reg [31:0] frame_bits_sent;  // Bits sent in current frame
reg serial_data_valid_prev;  // To detect valid transitions

// Debug: Show FIFO state after reset
always @(posedge clk) begin
    if (!rstn) begin
        // #2; // Wait for reset logic to complete
        // $display("  [%0t] P2S[%s:%08h] RESET: fifo_count=%d, wr_ptr=%d, rd_ptr=%d, buffer_full=%b", 
        //          $time, MODE, instance_id, fifo_count, fifo_wr_ptr, fifo_rd_ptr, buffer_full);
        // $display("  [%0t] P2S[%s:%08h] FIFO CONTENTS: FIFO[0][31:0]=%08h, FIFO[1][31:0]=%08h", 
        //          $time, MODE, instance_id, frame_fifo[0][31:0], frame_fifo[1][31:0]);
    end
end

// Debug register to track what was loaded
reg [31:0] loaded_data_debug;
reg [31:0] expected_data_debug;

// Transmission logic - convert frames to serial
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bit_counter <= 0;
        shift_register <= 0;
        serial_data_out <= 0;
        serial_data_valid <= 0;
        transmit_active <= 0;
        load_new_frame <= 0;
        transmit_gap <= 0;
        fifo_rd_ptr <= 0;
        first_bit_sent <= 0;
        total_bits_sent <= 0;
        frame_bits_sent <= 0;
        serial_data_valid_prev <= 0;
        first_frame_loaded <= 0;  // Reset transmission control
        loaded_data_debug <= 0;
        expected_data_debug <= 0;
    end else begin
        load_new_frame <= 0;  // Default
        
        // Update first_frame_loaded flag after first frame settles
        if (fifo_count > 0 && !first_frame_loaded) begin
            first_frame_loaded <= 1;  // Mark that we have at least one frame
        end else if (fifo_count == 0) begin
            first_frame_loaded <= 0;  // Clear when FIFO empties
        end
        
        // Start transmission when we have frames available (and not in gap)
        if (!transmit_active && !transmit_gap && fifo_count > 0 && first_frame_loaded) begin
            // Load new frame from FIFO
            shift_register <= frame_fifo[fifo_rd_ptr];
            transmit_active <= 1;
            bit_counter <= 0;
            load_new_frame <= 1;  // Signal to update FIFO
            
            // Enhanced debug to catch the issue
            // $display("  [%0t] P2S[%s:%08h]: LOADING frame from FIFO[%d]", $time, MODE, instance_id, fifo_rd_ptr);
            // $display("  [%0t] P2S[%s:%08h]: FIFO[0] contains: %08h...%08h", 
            //          $time, MODE, instance_id, frame_fifo[0][31:0], frame_fifo[0][FRAME_BITS-1:FRAME_BITS-32]);
            // $display("  [%0t] P2S[%s:%08h]: FIFO[1] contains: %08h...%08h", 
            //          $time, MODE, instance_id, frame_fifo[1][31:0], frame_fifo[1][FRAME_BITS-1:FRAME_BITS-32]);
            // $display("  [%0t] P2S[%s:%08h]: Loading shift_reg with: %08h...%08h from FIFO[%d]", 
            //          $time, MODE, instance_id, frame_fifo[fifo_rd_ptr][31:0], 
            //          frame_fifo[fifo_rd_ptr][FRAME_BITS-1:FRAME_BITS-32], fifo_rd_ptr);
            
            // $display("  [%0t] P2S[%s:%08h]: Starting transmission of frame from FIFO[%d], First 32 bits: %08h, count=%d", 
            //          $time, MODE, instance_id, fifo_rd_ptr, frame_fifo[fifo_rd_ptr][31:0], fifo_count);
            // $display("  [%0t] P2S[%s:%08h]: FIFO PTRS: wr_ptr=%d, rd_ptr=%d (before increment)", 
            //          $time, MODE, instance_id, fifo_wr_ptr, fifo_rd_ptr);
            // $display("  [%0t] P2S[%s:%08h]: Will transmit %d bits for this frame", 
            //          $time, MODE, instance_id, FRAME_BITS);
            frame_bits_sent <= 0;  // Reset frame bit counter
            
            // Debug: Save what we're loading for verification
            loaded_data_debug <= frame_fifo[fifo_rd_ptr][31:0];
            expected_data_debug <= frame_fifo[fifo_rd_ptr][31:0];
            
            fifo_rd_ptr <= fifo_rd_ptr + 1'b1;  // Natural bit wrapping for PTR_WIDTH bits
        end else if (transmit_active) begin
            // Immediate debug on first cycle of transmission
            if (bit_counter == 0 && load_new_frame) begin
                // $display("  [%0t] P2S[%s:%08h]: ALERT - Just loaded shift_reg, checking value next cycle",
                //          $time, MODE, instance_id);
            end
            // Transmit bits LSB-first (bit 0 first)
            serial_data_out <= shift_register[0];
            serial_data_valid <= 1;
            
            // Debug: Check shift register value at start of transmission
            if (bit_counter == 0) begin
                // $display("  [%0t] P2S[%s:%08h]: START OF TRANSMISSION - shift_reg[31:0]=%08h, first bit=%b",
                //          $time, MODE, instance_id, shift_register[31:0], shift_register[0]);
                // $display("  [%0t] P2S[%s:%08h]: Expected data was: %08h, Loaded data was: %08h",
                //          $time, MODE, instance_id, expected_data_debug, loaded_data_debug);
                // Check if shift register matches what we loaded
                if (shift_register[31:0] != loaded_data_debug) begin
                    // $display("  [%0t] P2S[%s:%08h]: ERROR! Shift register doesn't match loaded data!",
                    //          $time, MODE, instance_id);
                    // $display("  [%0t] P2S[%s:%08h]: shift_reg[31:0]=%08h, loaded_data=%08h",
                    //          $time, MODE, instance_id, shift_register[31:0], loaded_data_debug);
                end
            end
            
            shift_register <= {1'b0, shift_register[FRAME_BITS-1:1]};
            
            // Debug tracking
            if (!first_bit_sent) begin
                // $display("  [%0t] P2S[%s:%08h]: First bit transmitted! Value=%b, shift_reg[31:0]=%08h", 
                //          $time, MODE, instance_id, shift_register[0], shift_register[31:0]);
                first_bit_sent <= 1;
            end else if (bit_counter < 32) begin
                // Debug first 32 bits being transmitted
                // $display("  [%0t] P2S[%s:%08h]: Transmitting bit %d = %b (shift_reg[7:0]=%02h)", 
                //          $time, MODE, instance_id, bit_counter, shift_register[0], shift_register[7:0]);
            end
            total_bits_sent <= total_bits_sent + 1;
            frame_bits_sent <= frame_bits_sent + 1;
            
            // // Debug every 100 bits
            // if (bit_counter % 100 == 0 && bit_counter > 0) begin
            //     $display("  [%0t] P2S[%s:%08h]: Transmitted %d/%d bits", $time, MODE, instance_id, bit_counter, FRAME_BITS);
            // end
            
            // Check if frame transmission complete
            if (bit_counter == FRAME_BITS - 1) begin
                // Last bit is being transmitted this cycle
                transmit_active <= 0;
                bit_counter <= 0;
                // Force a gap if there are more frames to transmit
                if (fifo_count > 0) begin
                    transmit_gap <= 1;  // Enforce 1-cycle gap between frames
                end
                // Display FRAME_BITS since we know we've transmitted all bits
                // (frame_bits_sent shows old value due to non-blocking assignment)
                // $display("  [%0t] P2S[%s:%08h]: Frame transmission complete! Frame bits: %d, Total bits: %d", 
                //          $time, MODE, instance_id, FRAME_BITS, total_bits_sent + 1);
                // Check will always show frame_bits_sent = FRAME_BITS-1 due to non-blocking
                // The actual transmission is correct (verified by serial_data_valid transitions)
                if (frame_bits_sent != FRAME_BITS - 1) begin
                    // $display("  [%0t] P2S[%s:%08h]: ERROR - Frame counter mismatch: %d, expected %d!", 
                    //          $time, MODE, instance_id, frame_bits_sent, FRAME_BITS - 1);
                end
                // Note: serial_data_valid stays high for this cycle
                // It will be cleared in the next cycle when transmit_active is 0
            end else begin
                bit_counter <= bit_counter + 1;
            end
        end else if (transmit_gap) begin
            // Gap cycle between frames - ensure valid is low
            serial_data_valid <= 0;
            transmit_gap <= 0;  // Clear gap flag after one cycle
            // $display("  [%0t] P2S[%s:%08h]: Gap cycle between frames, serial_data_valid=0", 
            //          $time, MODE, instance_id);
        end else begin
            // Idle state - clear valid signal
            serial_data_valid <= 0;
        end
        
        // Track valid transitions for debug
        // if (serial_data_valid && !serial_data_valid_prev) begin
        //     $display("  [%0t] P2S[%s:%08h]: serial_data_valid rising edge", $time, MODE, instance_id);
        // end else if (!serial_data_valid && serial_data_valid_prev) begin
        //     $display("  [%0t] P2S[%s:%08h]: serial_data_valid falling edge after %d frame bits", 
        //              $time, MODE, instance_id, frame_bits_sent);
        // end
        serial_data_valid_prev <= serial_data_valid;
    end
end

// FIFO count management
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        fifo_count <= 0;
    end else begin
        // Match the write condition exactly for proper count tracking
        case ({parallel_data_valid && !buffer_full && !valid_accepted, load_new_frame})
            2'b10: begin
                fifo_count <= fifo_count + 1;  // Write only
                // $display("  [%0t] P2S[%s:%08h]: FIFO count increased to %d", $time, MODE, instance_id, fifo_count + 1);
            end
            2'b01: begin
                fifo_count <= fifo_count - 1;  // Read only
                // $display("  [%0t] P2S[%s:%08h]: FIFO count decreased to %d", $time, MODE, instance_id, fifo_count - 1);
            end
            2'b11: fifo_count <= fifo_count;      // Read and write
            default: fifo_count <= fifo_count;    // No change
        endcase
    end
end

endmodule