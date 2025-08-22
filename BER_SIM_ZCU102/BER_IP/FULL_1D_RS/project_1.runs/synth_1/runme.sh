#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/ids_lite/ISE/bin/lin64:/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/bin
else
  PATH=/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/ids_lite/ISE/bin/lin64:/CMC/tools/xilinx/Vivado_2022.2/Vivado/2022.2/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=
else
  LD_LIBRARY_PATH=:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/autofs/fs1.ece/fs1.eecg.tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_1D_RS/project_1.runs/synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log parallel_ber_top.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source parallel_ber_top.tcl
