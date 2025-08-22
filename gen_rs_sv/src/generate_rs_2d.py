"""
Reed-Solomon SystemVerilog Code Generator - 2D Implementation
Generates mathematically correct 2D RS codes with EXACT reference structure
"""

import argparse
import os
import shutil
from gf256 import GF256

class RSGenerator:
    """Generate 2D RS code with exact reference structure matching"""

    def __init__(self, n: int, k: int, output_dir: str = 'gen_2d'):
        self.n = n  # Total symbols per dimension
        self.k = k  # Data symbols per dimension
        self.n_parity = n - k  # Parity symbols per dimension
        self.t = self.n_parity // 2  # Error correction capability per dimension
        self.output_dir = output_dir
        self.gf = GF256()

        # Get generator polynomial coefficients for 1D RS codes used in 2D implementation
        self.gen_poly = self.gf.get_generator_polynomial(self.n_parity)

        # Ensure output directory exists
        os.makedirs(self.output_dir, exist_ok=True)

    def generate_syndrome_sv(self):
        """Generate syndrome.sv with exact reference structure for 2D"""
        header = """// -------------------------------------------------------------------------
//Syndrome generator circuit in Reed-Solomon Decoder
//Copyright (C) Tue Apr  2 17:07:53 2002
//by Ming-Han Lei(hendrik@humanistic.org) - Modified by Qasim Li (qasim.li@mail.mcgill.ca)
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
// --------------------------------------------------------------------------

"""

        # Generate syndrome modules
        modules = []
        for i in range(self.n_parity):
            modules.append(self.generate_syndrome_module(i))

        # Generate main syndrome module with EXACT reference interface
        main_module = self._generate_main_syndrome_exact()

        content = header + "\n".join(modules) + "\n\n" + main_module

        # Write to file
        filepath = os.path.join(self.output_dir, 'syndrome.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: syndrome.sv (exact structure for 2D)")

    def generate_syndrome_module(self, idx: int) -> str:
        """Generate a single syndrome computation module"""
        # Alpha^(i+1) for syndrome module i (narrow-sense BCH)
        # Module rsdec_syn_m0 computes at α^1, m1 at α^2, etc.
        alpha_power = self.gf.power(2, idx + 1)

        # Build XOR equations
        equations = []
        for out_bit in range(8):
            pattern = self.gf.get_xor_pattern(alpha_power, out_bit)
            if pattern:
                terms = [f"x[{b}]" for b in pattern]
                equations.append(f"\t\ty[{out_bit}] = {' ^ '.join(terms)};")
            else:
                equations.append(f"\t\ty[{out_bit}] = 0;")

        return f"""module rsdec_syn_m{idx} (y, x);
\tinput [7:0] x;
\toutput [7:0] y;
\treg [7:0] y;
\talways @ (x)
\tbegin
{chr(10).join(equations)}
\tend
endmodule"""

    def _generate_main_syndrome_exact(self) -> str:
        """Generate main rsdec_syn module with exact reference structure"""
        # Port list - EXACT order from reference
        port_list = ", ".join([f"y{i}" for i in range(self.n_parity)])

        # Output declarations
        output_decls = []
        for i in range(self.n_parity):
            output_decls.append(f"\toutput [7:0] y{i};")

        # Reg declarations FIRST (matching reference order)
        reg_decls = []
        for i in range(self.n_parity):
            reg_decls.append(f"\treg [7:0] y{i};")

        # Wire declarations AFTER reg (matching reference order)
        wire_decls = []
        for i in range(self.n_parity):
            wire_decls.append(f"\twire [7:0] scale{i};")

        # Module instantiations
        instantiations = []
        for i in range(self.n_parity):
            instantiations.append(f"\trsdec_syn_m{i} m{i} (scale{i}, y{i});")

        # Reset, init, enable, and shift logic - ALL written out explicitly
        reset_logic = []
        init_logic = []
        enable_logic = []
        shift_logic = []

        for i in range(self.n_parity):
            reset_logic.append(f"\t\t\ty{i} <= 0;")
            init_logic.append(f"\t\t\ty{i} <= u;")
            enable_logic.append(f"\t\t\ty{i} <= scale{i} ^ u;")

        # Shift logic (y0 <- y1, y1 <- y2, etc.)
        for i in range(self.n_parity - 1):
            shift_logic.append(f"\t\t\ty{i} <= y{i+1};")
        shift_logic.append(f"\t\t\ty{self.n_parity-1} <= y0;")  # Circular shift (reference behavior)

        return f"""module rsdec_syn ({port_list}, u, enable, shift, init, clk, clrn);
\tinput [7:0] u;
\tinput clk, clrn, shift, init, enable;
{chr(10).join(output_decls)}
{chr(10).join(reg_decls)}

{chr(10).join(wire_decls)}

{chr(10).join(instantiations)}

\talways @ (posedge clk or negedge clrn)
\tbegin
\t\tif (~clrn)
\t\tbegin
{chr(10).join(reset_logic)}
\t\tend
\t\telse if (init)
\t\tbegin
{chr(10).join(init_logic)}
\t\tend
\t\telse if (enable)
\t\tbegin
{chr(10).join(enable_logic)}
\t\tend
\t\telse if (shift)
\t\tbegin
{chr(10).join(shift_logic)}
\t\tend
\tend
endmodule"""

    def generate_rs_2d_encode_sv(self):
        """Generate rs_2d_encode.sv with exact reference structure"""
        # Calculate dimensions
        data_symbols = self.k * self.k
        encoded_symbols = self.n * self.n
        data_bits = data_symbols * 8
        encoded_bits = encoded_symbols * 8
        parity_size = self.n - self.k

        # Generate ALL buffer initializations explicitly
        buffer_inits = []
        for i in range(data_symbols):
            buffer_inits.append(f"            encoded_array[{i//self.k}][{i%self.k}] <= 0;")

        content = f"""`timescale 1ns / 1ps

// 2D Reed-Solomon Encoder
// Implements 2D RS({self.n},{self.k}) encoding with row/column encoding and parity-on-parity

module rs_2d_encoder #(
    parameter N = {self.n},                    // Total symbols per dimension
    parameter K = {self.k},                    // Data symbols per dimension
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
localparam DATA_SYMBOLS = K * K;                           // {data_symbols} symbols
localparam ENCODED_SYMBOLS = N * N;                        // {encoded_symbols} symbols
localparam DATA_BITS = DATA_SYMBOLS * SYMBOL_WIDTH;        // {data_bits} bits
localparam ENCODED_BITS = ENCODED_SYMBOLS * SYMBOL_WIDTH;  // {encoded_bits} bits
localparam PARITY_SIZE = N - K;                            // {parity_size} symbols

// State machine states
typedef enum logic [3:0] {{
    IDLE,
    COLLECT_DATA,
    ENCODE_ROWS,
    ENCODE_COLS,
    PARITY_ON_PARITY_ROWS,
    PARITY_ON_PARITY_COLS,
    VERIFY_PARITY,
    OUTPUT_DATA
}} state_t;

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

endmodule"""
        # Write to file
        filepath = os.path.join(self.output_dir, 'rs_2d_encode.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: rs_2d_encode.sv (exact structure for 2D)")

    def generate_rs_2d_decode_sv(self):
        """Generate rs_2d_decode.sv with exact reference structure"""
        # Calculate dimensions
        data_symbols = self.k * self.k
        encoded_symbols = self.n * self.n
        data_bits = data_symbols * 8
        encoded_bits = encoded_symbols * 8
        parity_size = self.n - self.k

        content = f"""`timescale 1ns / 1ps

// 2D Reed-Solomon Decoder
// Implements 2D RS({self.n},{self.k}) iterative decoding with row/column correction

module rs_2d_decoder #(
    parameter N = {self.n},                    // Total symbols per dimension
    parameter K = {self.k},                    // Data symbols per dimension
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
localparam DATA_SYMBOLS = K * K;                           // {data_symbols} symbols
localparam ENCODED_SYMBOLS = N * N;                        // {encoded_symbols} symbols
localparam DATA_BITS = DATA_SYMBOLS * SYMBOL_WIDTH;        // {data_bits} bits
localparam ENCODED_BITS = ENCODED_SYMBOLS * SYMBOL_WIDTH;  // {encoded_bits} bits

// State machine states
typedef enum logic [3:0] {{
    IDLE,
    COLLECT_DATA,
    DECODE_ROWS,
    DECODE_COLS,
    CHECK_CONVERGENCE,
    OUTPUT_DATA
}} state_t;

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

endmodule"""
        # Write to file
        filepath = os.path.join(self.output_dir, 'rs_2d_decode.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: rs_2d_decode.sv (exact structure for 2D)")

    def generate_encode_sv(self):
        """Generate encode.sv with correct mathematical coefficients"""
        header = """// -------------------------------------------------------------------------
//Reed-Solomon Encoder
//Copyright (C) Tue Apr  2 17:06:57 2002
//by Ming-Han Lei(hendrik@humanistic.org) - Modified by Qasim Li (qasim.li@mail.mcgill.ca)
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
// --------------------------------------------------------------------------

"""

        # Generate encoder modules
        modules = []
        for i in range(self.n_parity):
            modules.append(self.generate_encoder_module(i))

        # Generate main encoder module
        main_module = self._generate_main_encoder()

        content = header + "\n".join(modules) + "\n\n" + main_module

        # Write to file
        filepath = os.path.join(self.output_dir, 'encode.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: encode.sv")

    def generate_encoder_module(self, idx: int) -> str:
        """Generate a single encoder multiplier module"""
        coeff = self.gen_poly[idx] if idx < len(self.gen_poly) else 0

        # Build XOR equations
        equations = []
        for out_bit in range(8):
            pattern = self.gf.get_xor_pattern(coeff, out_bit)
            if pattern:
                terms = [f"x[{b}]" for b in pattern]
                equations.append(f"\t\ty[{out_bit}] = {' ^ '.join(terms)};")
            else:
                equations.append(f"\t\ty[{out_bit}] = 0;")

        return f"""module rs_enc_m{idx} (y, x);
\tinput [7:0] x;
\toutput [7:0] y;
\treg [7:0] y;
\talways @ (x)
\tbegin
{chr(10).join(equations)}
\tend
endmodule"""

    def _generate_main_encoder(self) -> str:
        """Generate the main rs_enc module with exact interface"""
        # Wire and register declarations
        wire_decls = []
        mem_decls = []
        for i in range(self.n_parity):
            wire_decls.append(f"\twire [7:0] scale{i};")
            mem_decls.append(f"\treg [7:0] mem{i};")

        # Module instantiations
        instantiations = []
        for i in range(self.n_parity):
            instantiations.append(f"\trs_enc_m{i} m{i} (scale{i}, feedback);")

        # Memory updates (shift register pattern)
        mem_updates = []
        for i in range(self.n_parity - 1, 0, -1):
            mem_updates.append(f"\t\t\tmem{i} <= mem{i-1} ^ scale{i};")
        mem_updates.append(f"\t\t\tmem0 <= scale0;")

        # Memory resets
        mem_resets = []
        for i in range(self.n_parity):
            mem_resets.append(f"\t\t\tmem{i} <= 0;")

        return f"""module rs_enc (y, x, enable, data, clk, clrn);
\tinput [7:0] x;
\tinput clk, clrn, enable, data;
\toutput [7:0] y;
\treg [7:0] y;

{chr(10).join(wire_decls)}
{chr(10).join(mem_decls)}
\treg [7:0] feedback;

{chr(10).join(instantiations)}

\talways @ (posedge clk or negedge clrn)
\tbegin
\t\tif (~clrn)
\t\tbegin
{chr(10).join(mem_resets)}
\t\tend
\t\telse if (enable)
\t\tbegin
{chr(10).join(mem_updates)}
\t\tend
\tend

\talways @ (data or x or mem{self.n_parity-1})
\t\tif (data) feedback = x ^ mem{self.n_parity-1};
\t\telse feedback = 0;

\talways @ (data or x or mem{self.n_parity-1})
\t\tif (data) y = x;
\t\telse y = mem{self.n_parity-1};

endmodule"""

    def generate_encode_wrapper(self):
        """Generate rs_encode_wrapper.sv with EXACT reference structure"""
        # Generate ALL buffer initializations explicitly
        buffer_inits = []
        for i in range(self.k):
            buffer_inits.append(f"            data_buffer[{i}] <= 0;")

        # Generate ALL buffer loads explicitly
        buffer_loads = []
        for i in range(self.k):
            buffer_loads.append(f"                        data_buffer[{i}] <= datain[{i}*8 +: 8];")

        content = f"""module rs_encode_wrapper(
    input clk,
    input rst_n,
    input clrn,
    input encode_en,               // 开始编码的外部信号
    input scan_mode,
    input [8*{self.k}-1:0] datain,
    output reg [8*{self.n}-1:0] encoded_data,
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
    reg [7:0] data_buffer[0:{self.k-1}]; // Buffer to hold input data
    integer i, j;

    assign valid_re = valid;
    assign ready_re = 1'b1;
    assign encoded_data_re = {{50{{valid}}}};

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
            enc_ena <= 0;
            data_present <= 0;
            valid <= 0;
            ready <= 1; // Initially ready
            encoded_data <= 0;
{chr(10).join(buffer_inits)}
        end else if (!clrn) begin
            // Reset logic
            message <= 8'b0;
            state <= S_IDLE;
            i <= 0;
            j <= 0;
            enc_ena <= 0;
            data_present <= 0;
            valid <= 0;
            ready <= 1; // Initially ready
            encoded_data <= 0;
{chr(10).join(buffer_inits)}
        end else begin
            case (state)
                S_IDLE: begin
                    valid <= 0; // Clear valid signal
                    if (encode_en && ready) begin
                        i <= 0;
                        ready <= 0; // Not ready until encoding is done
                        state <= S_LOAD;
                        // Load data into buffer
{chr(10).join(buffer_loads)}
                    end
                end

                S_LOAD: begin
                    enc_ena <= 1; // Enable encoder for {self.n} cycles
                    if (i < {self.k}) begin
                        message <= data_buffer[i];
                        data_present <= 1; // Latch data for {self.k} cycles
                        i <= i + 1;
                        // if (i > 0) begin
                        encoded_data[(i-1)*8 +: 8] <= encoded;
                        // end
                    end else begin
                        encoded_data[(i-1)*8 +: 8] <= encoded;
                        data_present <= 0; // Stop latching data
                        state <= S_ENCODE;
                    end
                end

                S_ENCODE: begin
                    // Wait for encoder to finish encoding
                    if (i >= {self.n}) begin
                        enc_ena <= 0; // Disable encoder
                        // encoded_data[(i)*8 +: 8] <= encoded;
                        state <= S_FINISH; // Move to finish state
                    end else begin
                        i <= i + 1;
                        encoded_data[(i)*8 +: 8] <= encoded;
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
endmodule"""

        # Write to file
        filepath = os.path.join(self.output_dir, 'rs_encode_wrapper.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: rs_encode_wrapper.sv (exact structure)")

    def generate_decode_wrapper(self):
        """Generate rs_decode_wrapper.sv with EXACT reference structure"""
        content = f"""module rs_decode_wrapper(
    input clk,
    input rst_n, // Active low reset
    input decode_en,
    input clrn,
    input scan_mode,
    input [{self.n}*8-1:0] encoded_data,
    output reg [{self.n}*8-1:0] error_pos,
    output reg output_valid,
    output reg ready,
    output  with_error,  //output reg  with_error

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

localparam [7:0] k = 8'd{self.n};

assign ready_re = 1'b1;
assign output_valid_re = output_valid;
assign with_error_re = 1'b1;
assign error_pos_re = {{50{{output_valid}}}};

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
    end else if (!clrn) begin
        received <= 8'b0;
        state <= IDLE;
        bit_count <= 0;
        error_pos <= 0;
        output_valid <= 0;
        decode_counter <= 0;
        dec_ena <= 0;
        ready <= 1;
    end else begin
        case (state)
            IDLE: begin
                if (decode_en) begin
                    state <= DECODE;
                    dec_ena <= 0; // Enable the decoder
                    decode_counter <= 0; // Reset the counter
                    error_pos <= 0;
                    bit_count <= 0;
                    ready <= 0;
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
                end else if (decode_counter < k + {self.n_parity}) begin
                    // Wait {self.n_parity} cycles for decoder to compute syndromes and set with_error
                    decode_counter <= decode_counter + 1;
                end else begin
                    // After {self.n_parity} cycle wait, check with_error
                    // $display("  [%0t] RS_DECODE_WRAPPER: Wait complete, with_error=%b", $time, with_error);
                    if (with_error) begin
                        // $display("  [%0t] RS_DECODE_WRAPPER: Errors detected, transitioning to COLLECT_ERROR", $time);
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
                if (valid) begin
                    error_pos[bit_count*8 +: 8] <= error; // Collect error data
                    bit_count <= bit_count + 1; // Increment bit_count to point to the next byte
                    if (bit_count >= k-1) begin // Check if all bytes processed
                        state <= COMPLETE;
                    end
                end else begin
                    state <= COLLECT_ERROR; // Transition to complete once valid goes low
                end
            end
            COMPLETE: begin
                output_valid <= 1; // Indicate that the output data is valid
                state <= IDLE; // Reset to idle state for the next operation
                bit_count <= 0; // Reset bit_count for the next operation
                ready <= 1;
            end
            default: state <= IDLE;
        endcase
    end
end

endmodule"""

        # Write to file
        filepath = os.path.join(self.output_dir, 'rs_decode_wrapper.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: rs_decode_wrapper.sv (exact structure)")

    def generate_decode_sv(self):
        """Generate decode.sv with parameterized syndrome count"""
        # Generate syndrome wire declarations
        syndrome_wires = ", ".join([f"s{i}" for i in range(self.n_parity)])
        syndrome_wire_decls = "\n\t".join([f"wire [7:0] s{i};" for i in range(self.n_parity)])

        # Generate rsdec_syn instantiation with correct number of syndromes
        syndrome_ports = ", ".join([f"s{i}" for i in range(self.n_parity)])

        # Generate rsdec_berl syndrome connections (s0, s31, s30, ... s1 pattern)
        berl_syndromes = f"s0, " + ", ".join([f"s{i}" for i in range(self.n_parity-1, 0, -1)])

        # Generate syndrome OR check for with_error
        syndrome_or = " | ".join([f"s{i}" for i in range(self.n_parity)])

        # Always @ sensitivity list for with_error
        syndrome_sensitivity = " or ".join([f"s{i}" for i in range(self.n_parity)])

        content = f"""// -------------------------------------------------------------------------
//Reed-Solomon decoder
//Copyright (C) Wed May 22 10:06:57 2002
//by Ming-Han Lei(hendrik@humanistic.org) - Modified by Qasim Li (qasim.li@mail.mcgill.ca)
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
// --------------------------------------------------------------------------

module rsdec(x, error, with_error, enable, valid, k, clk, clrn);
\tinput enable, clk, clrn;
\tinput [7:0] k, x;
\toutput [7:0] error;
\twire [7:0] error;
\toutput with_error, valid;
\treg with_error, valid;

{chr(10).join(["\t" + decl for decl in syndrome_wire_decls.split("\n")])}
\twire [7:0] lambda, omega, alpha;
\treg [5:0] count;
\treg [{self.n_parity}:0] phase;
\twire [7:0] D0, D1, DI;
\treg [7:0] D, D2;
\treg [7:0] u, length0, length1, length2, length3;
\treg syn_enable, syn_init, syn_shift, berl_enable;
\treg chien_search, chien_load, shorten;

\talways @ (chien_search or shorten)
\t\tvalid = chien_search & ~shorten;

\trsdec_syn x0 ({syndrome_ports},
\t\tu, syn_enable, syn_shift&phase[0], syn_init, clk, clrn);
\trsdec_berl x1 (lambda, omega,
\t\t{berl_syndromes},
\t\tD0, D2, count, phase[0], phase[{self.n_parity}], berl_enable, clk, clrn);
\trsdec_chien x2 (error, alpha, lambda, omega,
\t\tD1, DI, chien_search, chien_load, shorten, clk, clrn);
\tinverse x3 (DI, D);

\talways @ (posedge clk or negedge clrn)
\tbegin
\t\tif (~clrn)
\t\tbegin
\t\t\tsyn_enable <= 0;
\t\t\tsyn_shift <= 0;
\t\t\tberl_enable <= 0;
\t\t\tchien_search <= 1;
\t\t\tchien_load <= 0;
\t\t\tlength0 <= 0;
\t\t\tlength2 <= 255 - k;
\t\t\tcount <= -1;
\t\t\tphase <= 1;
\t\t\tu <= 0;
\t\t\tshorten <= 1;
\t\t\tsyn_init <= 0;
\t\tend
\t\telse
\t\tbegin
\t\t\tif (enable & ~syn_enable & ~syn_shift)
\t\t\tbegin
\t\t\t\tsyn_enable <= 1;
\t\t\t\tsyn_init <= 1;
\t\t\tend
\t\t\tif (syn_enable)
\t\t\tbegin
\t\t\t\tlength0 <= length1;
\t\t\t\tsyn_init <= 0;
\t\t\t\tif (length1 == k)
\t\t\t\tbegin
\t\t\t\tsyn_enable <= 0;
\t\t\t\tsyn_shift <= 1;
\t\t\t\tberl_enable <= 1;
\t\t\t\tend
\t\t\tend
\t\t\tif (berl_enable & with_error)
\t\t\tbegin
\t\t\t\tif (phase[0])
\t\t\t\tbegin
\t\t\t\t\tcount <= count + 1;
\t\t\t\t\tif (count == {self.n_parity - 1})
\t\t\t\t\tbegin
\t\t\t\t\t\tsyn_shift <= 0;
\t\t\t\t\t\tlength0 <= 0;
\t\t\t\t\t\tchien_load <= 1;
\t\t\t\t\t\tlength2 <= length0;
\t\t\t\t\tend
\t\t\t\tend
\t\t\t\tphase <= {{phase[{self.n_parity-1}:0], phase[{self.n_parity}]}};
\t\t\tend
\t\t\tif (berl_enable & ~with_error)
\t\t\t\tif (&count)
\t\t\t\tbegin
\t\t\t\t\tsyn_shift <= 0;
\t\t\t\t\tlength0 <= 0;
\t\t\t\t\tberl_enable <= 0;
\t\t\t\tend
\t\t\t\telse
\t\t\t\t\tphase <= {{phase[{self.n_parity-1}:0], phase[{self.n_parity}]}};
\t\t\tif (chien_load & phase[{self.n_parity}])
\t\t\tbegin
\t\t\t\tberl_enable <= 0;
\t\t\t\tchien_load <= 0;
\t\t\t\tchien_search <= 1;
\t\t\t\tcount <= -1;
\t\t\t\tphase <= 1;
\t\t\tend
\t\t\tif (chien_search)
\t\t\tbegin
\t\t\t\tlength2 <= length3;
\t\t\t\tif (length3 == 0)
\t\t\t\t\tchien_search <= 0;
\t\t\tend
\t\tif (enable) u <= x;
\t\tif (shorten == 1 && length2 == 0)
\t\t\tshorten <= 0;
\t\tend

\tend

\talways @ (chien_search or D0 or D1)
\t\tif (chien_search) D = D1;
\t\telse D = D0;

\talways @ (DI or alpha or chien_load)
\t\tif (chien_load) D2 = alpha;
\t\telse D2 = DI;

\talways @ (length0) length1 = length0 + 1;
\talways @ (length2) length3 = length2 - 1;
\talways @ (syn_shift or {syndrome_sensitivity})
\t\tif (syn_shift && ({syndrome_or})!= 0)
\t\t\twith_error = 1;
\t\telse with_error = 0;

endmodule"""

        filepath = os.path.join(self.output_dir, 'decode.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: decode.sv")

    def generate_multiply_module(self) -> str:
        """Generate GF(256) multiply module"""
        # Generate multiplication lookup table for GF(256)
        mult_lines = []
        for out_bit in range(8):
            terms = []
            for a_bit in range(8):
                for b_bit in range(8):
                    # Calculate product in GF(256)
                    a_val = 1 << a_bit
                    b_val = 1 << b_bit
                    product = self.gf.mult(a_val, b_val)
                    if product & (1 << out_bit):
                        terms.append(f"(a[{a_bit}] & b[{b_bit}])")
            if terms:
                mult_lines.append(f"\t\ty[{out_bit}] = {' ^ '.join(terms)};")
            else:
                mult_lines.append(f"\t\ty[{out_bit}] = 0;")

        return f"""module multiply (y, a, b);
\tinput [7:0] a, b;
\toutput [7:0] y;
\treg [7:0] y;
\talways @ (a or b)
\tbegin
{chr(10).join(mult_lines)}
\tend
endmodule"""

    def generate_berlekamp_sv(self):
        """Generate berlekamp.sv with parameterized syndrome inputs"""
        # Generate syndrome parameter list
        syndrome_params = ", ".join([f"syndrome{i}" for i in range(self.n_parity)])
        syndrome_inputs = "\n\t".join([f"input [7:0] syndrome{i};" for i in range(self.n_parity)])

        # Generate tmp wire declarations
        tmp_wires = "\n\t".join([f"wire [7:0] tmp{i};" for i in range(self.n_parity)])

        # Generate multiply module instantiations
        multiply_instances = []
        for i in range(self.n_parity):
            if i == 0:
                multiply_instances.append(f"\trsdec_berl_multiply x{i} (tmp{i}, B[{self.n_parity-2}], D, lambda[{i}], syndrome{i}, phase0);")
            elif i == 1:
                multiply_instances.append(f"\trsdec_berl_multiply x{i} (tmp{i}, lambda[{self.n_parity-1}], DI, lambda[{i}], syndrome{i}, phase0);")
            elif i == 2:
                multiply_instances.append(f"\trsdec_berl_multiply x{i} (tmp{i}, A[{self.n_parity-2}], D, lambda[{i}], syndrome{i}, phase0);")
            elif i == 3:
                multiply_instances.append(f"\trsdec_berl_multiply x{i} (tmp{i}, omega[{self.n_parity-1}], DI, lambda[{i}], syndrome{i}, phase0);")
            else:
                multiply_instances.append(f"\tmultiply x{i} (tmp{i}, lambda[{i}], syndrome{i});")

        # Generate tmp XOR for D calculation
        tmp_xor = " ^ ".join([f"tmp{i}" for i in range(self.n_parity)])

        # Generate for loop bounds for arrays
        lambda_reset = f"\t\t\tfor (j = 0; j < {self.n_parity}; j = j + 1) lambda[j] <= 0;"
        B_reset = f"\t\t\tfor (j = 0; j < {self.n_parity-1}; j = j + 1) B[j] <= 0;"
        omega_reset = f"\t\t\tfor (j = 0; j < {self.n_parity}; j = j + 1) omega[j] <= 0;"
        A_reset = f"\t\t\tfor (j = 0; j < {self.n_parity-1}; j = j + 1) A[j] <= 0;"

        lambda_init1 = f"\t\t\tfor (j = 1; j < {self.n_parity}; j = j +1) lambda[j] <= 0;"
        B_init1 = f"\t\t\tfor (j = 1; j < {self.n_parity-1}; j = j +1) B[j] <= 0;"
        omega_init1 = f"\t\t\tfor (j = 1; j < {self.n_parity}; j = j +1) omega[j] <= 0;"
        A_init = f"\t\t\tfor (j = 0; j < {self.n_parity-1}; j = j + 1) A[j] <= 0;"

        lambda_shift = f"\t\t\t\tfor (j = 1; j < {self.n_parity}; j = j + 1)\n\t\t\t\t\tlambda[j] <= lambda[j-1];"
        B_shift = f"\t\t\t\tfor (j = 1; j < {self.n_parity-1}; j = j + 1)\n\t\t\t\t\tB[j] <= B[j-1];"
        omega_shift = f"\t\t\t\tfor (j = 1; j < {self.n_parity}; j = j + 1)\n\t\t\t\t\tomega[j] <= omega[j-1];"
        A_shift = f"\t\t\t\tfor (j = 1; j < {self.n_parity-1}; j = j + 1)\n\t\t\t\t\tA[j] <= A[j-1];"

        content = f"""// -------------------------------------------------------------------------
//Berlekamp circuit for Reed-Solomon decoder
//Copyright (C) Tue Apr  2 17:07:10 2002
//by Ming-Han Lei(hendrik@humanistic.org) - Modified by Qasim Li (qasim.li@mail.mcgill.ca)
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
// --------------------------------------------------------------------------

module rsdec_berl (lambda_out, omega_out, {syndrome_params},
\t\tD, DI, count, phase0, phase{self.n_parity}, enable, clk, clrn);
\tinput clk, clrn, enable, phase0, phase{self.n_parity};
{chr(10).join(["\t" + line for line in syndrome_inputs.split("\n")])}
\tinput [7:0] DI;
\tinput [5:0] count;
\toutput [7:0] D;
\toutput [7:0] lambda_out, omega_out;
\treg [7:0] lambda_out;
\treg [7:0] omega_out;
\treg [7:0] D;

\tinteger j;
\treg init, delta;
\treg [4:0] L;
\treg [7:0] lambda[{self.n_parity-1}:0];
\treg [7:0] omega[{self.n_parity-1}:0];
\treg [7:0] A[{self.n_parity-2}:0];
\treg [7:0] B[{self.n_parity-2}:0];
{chr(10).join(["\t" + line for line in tmp_wires.split("\n")])}

\talways @ (tmp1) lambda_out = tmp1;
\talways @ (tmp3) omega_out = tmp3;

\talways @ (L or D or count)
\t\t// delta = (D != 0 && 2*L <= i);
\t\tif (D != 0 && count >= {{L, 1'b0}}) delta = 1;
\t\telse delta = 0;

{chr(10).join(multiply_instances)}

\talways @ (posedge clk or negedge clrn)
\tbegin
\t\tif (~clrn)
\t\tbegin
{lambda_reset}
{B_reset}
{omega_reset}
{A_reset}
\t\t\tL <= 0;
\t\t\tD <= 0;
\t\tend
\t\telse if (~enable)
\t\tbegin
\t\t\tlambda[0] <= 1;
{lambda_init1}
\t\t\tB[0] <= 1;
{B_init1}
\t\t\tomega[0] <= 1;
{omega_init1}
{A_init}
\t\t\tL <= 0;
\t\t\tD <= 0;
\t\tend
\t\telse
\t\tbegin
\t\t\tif (~phase0)
\t\t\tbegin
\t\t\t\tif (~phase{self.n_parity}) lambda[0] <= lambda[{self.n_parity-1}] ^ tmp0;
\t\t\t\telse lambda[0] <= lambda[{self.n_parity-1}];
{chr(10).join(["\t\t\t" + line for line in lambda_shift.split("\n")])}
\t\t\tend

\t\t\tif (~phase0)
\t\t\tbegin
\t\t\t\tif (delta)\tB[0] <= tmp1;
\t\t\t\telse if (~phase{self.n_parity}) B[0] <= B[{self.n_parity-2}];
\t\t\t\telse B[0] <= 0;
{chr(10).join(["\t\t\t" + line for line in B_shift.split("\n")])}
\t\t\tend

\t\t\tif (~phase0)
\t\t\tbegin
\t\t\t\tif (~phase{self.n_parity}) omega[0] <= omega[{self.n_parity-1}] ^ tmp2;
\t\t\t\telse omega[0] <= omega[{self.n_parity-1}];
{chr(10).join(["\t\t\t" + line for line in omega_shift.split("\n")])}
\t\t\tend

\t\t\tif (~phase0)
\t\t\tbegin
\t\t\t\tif (delta)\tA[0] <= tmp3;
\t\t\t\telse if (~phase{self.n_parity}) A[0] <= A[{self.n_parity-2}];
\t\t\t\telse A[0] <= 0;
{chr(10).join(["\t\t\t" + line for line in A_shift.split("\n")])}
\t\t\tend

\t\t\tif ((phase0 & delta) && (count != -1)) L <= count - L + 1;

\t\t\tif (phase0)
\t\t\t\tD <= {tmp_xor};

\t\tend
\tend

endmodule


module rsdec_berl_multiply (y, a, b, c, d, e);
\tinput [7:0] a, b, c, d;
\tinput e;
\toutput [7:0] y;
\twire [7:0] y;
\treg [7:0] p, q;

\talways @ (a or c or e)
\t\tif (e) p = c;
\t\telse p = a;
\talways @ (b or d or e)
\t\tif (e) q = d;
\t\telse q = b;

\tmultiply x0 (y, p, q);

endmodule

{self.generate_multiply_module()}
"""

        filepath = os.path.join(self.output_dir, 'berlekamp.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: berlekamp.sv (full parameterized implementation)")

    def generate_chien_search_sv(self):
        """Generate chien-search.sv with exact reference structure"""
        # Generate scale modules - only n_parity modules (reused for both lambda and omega)
        scale_modules = []
        for i in range(self.n_parity):
            # Get XOR pattern for α^i (scale0 = α^0 = identity)
            alpha_power = self.gf.power(2, i) if i > 0 else 1
            equations = []
            for out_bit in range(8):
                pattern = self.gf.get_xor_pattern(alpha_power, out_bit)
                if pattern:
                    terms = [f"x[{b}]" for b in pattern]
                    equations.append(f"\t\ty[{out_bit}] = {' ^ '.join(terms)};")
                else:
                    equations.append(f"\t\ty[{out_bit}] = 0;")

            scale_modules.append(f"""module rsdec_chien_scale{i} (y, x);
\tinput [7:0] x;
\toutput [7:0] y;
\treg [7:0] y;

\talways @ (x)
\tbegin
{chr(10).join(equations)}
\tend
endmodule
""")

        # Generate wire declarations for scale and reg declarations for data
        scale_wires = "\n\t".join([f"wire [7:0] scale{i};" for i in range(2 * self.n_parity)])
        data_regs = "\n\t".join([f"reg [7:0] data{i};" for i in range(self.n_parity)])

        # Generate reg declarations for a, l, o (in reference order)
        a_regs = "\n\t".join([f"reg [7:0] a{i};" for i in range(self.n_parity)])
        l_regs = "\n\t".join([f"reg [7:0] l{i};" for i in range(self.n_parity)])
        o_regs = "\n\t".join([f"reg [7:0] o{i};" for i in range(self.n_parity)])

        # Generate scale module instantiations for lambda (data -> scale)
        lambda_scale = "\n\t".join([f"rsdec_chien_scale{i} x{i} (scale{i}, data{i});"
                                   for i in range(self.n_parity)])

        # Generate scale module instantiations for omega (o -> scale) - REUSE same modules
        omega_scale = "\n\t".join([f"rsdec_chien_scale{i} x{i+self.n_parity} (scale{i+self.n_parity}, o{i});"
                                  for i in range(self.n_parity)])

        # Generate data mux (shorten ? a : l)
        data_mux = "\n\n\t".join([f"always @ (shorten or a{i} or l{i})\n\t\tif (shorten) data{i} = a{i};\n\t\telse data{i} = l{i};"
                                   for i in range(self.n_parity)])

        # Generate always block reset assignments
        l_reset = "\n\t\t\t".join([f"l{i} <= 0;" for i in range(self.n_parity)])
        o_reset = "\n\t\t\t".join([f"o{i} <= 0;" for i in range(self.n_parity)])
        a_reset_1 = "\n\t\t\t".join([f"a{i} <= 1;" for i in range(self.n_parity)])

        # Generate shorten assignments
        a_shorten = "\n\t\t\t".join([f"a{i} <= scale{i};" for i in range(self.n_parity)])

        # Generate search assignments
        l_search = "\n\t\t\t".join([f"l{i} <= scale{i};" for i in range(self.n_parity)])
        o_search = "\n\t\t\t".join([f"o{i} <= scale{i+self.n_parity};" for i in range(self.n_parity)])

        # Generate load assignments (shift chain)
        l_load = [f"l0 <= lambda;"]
        l_load.extend([f"l{i} <= l{i-1};" for i in range(1, self.n_parity)])
        l_load_str = "\n\t\t\t".join(l_load)

        o_load = [f"o0 <= omega;"]
        o_load.extend([f"o{i} <= o{i-1};" for i in range(1, self.n_parity)])
        o_load_str = "\n\t\t\t".join(o_load)

        # Fix: a0 should receive a{self.n_parity-1} for circular shift
        a_load = [f"a0 <= a{self.n_parity-1};"]
        a_load.extend([f"a{i} <= a{i-1};" for i in range(1, self.n_parity)])
        a_load_str = "\n\t\t\t".join(a_load)

        # Generate even/odd sensitivity lists
        even_sensitivity = " or ".join([f"l{i}" for i in range(0, self.n_parity, 2)])
        odd_sensitivity = " or ".join([f"l{i}" for i in range(1, self.n_parity, 2)])
        numerator_sensitivity = " or ".join([f"o{i}" for i in range(self.n_parity)])

        # Generate even/odd/numerator XOR
        even_xor = " ^ ".join([f"l{i}" for i in range(0, self.n_parity, 2)])
        odd_xor = " ^ ".join([f"l{i}" for i in range(1, self.n_parity, 2)])
        numerator_xor = " ^ ".join([f"o{i}" for i in range(self.n_parity)])

        content = f"""// -------------------------------------------------------------------------
//Chien-Forney search circuit for Reed-Solomon decoder
//Copyright (C) Tue Apr  2 17:07:16 2002
//by Ming-Han Lei(hendrik@humanistic.org) - Modified by Qasim Li (qasim.li@mail.mcgill.ca)
//
//This program is free software; you can redistribute it and/or
//modify it under the terms of the GNU Lesser General Public License
//as published by the Free Software Foundation; either version 2
//of the License, or (at your option) any later version.
//
//This program is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU Lesser General Public License
//along with this program; if not, write to the Free Software
//Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
// --------------------------------------------------------------------------

{"".join(scale_modules)}

module rsdec_chien (error, alpha, lambda, omega, even, D, search, load, shorten, clk, clrn);
\tinput clk, clrn, load, search, shorten;
\tinput [7:0] D;
\tinput [7:0] lambda;
\tinput [7:0] omega;
\toutput [7:0] even, error;
\toutput [7:0] alpha;
\treg [7:0] even, error;
\treg [7:0] alpha;

{chr(10).join(["\t" + line for line in scale_wires.split("\n")])}
{chr(10).join(["\t" + line for line in data_regs.split("\n")])}
{chr(10).join(["\t" + line for line in a_regs.split("\n")])}
{chr(10).join(["\t" + line for line in l_regs.split("\n")])}
{chr(10).join(["\t" + line for line in o_regs.split("\n")])}
\treg [7:0] odd, numerator;
\twire [7:0] tmp;
\tinteger j;

{chr(10).join(["\t" + line for line in lambda_scale.split("\n")])}
{chr(10).join(["\t" + line for line in omega_scale.split("\n")])}

{chr(10).join(["\t" + line for line in data_mux.split("\n")])}

\talways @ (posedge clk or negedge clrn)
\tbegin
\t\tif (~clrn)
\t\tbegin
\t\t\t{l_reset}
\t\t\t{o_reset}
\t\t\t{a_reset_1}
\t\tend
\t\telse if (shorten)
\t\tbegin
\t\t\t{a_shorten}
\t\tend
\t\telse if (search)
\t\tbegin
\t\t\t{l_search}
\t\t\t{o_search}
\t\tend
\t\telse if (load)
\t\tbegin
\t\t\t{l_load_str}
\t\t\t{o_load_str}
\t\t\t{a_load_str}
\t\tend
\tend

\talways @ ({even_sensitivity})
\t\teven = {even_xor};

\talways @ ({odd_sensitivity})
\t\todd = {odd_xor};

\talways @ ({numerator_sensitivity})
\t\tnumerator = {numerator_xor};

\tmultiply m0 (tmp, numerator, D);

\talways @ (even or odd or tmp)
\t\tif (even == odd) error = tmp;
\t\telse error = 0;

\talways @ (a{self.n_parity-1}) alpha = a{self.n_parity-1};

endmodule"""

        filepath = os.path.join(self.output_dir, 'chien-search.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: chien-search.sv (full parameterized with exact structure)")

    def copy_static_files(self):
        """Copy static files from ref_2d directory"""
        # Files that need to be copied from ref_2d
        static_files = [
            'serial_to_parallel.sv',
            'parallel_to_serial.sv',
            'counter.sv',
            'inverse.sv',
            'data-rom.sv'
        ]

        for filename in static_files:
            src = os.path.join('ref_2d', filename)
            dst = os.path.join(self.output_dir, filename)
            if os.path.exists(src):
                shutil.copy2(src, dst)
                print(f"Copied: {filename}")
            else:
                print(f"Warning: {filename} not found in ref_2d/")

    def generate_all(self):
        """Generate all files with exact structure matching for 2D RS"""
        print(f"Generating 2D RS({self.n}, {self.k}) code with EXACT structure matching...")
        print(f"Parity symbols per dimension: {self.n_parity}")
        print(f"Data symbols: {self.k}x{self.k} = {self.k*self.k}")
        print(f"Encoded symbols: {self.n}x{self.n} = {self.n*self.n}")
        print("-" * 50)

        # Generate all required files for 2D RS implementation
        self.generate_syndrome_sv()
        self.generate_encode_sv()
        self.generate_encode_wrapper()
        self.generate_decode_sv()
        self.generate_berlekamp_sv()
        self.generate_chien_search_sv()
        self.generate_decode_wrapper()
        self.generate_rs_2d_encode_sv()
        self.generate_rs_2d_decode_sv()

        # Copy static files from ref_2d
        self.copy_static_files()

        print("-" * 50)
        print(f"Generation complete! Files written to {self.output_dir}/")

def main():
    parser = argparse.ArgumentParser(description='Generate 2D Reed-Solomon SystemVerilog code with exact structure')
    parser.add_argument('--n', type=int, default=15, help='Codeword length per dimension (default: 15 for RS(15,11))')
    parser.add_argument('--k', type=int, default=11, help='Data symbols per dimension (default: 11 for RS(15,11))')
    parser.add_argument('--output', type=str, default='gen_2d', help='Output directory')

    args = parser.parse_args()

    generator = RSGenerator(args.n, args.k, args.output)
    generator.generate_all()

if __name__ == '__main__':
    main()
