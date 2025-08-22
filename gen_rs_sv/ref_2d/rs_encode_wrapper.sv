module rs_encode_wrapper(
    input clk,
    input rst_n,
    input clrn,
    input encode_en,               // 开始编码的外部信号
    input scan_mode,
    input [8*11-1:0] datain,
    output reg [8*15-1:0] encoded_data,
    output reg valid,              // 编码完成的信号
    output reg ready,               // 可以进行编码的信号
    
    output     ready_re, 
    output     valid_re,
    output [49:0] encoded_data_re
);

    // Internal signals
    reg [7:0] message;
    reg enc_ena;
    reg data_present;
    wire [7:0] encoded;
    reg [7:0] data_buffer[0:10]; // Buffer to hold input data
    integer i, j;
    reg [4:0] output_idx;  // Track where to store in output array

    assign valid_re = valid;
    assign ready_re = 1'b1;
    assign encoded_data_re = {50{valid}};
     
    // Instantiate the rs_enc module
    rs_enc x1 (
        .y(encoded),
        .x(message),
        .enable(enc_ena),
        .data(data_present),
        .clk(clk),
        .clrn(rst_n & (clrn | scan_mode))
    );

    // State machine for control logic
    reg [3:0] state;
    localparam S_IDLE = 0, S_LOAD = 1, S_ENCODE = 2, S_FINISH = 3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
            message <= 8'b0;
            state <= S_IDLE;
            i <= 0;
            j <= 0;
            output_idx <= 0;
            enc_ena <= 0;
            data_present <= 0;
            valid <= 0;
            ready <= 1; // Initially ready
            encoded_data <= 0;
            data_buffer[0] <= 0;
            data_buffer[1] <= 0;
            data_buffer[2] <= 0;
            data_buffer[3] <= 0;
            data_buffer[4] <= 0;
            data_buffer[5] <= 0;
            data_buffer[6] <= 0;
            data_buffer[7] <= 0;
            data_buffer[8] <= 0;
            data_buffer[9] <= 0;
            data_buffer[10] <= 0;
        end else if (!clrn) begin
            // Reset logic
            message <= 8'b0;
            state <= S_IDLE;
            i <= 0;
            j <= 0;
            output_idx <= 0;
            enc_ena <= 0;
            data_present <= 0;
            valid <= 0;
            ready <= 1; // Initially ready
            encoded_data <= 0;
            data_buffer[0] <= 0;
            data_buffer[1] <= 0;
            data_buffer[2] <= 0;
            data_buffer[3] <= 0;
            data_buffer[4] <= 0;
            data_buffer[5] <= 0;
            data_buffer[6] <= 0;
            data_buffer[7] <= 0;
            data_buffer[8] <= 0;
            data_buffer[9] <= 0;
            data_buffer[10] <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    valid <= 0; // Clear valid signal
                    if (encode_en && ready) begin
                        i <= 0;
                        output_idx <= 0;  // Reset output index
                        ready <= 0; // Not ready until encoding is done
                        state <= S_LOAD;
                        // Load data into buffer
                        data_buffer[0] <= datain[0*8 +: 8];
                        data_buffer[1] <= datain[1*8 +: 8];
                        data_buffer[2] <= datain[2*8 +: 8];
                        data_buffer[3] <= datain[3*8 +: 8];
                        data_buffer[4] <= datain[4*8 +: 8];
                        data_buffer[5] <= datain[5*8 +: 8];
                        data_buffer[6] <= datain[6*8 +: 8];
                        data_buffer[7] <= datain[7*8 +: 8];
                        data_buffer[8] <= datain[8*8 +: 8];
                        data_buffer[9] <= datain[9*8 +: 8];
                        data_buffer[10] <= datain[10*8 +: 8];
                    end
                end

                S_LOAD: begin
                    enc_ena <= 1; // Enable encoder for 15 cycles
                    if (i < 11) begin
                        message <= data_buffer[i];
                        data_present <= 1; // Latch data for 11 cycles
                        i <= i + 1;
                        // Only store when we have valid output from encoder
                        if (output_idx < i) begin
                            encoded_data[output_idx*8 +: 8] <= encoded;
                            output_idx <= output_idx + 1;
                        end
                    end else begin
                        // Store the last data byte output
                        if (output_idx < 11) begin
                            encoded_data[output_idx*8 +: 8] <= encoded;
                            output_idx <= output_idx + 1;
                        end
                        data_present <= 0; // Stop latching data
                        state <= S_ENCODE;
                    end
                end

                S_ENCODE: begin
                    // Wait for encoder to finish encoding (output parity bytes)
                    if (output_idx >= 15) begin
                        enc_ena <= 0; // Disable encoder
                        state <= S_FINISH; // Move to finish state
                    end else begin
                        encoded_data[output_idx*8 +: 8] <= encoded;
                        output_idx <= output_idx + 1;
                        i <= i + 1;  // Keep incrementing i for cycle count
                    end
                end

                S_FINISH: begin
                    valid <= 1; // Indicate encoding complete
                    ready <= 1; // Ready for next encoding
                    state <= S_IDLE; // Go back to idle state
                end
            endcase
        end
    end
endmodule