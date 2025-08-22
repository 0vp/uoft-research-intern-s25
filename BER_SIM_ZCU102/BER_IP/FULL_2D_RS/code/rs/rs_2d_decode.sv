`timescale 1ns / 1ps

// 2D Reed-Solomon Decoder
// Implements 2D RS(30,24) iterative decoding with row/column correction

module rs_2d_decoder #(
    parameter N = 30,                    // Total symbols per dimension
    parameter K = 24,                    // Data symbols per dimension
    parameter SYMBOL_WIDTH = 8           // Bits per symbol
)(
    input wire clk,
    input wire rstn,
    input wire [4:0] max_iterations,     // Maximum decoding iterations (dynamic input)
    input wire data_in,
    input wire data_in_valid,
    output wire data_out,
    output wire data_out_valid,
    output wire ready
);

// Calculate dimensions
localparam DATA_SYMBOLS = K * K;                           // 576 symbols
localparam ENCODED_SYMBOLS = N * N;                        // 900 symbols
localparam DATA_BITS = DATA_SYMBOLS * SYMBOL_WIDTH;        // 4608 bits
localparam ENCODED_BITS = ENCODED_SYMBOLS * SYMBOL_WIDTH;  // 7200 bits

// State machine states
typedef enum logic [3:0] {
    IDLE,
    COLLECT_DATA,
    DECODE_ROWS,
    DECODE_COLS,
    CHECK_CONVERGENCE,
    OUTPUT_DATA
} state_t;

state_t state, next_state, prev_state;

// 2D array for decoding
reg [SYMBOL_WIDTH-1:0] received_array [0:N-1][0:N-1];
reg [SYMBOL_WIDTH-1:0] previous_array [0:N-1][0:N-1];

// Control signals
reg [7:0] row_idx, col_idx;
reg [7:0] iteration_count;
reg decoding_busy;
reg decoder_busy_1d;
reg changes_detected;
reg [31:0] total_changes;
// Track which row/column is actually being decoded
reg [7:0] active_row_idx, active_col_idx;
// Prevent multiple processing of same result
reg result_consumed_row, result_consumed_col;
// Track if decode is in progress
reg decode_in_progress_row, decode_in_progress_col;
// Debug: Track operations since last clear
reg [7:0] ops_since_clear;

// SerDes interface signals
wire [ENCODED_BITS-1:0] s2p_data;
wire s2p_valid;
wire s2p_ready_internal;
wire p2s_ready;
reg [DATA_BITS-1:0] p2s_data;
reg p2s_valid;

// 1D decoder interface
reg [N*SYMBOL_WIDTH-1:0] dec_1d_input;
reg dec_1d_enable;
wire [N*SYMBOL_WIDTH-1:0] dec_1d_error_pos;
wire dec_1d_valid;
wire dec_1d_ready;
wire dec_1d_with_error;
wire dec_1d_complete;  // New signal for decode completion
reg dec_1d_clrn;

// Ready signal management
wire s2p_buffer_full;
assign ready = !s2p_buffer_full && !decoding_busy;
assign s2p_ready_internal = !decoding_busy && p2s_ready;

// Clear pulse generator for 1D decoder
reg [2:0] clrn_counter;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        dec_1d_clrn <= 1;
        clrn_counter <= 0;
    end else begin
        if (state != next_state && next_state == IDLE) begin
            $display("[%0t] DECODER: Pulsing clrn - transitioning to IDLE (ops_since_clear=%d)",
                     $time, ops_since_clear);
            dec_1d_clrn <= 0;
            clrn_counter <= 3;
            ops_since_clear <= 0;  // Reset counter
        end else if (clrn_counter > 0) begin
            clrn_counter <= clrn_counter - 1;
            if (clrn_counter == 1) begin
                dec_1d_clrn <= 1;
            end
        end
    end
end

// Track 1D decoder busy state
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        decoder_busy_1d <= 0;
    end else if (dec_1d_enable) begin
        decoder_busy_1d <= 1;
    end else if (dec_1d_complete) begin
        decoder_busy_1d <= 0;  // Clear busy when fully complete
    end
end

// Serial to Parallel converter
serial_to_parallel #(
    .N(N),
    .K(K),
    .SYMBOL_WIDTH(SYMBOL_WIDTH),
    .MODE("DECODE_2D")
) s2p (
    .clk(clk),
    .rstn(rstn),
    .serial_data_in(data_in),
    .serial_data_valid(data_in_valid),
    .parallel_data_out(s2p_data),
    .parallel_data_valid(s2p_valid),
    .parallel_data_ready(s2p_ready_internal),
    .buffer_full(s2p_buffer_full)
);

// ZGC RS Decoder Wrapper (1D decoder for rows/columns)
rs_decode_wrapper dec_1d (
    .clk(clk),
    .rst_n(rstn),
    .clrn(dec_1d_clrn),
    .scan_mode(1'b0),
    .decode_en(dec_1d_enable),
    .encoded_data(dec_1d_input),
    .error_pos(dec_1d_error_pos),
    .output_valid(dec_1d_valid),
    .ready(dec_1d_ready),
    .with_error(dec_1d_with_error),
    .decode_complete(dec_1d_complete)
);

// Parallel to Serial converter
parallel_to_serial #(
    .N(N),
    .K(K),
    .SYMBOL_WIDTH(SYMBOL_WIDTH),
    .MODE("DECODE_2D")
) p2s (
    .clk(clk),
    .rstn(rstn),
    .parallel_data_in(p2s_data),
    .parallel_data_valid(p2s_valid),
    .parallel_data_ready(p2s_ready),
    .serial_data_out(data_out),
    .serial_data_valid(data_out_valid)
);

// State machine with debug tracking
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        state <= IDLE;
        prev_state <= IDLE;
    end else begin
        prev_state <= state;
        state <= next_state;
        // Critical state transition debug
        if (state != prev_state) begin
            $display("[%0t] DECODER STATE TRANSITION: %s -> %s (row_idx=%d, col_idx=%d, iter=%d)",
                     $time, prev_state.name(), state.name(), row_idx, col_idx, iteration_count);
        end
    end
end

// Next state logic with debug
always @(*) begin
    next_state = state;

    case (state)
        IDLE: begin
            if (s2p_valid) begin
                next_state = COLLECT_DATA;
                $display("[%0t] DECODER next_state: IDLE -> COLLECT_DATA (s2p_valid=%b)", $time, s2p_valid);
            end
        end

        COLLECT_DATA: begin
            next_state = DECODE_ROWS;
            $display("[%0t] DECODER next_state: COLLECT_DATA -> DECODE_ROWS (unconditional)", $time);
        end

        DECODE_ROWS: begin
            if (row_idx >= N && !decoder_busy_1d) begin
                next_state = DECODE_COLS;
                $display("[%0t] DECODER next_state: DECODE_ROWS -> DECODE_COLS (row_idx=%d, busy=%b)",
                         $time, row_idx, decoder_busy_1d);
            end
        end

        DECODE_COLS: begin
            if (col_idx >= N && !decoder_busy_1d) begin
                next_state = CHECK_CONVERGENCE;
                $display("[%0t] DECODER next_state: DECODE_COLS -> CHECK_CONVERGENCE (col_idx=%d, busy=%b)",
                         $time, col_idx, decoder_busy_1d);
            end
        end

        CHECK_CONVERGENCE: begin
            if (iteration_count >= max_iterations - 1 || !changes_detected) begin
                next_state = OUTPUT_DATA;
                $display("[%0t] DECODER next_state: CHECK_CONVERGENCE -> OUTPUT_DATA (iter=%d, changes=%b)",
                         $time, iteration_count, changes_detected);
            end else begin
                next_state = DECODE_ROWS;
                $display("[%0t] DECODER next_state: CHECK_CONVERGENCE -> DECODE_ROWS (iter=%d, changes=%b)",
                         $time, iteration_count, changes_detected);
            end
        end

        OUTPUT_DATA: begin
            if (p2s_valid && p2s_ready) begin
                next_state = IDLE;
                $display("[%0t] DECODER next_state: OUTPUT_DATA -> IDLE (p2s_valid=%b, p2s_ready=%b)",
                         $time, p2s_valid, p2s_ready);
            end
        end

        default: next_state = IDLE;
    endcase
end

// Main decoding logic
integer i, j;
reg [N*SYMBOL_WIDTH-1:0] corrected_row_col;

always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        row_idx <= 0;
        col_idx <= 0;
        iteration_count <= 0;
        decoding_busy <= 0;
        dec_1d_enable <= 0;
        p2s_valid <= 0;
        p2s_data <= 0;
        changes_detected <= 0;
        total_changes <= 0;
        active_row_idx <= 0;
        active_col_idx <= 0;
        result_consumed_row <= 0;
        result_consumed_col <= 0;
        decode_in_progress_row <= 0;
        decode_in_progress_col <= 0;
        ops_since_clear <= 0;

        // Initialize arrays
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                received_array[i][j] <= 0;
                previous_array[i][j] <= 0;
            end
        end
    end else begin
        dec_1d_enable <= 0;

        case (state)
            IDLE: begin
                if (prev_state != IDLE) begin
                    $display("[%0t] DECODER: Entering IDLE state", $time);
                end
                decoding_busy <= 0;
                p2s_valid <= 0;
                row_idx <= 0;
                col_idx <= 0;
                iteration_count <= 0;
                total_changes <= 0;
                active_row_idx <= 0;
                active_col_idx <= 0;
                result_consumed_row <= 0;
                result_consumed_col <= 0;
                decode_in_progress_row <= 0;
                decode_in_progress_col <= 0;
            end

            COLLECT_DATA: begin
                // State entry debug
                if (prev_state != COLLECT_DATA) begin
                    $display("[%0t] DECODER: Entering COLLECT_DATA, unpacking %d symbols", $time, ENCODED_SYMBOLS);
                end
                decoding_busy <= 1;
                // Unpack data into 2D array (N×N encoded symbols)
                for (i = 0; i < N; i = i + 1) begin
                    for (j = 0; j < N; j = j + 1) begin
                        received_array[i][j] <= s2p_data[(i*N+j)*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                        previous_array[i][j] <= s2p_data[(i*N+j)*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end
                end
                changes_detected <= 1; // Force at least one iteration
                $display("[%0t] DECODER: Data collected, changes_detected=%b, ready for DECODE_ROWS",
                         $time, changes_detected);
            end

            DECODE_ROWS: begin
                // State entry debug
                if (prev_state != DECODE_ROWS) begin
                    $display("[%0t] DECODER: Entering DECODE_ROWS, row_idx=%d, decoder_busy_1d=%b, dec_1d_ready=%b",
                             $time, row_idx, decoder_busy_1d, dec_1d_ready);
                end

                if (row_idx == 0 && iteration_count > 0) begin
                    // Save current state before new iteration
                    for (i = 0; i < N; i = i + 1) begin
                        for (j = 0; j < N; j = j + 1) begin
                            previous_array[i][j] <= received_array[i][j];
                        end
                    end
                    total_changes <= 0;
                end

                // Only trigger if no decode is in progress
                if (row_idx < N && !decoder_busy_1d && dec_1d_ready && !decode_in_progress_row) begin
                    ops_since_clear <= ops_since_clear + 1;
                    $display("[%0t] DECODER: Triggering 1D decoder for row %d (op #%d since clear)",
                             $time, row_idx, ops_since_clear);
                    // Prepare row data for decoding
                    for (i = 0; i < N; i = i + 1) begin
                        dec_1d_input[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] = received_array[row_idx][i];
                    end
                    dec_1d_enable <= 1;
                    active_row_idx <= row_idx;  // Save which row we're decoding
                    decode_in_progress_row <= 1;  // Mark decode in progress
                    result_consumed_row <= 0;  // Reset for new decode
                    // Don't increment row_idx yet!
                end else if (dec_1d_complete && !result_consumed_row && decode_in_progress_row) begin
                    // Process result only once - wait for COMPLETE state
                    result_consumed_row <= 1;  // Mark as consumed
                    decode_in_progress_row <= 0;  // Clear in-progress flag
                    row_idx <= row_idx + 1;  // NOW increment to next row

                    $display("[%0t] DECODER: Row %d decode_complete received, with_error=%b",
                             $time, active_row_idx, dec_1d_with_error);

                    // Debug prints only if errors detected
                    if (dec_1d_with_error) begin
                        $display("[%0t] DECODER: Applying error correction to row %d", $time, active_row_idx);
                        $display("  Error pattern: %h", dec_1d_error_pos);
                    end

                    // ALWAYS XOR error positions with received data (like 1D decoder does)
                    // If no errors, error_pos will be all zeros, so XOR doesn't change data
                    for (i = 0; i < N; i = i + 1) begin
                        corrected_row_col[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] =
                            received_array[active_row_idx][i] ^ dec_1d_error_pos[i*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end

                    // Count changes BEFORE updating array
                    for (i = 0; i < N; i = i + 1) begin
                        if (corrected_row_col[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] != received_array[active_row_idx][i]) begin
                            total_changes <= total_changes + 1;
                        end
                    end

                    // THEN update the row with corrected values
                    for (i = 0; i < N; i = i + 1) begin
                        received_array[active_row_idx][i] <= corrected_row_col[i*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end

                    // Concise progress indicator
                    $display("[%0t] Progress: Iter %d | Row %d | changes: %d",
                             $time, iteration_count + 1, active_row_idx, total_changes);
                end
            end

            DECODE_COLS: begin
                // State entry debug
                if (prev_state != DECODE_COLS) begin
                    $display("[%0t] DECODER: Entering DECODE_COLS, col_idx=%d, decoder_busy_1d=%b, dec_1d_ready=%b",
                             $time, col_idx, decoder_busy_1d, dec_1d_ready);
                end

                // Only trigger if no decode is in progress
                if (col_idx < N && !decoder_busy_1d && dec_1d_ready && !decode_in_progress_col) begin
                    ops_since_clear <= ops_since_clear + 1;
                    $display("[%0t] DECODER: Triggering 1D decoder for column %d (op #%d since clear)",
                             $time, col_idx, ops_since_clear);
                    // Prepare column data for decoding
                    for (i = 0; i < N; i = i + 1) begin
                        dec_1d_input[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] = received_array[i][col_idx];
                    end
                    dec_1d_enable <= 1;
                    active_col_idx <= col_idx;  // Save which column we're decoding
                    decode_in_progress_col <= 1;  // Mark decode in progress
                    result_consumed_col <= 0;  // Reset for new decode
                    // Don't increment col_idx yet!
                end else if (dec_1d_complete && !result_consumed_col && decode_in_progress_col) begin
                    // Process result only once - wait for COMPLETE state
                    result_consumed_col <= 1;  // Mark as consumed
                    decode_in_progress_col <= 0;  // Clear in-progress flag
                    col_idx <= col_idx + 1;  // NOW increment to next column

                    $display("[%0t] DECODER: Column %d decode_complete received, with_error=%b",
                             $time, active_col_idx, dec_1d_with_error);

                    // Debug prints only if errors detected
                    if (dec_1d_with_error) begin
                        $display("[%0t] DECODER: Applying error correction to column %d", $time, active_col_idx);
                        $display("  Error pattern: %h", dec_1d_error_pos);
                    end

                    // ALWAYS XOR error positions with received data (like 1D decoder does)
                    // If no errors, error_pos will be all zeros, so XOR doesn't change data
                    for (i = 0; i < N; i = i + 1) begin
                        corrected_row_col[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] =
                            received_array[i][active_col_idx] ^ dec_1d_error_pos[i*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end

                    // Count changes BEFORE updating array
                    for (i = 0; i < N; i = i + 1) begin
                        if (corrected_row_col[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] != received_array[i][active_col_idx]) begin
                            total_changes <= total_changes + 1;
                        end
                    end

                    // THEN update the column with corrected values
                    for (i = 0; i < N; i = i + 1) begin
                        received_array[i][active_col_idx] <= corrected_row_col[i*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end

                    // Concise progress indicator
                    $display("[%0t] Progress: Iter %d | Col %d | changes: %d",
                             $time, iteration_count + 1, active_col_idx, total_changes);
                end
            end

            CHECK_CONVERGENCE: begin
                // State entry debug
                if (prev_state != CHECK_CONVERGENCE) begin
                    $display("[%0t] DECODER: Entering CHECK_CONVERGENCE, total_changes=%d, iteration=%d",
                             $time, total_changes, iteration_count);
                end

                iteration_count <= iteration_count + 1;
                changes_detected <= (total_changes > 0);
                row_idx <= 0;
                col_idx <= 0;

                // Debug output (iteration_count is 0-indexed)
                if (total_changes == 0) begin
                    $display("[%0t] DECODER: Converged after %d iterations", $time, iteration_count + 1);
                end else if (iteration_count >= max_iterations - 1) begin
                    $display("[%0t] DECODER: Max iterations (%d) reached", $time, max_iterations);
                end else begin
                    $display("[%0t] DECODER: Iteration %d complete, %d changes detected, continuing",
                             $time, iteration_count + 1, total_changes);
                end
            end

            OUTPUT_DATA: begin
                // // State entry debug
                // if (prev_state != OUTPUT_DATA) begin
                //     $display("[%0t] DECODER: Entering OUTPUT_DATA after %d iterations",
                //              $time, iteration_count);
                //     $display("[%0t] DECODER: Extracting data from array[0..%d][0..%d]", $time, K-1, K-1);
                //     // Show first few bytes of output
                //     for (i = 0; i < 2; i = i + 1) begin
                //         $display("  Row %d: [0]=%02h [1]=%02h [2]=%02h [3]=%02h [4]=%02h",
                //                  i, received_array[i][0], received_array[i][1],
                //                  received_array[i][2], received_array[i][3], received_array[i][4]);
                //     end
                // end
                // Pack data portion (K×K) into output vector
                for (i = 0; i < K; i = i + 1) begin
                    for (j = 0; j < K; j = j + 1) begin
                        p2s_data[(i*K+j)*SYMBOL_WIDTH +: SYMBOL_WIDTH] <= received_array[i][j];
                    end
                end
                p2s_valid <= 1;

                if (p2s_valid && p2s_ready) begin
                    p2s_valid <= 0;
                    row_idx <= 0;
                    col_idx <= 0;
                    iteration_count <= 0;
                end
            end
        endcase
    end
end

endmodule