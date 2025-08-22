`timescale 1ns / 1ps

// 1D Reed-Solomon Encoder with ZGC IP Integration

module rs_1d_encoder #(
    parameter N = 200,           // Total symbols in codeword (ZGC IP)
    parameter K = 168,           // Information symbols (ZGC IP)
    parameter SYMBOL_WIDTH = 8   // Bits per symbol
)(
    input wire clk,
    input wire rstn,
    input wire data_in,
    input wire data_in_valid,
    output wire data_out,
    output wire data_out_valid,
    output wire ready             // Ready to accept input data
);

    // Internal wires for SerDes + ZGC IP pipeline
    wire [K*SYMBOL_WIDTH-1:0] s2p_data;        // 1344 bits to encoder
    wire s2p_valid;
    wire enc_ready;                            // Ready signal FROM encoder
    wire [N*SYMBOL_WIDTH-1:0] enc_data_raw;    // Raw data from encoder
    reg [N*SYMBOL_WIDTH-1:0] enc_data;         // Processed data (passthrough for testing)
    wire enc_valid_raw;                        // Raw valid from encoder
    reg enc_valid;                             // Processed valid signal
    wire p2s_ready;                            // Ready signal FROM P2S

    // Track encoder busy state - MUST be declared before use in wire assignments
    reg encoder_busy;

    // Create proper ready signal for S2P with correct cascading
    // S2P should only accept new data when entire pipeline is ready
    wire s2p_ready_internal = enc_ready && !encoder_busy && p2s_ready;
    
    // Generate encode pulse on valid && ready (one cycle due to S2P deassertion behavior)
    wire encode_en_pulse = s2p_valid && s2p_ready_internal;

    // Track encoder busy state (declared above)
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            encoder_busy <= 0;
        end else if (encode_en_pulse) begin
            encoder_busy <= 1;  // Encoder starts processing
        end else if (enc_valid_raw) begin
            encoder_busy <= 0;  // Encoder finished
        end
    end
    
    // Debug monitoring for encoder data flow
    reg [31:0] enc_frame_count;
    always @(posedge clk) begin
        if (!rstn) begin
            enc_frame_count <= 0;
        end else begin
            // if (encode_en_pulse) begin
            //     enc_frame_count <= enc_frame_count + 1;
            //     $display("  [%0t] ENCODER: Triggering encode FRAME %d, s2p_valid=%b, s2p_ready_internal=%b, enc_ready=%b, p2s_ready=%b",
            //              $time, enc_frame_count + 1, s2p_valid, s2p_ready_internal, enc_ready, p2s_ready);
            //     $display("  [%0t] ENCODER: Frame %d input data first 32 bits: %08h", 
            //              $time, enc_frame_count + 1, s2p_data[31:0]);
            // end
            // if (enc_valid && !p2s_ready) begin
            //     $display("  [%0t] ENCODER WARNING: Trying to send data but P2S not ready!", $time);
            // end
            // if (enc_valid_raw) begin
            //     $display("  [%0t] ENCODER: Frame %d output valid from ZGC, p2s_ready=%b, p2s_buffer_full=%b", 
            //              $time, enc_frame_count, p2s_ready, p2s.buffer_full);
            //     $display("  [%0t] ENCODER: Frame %d encoded data first 32 bits: %08h", 
            //              $time, enc_frame_count, enc_data_raw[31:0]);
            // end
            // if (s2p_valid && !s2p_ready_internal) begin
            //     $display("  [%0t] ENCODER: S2P has data but not ready! enc_ready=%b, p2s_ready=%b, encoder_busy=%b",
            //              $time, enc_ready, p2s_ready, encoder_busy);
            // end
        end
    end
    
    // Clear pulse generator for encoder - pulse clrn low between frames
    reg enc_frame_complete;
    reg [2:0] enc_clrn_counter;
    reg enc_clrn_internal;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            enc_frame_complete <= 0;
            enc_clrn_counter <= 0;
            enc_clrn_internal <= 1;  // clrn is active low, so default high
        end else begin
            // Detect frame completion: encoder output accepted by P2S
            enc_frame_complete <= enc_valid && p2s_ready;
            
            // Generate 3-cycle active-low pulse after frame completion
            if (enc_frame_complete) begin
                enc_clrn_internal <= 0;  // Start clear pulse
                enc_clrn_counter <= 3;
            end else if (enc_clrn_counter > 0) begin
                enc_clrn_counter <= enc_clrn_counter - 1;
                if (enc_clrn_counter == 1) begin
                    enc_clrn_internal <= 1;  // End clear pulse
                end
            end
        end
    end
    
    // Use only encoder output (no passthrough)
    localparam PARITY_BITS = (N - K) * SYMBOL_WIDTH;
    
    // Proper handshaking: Hold valid HIGH until P2S accepts
    reg enc_data_pending;  // Flag indicating encoder has data waiting
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            enc_data <= 0;
            enc_valid <= 0;
            enc_data_pending <= 0;
        end else begin
            // Capture encoder output when it becomes valid
            if (enc_valid_raw && !enc_data_pending) begin
                // Store encoder output and mark as pending
                enc_data <= enc_data_raw;
                enc_data_pending <= 1;
            end
            
            // Hold valid HIGH until P2S accepts (proper ready/valid protocol)
            if (enc_data_pending) begin
                enc_valid <= 1;  // Assert and HOLD valid
                
                // Only clear when transfer completes (valid && ready)
                if (enc_valid && p2s_ready) begin
                    enc_data_pending <= 0;  // Transfer complete
                end
            end else begin
                enc_valid <= 0;  // No data to send
            end
        end
    end

    // Ready signal now declared above with encode pulse

    // Buffer full signal from S2P
    wire s2p_buffer_full;
    
    // Serial to Parallel converter - collect input bits
    serial_to_parallel #(
        .N(N), 
        .K(K), 
        .SYMBOL_WIDTH(SYMBOL_WIDTH), 
        .MODE("ENCODE")
    ) s2p (
        .clk(clk), 
        .rstn(rstn),
        .serial_data_in(data_in), 
        .serial_data_valid(data_in_valid),
        .parallel_data_out(s2p_data), 
        .parallel_data_valid(s2p_valid), 
        .parallel_data_ready(s2p_ready_internal),  // Use internal ready signal
        .buffer_full(s2p_buffer_full)  // Get buffer status
    );

    // ZGC RS Encoder Wrapper - performs actual encoding
    rs_encode_wrapper zgc_enc (
        .clk(clk), 
        .rst_n(rstn), 
        .clrn(enc_clrn_internal), 
        .scan_mode(1'b0),
        .encode_en(encode_en_pulse),           // Use pulse instead of continuous
        .datain(s2p_data),                      // Use data directly (no reversal)
        .encoded_data(enc_data_raw), 
        .valid(enc_valid_raw), 
        .ready(enc_ready),                     // OUTPUT from encoder
        .ready_re(),  // Unused debug outputs
        .valid_re(),
        .encoded_data_re()
    );

    // Parallel to Serial converter - output encoded bits
    parallel_to_serial #(
        .N(N), 
        .K(K), 
        .SYMBOL_WIDTH(SYMBOL_WIDTH), 
        .MODE("ENCODE")
    ) p2s (
        .clk(clk), 
        .rstn(rstn),
        .parallel_data_in(enc_data), 
        .parallel_data_valid(enc_valid), 
        .parallel_data_ready(p2s_ready),
        .serial_data_out(data_out), 
        .serial_data_valid(data_out_valid)  // Direct connection - backpressure through channel
    );
    
    // Ready signal - encoder can accept data when S2P FIFO is not full
    assign ready = !s2p_buffer_full;

endmodule

// 1D Reed-Solomon Decoder with ZGC IP Integration
module rs_1d_decoder #(
    parameter N = 200,            // Total symbols (ZGC IP)
    parameter K = 168,            // Information symbols (ZGC IP)
    parameter SYMBOL_WIDTH = 8   // Bits per symbol
)(
    input wire clk,
    input wire rstn,
    input wire data_in,              // Single bit input
    input wire data_in_valid,
    output wire data_out,            // Single bit output
    output wire data_out_valid,
    output wire ready                // Ready to accept input data
);

    // Internal wires for SerDes + ZGC IP pipeline  
    wire [N*SYMBOL_WIDTH-1:0] s2p_data;        // 1600 bits to decoder
    wire s2p_valid;
    wire dec_ready;                            // Ready signal FROM decoder
    wire [N*SYMBOL_WIDTH-1:0] error_pos;       // Error positions from decoder
    wire dec_valid_raw;                        // Raw output from decoder (may be stuck high)
    reg dec_valid_pulse;                       // Pulsed version for P2S
    wire p2s_ready;                            // Ready signal FROM P2S
    wire with_error;
    
    // Track decoder busy state - MUST be declared before use in wire assignments
    reg decoder_busy;
    
    // Create proper ready signal for S2P decoder with correct cascading
    wire s2p_ready_internal_dec = dec_ready && !decoder_busy && p2s_ready;
    
    wire decode_en_pulse = s2p_valid && s2p_ready_internal_dec;
    reg [31:0] decoder_instance_id;
    reg [31:0] dec_frame_count;
    
    // Debug monitoring for decoder data flow
    always @(posedge clk) begin
        if (!rstn) begin
            dec_frame_count <= 0;
        end else begin
            // if (decode_en_pulse) begin
            //     dec_frame_count <= dec_frame_count + 1;
            //     $display("  [%0t] RS_1D_DEC[%08h]: Triggering decode FRAME %d",
            //              $time, decoder_instance_id, dec_frame_count + 1);
            //     $display("  [%0t] RS_1D_DEC[%08h]: Frame %d input data first 32 bits: %08h", 
            //              $time, decoder_instance_id, dec_frame_count + 1, s2p_data[31:0]);
            // end
            // if (dec_valid_raw) begin
            //     $display("  [%0t] RS_1D_DEC[%08h]: Frame %d decoder output valid, with_error=%b", 
            //              $time, decoder_instance_id, dec_frame_count, with_error);
            //     if (with_error) begin
            //         $display("  [%0t] RS_1D_DEC[%08h]: Frame %d ERROR PATTERN first 32 bits: %08h", 
            //                  $time, decoder_instance_id, dec_frame_count, error_pos[31:0]);
            //         // Show more of the error pattern to understand what's happening
            //         $display("  [%0t] RS_1D_DEC[%08h]: Frame %d ERROR PATTERN [63:32]: %08h", 
            //                  $time, decoder_instance_id, dec_frame_count, error_pos[63:32]);
            //         $display("  [%0t] RS_1D_DEC[%08h]: Frame %d ERROR PATTERN [95:64]: %08h", 
            //                  $time, decoder_instance_id, dec_frame_count, error_pos[95:64]);
            //     end
            // end
        end
    end
    
    // Track decoder busy state (declared above)
    
    // Register to hold corrected data when decoder completes
    reg [K*SYMBOL_WIDTH-1:0] corrected_data_reg;
    reg corrected_data_valid;
    reg corrected_data_pending;  // Flag indicating decoder has data waiting
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            decoder_busy <= 0;
        end else if (decode_en_pulse) begin
            decoder_busy <= 1;  // Decoder starts processing
        end else if (dec_valid_raw) begin
            decoder_busy <= 0;  // Decoder finished
        end
    end
    
    initial begin
        decoder_instance_id = $random;
        // $display("RS_1D_DECODER Instance ID: %08h", decoder_instance_id);
    end
    
    // Clear pulse generator for decoder - pulse clrn low between frames
    reg dec_frame_complete;
    reg [2:0] dec_clrn_counter;
    reg dec_clrn_internal;
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dec_frame_complete <= 0;
            dec_clrn_counter <= 0;
            dec_clrn_internal <= 1;  // clrn is active low, so default high
        end else begin
            // Detect frame completion: corrected data accepted by P2S
            dec_frame_complete <= corrected_data_valid && p2s_ready;
            
            // Generate 3-cycle active-low pulse after frame completion
            if (dec_frame_complete) begin
                dec_clrn_internal <= 0;  // Start clear pulse
                dec_clrn_counter <= 3;
                // $display("  [%0t] RS_1D_DEC[%08h]: Pulsing clrn low for decoder reset", $time, decoder_instance_id);
            end else if (dec_clrn_counter > 0) begin
                dec_clrn_counter <= dec_clrn_counter - 1;
                if (dec_clrn_counter == 1) begin
                    dec_clrn_internal <= 1;  // End clear pulse
                    // $display("  [%0t] RS_1D_DEC[%08h]: clrn pulse complete", $time, decoder_instance_id);
                end
            end
        end
    end
    
    // Edge detection for decoder output_valid (workaround for stuck-high bug)
    reg dec_valid_raw_d;
    reg dec_valid_raw_d2;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            dec_valid_raw_d <= 0;
            dec_valid_raw_d2 <= 0;
            dec_valid_pulse <= 0;
        end else begin
            dec_valid_raw_d <= dec_valid_raw;
            dec_valid_raw_d2 <= dec_valid_raw_d;
            // Only generate pulse on rising edge
            dec_valid_pulse <= dec_valid_raw && !dec_valid_raw_d;
        end
    end
    
    // Apply error correction from decoder
    wire [N*SYMBOL_WIDTH-1:0] corrected_codeword;
    // XOR the input with error pattern to get corrected data (no reversal)
    assign corrected_codeword = s2p_data ^ error_pos;
    
    // Extract information symbols (first K symbols) from corrected codeword
    wire [K*SYMBOL_WIDTH-1:0] corrected_data;
    assign corrected_data = corrected_codeword[K*SYMBOL_WIDTH-1:0];
    
    // Corrected data registers now declared above
    
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            corrected_data_reg <= 0;
            corrected_data_valid <= 0;
            corrected_data_pending <= 0;
        end else begin
            // Capture corrected data when decoder completes
            if (dec_valid_pulse && !corrected_data_pending) begin
                // Debug: show what correction is being applied
                // if (with_error) begin
                //     $display("  [%0t] RS_1D_DEC[%08h]: Applying error correction to frame %d",
                //              $time, decoder_instance_id, dec_frame_count);
                //     $display("  [%0t] RS_1D_DEC[%08h]: Original data: %08h, Error pattern: %08h, Corrected: %08h",
                //              $time, decoder_instance_id, s2p_data[31:0], error_pos[31:0], corrected_data[31:0]);
                // end else begin
                //     $display("  [%0t] RS_1D_DEC[%08h]: No errors in frame %d, passing through original data",
                //              $time, decoder_instance_id, dec_frame_count);
                // end
                corrected_data_reg <= corrected_data;
                corrected_data_pending <= 1;  // Mark data as pending
            end
            
            // Hold valid HIGH until P2S accepts (proper ready/valid protocol)
            if (corrected_data_pending) begin
                corrected_data_valid <= 1;  // Assert and HOLD valid
                
                // Only clear when transfer completes (valid && ready)
                if (corrected_data_valid && p2s_ready) begin
                    corrected_data_pending <= 0;  // Transfer complete
                end
            end else begin
                corrected_data_valid <= 0;  // No data to send
            end
        end
    end

    // Ready signal for decoder now declared above

    // Buffer full signal from S2P
    wire s2p_buffer_full_dec;
    
    // Serial to Parallel converter - collect encoded bits
    serial_to_parallel #(
        .N(N), 
        .K(K), 
        .SYMBOL_WIDTH(SYMBOL_WIDTH), 
        .MODE("DECODE")
    ) s2p (
        .clk(clk), 
        .rstn(rstn),
        .serial_data_in(data_in), 
        .serial_data_valid(data_in_valid),
        .parallel_data_out(s2p_data), 
        .parallel_data_valid(s2p_valid), 
        .parallel_data_ready(s2p_ready_internal_dec),  // Use internal ready signal
        .buffer_full(s2p_buffer_full_dec)  // Get buffer status
    );

    // ZGC RS Decoder Wrapper - performs error correction
    rs_decode_wrapper zgc_dec (
        .clk(clk), 
        .rst_n(rstn), 
        .clrn(dec_clrn_internal), 
        .scan_mode(1'b0),
        .decode_en(decode_en_pulse),           // Use pulse instead of continuous
        .encoded_data(s2p_data),               // Use data directly (no reversal)
        .error_pos(error_pos),       
        .output_valid(dec_valid_raw),          // Raw signal (may be stuck high)
        .ready(dec_ready),                     // OUTPUT from decoder
        .with_error(with_error),
        .ready_re(),                           // Unused debug outputs
        .output_valid_re(),
        .error_pos_re(),
        .with_error_re()
    );

    // Parallel to Serial converter - output corrected information bits
    parallel_to_serial #(
        .N(N), 
        .K(K), 
        .SYMBOL_WIDTH(SYMBOL_WIDTH), 
        .MODE("DECODE")
    ) p2s (
        .clk(clk), 
        .rstn(rstn),
        .parallel_data_in(corrected_data_reg),        // Use registered corrected data
        .parallel_data_valid(corrected_data_valid),   // Use corrected data valid signal
        .parallel_data_ready(p2s_ready),       
        .serial_data_out(data_out), 
        .serial_data_valid(data_out_valid)
    );
    
    // Ready signal - decoder can accept data when S2P FIFO is not full
    assign ready = !s2p_buffer_full_dec;

endmodule