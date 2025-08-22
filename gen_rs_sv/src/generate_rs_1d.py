"""
Reed-Solomon SystemVerilog Code Generator - Exact Structure Match
Generates mathematically correct RS codes with EXACT reference structure
"""

import argparse
import os
import shutil
from gf256 import GF256

class RS1DGenerator:
    """Generate RS code with exact reference structure matching"""
    
    def __init__(self, n: int, k: int, output_dir: str = 'gen'):
        self.n = n  # Total codeword length
        self.k = k  # Data symbols
        self.n_parity = n - k  # Parity symbols
        self.t = self.n_parity // 2  # Error correction capability
        self.output_dir = output_dir
        self.gf = GF256()
        
        # Get generator polynomial coefficients
        self.gen_poly = self.gf.get_generator_polynomial(self.n_parity)
        
        # Ensure output directory exists
        os.makedirs(self.output_dir, exist_ok=True)
    
    def generate_syndrome_sv(self):
        """Generate syndrome.sv with exact reference structure"""
        header = """// -------------------------------------------------------------------------
//Syndrome generator circuit in Reed-Solomon Decoder
//Copyright (C) Tue Apr  2 17:07:53 2002
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
        print(f"Generated: syndrome.sv (exact structure)")
    
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
//GNU Lesser General Public License for more details.
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
    
    def generate_decode_sv(self):
        """Generate decode.sv with parameterized syndrome count"""
        # Generate syndrome wire declarations
        syndrome_wires = ", ".join([f"s{i}" for i in range(self.n_parity)])
        syndrome_wire_decls = "\n\t".join([f"wire [7:0] s{i};" for i in range(self.n_parity)])
        
        # Generate rsdec_syn instantiation with correct number of syndromes
        syndrome_ports = ", ".join([f"s{i}" for i in range(self.n_parity)])
        
        # Generate rsdec_berl syndrome connections (s0, s31, s30, ... s1 pattern)
        berl_syndromes = f"s0, " + ", ".join([f"s{i}" for i in range(self.n_parity-1, 0, -1)])
        
        # Phase register width based on parity symbols
        phase_width = self.n_parity
        
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

\t{syndrome_wire_decls}
\twire [7:0] lambda, omega, alpha;
\treg [5:0] count;
\treg [{phase_width}:0] phase;
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
\t\tD0, D2, count, phase[0], phase[{phase_width}], berl_enable, clk, clrn);
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
\t\t\t\t\tsyn_enable <= 0;
\t\t\t\t\tsyn_shift <= 1;
\t\t\t\t\tberl_enable <= 1;
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
\t\t\t\tphase <= {{phase[{self.n_parity-1}:0], phase[{phase_width}]}};
\t\t\tend
\t\t\tif (berl_enable & ~with_error)
\t\t\t\tif (&count)
\t\t\t\tbegin
\t\t\t\t\tsyn_shift <= 0;
\t\t\t\t\tlength0 <= 0;
\t\t\t\t\tberl_enable <= 0;
\t\t\t\tend
\t\t\t\telse
\t\t\t\t\tphase <= {{phase[{self.n_parity-1}:0], phase[{phase_width}]}};
\t\t\tif (chien_load & phase[{phase_width}])
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

endmodule
"""
        
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
\t{syndrome_inputs}
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
\t{tmp_wires}

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
{lambda_shift}
\t\t\tend

\t\t\tif (~phase0)
\t\t\tbegin
\t\t\t\tif (delta)\tB[0] <= tmp1;
\t\t\t\telse if (~phase{self.n_parity}) B[0] <= B[{self.n_parity-2}];
\t\t\t\telse B[0] <= 0;
{B_shift}
\t\t\tend

\t\t\tif (~phase0)
\t\t\tbegin
\t\t\t\tif (~phase{self.n_parity}) omega[0] <= omega[{self.n_parity-1}] ^ tmp2;
\t\t\t\telse omega[0] <= omega[{self.n_parity-1}];
{omega_shift}
\t\t\tend

\t\t\tif (~phase0)
\t\t\tbegin
\t\t\t\tif (delta)\tA[0] <= tmp3;
\t\t\t\telse if (~phase{self.n_parity}) A[0] <= A[{self.n_parity-2}];
\t\t\t\telse A[0] <= 0;
{A_shift}
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
        
        # Fix: a0 should receive a31 for circular shift
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

\t{scale_wires}
\t{data_regs}
\t{a_regs}
\t{l_regs}
\t{o_regs}
\treg [7:0] odd, numerator;
\twire [7:0] tmp;
\tinteger j;

\t{lambda_scale}
\t{omega_scale}

\t{data_mux}

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

endmodule
"""
        
        filepath = os.path.join(self.output_dir, 'chien-search.sv')
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Generated: chien-search.sv (full parameterized with exact structure)")
    
    def copy_static_files(self):
        """Copy static files from reference"""
        # Only copy files that don't need parameterization
        static_files = ['inverse.sv', 'data-rom.sv']
        for filename in static_files:
            src = os.path.join('ref', filename)
            dst = os.path.join(self.output_dir, filename)
            if os.path.exists(src):
                shutil.copy2(src, dst)
                print(f"Copied: {filename}")
    
    def generate_all(self):
        """Generate all files with exact structure matching"""
        print(f"Generating RS({self.n}, {self.k}) code with EXACT structure matching...")
        print(f"Parity symbols: {self.n_parity}")
        print("-" * 50)
        
        # Generate encoder (same as before)
        self.generate_encode_sv()
        
        # Generate syndrome with EXACT structure
        self.generate_syndrome_sv()
        
        # Generate wrappers with EXACT structure
        self.generate_encode_wrapper()
        self.generate_decode_wrapper()
        
        # Generate decoder files
        self.generate_decode_sv()
        self.generate_berlekamp_sv()
        self.generate_chien_search_sv()
        
        # Copy static files
        self.copy_static_files()
        
        print("-" * 50)
        print(f"Generation complete! Files written to {self.output_dir}/")

def main():
    parser = argparse.ArgumentParser(description='Generate Reed-Solomon SystemVerilog code with exact structure')
    parser.add_argument('--n', type=int, default=200, help='Codeword length')
    parser.add_argument('--k', type=int, default=168, help='Data symbols')
    parser.add_argument('--output', type=str, default='gen', help='Output directory')
    
    args = parser.parse_args()
    
    generator = RS1DGenerator(args.n, args.k, args.output)
    generator.generate_all()

if __name__ == '__main__':
    main()