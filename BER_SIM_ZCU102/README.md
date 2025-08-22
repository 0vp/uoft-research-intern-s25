# BER Simulation System for ZCU102

A comprehensive FPGA based, bit error rate (BER) simulation framework for Reed-Solomon forward error correction codes on the Xilinx ZCU102 evaluation board.

## System Architecture

**FPGA Hardware Components:**
- Controller IP: configuration and control logic
- BER_IP: Reed-Solomon decoder (1D or 2D modes)
- BRAM: Results and statistics storage

**ARM Processing System:**
- Linux OS
- BER test software (ber_test.c)
- Python analysis scripts

## Data Path Flow

```
PRBS Data -> Grey Encode -> Precode TX -> EPF Channel 1 -> Precode RX -> Grey Decode
    |
Reed-Solomon Encoder -> [Convolutional Interleaver - DISABLED] -> Grey Encode
    |
ISI Channel -> Random Noise Addition -> SOVA Equalizer -> PAM4 to Binary
    |
[Convolutional Deinterleaver - DISABLED] -> Reed-Solomon Decoder -> Grey Encode
    |
Precode TX -> EPF Channel 3 -> Precode RX -> Grey Decode -> Error Counting -> BRAM Storage
```

**Note**: The convolutional interleaver/deinterleaver is currently disabled in this implementation.

## Project Structure

```
BER_SIM_ZCU102/
├── BER_IP/
│   ├── FULL_1D_RS/         # 1D Reed-Solomon implementation
│   └── FULL_2D_RS/         # 2D Reed-Solomon implementation
├── CONTROLLER_IP/          # Simulation controller
├── TOP/FULL_SOVA/          # Top-level Vivado project (what you should compile)
└── sw/                     # Software components
    ├── ber_test.c          # Main test application
    ├── parse.py            # Results analysis
    ├── plot.py             # Visualization
    └── build.sh            # Build script
```

## Hardware Design

### BER_IP Implementation

**1D Reed-Solomon (FULL_1D_RS)**
- Location: `BER_IP/FULL_1D_RS/code/ber_top.sv`
- Features: Single-pass decoding, RS(15,11), 4 parity symbols - drop in replacement using ../gen_rs_sv
- Performance: Standard Reed-Solomon correction capability

**2D Reed-Solomon (FULL_2D_RS)**  
- Location: `BER_IP/FULL_2D_RS/code/ber_top.sv`
- Features: Iterative row-column decoding, enhanced burst error correction
- Performance: 1-3 dB coding gain improvement over 1D
- Note: Single decoder/encoder instance with handoff mechanism (see TODO for parallel implementation)

### Controller Configuration

**Critical Setup** - Edit this file before building:
`CONTROLLER_IP/ip_repo/sim_controller_1.0/hdl/sim_controller_v1_0.v`

**Line 133 Configuration:**
```verilog
// For 1D Mode - COMMENT OUT:
// .MAX_ITERATIONS_2D(max_iterations_2d),

// For 2D Mode - UNCOMMENT:
.MAX_ITERATIONS_2D(max_iterations_2d),
```

## Software Components

### ber_test.c - Main Application

**Memory Mapping:**
- BRAM Base: 0xA0000000 (BER statistics)
- UART Base: 0xA0010000 (Communication)
- Controller: 0xA0020000 (Simulation control)

**BRAM Layout:**
- 0x00-0x07: total_bits (64-bit)
- 0x08-0x0F: total_bit_errors_pre (64-bit)  
- 0x10-0x17: total_bit_errors_post (64-bit)
- 0x18-0x1F: total_frames (64-bit)
- 0x20-0x27: total_frame_errors (64-bit)

### Python Scripts

**parse.py**: Results analysis and statistics
**plot.py**: BER performance visualization  
**build.sh**: Automated compilation

## Build Process

### 1. Vivado Compilation

```bash
cd BER_SIM_ZCU102/TOP/FULL_SOVA/
vivado BER_sim.xpr
```

**Build Steps:**
1. Configure Controller IP (edit line 133 for 1D/2D mode)
2. Run Synthesis
3. Run Implementation
4. Generate Bitstream
5. Export Hardware with bitstream -> .xsa file

### 2. PetaLinux Project

**Create Project:**
```bash
cd ~/projects
petalinux-create -t project -n ber_sim_project -s xilinx-zcu102-v2022.2-10141622.bsp
cd ber_sim_project
```

**Build System:**
```bash
# Import hardware
petalinux-config --get-hw-description=../path/to/design.xsa

# Build project  
petalinux-build

# Package boot image
petalinux-package --boot --fsbl images/linux/zynqmp_fsbl.elf \
                  --fpga images/linux/system.bit \
                  --u-boot images/linux/u-boot.elf --force
```

## FPGA Deployment

### Hardware Configuration with xlnx-config

**1. Create Configuration Profiles:**
```bash
# On ZCU102
sudo mkdir -p /boot/firmware/xlnx-config/test_pac/hwconfig/<config_name>/zcu102/
```

**2. Copy Hardware Files:**
```bash
# Copy bitstream and device tree
sudo cp system.bit system.dtb /boot/firmware/xlnx-config/test_pac/hwconfig/<config_name>/zcu102/
```

**3. Activate Configuration:**
```bash
# View available configurations
sudo xlnx-config -q

# Deactivate current (if any)
sudo xlnx-config --deactivate

# Activate desired mode
sudo xlnx-config --activate <config_name>

# Reboot to load configuration
sudo reboot
```

## Running BER Tests

### 1. Software Setup

```bash
# Build on target
cd /home/root/ber_sim/sw/
sudo ./build.sh
```

### 2. Execute Tests

**Basic Usage:**
```bash
sudo ./ber_test

# for 2D, MAX_ITERATIONS can be set with -i <iterations>
sudo ./ber_test -i <iterations>
```

### 3. Analysis

```bash
# Parse results
python3 parse.py results.log

# Generate plots
python3 plot.py
```

## Future Improvements / TODO
1. Convolutional Interleaver/Deinterleaver is disabled in this implementation, add it back and see if it improves the BER performance.
1. 2D encoder/decoder is not optimized for speed, but for implementation simplicity. Optimize it perhaps with multiple instances of the 2D encoder/decoder and pipelining.
1. Known bug that the RS encoder/decoders are block based, while the FPPGA-FEC is streaming bits, therefore there is sometimes a deadlock that can occur, the current fix is just soft resetting with a new seed set with LFSR every `n` frames (programmed in ber_top.sv via `FRAMES_BEFORE_RESET`).