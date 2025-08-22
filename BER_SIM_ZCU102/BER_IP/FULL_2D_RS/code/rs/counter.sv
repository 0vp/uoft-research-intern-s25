`timescale 1ns / 1ps

// Counter-based data generator matching prbs63_120_8 interface
// Generates predictable incrementing pattern for debugging
// Outputs LSB of an 8-bit counter as data bit
// 
// IMPORTANT: After generating N_PCS frames, the module stops generating data
// and maintains its state. To generate more frames, pulse rstn low to reset.

module counter #(
    parameter SEED = 64'h0000000000000001,  // Kept for interface compatibility (unused)
    parameter RS_K = 60,                    // RS information symbols
    parameter RS_N = 68,                    // RS codeword length
    parameter RS_SYMBOL_WIDTH = 8           // Bits per RS symbol
)(
    input clk,
    input en,
    input rstn,
    input [31:0] N_PCS,                     // Number of frames to generate (now an input)
    output reg data,
    output reg valid = 0
);
    
    // Internal counters
    reg [7:0] counter = 0;        // Current 8-bit symbol value
    reg [2:0] bit_index = 0;      // Which bit of symbol to output (0-7)
    
    // Frame bit counter
    reg [31:0] bit_count = 0;
    
    // Frame counter
    reg [31:0] frame_count = 0;
    
    // Calculate bit counts from RS parameters
    localparam INFO_BITS = RS_K * RS_SYMBOL_WIDTH;
    localparam TOTAL_BITS = RS_N * RS_SYMBOL_WIDTH;
    
    always @(posedge clk) begin
        if (!rstn) begin
            counter <= 0;
            bit_index <= 0;
            valid <= 0;
            bit_count <= 0;
            frame_count <= 0;
            data <= 0;
        end else begin
            if (en) begin
                if (frame_count < N_PCS) begin
                    if (bit_count < INFO_BITS) begin
                        // Output current bit of 8-bit symbol
                        data <= counter[bit_index];
                        valid <= 1;
                        bit_count <= bit_count + 1;
                        
                        // Move to next bit, increment counter after 8 bits
                        if (bit_index == 7) begin
                            bit_index <= 0;
                            counter <= counter + 1;  // Move to next 8-bit symbol
                        end else begin
                            bit_index <= bit_index + 1;  // Next bit of current symbol
                        end
                    end else if (bit_count < TOTAL_BITS - 1) begin
                        // Pad with zeros for parity section
                        valid <= 0;
                        bit_count <= bit_count + 1;
                        // Counter and bit_index hold their values during padding
                    end else if (bit_count == TOTAL_BITS - 1) begin
                        // End of frame
                        valid <= 0;
                        bit_count <= 0;
                        frame_count <= frame_count + 1;
                        // Counter continues from where it left off
                        
                        // Debug: Report frame completion
                        if (frame_count + 1 == N_PCS) begin
                            $display("  [%0t] Counter: Completed frame %0d/%0d - stopping generation", 
                                     $time, frame_count + 1, N_PCS);
                        end else if (frame_count < N_PCS) begin
                            $display("  [%0t] Counter: Completed frame %0d/%0d - continuing", 
                                     $time, frame_count + 1, N_PCS);
                        end
                    end
                end else begin
                    // All frames completed, stop generating data
                    valid <= 0;
                    // Keep frame_count at N_PCS to prevent restarting
                    // Don't reset counters - maintain state
                end
            end else begin
                valid <= 0;
            end
        end
    end
    
endmodule