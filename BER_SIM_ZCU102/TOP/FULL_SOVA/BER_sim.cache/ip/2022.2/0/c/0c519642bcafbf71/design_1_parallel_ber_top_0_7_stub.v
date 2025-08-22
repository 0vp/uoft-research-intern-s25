// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Thu Aug 14 16:36:59 2025
// Host        : quattro.eecg running 64-bit Debian GNU/Linux 12 (bookworm)
// Command     : write_verilog -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ design_1_parallel_ber_top_0_7_stub.v
// Design      : design_1_parallel_ber_top_0_7
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu9eg-ffvb1156-2-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "parallel_ber_top,Vivado 2022.2" *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix(clk, en, rstn, precode_en, probability_in, 
  probability_idx, total_bits, total_bit_errors_pre, total_bit_errors_post, total_frames, 
  total_frame_errors)
/* synthesis syn_black_box black_box_pad_pin="clk,en,rstn,precode_en,probability_in[63:0],probability_idx[31:0],total_bits[63:0],total_bit_errors_pre[63:0],total_bit_errors_post[63:0],total_frames[63:0],total_frame_errors[63:0]" */;
  input clk;
  input en;
  input rstn;
  input precode_en;
  input [63:0]probability_in;
  input [31:0]probability_idx;
  output [63:0]total_bits;
  output [63:0]total_bit_errors_pre;
  output [63:0]total_bit_errors_post;
  output [63:0]total_frames;
  output [63:0]total_frame_errors;
endmodule
