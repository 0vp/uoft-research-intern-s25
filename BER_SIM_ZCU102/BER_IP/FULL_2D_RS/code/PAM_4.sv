`timescale 1ns / 1ps

module pam_4_encode #(
    parameter SIGNAL_RESOLUTION = 8,
    parameter SYMBOL_SEPARATION = 48)(
    input clk,
    input rstn,
    input [1:0] symbol_in,
    input symbol_in_valid,
    output reg [SIGNAL_RESOLUTION-1:0] signal_out, //128 to -127 as signed int
    output reg signal_out_valid = 0);

    always @ (posedge clk) begin
        if (!rstn) begin
            signal_out_valid <= 0;
        end else begin
            if (symbol_in_valid) begin
                case(symbol_in)
                    2'b00: signal_out <= -SYMBOL_SEPARATION*1.5;
                    2'b01: signal_out <= -SYMBOL_SEPARATION*0.5;
                    2'b10: signal_out <= SYMBOL_SEPARATION*0.5;
                    2'b11: signal_out <= SYMBOL_SEPARATION*1.5;
                endcase
                signal_out_valid <= 1;
            end else begin
                signal_out_valid <= 0; // To align with previous valid signal in order to convert back to binary data
            end
        end
    end
endmodule

// PAM4 to Binary converter for RS decoder
// Converts ALL PAM4 symbols to binary (including parity)
module pam4_to_binary_rs #(
    parameter N = 68,           // Total symbols in RS codeword
    parameter K = 60,           // Information symbols
    parameter SYMBOL_WIDTH = 8  // Bits per symbol
)(
    input wire clk,
    input wire rstn,
    input wire [1:0] symbol_in,      // PAM-4 symbol from SOVA (0,1,2,3)
    input wire symbol_in_valid,
    output reg data_out,             // Single bit output
    output reg data_out_valid
);

    // Calculate derived parameters for PAM-4 operation
    localparam TOTAL_BITS = N * SYMBOL_WIDTH;  // 544 total bits
    localparam PAM4_TOTAL_SYMBOLS = TOTAL_BITS / 2;  // 272 PAM-4 symbols for 544 bits
    localparam COUNTER_WIDTH = $clog2(PAM4_TOTAL_SYMBOLS + 1);
    localparam OUTPUT_COUNTER_WIDTH = $clog2(TOTAL_BITS + 1);
    
    reg [COUNTER_WIDTH-1:0] counter = 0;
    reg [TOTAL_BITS-1:0] data_reg;    // 544 bits
    reg output_ready = 0;
    reg [OUTPUT_COUNTER_WIDTH-1:0] output_counter = 0;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_out <= 0;
            data_out_valid <= 0;
            counter <= 0;
            output_ready <= 0;
            output_counter <= 0;
        end else begin
            
            // Handle output when ready
            if (output_ready) begin
                data_out <= data_reg[output_counter];
                data_out_valid <= 1;
                output_counter <= output_counter + 1;
                
                if (output_counter == (TOTAL_BITS - 1)) begin  // Output all 544 bits
                    output_ready <= 0;
                    output_counter <= 0;
                end
            end else begin
                data_out_valid <= 0;
            end
            
            // Collect ALL incoming symbols
            if (symbol_in_valid && counter < PAM4_TOTAL_SYMBOLS) begin
                // Direct PAM-4 to binary conversion (NOT Gray code)
                case(symbol_in)
                    2'd0: begin  // PAM symbol 0 → bits 00
                        data_reg[counter*2] <= 1'b0;      // LSB at even index
                        data_reg[counter*2+1] <= 1'b0;    // MSB at odd index  
                    end
                    2'd1: begin  // PAM symbol 1 → bits 01
                        data_reg[counter*2] <= 1'b0;
                        data_reg[counter*2+1] <= 1'b1;
                    end
                    2'd2: begin  // PAM symbol 2 → bits 11
                        data_reg[counter*2] <= 1'b1;
                        data_reg[counter*2+1] <= 1'b1;
                    end
                    2'd3: begin  // PAM symbol 3 → bits 10
                        data_reg[counter*2] <= 1'b1;
                        data_reg[counter*2+1] <= 1'b0;
                    end
                endcase
                
                counter <= counter + 1;
                
                // When we have all PAM4 symbols, start outputting
                if (counter == (PAM4_TOTAL_SYMBOLS - 1)) begin
                    output_ready <= 1;
                    output_counter <= 0;
                    counter <= 0;  // Reset for next codeword
                end
            end
        end
    end

endmodule