vlib work
vlib activehdl

vlib activehdl/xilinx_vip
vlib activehdl/xpm
vlib activehdl/axi_bram_ctrl_v4_1_7
vlib activehdl/xil_defaultlib
vlib activehdl/blk_mem_gen_v8_4_5
vlib activehdl/axi_lite_ipif_v3_0_4
vlib activehdl/lib_pkg_v1_0_2
vlib activehdl/lib_srl_fifo_v1_0_2
vlib activehdl/lib_cdc_v1_0_2
vlib activehdl/axi_uartlite_v2_0_31
vlib activehdl/axi_infrastructure_v1_1_0
vlib activehdl/axi_vip_v1_1_13
vlib activehdl/zynq_ultra_ps_e_vip_v1_0_13
vlib activehdl/xlconstant_v1_1_7
vlib activehdl/proc_sys_reset_v5_0_13
vlib activehdl/smartconnect_v1_0
vlib activehdl/axi_register_slice_v2_1_27

vmap xilinx_vip activehdl/xilinx_vip
vmap xpm activehdl/xpm
vmap axi_bram_ctrl_v4_1_7 activehdl/axi_bram_ctrl_v4_1_7
vmap xil_defaultlib activehdl/xil_defaultlib
vmap blk_mem_gen_v8_4_5 activehdl/blk_mem_gen_v8_4_5
vmap axi_lite_ipif_v3_0_4 activehdl/axi_lite_ipif_v3_0_4
vmap lib_pkg_v1_0_2 activehdl/lib_pkg_v1_0_2
vmap lib_srl_fifo_v1_0_2 activehdl/lib_srl_fifo_v1_0_2
vmap lib_cdc_v1_0_2 activehdl/lib_cdc_v1_0_2
vmap axi_uartlite_v2_0_31 activehdl/axi_uartlite_v2_0_31
vmap axi_infrastructure_v1_1_0 activehdl/axi_infrastructure_v1_1_0
vmap axi_vip_v1_1_13 activehdl/axi_vip_v1_1_13
vmap zynq_ultra_ps_e_vip_v1_0_13 activehdl/zynq_ultra_ps_e_vip_v1_0_13
vmap xlconstant_v1_1_7 activehdl/xlconstant_v1_1_7
vmap proc_sys_reset_v5_0_13 activehdl/proc_sys_reset_v5_0_13
vmap smartconnect_v1_0 activehdl/smartconnect_v1_0
vmap axi_register_slice_v2_1_27 activehdl/axi_register_slice_v2_1_27

vlog -work xilinx_vip  -sv2k12 "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  \
"/autofs/fs1.ece/fs1.vrg.CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work axi_bram_ctrl_v4_1_7 -93  \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f80b/hdl/axi_bram_ctrl_v4_1_rfs.vhd" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ip/design_1_axi_bram_ctrl_0_0/sim/design_1_axi_bram_ctrl_0_0.vhd" \

vlog -work blk_mem_gen_v8_4_5  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/25a8/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_bram_ctrl_0_bram_0/sim/design_1_axi_bram_ctrl_0_bram_0.v" \

vcom -work axi_lite_ipif_v3_0_4 -93  \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66ea/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd" \

vcom -work lib_pkg_v1_0_2 -93  \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/0513/hdl/lib_pkg_v1_0_rfs.vhd" \

vcom -work lib_srl_fifo_v1_0_2 -93  \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/51ce/hdl/lib_srl_fifo_v1_0_rfs.vhd" \

vcom -work lib_cdc_v1_0_2 -93  \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work axi_uartlite_v2_0_31 -93  \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/67a1/hdl/axi_uartlite_v2_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ip/design_1_axi_uartlite_0_0/sim/design_1_axi_uartlite_0_0.vhd" \

vlog -work axi_infrastructure_v1_1_0  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_vip_v1_1_13  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ffc2/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work zynq_ultra_ps_e_vip_v1_0_13  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl/zynq_ultra_ps_e_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_zynq_ultra_ps_e_0_0/sim/design_1_zynq_ultra_ps_e_0_0_vip_wrapper.v" \

vlog -work xlconstant_v1_1_7  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/badb/hdl/xlconstant_v1_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_0/sim/bd_afc3_one_0.v" \

