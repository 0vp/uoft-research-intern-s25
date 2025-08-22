`timescale 1ns / 1ps

// 2D Reed-Solomon Encoder
// Implements 2D RS(15,11) encoding with row/column encoding and parity-on-parity

module rs_2d_encoder #(
    parameter N = 15,                    // Total symbols per dimension
    parameter K = 11,                    // Data symbols per dimension
    parameter SYMBOL_WIDTH = 8           // Bits per symbol
)(
    input wire clk,
    input wire rstn,
    input wire data_in,
    input wire data_in_valid,
    output wire data_out,
    output wire data_out_valid,
    output wire ready
);

// Calculate dimensions
localparam DATA_SYMBOLS = K * K;                           // 121 symbols
localparam ENCODED_SYMBOLS = N * N;                        // 225 symbols
localparam DATA_BITS = DATA_SYMBOLS * SYMBOL_WIDTH;        // 968 bits
localparam ENCODED_BITS = ENCODED_SYMBOLS * SYMBOL_WIDTH;  // 1800 bits
localparam PARITY_SIZE = N - K;                            // 4 symbols

// State machine states
typedef enum logic [3:0] {
    IDLE,
    COLLECT_DATA,
    ENCODE_ROWS,
    ENCODE_COLS,
    PARITY_ON_PARITY_ROWS,
    PARITY_ON_PARITY_COLS,
    VERIFY_PARITY,
    OUTPUT_DATA
} state_t;

state_t state, next_state, prev_state;

// 2D array for encoding
reg [SYMBOL_WIDTH-1:0] encoded_array [0:N-1][0:N-1];

// Temporary arrays for parity-on-parity verification
reg [SYMBOL_WIDTH-1:0] temp_parity_rows [0:PARITY_SIZE-1][0:PARITY_SIZE-1];
reg [SYMBOL_WIDTH-1:0] temp_parity_cols [0:PARITY_SIZE-1][0:PARITY_SIZE-1];

// Control signals
reg [7:0] row_idx, col_idx;
reg encoding_busy;
reg encoder_busy_1d;
// Track if encoder has been triggered for current index
reg encoder_triggered;
// Track which row/col output we're expecting from the encoder
reg [7:0] encoder_output_row_idx;
reg [7:0] encoder_output_col_idx;

// SerDes interface signals
wire [DATA_BITS-1:0] s2p_data;
wire s2p_valid;
wire s2p_ready_internal;
wire p2s_ready;
reg [ENCODED_BITS-1:0] p2s_data;
reg p2s_valid;

// 1D encoder interface
reg [K*SYMBOL_WIDTH-1:0] enc_1d_input;
reg enc_1d_enable;
wire [N*SYMBOL_WIDTH-1:0] enc_1d_output;
wire enc_1d_valid;
wire enc_1d_ready;
reg enc_1d_clrn;

// Ready signal management
wire s2p_buffer_full;
assign ready = !s2p_buffer_full && !encoding_busy;
assign s2p_ready_internal = !encoding_busy && p2s_ready;

// Clear pulse generator for 1D encoder
reg [2:0] clrn_counter;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        enc_1d_clrn <= 1;
        clrn_counter <= 0;
    end else begin
        if (state != next_state && next_state == IDLE) begin
            enc_1d_clrn <= 0;
            clrn_counter <= 3;
        end else if (clrn_counter > 0) begin
            clrn_counter <= clrn_counter - 1;
            if (clrn_counter == 1) begin
                enc_1d_clrn <= 1;
            end
        end
    end
end

// Track 1D encoder busy state
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        encoder_busy_1d <= 0;
    end else if (enc_1d_enable) begin
        encoder_busy_1d <= 1;
    end else if (enc_1d_valid) begin
        encoder_busy_1d <= 0;
    end
end

// Serial to Parallel converter
serial_to_parallel #(
    .N(N),
    .K(K),
    .SYMBOL_WIDTH(SYMBOL_WIDTH),
    .MODE("ENCODE_2D")
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

// ZGC RS Encoder Wrapper (1D encoder for rows/columns)
rs_encode_wrapper enc_1d (
    .clk(clk),
    .rst_n(rstn),
    .clrn(enc_1d_clrn),
    .scan_mode(1'b0),
    .encode_en(enc_1d_enable),
    .datain(enc_1d_input),
    .encoded_data(enc_1d_output),
    .valid(enc_1d_valid),
    .ready(enc_1d_ready)
);

// Parallel to Serial converter
parallel_to_serial #(
    .N(N),
    .K(K),
    .SYMBOL_WIDTH(SYMBOL_WIDTH),
    .MODE("ENCODE_2D")
) p2s (
    .clk(clk),
    .rstn(rstn),
    .parallel_data_in(p2s_data),
    .parallel_data_valid(p2s_valid),
    .parallel_data_ready(p2s_ready),
    .serial_data_out(data_out),
    .serial_data_valid(data_out_valid)
);

// State machine
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        state <= IDLE;
        prev_state <= IDLE;
    end else begin
        prev_state <= state;
        state <= next_state;
    end
end

// Next state logic
always @(*) begin
    next_state = state;
    
    case (state)
        IDLE: begin
            if (s2p_valid) begin
                next_state = COLLECT_DATA;
            end
        end
        
        COLLECT_DATA: begin
            next_state = ENCODE_ROWS;
        end
        
        ENCODE_ROWS: begin
            if (row_idx >= K && !encoder_busy_1d && !encoder_triggered) begin  // Wait for last row to complete
                next_state = ENCODE_COLS;
            end
        end
        
        ENCODE_COLS: begin
            if (col_idx >= K && !encoder_busy_1d && !encoder_triggered) begin  // Wait for last column to complete
                next_state = PARITY_ON_PARITY_ROWS;
            end
        end
        
        PARITY_ON_PARITY_ROWS: begin
            if (row_idx >= N && !encoder_busy_1d && !encoder_triggered) begin  // Wait for last row parity to complete
                next_state = PARITY_ON_PARITY_COLS;
            end
        end
        
        PARITY_ON_PARITY_COLS: begin
            if (col_idx >= N && !encoder_busy_1d && !encoder_triggered) begin  // Wait for last column parity to complete
                next_state = VERIFY_PARITY;
            end
        end
        
        VERIFY_PARITY: begin
            next_state = OUTPUT_DATA;
        end
        
        OUTPUT_DATA: begin
            if (p2s_valid && p2s_ready) begin
                next_state = IDLE;
            end
        end
        
        default: next_state = IDLE;
    endcase
end

// Main encoding logic
integer i, j;
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        row_idx <= 0;
        col_idx <= 0;
        encoding_busy <= 0;
        enc_1d_enable <= 0;
        p2s_valid <= 0;
        p2s_data <= 0;
        encoder_triggered <= 0;
        encoder_output_row_idx <= 0;
        encoder_output_col_idx <= 0;
        
        // Initialize arrays
        for (i = 0; i < N; i = i + 1) begin
            for (j = 0; j < N; j = j + 1) begin
                encoded_array[i][j] <= 0;
            end
        end
        for (i = 0; i < PARITY_SIZE; i = i + 1) begin
            for (j = 0; j < PARITY_SIZE; j = j + 1) begin
                temp_parity_rows[i][j] <= 0;
                temp_parity_cols[i][j] <= 0;
            end
        end
    end else begin
        enc_1d_enable <= 0;
        
        case (state)
            IDLE: begin
                encoding_busy <= 0;
                p2s_valid <= 0;
                row_idx <= 0;
                col_idx <= 0;
                encoder_triggered <= 0;
            end
            
            COLLECT_DATA: begin
                encoding_busy <= 1;
                // Unpack data into 2D array (K×K data symbols)
                for (i = 0; i < K; i = i + 1) begin
                    for (j = 0; j < K; j = j + 1) begin
                        encoded_array[i][j] <= s2p_data[(i*K+j)*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end
                end
            end
            
            ENCODE_ROWS: begin
                // Reset encoder_triggered on state entry
                if (prev_state == COLLECT_DATA) begin
                    encoder_triggered <= 0;
                    row_idx <= 0;  // Ensure row_idx starts at 0
                end
                
                // Debug: Mark state entry
                if (row_idx == 0 && col_idx == 0) begin
                    // $display("[%0t] ENCODER: Starting ENCODE_ROWS", $time);
                end
                
                if (row_idx < K && !encoder_triggered && !encoder_busy_1d && enc_1d_ready) begin  // Only encode K data rows
                    // Prepare row data for encoding
                    for (i = 0; i < K; i = i + 1) begin
                        enc_1d_input[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] = encoded_array[row_idx][i];
                    end
                    enc_1d_enable <= 1;
                    encoder_output_row_idx <= row_idx;  // Track which row we just sent
                    encoder_triggered <= 1;  // Prevent retriggering
                    row_idx <= row_idx + 1;
                end else if (enc_1d_valid && encoder_triggered) begin
                    // Store encoded row at the correct index
                    for (i = 0; i < N; i = i + 1) begin
                        encoded_array[encoder_output_row_idx][i] <= enc_1d_output[i*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end
                    encoder_triggered <= 0;  // Allow next trigger
                    // Row stored at encoder_output_row_idx
                end
            end
            
            ENCODE_COLS: begin
                // Reset encoder_triggered on state entry
                if (prev_state == ENCODE_ROWS) begin
                    encoder_triggered <= 0;
                    col_idx <= 0;  // Ensure col_idx starts at 0
                end
                
                // Debug: Mark state entry
                if (col_idx == 0 && row_idx >= K) begin
                    // $display("[%0t] ENCODER: Starting ENCODE_COLS", $time);
                end
                
                if (col_idx < K && !encoder_triggered && !encoder_busy_1d && enc_1d_ready) begin
                    // Prepare column data for encoding
                    for (i = 0; i < K; i = i + 1) begin
                        enc_1d_input[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] = encoded_array[i][col_idx];
                    end
                    enc_1d_enable <= 1;
                    encoder_output_col_idx <= col_idx;  // Track which column we just sent
                    encoder_triggered <= 1;  // Prevent retriggering
                    col_idx <= col_idx + 1;
                end else if (enc_1d_valid && encoder_triggered) begin
                    // Column parity stored
                    // Store column parity only (data already in place) at the correct column index
                    for (i = 0; i < PARITY_SIZE; i = i + 1) begin
                        encoded_array[K+i][encoder_output_col_idx] <= enc_1d_output[(K+i)*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                    end
                    encoder_triggered <= 0;  // Allow next trigger
                    // Also check if we're accidentally overwriting data
                    for (i = 0; i < K; i = i + 1) begin
                        if (enc_1d_output[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] != encoded_array[i][encoder_output_col_idx]) begin
                            $display("  WARNING: Data mismatch at [%d][%d]: expected %02h, got %02h",
                                     i, encoder_output_col_idx, encoded_array[i][encoder_output_col_idx], 
                                     enc_1d_output[i*SYMBOL_WIDTH +: SYMBOL_WIDTH]);
                        end
                    end
                end
                
                // Check if column encoding is complete
                if (col_idx >= K && !encoder_busy_1d) begin
                    // Ready to transition to PARITY_ON_PARITY_ROWS
                end
            end
            
            PARITY_ON_PARITY_ROWS: begin
                // Reset on state entry from ENCODE_COLS
                if (prev_state == ENCODE_COLS) begin
                    encoder_triggered <= 0;
                    row_idx <= K;  // Start at row 11 (K=11)
                    col_idx <= 0;  // Reset col_idx
                end
                
                // Sequential encoding: wait for each encoder to complete
                if (row_idx < N && row_idx >= K && !encoder_busy_1d && enc_1d_ready) begin
                    if (!encoder_triggered) begin
                        // Prepare and trigger encoder for current row
                        for (i = 0; i < K; i = i + 1) begin
                            enc_1d_input[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] = encoded_array[row_idx][i];
                        end
                        // Encoding parity row
                        encoder_output_row_idx <= row_idx;  // Track which row we're encoding
                        enc_1d_enable <= 1;
                        encoder_triggered <= 1;  // Mark as triggered
                    end
                end else if (enc_1d_valid && encoder_triggered) begin
                    // Process encoder output
                    // Store output at correct index
                    if (encoder_output_row_idx >= K && encoder_output_row_idx < N) begin
                        for (i = 0; i < PARITY_SIZE; i = i + 1) begin
                            temp_parity_rows[encoder_output_row_idx-K][i] <= enc_1d_output[(K+i)*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                            // Store row parity
                        end
                    end
                    row_idx <= row_idx + 1;  // Only increment after storing
                    encoder_triggered <= 0;   // Reset for next iteration
                end
            end
            
            PARITY_ON_PARITY_COLS: begin
                // Reset on state entry
                if (prev_state == PARITY_ON_PARITY_ROWS) begin
                    encoder_triggered <= 0;
                    col_idx <= K;  // Start at column 11
                    row_idx <= 0;  // Reset row_idx for any future use
                end
                
                // Sequential encoding: wait for each encoder to complete
                if (col_idx < N && col_idx >= K && !encoder_busy_1d && enc_1d_ready) begin
                    if (!encoder_triggered) begin
                        // Prepare and trigger encoder for current column
                        for (i = 0; i < K; i = i + 1) begin
                            enc_1d_input[i*SYMBOL_WIDTH +: SYMBOL_WIDTH] = encoded_array[i][col_idx];
                        end
                        // Encoding parity column
                        encoder_output_col_idx <= col_idx;  // Track which column we're encoding
                        enc_1d_enable <= 1;
                        encoder_triggered <= 1;  // Mark as triggered
                    end
                end else if (enc_1d_valid && encoder_triggered) begin
                    // Store output at correct index
                    if (encoder_output_col_idx >= K && encoder_output_col_idx < N) begin
                        for (i = 0; i < PARITY_SIZE; i = i + 1) begin
                            temp_parity_cols[i][encoder_output_col_idx-K] <= enc_1d_output[(K+i)*SYMBOL_WIDTH +: SYMBOL_WIDTH];
                            // Store column parity
                        end
                    end
                    col_idx <= col_idx + 1;  // Only increment after storing
                    encoder_triggered <= 0;   // Reset for next iteration
                end
            end
            
            VERIFY_PARITY: begin
                // Debug: Show complete parity-on-parity comparison
                // $display("[%0t] P-o-P Verification:", $time);
                for (i = 0; i < PARITY_SIZE; i = i + 1) begin
                    for (j = 0; j < PARITY_SIZE; j = j + 1) begin
                        // $display("  [%d][%d]: row=%02h, col=%02h, match=%b",
                                //  K+i, K+j, temp_parity_rows[i][j], temp_parity_cols[i][j],
                                //  temp_parity_rows[i][j] == temp_parity_cols[i][j]);
                    end
                end
                
                // Check for missing parity values (should never be zero)
                for (i = 0; i < PARITY_SIZE; i = i + 1) begin
                    for (j = 0; j < PARITY_SIZE; j = j + 1) begin
                        if (temp_parity_rows[i][j] == 0 && temp_parity_cols[i][j] == 0) begin
                            $display("[%0t] ERROR: Missing parity at position [%d][%d]!", $time, i, j);
                        end
                    end
                end
                
                // Verify parity-on-parity matches and fill bottom-right quadrant
                for (i = 0; i < PARITY_SIZE; i = i + 1) begin
                    for (j = 0; j < PARITY_SIZE; j = j + 1) begin
                        if (temp_parity_rows[i][j] == temp_parity_cols[i][j]) begin
                            encoded_array[K+i][K+j] <= temp_parity_rows[i][j];
                        end else begin
                            // Parity mismatch - use row parity (or handle error)
                            encoded_array[K+i][K+j] <= temp_parity_rows[i][j];
                            $display("[%0t] WARNING: Parity mismatch at [%d][%d], using row parity", $time, K+i, K+j);
                        end
                    end
                end
            end
            
            OUTPUT_DATA: begin
                // Pack 2D array into output vector
                for (i = 0; i < N; i = i + 1) begin
                    for (j = 0; j < N; j = j + 1) begin
                        p2s_data[(i*N+j)*SYMBOL_WIDTH +: SYMBOL_WIDTH] <= encoded_array[i][j];
                    end
                end
                p2s_valid <= 1;
                
                if (p2s_valid && p2s_ready) begin
                    p2s_valid <= 0;
                    row_idx <= 0;
                    col_idx <= 0;
                    encoder_triggered <= 0;  // Reset for next frame
                end
            end
        endcase
    end
end

endmodule