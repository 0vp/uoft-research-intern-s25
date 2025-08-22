-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
-- Date        : Thu Aug 14 00:27:11 2025
-- Host        : quattro.eecg running 64-bit Debian GNU/Linux 12 (bookworm)
-- Command     : write_vhdl -force -mode synth_stub -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
--               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ design_1_parallel_ber_top_0_7_stub.vhdl
-- Design      : design_1_parallel_ber_top_0_7
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xczu9eg-ffvb1156-2-e
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
  Port ( 
    clk : in STD_LOGIC;
    en : in STD_LOGIC;
    rstn : in STD_LOGIC;
    precode_en : in STD_LOGIC;
    probability_in : in STD_LOGIC_VECTOR ( 63 downto 0 );
    probability_idx : in STD_LOGIC_VECTOR ( 31 downto 0 );
    total_bits : out STD_LOGIC_VECTOR ( 63 downto 0 );
    total_bit_errors_pre : out STD_LOGIC_VECTOR ( 63 downto 0 );
    total_bit_errors_post : out STD_LOGIC_VECTOR ( 63 downto 0 );
    total_frames : out STD_LOGIC_VECTOR ( 63 downto 0 );
    total_frame_errors : out STD_LOGIC_VECTOR ( 63 downto 0 )
  );

end decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix;

architecture stub of decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk,en,rstn,precode_en,probability_in[63:0],probability_idx[31:0],total_bits[63:0],total_bit_errors_pre[63:0],total_bit_errors_post[63:0],total_frames[63:0],total_frame_errors[63:0]";
attribute X_CORE_INFO : string;
attribute X_CORE_INFO of stub : architecture is "parallel_ber_top,Vivado 2022.2";
begin
end;
