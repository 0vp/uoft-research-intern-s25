// -------------------------------------------------------------------------
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

module rsdec_berl (lambda_out, omega_out, syndrome0, syndrome1, syndrome2, syndrome3, syndrome4, syndrome5,
		D, DI, count, phase0, phase6, enable, clk, clrn);
	input clk, clrn, enable, phase0, phase6;
	input [7:0] syndrome0;
		input [7:0] syndrome1;
		input [7:0] syndrome2;
		input [7:0] syndrome3;
		input [7:0] syndrome4;
		input [7:0] syndrome5;
	input [7:0] DI;
	input [5:0] count;
	output [7:0] D;
	output [7:0] lambda_out, omega_out;
	reg [7:0] lambda_out;
	reg [7:0] omega_out;
	reg [7:0] D;

	integer j;
	reg init, delta;
	reg [4:0] L;
	reg [7:0] lambda[5:0];
	reg [7:0] omega[5:0];
	reg [7:0] A[4:0];
	reg [7:0] B[4:0];
	wire [7:0] tmp0;
		wire [7:0] tmp1;
		wire [7:0] tmp2;
		wire [7:0] tmp3;
		wire [7:0] tmp4;
		wire [7:0] tmp5;

	always @ (tmp1) lambda_out = tmp1;
	always @ (tmp3) omega_out = tmp3;

	always @ (L or D or count)
		// delta = (D != 0 && 2*L <= i);
		if (D != 0 && count >= {L, 1'b0}) delta = 1;
		else delta = 0;

	rsdec_berl_multiply x0 (tmp0, B[4], D, lambda[0], syndrome0, phase0);
	rsdec_berl_multiply x1 (tmp1, lambda[5], DI, lambda[1], syndrome1, phase0);
	rsdec_berl_multiply x2 (tmp2, A[4], D, lambda[2], syndrome2, phase0);
	rsdec_berl_multiply x3 (tmp3, omega[5], DI, lambda[3], syndrome3, phase0);
	multiply x4 (tmp4, lambda[4], syndrome4);
	multiply x5 (tmp5, lambda[5], syndrome5);

	always @ (posedge clk or negedge clrn)
	begin
		if (~clrn)
		begin
			for (j = 0; j < 6; j = j + 1) lambda[j] <= 0;
			for (j = 0; j < 5; j = j + 1) B[j] <= 0;
			for (j = 0; j < 6; j = j + 1) omega[j] <= 0;
			for (j = 0; j < 5; j = j + 1) A[j] <= 0;
			L <= 0;
			D <= 0;
		end
		else if (~enable)
		begin
			lambda[0] <= 1;
			for (j = 1; j < 6; j = j +1) lambda[j] <= 0;
			B[0] <= 1;
			for (j = 1; j < 5; j = j +1) B[j] <= 0;
			omega[0] <= 1;
			for (j = 1; j < 6; j = j +1) omega[j] <= 0;
			for (j = 0; j < 5; j = j + 1) A[j] <= 0;
			L <= 0;
			D <= 0;
		end
		else
		begin
			if (~phase0)
			begin
				if (~phase6) lambda[0] <= lambda[5] ^ tmp0;
				else lambda[0] <= lambda[5];
							for (j = 1; j < 6; j = j + 1)
								lambda[j] <= lambda[j-1];
			end

			if (~phase0)
			begin
				if (delta)	B[0] <= tmp1;
				else if (~phase6) B[0] <= B[4];
				else B[0] <= 0;
							for (j = 1; j < 5; j = j + 1)
								B[j] <= B[j-1];
			end

			if (~phase0)
			begin
				if (~phase6) omega[0] <= omega[5] ^ tmp2;
				else omega[0] <= omega[5];
							for (j = 1; j < 6; j = j + 1)
								omega[j] <= omega[j-1];
			end

			if (~phase0)
			begin
				if (delta)	A[0] <= tmp3;
				else if (~phase6) A[0] <= A[4];
				else A[0] <= 0;
							for (j = 1; j < 5; j = j + 1)
								A[j] <= A[j-1];
			end

			if ((phase0 & delta) && (count != -1)) L <= count - L + 1;

			if (phase0)
				D <= tmp0 ^ tmp1 ^ tmp2 ^ tmp3 ^ tmp4 ^ tmp5;

		end
	end

endmodule


module rsdec_berl_multiply (y, a, b, c, d, e);
	input [7:0] a, b, c, d;
	input e;
	output [7:0] y;
	wire [7:0] y;
	reg [7:0] p, q;

	always @ (a or c or e)
		if (e) p = c;
		else p = a;
	always @ (b or d or e)
		if (e) q = d;
		else q = b;

	multiply x0 (y, p, q);

endmodule

module multiply (y, a, b);
	input [7:0] a, b;
	output [7:0] y;
	reg [7:0] y;
	always @ (a or b)
	begin
		y[0] = (a[0] & b[0]) ^ (a[1] & b[7]) ^ (a[2] & b[6]) ^ (a[2] & b[7]) ^ (a[3] & b[5]) ^ (a[3] & b[6]) ^ (a[3] & b[7]) ^ (a[4] & b[4]) ^ (a[4] & b[5]) ^ (a[4] & b[6]) ^ (a[4] & b[7]) ^ (a[5] & b[3]) ^ (a[5] & b[4]) ^ (a[5] & b[5]) ^ (a[5] & b[6]) ^ (a[5] & b[7]) ^ (a[6] & b[2]) ^ (a[6] & b[3]) ^ (a[6] & b[4]) ^ (a[6] & b[5]) ^ (a[6] & b[6]) ^ (a[6] & b[7]) ^ (a[7] & b[1]) ^ (a[7] & b[2]) ^ (a[7] & b[3]) ^ (a[7] & b[4]) ^ (a[7] & b[5]) ^ (a[7] & b[6]);
		y[1] = (a[0] & b[1]) ^ (a[1] & b[0]) ^ (a[1] & b[7]) ^ (a[2] & b[6]) ^ (a[3] & b[5]) ^ (a[4] & b[4]) ^ (a[5] & b[3]) ^ (a[6] & b[2]) ^ (a[7] & b[1]) ^ (a[7] & b[7]);
		y[2] = (a[0] & b[2]) ^ (a[1] & b[1]) ^ (a[1] & b[7]) ^ (a[2] & b[0]) ^ (a[2] & b[6]) ^ (a[3] & b[5]) ^ (a[3] & b[7]) ^ (a[4] & b[4]) ^ (a[4] & b[6]) ^ (a[4] & b[7]) ^ (a[5] & b[3]) ^ (a[5] & b[5]) ^ (a[5] & b[6]) ^ (a[5] & b[7]) ^ (a[6] & b[2]) ^ (a[6] & b[4]) ^ (a[6] & b[5]) ^ (a[6] & b[6]) ^ (a[6] & b[7]) ^ (a[7] & b[1]) ^ (a[7] & b[3]) ^ (a[7] & b[4]) ^ (a[7] & b[5]) ^ (a[7] & b[6]);
		y[3] = (a[0] & b[3]) ^ (a[1] & b[2]) ^ (a[2] & b[1]) ^ (a[2] & b[7]) ^ (a[3] & b[0]) ^ (a[3] & b[6]) ^ (a[4] & b[5]) ^ (a[4] & b[7]) ^ (a[5] & b[4]) ^ (a[5] & b[6]) ^ (a[5] & b[7]) ^ (a[6] & b[3]) ^ (a[6] & b[5]) ^ (a[6] & b[6]) ^ (a[6] & b[7]) ^ (a[7] & b[2]) ^ (a[7] & b[4]) ^ (a[7] & b[5]) ^ (a[7] & b[6]) ^ (a[7] & b[7]);
		y[4] = (a[0] & b[4]) ^ (a[1] & b[3]) ^ (a[2] & b[2]) ^ (a[3] & b[1]) ^ (a[3] & b[7]) ^ (a[4] & b[0]) ^ (a[4] & b[6]) ^ (a[5] & b[5]) ^ (a[5] & b[7]) ^ (a[6] & b[4]) ^ (a[6] & b[6]) ^ (a[6] & b[7]) ^ (a[7] & b[3]) ^ (a[7] & b[5]) ^ (a[7] & b[6]) ^ (a[7] & b[7]);
		y[5] = (a[0] & b[5]) ^ (a[1] & b[4]) ^ (a[2] & b[3]) ^ (a[3] & b[2]) ^ (a[4] & b[1]) ^ (a[4] & b[7]) ^ (a[5] & b[0]) ^ (a[5] & b[6]) ^ (a[6] & b[5]) ^ (a[6] & b[7]) ^ (a[7] & b[4]) ^ (a[7] & b[6]) ^ (a[7] & b[7]);
		y[6] = (a[0] & b[6]) ^ (a[1] & b[5]) ^ (a[2] & b[4]) ^ (a[3] & b[3]) ^ (a[4] & b[2]) ^ (a[5] & b[1]) ^ (a[5] & b[7]) ^ (a[6] & b[0]) ^ (a[6] & b[6]) ^ (a[7] & b[5]) ^ (a[7] & b[7]);
		y[7] = (a[0] & b[7]) ^ (a[1] & b[6]) ^ (a[1] & b[7]) ^ (a[2] & b[5]) ^ (a[2] & b[6]) ^ (a[2] & b[7]) ^ (a[3] & b[4]) ^ (a[3] & b[5]) ^ (a[3] & b[6]) ^ (a[3] & b[7]) ^ (a[4] & b[3]) ^ (a[4] & b[4]) ^ (a[4] & b[5]) ^ (a[4] & b[6]) ^ (a[4] & b[7]) ^ (a[5] & b[2]) ^ (a[5] & b[3]) ^ (a[5] & b[4]) ^ (a[5] & b[5]) ^ (a[5] & b[6]) ^ (a[5] & b[7]) ^ (a[6] & b[1]) ^ (a[6] & b[2]) ^ (a[6] & b[3]) ^ (a[6] & b[4]) ^ (a[6] & b[5]) ^ (a[6] & b[6]) ^ (a[7] & b[0]) ^ (a[7] & b[1]) ^ (a[7] & b[2]) ^ (a[7] & b[3]) ^ (a[7] & b[4]) ^ (a[7] & b[5]);
	end
endmodule
