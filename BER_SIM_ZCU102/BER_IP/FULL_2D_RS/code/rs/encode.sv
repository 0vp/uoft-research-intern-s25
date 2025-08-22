// -------------------------------------------------------------------------
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

module rs_enc_m0 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[0] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
		y[1] = x[0] ^ x[1] ^ x[2] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
		y[2] = x[0] ^ x[1] ^ x[6];
		y[3] = x[0] ^ x[1] ^ x[2] ^ x[7];
		y[4] = x[0] ^ x[1] ^ x[2] ^ x[3];
		y[5] = x[1] ^ x[2] ^ x[3] ^ x[4];
		y[6] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5];
		y[7] = x[1] ^ x[2] ^ x[4] ^ x[6] ^ x[7];
	end
endmodule
module rs_enc_m1 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[1] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
		y[1] = x[1] ^ x[2] ^ x[3] ^ x[6] ^ x[7];
		y[2] = x[0] ^ x[1] ^ x[2] ^ x[5];
		y[3] = x[1] ^ x[2] ^ x[3] ^ x[6];
		y[4] = x[2] ^ x[3] ^ x[4] ^ x[7];
		y[5] = x[0] ^ x[3] ^ x[4] ^ x[5];
		y[6] = x[0] ^ x[1] ^ x[4] ^ x[5] ^ x[6];
		y[7] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[6];
	end
endmodule
module rs_enc_m2 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[0] ^ x[1] ^ x[2] ^ x[6] ^ x[7];
		y[1] = x[0] ^ x[3] ^ x[6];
		y[2] = x[0] ^ x[2] ^ x[4] ^ x[6];
		y[3] = x[1] ^ x[3] ^ x[5] ^ x[7];
		y[4] = x[2] ^ x[4] ^ x[6];
		y[5] = x[0] ^ x[3] ^ x[5] ^ x[7];
		y[6] = x[1] ^ x[4] ^ x[6];
		y[7] = x[0] ^ x[1] ^ x[5] ^ x[6];
	end
endmodule
module rs_enc_m3 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[3] ^ x[4] ^ x[5] ^ x[6];
		y[1] = x[0] ^ x[3] ^ x[7];
		y[2] = x[1] ^ x[3] ^ x[5] ^ x[6];
		y[3] = x[2] ^ x[4] ^ x[6] ^ x[7];
		y[4] = x[3] ^ x[5] ^ x[7];
		y[5] = x[0] ^ x[4] ^ x[6];
		y[6] = x[1] ^ x[5] ^ x[7];
		y[7] = x[2] ^ x[3] ^ x[4] ^ x[5];
	end
endmodule
module rs_enc_m4 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[1] ^ x[2] ^ x[7];
		y[1] = x[1] ^ x[3] ^ x[7];
		y[2] = x[1] ^ x[4] ^ x[7];
		y[3] = x[2] ^ x[5];
		y[4] = x[3] ^ x[6];
		y[5] = x[0] ^ x[4] ^ x[7];
		y[6] = x[1] ^ x[5];
		y[7] = x[0] ^ x[1] ^ x[6] ^ x[7];
	end
endmodule
module rs_enc_m5 (y, x);
	input [7:0] x;
	output [7:0] y;
	reg [7:0] y;
	always @ (x)
	begin
		y[0] = x[2] ^ x[4] ^ x[6];
		y[1] = x[0] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
		y[2] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[5] ^ x[7];
		y[3] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[6];
		y[4] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[7];
		y[5] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6];
		y[6] = x[0] ^ x[1] ^ x[2] ^ x[3] ^ x[4] ^ x[5] ^ x[6] ^ x[7];
		y[7] = x[1] ^ x[3] ^ x[5] ^ x[7];
	end
endmodule

module rs_enc (y, x, enable, data, clk, clrn);
	input [7:0] x;
	input clk, clrn, enable, data;
	output [7:0] y;
	reg [7:0] y;

	wire [7:0] scale0;
	wire [7:0] scale1;
	wire [7:0] scale2;
	wire [7:0] scale3;
	wire [7:0] scale4;
	wire [7:0] scale5;
	reg [7:0] mem0;
	reg [7:0] mem1;
	reg [7:0] mem2;
	reg [7:0] mem3;
	reg [7:0] mem4;
	reg [7:0] mem5;
	reg [7:0] feedback;

	rs_enc_m0 m0 (scale0, feedback);
	rs_enc_m1 m1 (scale1, feedback);
	rs_enc_m2 m2 (scale2, feedback);
	rs_enc_m3 m3 (scale3, feedback);
	rs_enc_m4 m4 (scale4, feedback);
	rs_enc_m5 m5 (scale5, feedback);

	always @ (posedge clk or negedge clrn)
	begin
		if (~clrn)
		begin
			mem0 <= 0;
			mem1 <= 0;
			mem2 <= 0;
			mem3 <= 0;
			mem4 <= 0;
			mem5 <= 0;
		end
		else if (enable)
		begin
			mem5 <= mem4 ^ scale5;
			mem4 <= mem3 ^ scale4;
			mem3 <= mem2 ^ scale3;
			mem2 <= mem1 ^ scale2;
			mem1 <= mem0 ^ scale1;
			mem0 <= scale0;
		end
	end

	always @ (data or x or mem5)
		if (data) feedback = x ^ mem5;
		else feedback = 0;

	always @ (data or x or mem5)
		if (data) y = x;
		else y = mem5;

endmodule