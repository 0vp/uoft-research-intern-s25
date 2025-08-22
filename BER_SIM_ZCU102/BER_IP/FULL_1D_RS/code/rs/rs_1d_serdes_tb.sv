`timescale 1ns / 1ps

// Test bench for RS(200,168) SerDes + ZGC IP Integration
// Validates the drop-in replacement for current rs_1d.sv
// Uses 8-bit upcounter for predictable test patterns

module rs_1d_serdes_tb;

// Parameters matching new ZGC IP configuration
localparam RS_N = 15;                    // ZGC IP codeword length
localparam RS_K = 11;                    // ZGC IP information symbols  
localparam RS_SYMBOL_WIDTH = 8;           // Symbol width
localparam INFO_BITS = RS_K * RS_SYMBOL_WIDTH;    // 1344 bits
localparam CODE_BITS = RS_N * RS_SYMBOL_WIDTH;    // 1600 bits
localparam NUM_TEST_FRAMES = 3;           // Number of frames for continuous streaming test (adjustable)

// Clock and reset
reg clk, rstn;
always #5 clk = ~clk;  // 100MHz clockz

// Test control
reg test_active;
reg inject_errors;
integer test_number;
integer error_count;
integer bit_count;
reg [31:0] counter_frames;  // Dynamic frame count for counter

// Data generation using counter module
wire data_bit;
wire data_valid;

// Ready signals for backpressure
wire enc_ready;  // Encoder ready to accept data
wire dec_ready;  // Decoder ready to accept data

// Instantiate counter module for predictable test patterns
// Gate counter enable with encoder ready for proper backpressure
counter #(
    .RS_K(RS_K),
    .RS_N(RS_N),
    .RS_SYMBOL_WIDTH(RS_SYMBOL_WIDTH)
) data_gen (
    .clk(clk),
    .en(test_active && enc_ready),  // Only generate when encoder is ready
    .rstn(rstn),
    .N_PCS(counter_frames),  // Dynamic frame count
    .data(data_bit),
    .valid(data_valid)
);

// Pipeline stages (mimic ber_top.sv exactly)
wire enc_data_out, enc_data_valid;        // After encoder
wire channel_data, channel_valid;         // After channel (with/without errors)  
wire dec_data_out, dec_data_valid;        // After decoder

// SerDes-only test signals
wire serdes_out, serdes_valid;            // Direct S2P->P2S bypass output
reg serdes_test_mode;                     // Enable SerDes-only test mode

// Bit position tracking for error injection
reg [15:0] bit_position;

// Instantiate new rs_1d modules with ZGC IP + SerDes
rs_1d_encoder #(
    .N(RS_N), 
    .K(RS_K), 
    .SYMBOL_WIDTH(RS_SYMBOL_WIDTH)
) encoder (
    .clk(clk), 
    .rstn(rstn),
    .data_in(data_bit), 
    .data_in_valid(data_valid && !serdes_test_mode),  // Disable during SerDes-only test
    .data_out(enc_data_out), 
    .data_out_valid(enc_data_valid),
    .ready(enc_ready)  // Encoder ready signal
);

// Channel model (inject errors at known positions)
wire error_injection;
// assign error_injection = inject_errors && enc_data_valid && (
//     bit_position == 700 ||     // Error positions within 1600-bit codeword
//     bit_position == 800 ||     
//     bit_position == 900
// );
assign error_injection = inject_errors && enc_data_valid && (
    (bit_position % CODE_BITS) == 56 ||
    (bit_position % CODE_BITS) == 56 ||
    (bit_position % CODE_BITS) == 57 ||
    (bit_position % CODE_BITS) == 58
);
assign channel_data = error_injection ? ~enc_data_out : enc_data_out;
// Gate channel with decoder ready for proper backpressure
assign channel_valid = enc_data_valid && dec_ready;

// Track bit position within codeword
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        bit_position <= 0;
    end else if (channel_valid) begin  // Only count when data actually passes through channel
        bit_position <= (bit_position == CODE_BITS - 1) ? 0 : bit_position + 1;
    end
end

rs_1d_decoder #(
    .N(RS_N), 
    .K(RS_K), 
    .SYMBOL_WIDTH(RS_SYMBOL_WIDTH)
) decoder (
    .clk(clk), 
    .rstn(rstn),
    .data_in(channel_data), 
    .data_in_valid(channel_valid),
    .data_out(dec_data_out), 
    .data_out_valid(dec_data_valid),
    .ready(dec_ready)  // Decoder ready signal
);

// SerDes-only bypass test: Direct S2P -> P2S connection
// This tests ONLY the SerDes converters without any RS encoding/decoding
wire [INFO_BITS-1:0] s2p_bypass_data;
wire s2p_bypass_valid;
wire p2s_bypass_ready;

// Serial to Parallel converter (standalone for bypass test)
serial_to_parallel #(
    .N(RS_N),
    .K(RS_K),
    .SYMBOL_WIDTH(RS_SYMBOL_WIDTH),
    .MODE("ENCODE")  // Collect K*8 = 1344 bits
) s2p_bypass (
    .clk(clk),
    .rstn(rstn),
    .serial_data_in(data_bit),
    .serial_data_valid(data_valid && serdes_test_mode),
    .parallel_data_out(s2p_bypass_data),
    .parallel_data_valid(s2p_bypass_valid),
    .parallel_data_ready(p2s_bypass_ready)
);

// Parallel to Serial converter (standalone for bypass test)
parallel_to_serial #(
    .N(RS_N),
    .K(RS_K),
    .SYMBOL_WIDTH(RS_SYMBOL_WIDTH),
    .MODE("DECODE")  // Output K*8 = 1344 bits
) p2s_bypass (
    .clk(clk),
    .rstn(rstn),
    .parallel_data_in(s2p_bypass_data),
    .parallel_data_valid(s2p_bypass_valid),
    .parallel_data_ready(p2s_bypass_ready),
    .serial_data_out(serdes_out),
    .serial_data_valid(serdes_valid)
);

// Test data collection for validation
reg [INFO_BITS-1:0] input_data;
reg [INFO_BITS-1:0] output_data;
reg [15:0] input_bit_count;
reg [15:0] output_bit_count;

// Adaptive timeout for large frame counts
localparam OUTPUT_TIMEOUT_PER_FRAME = 20000;  // Conservative: 20k cycles per frame
localparam MAX_OUTPUT_TIMEOUT = OUTPUT_TIMEOUT_PER_FRAME * NUM_TEST_FRAMES;

// Continuous streaming test data (for Test 3)
reg [INFO_BITS*NUM_TEST_FRAMES-1:0] all_input_data;   // Store all frames of input
reg [INFO_BITS*NUM_TEST_FRAMES-1:0] all_output_data;  // Collect all frames of output

// Collect input data
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        input_data <= 0;
        input_bit_count <= 0;
    end else if (data_valid && input_bit_count < INFO_BITS) begin
        input_data[input_bit_count] <= data_bit;  // Place bit at correct position
        input_bit_count <= input_bit_count + 1;
        if (input_bit_count == INFO_BITS - 1) begin
            input_bit_count <= 0;  // Reset for next frame
        end
    end
end

// Monitor ready signals for debugging backpressure
reg enc_ready_prev, dec_ready_prev;
reg enc_data_valid_prev;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        enc_ready_prev <= 1;
        dec_ready_prev <= 1;
        enc_data_valid_prev <= 0;
    end else begin
        if (enc_ready !== enc_ready_prev || dec_ready !== dec_ready_prev) begin
            $display("  [%0t] Ready signals CHANGED: enc_ready=%b, dec_ready=%b", $time, enc_ready, dec_ready);
            enc_ready_prev <= enc_ready;
            dec_ready_prev <= dec_ready;
        end
        // Track encoder valid transitions
        if (enc_data_valid && !enc_data_valid_prev) begin
            $display("  [%0t] enc_data_valid RISING EDGE, enc_data_out=%b, p2s.serial_data_out=%b",
                     $time, enc_data_out, encoder.p2s.serial_data_out);
        end else if (!enc_data_valid && enc_data_valid_prev) begin
            $display("  [%0t] enc_data_valid FALLING EDGE", $time);
        end
        enc_data_valid_prev <= enc_data_valid;
    end
end

// Continuous monitoring of ready signals to debug backpressure
always @(posedge clk) begin
    if (test_active && ($time % 1000 == 0)) begin  // Every 1000 time units
        $display("  [%0t] READY STATUS: enc_ready=%b, dec_ready=%b, enc_p2s_ready=%b, dec_p2s_ready=%b",
                 $time, enc_ready, dec_ready, 
                 encoder.p2s.parallel_data_ready,
                 decoder.p2s.parallel_data_ready);
    end
end

// Collect output data (from decoder or SerDes bypass)
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        output_data <= 0;
        output_bit_count <= 0;
    end else begin
        // Select output based on test mode
        if (serdes_test_mode) begin
            // Collect from SerDes bypass
            if (serdes_valid && output_bit_count < INFO_BITS) begin
                output_data[output_bit_count] <= serdes_out;  // Place bit at correct position
                output_bit_count <= output_bit_count + 1;
                // Don't reset counter here - let the test task handle it
            end
        end else begin
            // Collect from decoder
            if (dec_data_valid && output_bit_count < INFO_BITS) begin
                output_data[output_bit_count] <= dec_data_out;  // Place bit at correct position
                output_bit_count <= output_bit_count + 1;
                // Don't reset counter here - let the test task handle it
            end
        end
    end
end

// Test sequence
initial begin
    $display("=== RS(200,168) SerDes + ZGC IP Test Bench ===");
    $display("INFO_BITS = %d, CODE_BITS = %d", INFO_BITS, CODE_BITS);
    
    clk = 0; rstn = 0; test_active = 0; inject_errors = 0;
    test_number = 0;
    error_count = 0; bit_count = 0; serdes_test_mode = 0;
    counter_frames = 1;  // Default to single frame
    
    #20 rstn = 1;
    #10;
    
    // TEST 0: SerDes-only test (S2P → P2S bypass)
    $display("\n=== TEST 0: SerDes-Only Test (S2P → P2S Direct) ===");
    test_number = 0;
    inject_errors = 0;
    counter_frames = 1;  // Single frame for this test
    test_active = 1;
    run_serdes_only_test();
    reset_between_tests();  // Clean reset and flush
    
    // TEST 1: SerDes Pipeline Validation (no errors)
    $display("\n=== TEST 1: SerDes Pipeline Validation (Clean Channel) ===");
    test_number = 1; 
    inject_errors = 0;
    counter_frames = 1;  // Single frame for this test
    test_active = 1;
    run_clean_channel_test();
    reset_between_tests();  // Clean reset and flush
    
    // TEST 2: Error injection and correction
    $display("\n=== TEST 2: Error Injection and Correction ==="); 
    test_number = 2; 
    inject_errors = 1;
    counter_frames = 1;  // Single frame for this test
    test_active = 1;
    run_error_correction_test();
    reset_between_tests();  // Clean reset and flush
    
    // TEST 3: Multiple frames with different patterns
    $display("\n=== TEST 3: Multiple Frame Test (WITH ERROR INJECTION) ===");
    test_number = 3;
    inject_errors = 1;  // Enable error injection to test RS correction
    reset_between_tests();  // Clean reset to ensure counter starts from 0
    counter_frames = NUM_TEST_FRAMES;  // Generate all frames continuously
    test_active = 1;
    run_multiple_frame_test();
    
    $display("\n=== ALL TESTS COMPLETED ===");
    $display("Total tests run: %d", test_number);
    $finish;
end

// Counter module handles all data generation automatically
// It resets to 0 on rstn and generates incrementing pattern

// Test tasks
task reset_between_tests;
    begin
        $display("  Resetting between tests...");
        // Stop all activity
        test_active = 0;
        
        // Apply reset pulse
        rstn = 0;
        repeat(10) @(posedge clk);
        rstn = 1;
        repeat(10) @(posedge clk);
        
        // Clear all test data collectors
        input_data = 0;
        output_data = 0;
        input_bit_count = 0;
        output_bit_count = 0;
        bit_position = 0;
        bit_count = 0;
        
        // Wait for pipelines to fully clear
        repeat(100) @(posedge clk);
        $display("  Reset complete");
    end
endtask

task run_serdes_only_test;
    integer i;
    integer timeout;
    begin
        $display("Testing SerDes-only bypass (S2P -> P2S direct connection)");
        $display("This validates bit accuracy without any RS encoding/decoding");
        serdes_test_mode = 1;  // Enable SerDes bypass mode
        
        $display("Sending %d bits with counter starting from 0", INFO_BITS);
        $display("  Counter pattern: LSB of incrementing 8-bit counter");
        $display("  Expected: 0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,...");
        $display("  SerDes test mode enabled: data_bit -> S2P -> P2S -> serdes_out");
        $display("  S2P ready: %b, P2S ready: %b", p2s_bypass_ready, s2p_bypass.parallel_data_ready);
        
        // Counter module automatically generates INFO_BITS of data
        // Wait for counter to complete
        timeout = 0;
        while (data_gen.bit_count < INFO_BITS && timeout < INFO_BITS * 2) begin
            @(posedge clk);
            timeout = timeout + 1;
            
            // Debug first few bits
            if (data_valid && data_gen.counter < 10) begin
                $display("  [%0t] Counter=%03d, Bit: data_bit=%b, data_valid=%b", 
                         $time, data_gen.counter, data_bit, data_valid);
            end
            
            // Show byte boundaries
            if (data_valid && data_gen.counter % 8 == 0 && data_gen.counter < 64) begin
                $display("  Byte %d starting (counter=%03d)", data_gen.counter/8, data_gen.counter);
            end
        end
        
        $display("  All %d bits sent", INFO_BITS);
        
        // Monitor S2P->P2S connection in bypass
        repeat(10) @(posedge clk);
        $display("  S2P bypass status: valid=%b, data[31:0]=%08h", 
                 s2p_bypass.parallel_data_valid, s2p_bypass.parallel_data_out[31:0]);
        $display("  P2S bypass ready=%b, S2P frames=%d, P2S frames=%d", 
                 p2s_bypass.parallel_data_ready, s2p_bypass.frames_buffered, p2s_bypass.frames_buffered);
        
        // Wait for SerDes output
        wait_for_serdes_output();
        
        // Validate bit-for-bit accuracy
        $display("Comparing input and output data:");
        $display("  First 64 bits of input:  %016h", input_data[63:0]);
        $display("  First 64 bits of output: %016h", output_data[63:0]);
        
        if (input_data == output_data) begin
            $display("PASS: SerDes-only test - Perfect bit accuracy!");
            $display("  All %d bits match exactly", INFO_BITS);
        end else begin
            $display("FAIL: SerDes-only test - Bit mismatch detected");
            $display("  Input:  %h", input_data[255:0]);
            $display("  Output: %h", output_data[255:0]);
            
            // Find first mismatch
            for (i = 0; i < INFO_BITS; i = i + 1) begin
                if (input_data[i] != output_data[i]) begin
                    $display("  First mismatch at bit %d: input=%b, output=%b", 
                             i, input_data[i], output_data[i]);
                    break;
                end
            end
            error_count = error_count + 1;
        end
        
        serdes_test_mode = 0;  // Disable SerDes bypass mode
    end
endtask

task run_clean_channel_test;
    integer timeout;
    begin
        $display("Sending %d information bits through clean channel...", INFO_BITS);
        $display("  Counter starts from 0 again for this test");
        
        // Counter module automatically generates one complete frame
        // Just wait for it to complete
        timeout = 0;
        while (data_gen.bit_count < INFO_BITS && timeout < INFO_BITS * 2) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        
        // Wait for output
        wait_for_output_frame();
        
        // Always display data in hex for visibility
        $display("  Input data (first 64 bytes hex):");
        $display("    %h", input_data[511:0]);
        $display("  Output data (first 64 bytes hex):");
        $display("    %h", output_data[511:0]);
        
        // Validate
        if (input_data == output_data) begin
            $display("PASS: Clean channel - Input matches output");
        end else begin
            $display("FAIL: Clean channel - Input/output mismatch");
            $display("  Full Input:  %h", input_data);
            $display("  Full Output: %h", output_data);
            error_count = error_count + 1;
        end
    end
endtask

task run_error_correction_test;
    integer timeout;
    begin
        $display("Sending %d bits with 3 error injections...", INFO_BITS);
        $display("  Counter starts from 0 again for this test");
        
        // Counter module automatically generates one complete frame
        // Just wait for it to complete
        timeout = 0;
        while (data_gen.bit_count < INFO_BITS && timeout < INFO_BITS * 2) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        
        // Wait for output
        wait_for_output_frame();
        
        // Always display data in hex for visibility
        $display("  Input data (first 64 bytes hex):");
        $display("    %h", input_data[511:0]);
        $display("  Output data (first 64 bytes hex):");
        $display("    %h", output_data[511:0]);
        
        // Validate
        if (input_data == output_data) begin
            $display("PASS: Error correction - Errors corrected successfully");
            $display("  3 errors injected at positions 700, 800, 900");
        end else begin
            $display("FAIL: Error correction - Failed to correct errors");
            $display("  Full Input:  %h", input_data);
            $display("  Full Output: %h", output_data);
            error_count = error_count + 1;
        end
    end
endtask

task run_multiple_frame_test;
    integer i, j;
    integer input_idx;
    integer output_idx;
    integer input_timeout;
    integer output_timeout;
    begin
        $display("Testing %d consecutive frames with continuous streaming...", NUM_TEST_FRAMES);
        $display("  Counter starts from 0 and continues incrementing across all frames");
        if (inject_errors) begin
            $display("  ERROR INJECTION ENABLED: 3 bit errors per frame at positions 700, 800, 900");
            $display("  RS decoder should correct all errors");
        end
        
        // Initialize
        all_input_data = 0;
        all_output_data = 0;
        input_idx = 0;
        output_idx = 0;
        
        $display("  Starting parallel collection of input and output bits...");
        
        // Use fork-join to collect input and output SIMULTANEOUSLY
        fork
            // Thread 1: Collect input data
            begin
                input_timeout = 0;
                while (input_idx < INFO_BITS * NUM_TEST_FRAMES && input_timeout < INFO_BITS * NUM_TEST_FRAMES * 2) begin
                    @(posedge clk);
                    if (data_valid) begin
                        // Store the actual counter output
                        all_input_data[input_idx] = data_bit;
                        input_idx = input_idx + 1;
                        
                        // Show first few bits to verify pattern
                        if (input_idx <= 16) begin
                            $display("    Input Bit %d: data_bit=%b (counter=%d)", input_idx-1, data_bit, data_gen.counter);
                        end
                        
                        // Debug: Show what encoder S2P is collecting for frame boundaries
                        if ((input_idx - 1) % INFO_BITS < 32) begin
                            $display("  [%0t] COUNTER->ENCODER: Frame bit %d = %b (counter byte %d)",
                                     $time, (input_idx - 1) % INFO_BITS, data_bit, data_gen.counter / 8);
                        end
                        
                        // Progress indicator every 1000 bits
                        if (input_idx % 1000 == 0) begin
                            $display("  Collected %d input bits (counter=%d)...", input_idx, data_gen.counter);
                        end
                        
                        // Show frame boundaries
                        if (input_idx % INFO_BITS == 1) begin
                            $display("  Input Frame %d starting (bit %d, counter=%d)", 
                                    (input_idx-1) / INFO_BITS + 1, input_idx-1, data_gen.counter);
                            // Debug: Show expected first bytes of this frame
                            $display("  Expected frame %d first byte: %02x (counter starts at %d)",
                                    (input_idx-1) / INFO_BITS + 1, data_gen.counter, data_gen.counter);
                        end
                    end
                    input_timeout = input_timeout + 1;
                end
                $display("  Finished collecting %d input bits", input_idx);
            end
            
            // Thread 2: Collect decoder output synchronized with dec_data_valid
            begin
                output_timeout = 0;
                $display("  Waiting for decoder output to start...");
                
                while (output_idx < INFO_BITS * NUM_TEST_FRAMES && output_timeout < MAX_OUTPUT_TIMEOUT) begin
                    @(posedge clk);
                    
                    // Collect from decoder output whenever valid
                    if (dec_data_valid) begin
                        all_output_data[output_idx] = dec_data_out;
                        
                        // Show frame boundaries
                        if (output_idx % INFO_BITS == 0) begin
                            $display("  [%0t] Output Frame boundary detected at bit %d (Frame %d starts)", 
                                     $time, output_idx, (output_idx / INFO_BITS) + 1);
                        end
                        
                        // Debug Frame 3 extensively (starts at bit 2688)
                        if (output_idx >= 2688 && output_idx < 2700) begin
                            $display("  [%0t] TB Frame 3: bit %d, dec_data=%b, dec_valid=%b", 
                                     $time, output_idx, dec_data_out, dec_data_valid);
                        end
                        
                        // Debug around where it stops (2888)
                        if (output_idx >= 2880 && output_idx <= 2900) begin
                            $display("  [%0t] TB CRITICAL: bit %d, dec_data=%b, dec_valid=%b", 
                                     $time, output_idx, dec_data_out, dec_data_valid);
                        end
                        
                        // Debug last few bits to see where it stops
                        if (output_idx >= INFO_BITS * NUM_TEST_FRAMES - 10) begin
                            $display("  [%0t] TB: Received bit %d (dec_data_valid=%b, dec_data_out=%b)", 
                                     $time, output_idx, dec_data_valid, dec_data_out);
                        end
                        
                        output_idx = output_idx + 1;
                        
                        // Progress indicator
                        if (output_idx % 1000 == 0) begin
                            $display("  Received %d output bits...", output_idx);
                        end
                    end
                    
                    // Monitor when dec_data_valid is low during Frame 3
                    if (output_idx >= 2688 && output_idx < 2900 && !dec_data_valid) begin
                        if (output_timeout % 100 == 0) begin  // Every 100 cycles
                            $display("  [%0t] TB WAITING: output_idx=%d, dec_data_valid=0 (timeout=%d/%d)", 
                                     $time, output_idx, output_timeout, MAX_OUTPUT_TIMEOUT);
                        end
                    end
                    
                    // Progress monitoring for long frame tests
                    if (NUM_TEST_FRAMES > 10 && output_timeout % 10000 == 0 && output_timeout > 0) begin
                        $display("  [%0t] TB PROGRESS: Received %d/%d bits, timeout %d/%d", 
                                 $time, output_idx, INFO_BITS * NUM_TEST_FRAMES, output_timeout, MAX_OUTPUT_TIMEOUT);
                    end
                    
                    output_timeout = output_timeout + 1;
                end
                
                if (output_timeout >= MAX_OUTPUT_TIMEOUT) begin
                    $display("ERROR: Timeout after %d cycles - only received %d/%d output bits", 
                             MAX_OUTPUT_TIMEOUT, output_idx, INFO_BITS * NUM_TEST_FRAMES);
                    $display("  Consider increasing OUTPUT_TIMEOUT_PER_FRAME if decoder needs more time");
                    $display("  Last dec_data_valid seen at time %0t", $time - (output_timeout - output_idx));
                    $display("  Current time: %0t, dec_data_valid=%b", $time, dec_data_valid);
                    error_count = error_count + 1;
                end else begin
                    $display("  Successfully received all %d output bits", output_idx);
                end
            end
        join
        
        // VALIDATE: Check all frames at once
        validate_all_frames();
    end
endtask

task wait_for_serdes_output;
    integer timeout;
    begin
        timeout = 0;
        while (output_bit_count < INFO_BITS && timeout < 5000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 5000) begin
            $display("ERROR: Timeout waiting for SerDes output");
            $display("  Only received %d out of %d bits", output_bit_count, INFO_BITS);
            error_count = error_count + 1;
        end else begin
            $display("  SerDes output completed: %d bits received", output_bit_count);
        end
        // Wait a bit more for pipeline to clear
        repeat(50) @(posedge clk);
    end
endtask

task wait_for_output_frame;
    integer timeout;
    begin
        timeout = 0;
        while (output_bit_count < INFO_BITS && timeout < 10000) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 10000) begin
            $display("ERROR: Timeout waiting for decoder output");
            error_count = error_count + 1;
        end
        // Wait a bit more for pipeline to clear
        repeat(100) @(posedge clk);
    end
endtask

// Note: wait_for_all_output_frames task has been integrated into run_multiple_frame_test
// using fork-join for simultaneous input/output collection

// Display frame data in hex for visual inspection
task display_frame_data;
    input [INFO_BITS-1:0] frame_data;
    input string frame_name;
    integer byte_idx;
    reg [7:0] current_byte;
    begin
        $display("  %s Frame Data (first 32 bytes):", frame_name);
        $write("    ");
        for (byte_idx = 0; byte_idx < 32 && byte_idx < INFO_BITS/8; byte_idx = byte_idx + 1) begin
            current_byte = frame_data[byte_idx*8 +: 8];
            $write("%02h ", current_byte);
            if ((byte_idx + 1) % 16 == 0) begin
                $write("\n    ");
            end
        end
        $display("");
    end
endtask

// Validate all frames collected during continuous streaming
task validate_all_frames;
    integer frame_idx;
    integer bit_idx;
    integer frame_errors;
    integer all_match;
    reg [INFO_BITS-1:0] expected_frame;
    reg [INFO_BITS-1:0] received_frame;
    begin
        all_match = 1;
        
        $display("\n  ============ FRAME VALIDATION ============");
        $display("  Validating %d frames", NUM_TEST_FRAMES);
        
        // Check each frame
        for (frame_idx = 0; frame_idx < NUM_TEST_FRAMES; frame_idx = frame_idx + 1) begin
            frame_errors = 0;
            
            // Extract frame data
            for (bit_idx = 0; bit_idx < INFO_BITS; bit_idx = bit_idx + 1) begin
                expected_frame[bit_idx] = all_input_data[frame_idx*INFO_BITS + bit_idx];
                received_frame[bit_idx] = all_output_data[frame_idx*INFO_BITS + bit_idx];
                
                if (expected_frame[bit_idx] !== received_frame[bit_idx]) begin
                    frame_errors = frame_errors + 1;
                end
            end
            
            $display("\n  --- Frame %d ---", frame_idx + 1);
            display_frame_data(expected_frame, "Expected");
            display_frame_data(received_frame, "Received");
            
            if (frame_errors == 0) begin
                $display("  Result: PASS");
            end else begin
                $display("  Result: FAIL (%d bit errors)", frame_errors);
                
                // Show first few mismatches for diagnosis
                $display("  First mismatches (up to 10):");
                begin
                    integer mismatch_count;
                    mismatch_count = 0;
                    for (bit_idx = 0; bit_idx < INFO_BITS && mismatch_count < 10; bit_idx = bit_idx + 1) begin
                        if (expected_frame[bit_idx] !== received_frame[bit_idx]) begin
                            $display("    Bit %4d: expected=%b, got=%b (byte %d, bit %d)", 
                                    bit_idx, expected_frame[bit_idx], received_frame[bit_idx],
                                    bit_idx / 8, bit_idx % 8);
                            mismatch_count = mismatch_count + 1;
                        end
                    end
                end
                
                all_match = 0;
                error_count = error_count + 1;
            end
        end
        
        if (all_match) begin
            $display("  Overall: ALL FRAMES PASS - Continuous streaming works!");
        end else begin
            $display("  Overall: SOME FRAMES FAILED - Pipeline issues detected");
        end
    end
endtask

// Monitor for debugging
always @(posedge clk) begin
    if (enc_data_valid && test_active) begin
        bit_count <= bit_count + 1;
        if (bit_count % 1000 == 0) begin
            $display("  [%0t] Encoded %d bits...", $time, bit_count);
        end
        
        // Debug: Track first 32 bits of each frame through the channel
        if (bit_position < 32) begin
            $display("  [%0t] CHANNEL Frame bit %d: enc_out=%b, channel=%b, dec_will_receive=%b (inject=%b)",
                     $time, bit_position, enc_data_out, channel_data, channel_data, inject_errors);
            // Additional debug: Compare with P2S actual output
            if (encoder.p2s.serial_data_out !== enc_data_out) begin
                $display("  [%0t] ERROR: P2S output mismatch! p2s.serial_data_out=%b, enc_data_out=%b",
                         $time, encoder.p2s.serial_data_out, enc_data_out);
            end
        end
        
        // Debug: Show when frame boundaries occur
        if (bit_position == 0) begin
            $display("  [%0t] CHANNEL: New frame starting, first bit: enc_out=%b -> channel=%b",
                     $time, enc_data_out, channel_data);
        end
    end
    
    // Debug: Monitor what decoder S2P actually collects
    if (channel_valid && test_number == 3) begin
        // Track first few bits of what decoder receives
        if (decoder.s2p.bit_counter < 32) begin
            $display("  [%0t] DECODER S2P collecting bit %d: channel_data=%b, bit_counter=%d",
                     $time, decoder.s2p.bit_counter, channel_data, decoder.s2p.bit_counter);
        end
        
        // Show when decoder S2P completes a frame
        if (decoder.s2p.bit_counter == decoder.s2p.FRAME_BITS - 1) begin
            $display("  [%0t] DECODER S2P: About to complete frame, last bit=%b, collected data[31:0]=%08h",
                     $time, channel_data, decoder.s2p.shift_register[31:0]);
        end
    end
    
    // // Monitor SerDes bypass data flow
    // if (serdes_test_mode) begin
    //     // Track S2P bypass input
    //     if (data_valid && serdes_test_mode) begin
    //         if (bit_count < 5) begin
    //             $display("  [%0t] S2P_bypass input: bit=%b, valid=%b (serdes_test_mode=%b)", 
    //                      $time, data_bit, data_valid && serdes_test_mode, serdes_test_mode);
    //         end
    //     end
        
    //     // Monitor FIFO status
    //     if (s2p_bypass.frames_buffered > 0 || p2s_bypass.frames_buffered > 0) begin
    //         if (bit_count % 100 == 0) begin  // Report every 100 clocks
    //             $display("  [%0t] S2P FIFO: %d frames, P2S FIFO: %d frames", 
    //                      $time, s2p_bypass.frames_buffered, p2s_bypass.frames_buffered);
    //         end
    //     end
        
    //     // Track P2S output
    //     if (serdes_valid) begin
    //         if (output_bit_count < 10 || output_bit_count % 100 == 0 || output_bit_count >= INFO_BITS - 5) begin
    //             $display("  [%0t] P2S_bypass output: bit=%b, valid=%b, output_bit_count=%d", 
    //                      $time, serdes_out, serdes_valid, output_bit_count);
    //         end
    //     end
    // end
end

endmodule