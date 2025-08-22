// -------------------------------------------------------------------------
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
	input enable, clk, clrn;
	input [7:0] k, x;
	output [7:0] error;
	wire [7:0] error;
	output with_error, valid;
	reg with_error, valid;

	wire [7:0] s0;
		wire [7:0] s1;
		wire [7:0] s2;
		wire [7:0] s3;
		wire [7:0] s4;
		wire [7:0] s5;
	wire [7:0] lambda, omega, alpha;
	reg [5:0] count;
	reg [6:0] phase;
	wire [7:0] D0, D1, DI;
	reg [7:0] D, D2;
	reg [7:0] u, length0, length1, length2, length3;
	reg syn_enable, syn_init, syn_shift, berl_enable;
	reg chien_search, chien_load, shorten;

	always @ (chien_search or shorten)
		valid = chien_search & ~shorten;

	rsdec_syn x0 (s0, s1, s2, s3, s4, s5,
		u, syn_enable, syn_shift&phase[0], syn_init, clk, clrn);
	rsdec_berl x1 (lambda, omega,
		s0, s5, s4, s3, s2, s1,
		D0, D2, count, phase[0], phase[6], berl_enable, clk, clrn);
	rsdec_chien x2 (error, alpha, lambda, omega,
		D1, DI, chien_search, chien_load, shorten, clk, clrn);
	inverse x3 (DI, D);

	always @ (posedge clk or negedge clrn)
	begin
		if (~clrn)
		begin
			syn_enable <= 0;
			syn_shift <= 0;
			berl_enable <= 0;
			chien_search <= 1;
			chien_load <= 0;
			length0 <= 0;
			length2 <= 255 - k;
			count <= -1;
			phase <= 1;
			u <= 0;
			shorten <= 1;
			syn_init <= 0;
		end
		else
		begin
			if (enable & ~syn_enable & ~syn_shift)
			begin
				syn_enable <= 1;
				syn_init <= 1;
			end
			if (syn_enable)
			begin
				length0 <= length1;
				syn_init <= 0;
				if (length1 == k)
				begin
				syn_enable <= 0;
				syn_shift <= 1;
				berl_enable <= 1;
				end
			end
			if (berl_enable & with_error)
			begin
				if (phase[0])
				begin
					count <= count + 1;
					if (count == 5)
					begin
						syn_shift <= 0;
						length0 <= 0;
						chien_load <= 1;
						length2 <= length0;
					end
				end
				phase <= {phase[5:0], phase[6]};
			end
			if (berl_enable & ~with_error)
				if (&count)
				begin
					syn_shift <= 0;
					length0 <= 0;
					berl_enable <= 0;
				end
				else
					phase <= {phase[5:0], phase[6]};
			if (chien_load & phase[6])
			begin
				berl_enable <= 0;
				chien_load <= 0;
				chien_search <= 1;
				count <= -1;
				phase <= 1;
			end
			if (chien_search)
			begin
				length2 <= length3;
				if (length3 == 0)
					chien_search <= 0;
			end
		if (enable) u <= x;
		if (shorten == 1 && length2 == 0)
			shorten <= 0;
		end

	end

	always @ (chien_search or D0 or D1)
		if (chien_search) D = D1;
		else D = D0;

	always @ (DI or alpha or chien_load)
		if (chien_load) D2 = alpha;
		else D2 = DI;

	always @ (length0) length1 = length0 + 1;
	always @ (length2) length3 = length2 - 1;
	always @ (syn_shift or s0 or s1 or s2 or s3 or s4 or s5)
		if (syn_shift && (s0 | s1 | s2 | s3 | s4 | s5)!= 0)
			with_error = 1;
		else with_error = 0;

endmodule