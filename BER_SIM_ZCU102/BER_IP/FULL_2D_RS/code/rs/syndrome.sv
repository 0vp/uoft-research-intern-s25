// -------------------------------------------------------------------------
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

module rsdec_syn_m0 (y, x);
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
module rsdec_syn_m1 (y, x);
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
module rsdec_syn_m2 (y, x);
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
module rsdec_syn_m3 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[4] ^ x[5] ^ x[6] ^ x[7];
		y[1] = x[4];
		y[2] = x[4] ^ x[6] ^ x[7];
		y[3] = x[5] ^ x[7];
		y[4] = x[0] ^ x[6];
		y[5] = x[1] ^ x[7];
		y[6] = x[2];
		y[7] = x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
	end
endmodule
module rsdec_syn_m4 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
		y[1] = x[3];
		y[2] = x[3] ^ x[5] ^ x[6] ^ x[7];
		y[3] = x[4] ^ x[6] ^ x[7];
		y[4] = x[5] ^ x[7];
		y[5] = x[0] ^ x[6];
		y[6] = x[1] ^ x[7];
		y[7] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
	end
endmodule
module rsdec_syn_m5 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
		y[1] = x[2];
		y[2] = x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
		y[3] = x[3] ^ x[5] ^ x[6] ^ x[7];
		y[4] = x[4] ^ x[6] ^ x[7];
		y[5] = x[5] ^ x[7];
		y[6] = x[0] ^ x[6];
		y[7] = x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
	end
endmodule

module rsdec_syn (y0, y1, y2, y3, y4, y5, u, enable, shift, init, clk, clrn);
	input [7:0] u;
	input clk, clrn, shift, init, enable;
	output [7:0] y0;
	output [7:0] y1;
	output [7:0] y2;
	output [7:0] y3;
	output [7:0] y4;
	output [7:0] y5;
	reg [7:0] y0;
	reg [7:0] y1;
	reg [7:0] y2;
	reg [7:0] y3;
	reg [7:0] y4;
	reg [7:0] y5;

	wire [7:0] scale0;
	wire [7:0] scale1;
	wire [7:0] scale2;
	wire [7:0] scale3;
	wire [7:0] scale4;
	wire [7:0] scale5;

	rsdec_syn_m0 m0 (scale0, y0);
	rsdec_syn_m1 m1 (scale1, y1);
	rsdec_syn_m2 m2 (scale2, y2);
	rsdec_syn_m3 m3 (scale3, y3);
	rsdec_syn_m4 m4 (scale4, y4);
	rsdec_syn_m5 m5 (scale5, y5);

	always @ (posedge clk or negedge clrn)
	begin
		if (~clrn)
		begin
			y0 <= 0;
			y1 <= 0;
			y2 <= 0;
			y3 <= 0;
			y4 <= 0;
			y5 <= 0;
		end
		else if (init)
		begin
			y0 <= u;
			y1 <= u;
			y2 <= u;
			y3 <= u;
			y4 <= u;
			y5 <= u;
		end
		else if (enable)
		begin
			y0 <= scale0 ^ u;
			y1 <= scale1 ^ u;
			y2 <= scale2 ^ u;
			y3 <= scale3 ^ u;
			y4 <= scale4 ^ u;
			y5 <= scale5 ^ u;
		end
		else if (shift)
		begin
			y0 <= y1;
			y1 <= y2;
			y2 <= y3;
			y3 <= y4;
			y4 <= y5;
			y5 <= y0;
		end
	end
endmodule