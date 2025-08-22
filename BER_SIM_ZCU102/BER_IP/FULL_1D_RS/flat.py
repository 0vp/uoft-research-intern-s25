paths = [
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/ber_top_og.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/ber_top.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/gf_arithmetic.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/rs_1d_tb.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/rs_1d.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/rs_bit_symbol_converters.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/rs_decoder.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/rs_encoder.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/rs_gf_luts.vh",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/rs_tables.sv",
    "/fs1/eecg/tcc/liqasim1/Desktop/projects/s25-uoft-ri-fpga/BER_SIM_ZCU102/BER_IP/FULL_2D_RS/code/hamming_68_60.sv",
]

# go through each path, get the file name and contents, save it all to the 'flat.txt' file
with open('flat.txt', 'w') as flat_file:
    for path in paths:
        with open(path, 'r') as file:
            contents = file.read()
            # Extract the filename from the path
            filename = path.split('/')[-1]
            # Write the filename and contents to the flat file
            flat_file.write(f"File: {filename}\n")
            flat_file.write(contents + "\n\n")
            flat_file.write("---\n\n")