module rs_decode_wrapper(
    input clk,
    input rst_n, // Active low reset
    input decode_en,
    input clrn,
    input scan_mode,
    input [15*8-1:0] encoded_data,
    output reg [15*8-1:0] error_pos,
    output reg output_valid,
    output reg ready,
    output  with_error,  //output reg  with_error 
    output reg decode_complete,  // Pulses when decode fully completes
    
    output  ready_re,
    output  output_valid_re,
    output  [49:0] error_pos_re,
    output  with_error_re
);

// State declaration
localparam [1:0]
    IDLE = 2'b00,
    DECODE = 2'b01,
    COLLECT_ERROR = 2'b10,
    COMPLETE = 2'b11;

// Internal signals
reg [7:0] received;
reg dec_ena;
wire [7:0] error;
wire valid;
reg [11:0] bit_count;
reg [1:0] state, next_state;
reg [7:0] decode_counter; // Counter to maintain dec_ena for k clock cycles
reg [7:0] decode_number = 0; // Debug: Track which decode operation this is

localparam [7:0] k = 8'd15;

assign ready_re = 1'b1;
assign output_valid_re = output_valid;
assign with_error_re = 1'b1;
assign error_pos_re = {50{output_valid}};

// Instantiate the rsdec decoder module
rsdec x2 (
    .x(received),
    .error(error),
    .with_error(with_error), // Assuming not used, connect it properly if required
    .enable(dec_ena), // Connect dec_ena signal
    .valid(valid),
    .k(k),
    .clk(clk),
    .clrn(rst_n & (clrn | scan_mode))
    // Other connections to rsdec if needed
);

// State machine transition and output logic
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        received <= 8'b0;
        state <= IDLE;
        bit_count <= 0;
        error_pos <= 0;
        output_valid <= 0;
        decode_counter <= 0;
        dec_ena <= 0;
        ready <= 1;
        decode_number <= 0;
        decode_complete <= 0;
    end else if (!clrn) begin
        received <= 8'b0;
        state <= IDLE;
        bit_count <= 0;
        error_pos <= 0;
        output_valid <= 0;
        decode_counter <= 0;
        dec_ena <= 0;
        ready <= 1;
        decode_number <= 0;  // Reset decode count on clear
        decode_complete <= 0;
    end else begin
        case (state)
            IDLE: begin
                decode_complete <= 0;  // Clear the pulse
                if (decode_en) begin
                    state <= DECODE;
                    dec_ena <= 0; // Enable the decoder
                    decode_counter <= 0; // Reset the counter
                    error_pos <= 0;
                    bit_count <= 0;
                    ready <= 0;
                    decode_number <= decode_number + 1;
                    // $display("[%0t] RS_DECODE_WRAPPER: Starting decode operation #%d", 
                    //          $time, decode_number);
                end
            end
            DECODE: begin
                if (decode_counter < k) begin
                    // Feed data bytes 0 to k-1
                    dec_ena <= 1;
                    received <= encoded_data[decode_counter*8 +: 8]; // Grab the next byte of input data
                    decode_counter <= decode_counter + 1; // Increment counter
                end else if (decode_counter == k) begin
                    // Stop feeding, start waiting for decoder to process
                    dec_ena <= 0;
                    decode_counter <= decode_counter + 1;
                    // $display("  [%0t] RS_DECODE_WRAPPER: Fed all %d bytes, waiting for decoder to process", $time, k);
                end else if (decode_counter < k + 4) begin
                    // Wait 4 cycles for decoder to compute syndromes and set with_error
                    decode_counter <= decode_counter + 1;
                end else begin
                    // After 4 cycle wait, check with_error
                    // $display("[%0t] RS_DECODE_WRAPPER: Decode #%d complete, with_error=%b", 
                    //          $time, decode_number, with_error);
                    if (with_error) begin
                        // $display("[%0t] RS_DECODE_WRAPPER: Errors detected, entering COLLECT_ERROR state", $time);
                        // $display("[%0t] RS_DECODE_WRAPPER: Expecting to collect %d bytes", $time, k);
                        state <= COLLECT_ERROR;
                        decode_counter <= 0;
                    end else begin
                        // No errors, go straight to COMPLETE
                        // $display("  [%0t] RS_DECODE_WRAPPER: No errors detected, transitioning to COMPLETE", $time);
                        state <= COMPLETE;
                    end
                end
            end
            COLLECT_ERROR: begin
                // Debug: Track error collection
                if (valid) begin
                    error_pos[bit_count*8 +: 8] <= error; // Collect error data
                    // $display("[%0t] RS_DECODE_WRAPPER: COLLECT_ERROR - byte %d = %02h (valid=1)", 
                    //          $time, bit_count, error);
                    bit_count <= bit_count + 1; // Increment bit_count to point to the next byte
                    if (bit_count >= k-1) begin // Check if all bytes processed
                        // $display("[%0t] RS_DECODE_WRAPPER: Collected all %d bytes, moving to COMPLETE", 
                        //          $time, k);
                        state <= COMPLETE;
                    end
                end else begin
                    // Debug: Show when valid is low
                    if (bit_count > 0 && bit_count < k) begin
                        // $display("[%0t] RS_DECODE_WRAPPER: COLLECT_ERROR - valid=0, collected %d/%d bytes so far", 
                        //          $time, bit_count, k);
                    end
                    state <= COLLECT_ERROR; // Stay in COLLECT_ERROR state
                end
            end
            COMPLETE: begin
                if (with_error) begin
                    // $display("[%0t] RS_DECODE_WRAPPER: COMPLETE - Final error_pos pattern:", $time);
                    // $display("  error_pos = %h", error_pos);
                end
                $display("[%0t] RS_DECODE_WRAPPER: Decode #%d COMPLETE, pulsing decode_complete, with_error=%b", 
                         $time, decode_number, with_error);
                output_valid <= 1; // Indicate that the output data is valid
                decode_complete <= 1; // Pulse to indicate decode is fully complete
                state <= IDLE; // Reset to idle state for the next operation
                bit_count <= 0; // Reset bit_count for the next operation
                ready <= 1;
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule