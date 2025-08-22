# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\richa\Desktop\vitis_ZCU102\full_sova\design_1_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\richa\Desktop\vitis_ZCU102\full_sova\design_1_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {design_1_wrapper}\
-hw {Z:\Documents\Thesis\new_board\TOP\FULL_SOVA\design_1_wrapper.xsa}\
-fsbl-target {psu_cortexa53_0} -out {C:/Users/richa/Desktop/vitis_ZCU102/full_sova}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {64-bit} -support-app {hello_world}
platform generate -domains 
platform active {design_1_wrapper}
platform generate -quick
platform generate
platform config -updatehw {C:/Users/richa/Desktop/vitis_ZCU102/full_sova/full_700M.xsa}
platform generate -domains 
platform generate
platform active {design_1_wrapper}
platform config -updatehw {Z:/Documents/Thesis/new_board/TOP/FULL_SOVA/design_1_wrapper.xsa}
platform generate -domains 
platform config -updatehw {Z:/Documents/Thesis/new_board/TOP/FULL_SOVA/design_1_wrapper.xsa}
platform generate -domains 
platform config -updatehw {Z:/Documents/Thesis/new_board/TOP/FULL_SOVA/design_1_wrapper.xsa}
platform generate -domains 
platform active {design_1_wrapper}
platform generate
platform config -updatehw {Z:/Documents/Thesis/new_board/TOP/FULL_SOVA/design_1_wrapper.xsa}
platform generate -domains 
platform config -updatehw {Z:/Documents/Thesis/new_board/TOP/FULL_SOVA/design_1_wrapper.xsa}
platform generate -domains 
