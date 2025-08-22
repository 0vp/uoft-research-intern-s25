// -------------------------------------------------------------------------
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

module rsdec_chien_scale0 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;

	always @ (x)
	begin
		y[0] = x[0];
		y[1] = x[1];
		y[2] = x[2];
		y[3] = x[3];
		y[4] = x[4];
		y[5] = x[5];
		y[6] = x[6];
		y[7] = x[7];
	end
endmodule
module rsdec_chien_scale1 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;

	always @ (x)
	begin
		y[0] = x[7];
		y[1] = x[0] ^ x[7];
		y[2] = x[1] ^ x[7];
		y[3] = x[2];
		y[4] = x[3];
		y[5] = x[4];
		y[6] = x[5];
		y[7] = x[6] ^ x[7];
	end
endmodule
module rsdec_chien_scale2 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;

	always @ (x)
	begin
		y[0] = x[6] ^ x[7];
		y[1] = x[6];
		y[2] = x[0] ^ x[6];
		y[3] = x[1] ^ x[7];
		y[4] = x[2];
		y[5] = x[3];
		y[6] = x[4];
		y[7] = x[5] ^ x[6] ^ x[7];
	end
endmodule
module rsdec_chien_scale3 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;

	always @ (x)
	begin
		y[0] = x[5] ^ x[6] ^ x[7];
		y[1] = x[5];
		y[2] = x[5] ^ x[7];
		y[3] = x[0] ^ x[6];
		y[4] = x[1] ^ x[7];
		y[5] = x[2];
		y[6] = x[3];
		y[7] = x[4] ^ x[5] ^ x[6] ^ x[7];
	end
endmodule


module rsdec_chien (error, alpha, lambda, omega, even, D, search, load, shorten, clk, clrn);
	input clk, clrn, load, search, shorten;
	input [7:0] D;
	input [7:0] lambda;
	input [7:0] omega;
	output [7:0] even, error;
	output [7:0] alpha;
	reg [7:0] even, error;
	reg [7:0] alpha;

	wire [7:0] scale0;
	wire [7:0] scale1;
	wire [7:0] scale2;
	wire [7:0] scale3;
	wire [7:0] scale4;
	wire [7:0] scale5;
	wire [7:0] scale6;
	wire [7:0] scale7;
	reg [7:0] data0;
	reg [7:0] data1;
	reg [7:0] data2;
	reg [7:0] data3;
	reg [7:0] a0;
	reg [7:0] a1;
	reg [7:0] a2;
	reg [7:0] a3;
	reg [7:0] l0;
	reg [7:0] l1;
	reg [7:0] l2;
	reg [7:0] l3;
	reg [7:0] o0;
	reg [7:0] o1;
	reg [7:0] o2;
	reg [7:0] o3;
	reg [7:0] odd, numerator;
	wire [7:0] tmp;
	integer j;

	rsdec_chien_scale0 x0 (scale0, data0);
	rsdec_chien_scale1 x1 (scale1, data1);
	rsdec_chien_scale2 x2 (scale2, data2);
	rsdec_chien_scale3 x3 (scale3, data3);
	rsdec_chien_scale0 x4 (scale4, o0);
	rsdec_chien_scale1 x5 (scale5, o1);
	rsdec_chien_scale2 x6 (scale6, o2);
	rsdec_chien_scale3 x7 (scale7, o3);

	always @ (shorten or a0 or l0)
		if (shorten) data0 = a0;
		else data0 = l0;

	always @ (shorten or a1 or l1)
		if (shorten) data1 = a1;
		else data1 = l1;

	always @ (shorten or a2 or l2)
		if (shorten) data2 = a2;
		else data2 = l2;

	always @ (shorten or a3 or l3)
		if (shorten) data3 = a3;
		else data3 = l3;

	always @ (posedge clk or negedge clrn)
	begin
		if (~clrn)
		begin
			l0 <= 0;
			l1 <= 0;
			l2 <= 0;
			l3 <= 0;
			o0 <= 0;
			o1 <= 0;
			o2 <= 0;
			o3 <= 0;
			a0 <= 1;
			a1 <= 1;
			a2 <= 1;
			a3 <= 1;
		end
		else if (shorten)
		begin
			a0 <= scale0;
			a1 <= scale1;
			a2 <= scale2;
			a3 <= scale3;
		end
		else if (search)
		begin
			l0 <= scale0;
			l1 <= scale1;
			l2 <= scale2;
			l3 <= scale3;
			o0 <= scale4;
			o1 <= scale5;
			o2 <= scale6;
			o3 <= scale7;
		end
		else if (load)
		begin
			l0 <= lambda;
			l1 <= l0;
			l2 <= l1;
			l3 <= l2;
			o0 <= omega;
			o1 <= o0;
			o2 <= o1;
			o3 <= o2;
			a0 <= a3;
			a1 <= a0;
			a2 <= a1;
			a3 <= a2;
		end
	end

	always @ (l0 or l2)
		even = l0 ^ l2;

	always @ (l1 or l3)
		odd = l1 ^ l3;

	always @ (o0 or o1 or o2 or o3)
		numerator = o0 ^ o1 ^ o2 ^ o3;

	multiply m0 (tmp, numerator, D);

	always @ (even or odd or tmp)
		if (even == odd) error = tmp;
		else error = 0;

	always @ (a3) alpha = a3;

endmodule
