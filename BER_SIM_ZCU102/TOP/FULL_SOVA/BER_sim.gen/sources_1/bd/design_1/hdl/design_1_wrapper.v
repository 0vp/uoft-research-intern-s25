//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
//Date        : Thu Aug 21 22:52:51 2025
//Host        : quattro.eecg running 64-bit Debian GNU/Linux 12 (bookworm)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (uart2_pl_rxd,
    uart2_pl_txd);
  input uart2_pl_rxd;
  output uart2_pl_txd;

  wire uart2_pl_rxd;
  wire uart2_pl_txd;

  design_1 design_1_i
       (.uart2_pl_rxd(uart2_pl_rxd),
        .uart2_pl_txd(uart2_pl_txd));
endmodule
