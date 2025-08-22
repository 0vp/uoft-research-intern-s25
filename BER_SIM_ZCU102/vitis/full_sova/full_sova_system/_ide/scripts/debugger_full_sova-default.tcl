# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\Users\richa\Desktop\vitis_ZCU102\full_sova\full_sova_system\_ide\scripts\debugger_full_sova-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\Users\richa\Desktop\vitis_ZCU102\full_sova\full_sova_system\_ide\scripts\debugger_full_sova-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-SMT2NC 210308A46BE7" && level==0 && jtag_device_ctx=="jsn-JTAG-SMT2NC-210308A46BE7-24738093-0"}
fpga -file C:/Users/richa/Desktop/vitis_ZCU102/full_sova/full_sova/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw C:/Users/richa/Desktop/vitis_ZCU102/full_sova/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow C:/Users/richa/Desktop/vitis_ZCU102/full_sova/full_sova/Debug/full_sova.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