vcom -work proc_sys_reset_v5_0_13 -93  \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_1/sim/bd_afc3_psr_aclk_0.vhd" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/sc_util_v1_0_vl_rfs.sv" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/c012/hdl/sc_switchboard_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_2/sim/bd_afc3_arsw_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_3/sim/bd_afc3_rsw_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_4/sim/bd_afc3_awsw_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_5/sim/bd_afc3_wsw_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_6/sim/bd_afc3_bsw_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/be1f/hdl/sc_mmu_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_7/sim/bd_afc3_s00mmu_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/4fd2/hdl/sc_transaction_regulator_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_8/sim/bd_afc3_s00tr_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/637d/hdl/sc_si_converter_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_9/sim/bd_afc3_s00sic_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f38e/hdl/sc_axi2sc_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_10/sim/bd_afc3_s00a2s_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/sc_node_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_11/sim/bd_afc3_sarn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_12/sim/bd_afc3_srn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_13/sim/bd_afc3_sawn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_14/sim/bd_afc3_swn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_15/sim/bd_afc3_sbn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_16/sim/bd_afc3_s01mmu_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_17/sim/bd_afc3_s01tr_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_18/sim/bd_afc3_s01sic_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_19/sim/bd_afc3_s01a2s_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_20/sim/bd_afc3_sarn_1.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_21/sim/bd_afc3_srn_1.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_22/sim/bd_afc3_sawn_1.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_23/sim/bd_afc3_swn_1.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_24/sim/bd_afc3_sbn_1.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/9cc5/hdl/sc_sc2axi_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_25/sim/bd_afc3_m00s2a_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_26/sim/bd_afc3_m00arn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_27/sim/bd_afc3_m00rn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_28/sim/bd_afc3_m00awn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_29/sim/bd_afc3_m00wn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_30/sim/bd_afc3_m00bn_0.sv" \

vlog -work smartconnect_v1_0  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/6bba/hdl/sc_exit_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_31/sim/bd_afc3_m00e_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_32/sim/bd_afc3_m01s2a_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_33/sim/bd_afc3_m01arn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_34/sim/bd_afc3_m01rn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_35/sim/bd_afc3_m01awn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_36/sim/bd_afc3_m01wn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_37/sim/bd_afc3_m01bn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_38/sim/bd_afc3_m01e_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_39/sim/bd_afc3_m02s2a_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_40/sim/bd_afc3_m02arn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_41/sim/bd_afc3_m02rn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_42/sim/bd_afc3_m02awn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_43/sim/bd_afc3_m02wn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_44/sim/bd_afc3_m02bn_0.sv" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/ip/ip_45/sim/bd_afc3_m02e_0.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/bd_0/sim/bd_afc3.v" \

vlog -work axi_register_slice_v2_1_27  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b4/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ip/design_1_axi_smc_0/sim/design_1_axi_smc_0.v" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ip/design_1_rst_ps8_0_99M_0/sim/design_1_rst_ps8_0_99M_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ipshared/6285/code/grey_code.v" \
"../../../bd/design_1/ipshared/6285/code/precode.v" \

vlog -work xil_defaultlib  -sv2k12 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ipshared/6285/code/channel_model.sv" \
"../../../bd/design_1/ipshared/6285/code/convolutional_interleaver.sv" \
"../../../bd/design_1/ipshared/6285/code/epf_channel.sv" \
"../../../bd/design_1/ipshared/6285/code/hamming_68_60.sv" \
"../../../bd/design_1/ipshared/6285/code/noise.sv" \
"../../../bd/design_1/ipshared/6285/code/prbs.sv" \
"../../../bd/design_1/ipshared/6285/code/slicer.sv" \
"../../../bd/design_1/ipshared/6285/code/sova.sv" \
"../../../bd/design_1/ipshared/6285/code/sova_modules.sv" \
"../../../bd/design_1/ipshared/6285/code/ber_top.sv" \
"../../../bd/design_1/ip/design_1_parallel_ber_top_0_7/sim/design_1_parallel_ber_top_0_7.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/abef/hdl" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/f0b6/hdl/verilog" "+incdir+../../../../BER_sim.gen/sources_1/bd/design_1/ipshared/66be/hdl/verilog" "+incdir+/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/data/xilinx_vip/include" \
"../../../bd/design_1/ipshared/75ed/hdl/sim_controller_v1_0_M00_AXI.v" \
"../../../bd/design_1/ipshared/75ed/hdl/sim_controller_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/75ed/hdl/sim_controller_v1_0.v" \
"../../../bd/design_1/ip/design_1_sim_controller_0_0/sim/design_1_sim_controller_0_0.v" \
"../../../bd/design_1/sim/design_1.v" \

vlog -work xil_defaultlib \
"glbl.v"

