# Reed-Solomon SystemVerilog Code Generator

A comprehensive tool for generating mathematically correct Reed-Solomon error correction codes in SystemVerilog, supporting both 1D and 2D implementations with exact reference structure matching.

## Quick Start

### Using Shell Scripts (Recommended)

Generate 1D Reed-Solomon codes:
```bash
# Default RS(200, 168) code
./generate.sh

# Custom RS(N, K) code
./generate.sh 255 223 output_dir

# Standard telecommunications code
./generate.sh 204 188 gen_dvb
```

Generate 2D Reed-Solomon codes:
```bash
# Default 2D RS(15, 11) code
./generate_2d.sh

# Custom 2D RS(N, K) code
./generate_2d.sh 31 27 gen_2d_custom

# Large 2D implementation
./generate_2d.sh 63 55 gen_2d_large
```

### Using Python Scripts Directly

If shell scripts are not supported on your platform:

```bash
# 1D Reed-Solomon generation
python3 src/generate_rs_1d.py --n 200 --k 168 --output gen/
python3 src/generate_rs_1d.py --n 255 --k 223 --output gen_255_223/

# 2D Reed-Solomon generation  
python3 src/generate_rs_2d.py --n 15 --k 11 --output gen_2d/
python3 src/generate_rs_2d.py --n 31 --k 27 --output gen_2d_custom/
```

## Parameters

### Reed-Solomon Code Parameters

- **N**: Codeword length (total symbols including data + parity)
- **K**: Data symbols (information symbols)
- **N-K**: Parity symbols (redundancy for error correction)
- **t = (N-K)/2**: Error correction capability (correctable symbol errors)

### Parameter Constraints

- Must satisfy: `2 <= K < N <= 255` for GF(2^8)
- Parity symbols `N-K` should be even for optimal error correction
- Common telecommunications codes: RS(204,188), RS(255,223), RS(200,168)
- 2D codes use the same N,K per dimension: RS(N,K) × RS(N,K)

### Output Directory

- Shell scripts: Third parameter (default: `gen/` for 1D, `gen_2d/` for 2D)
- Python scripts: `--output` flag (default: current directory)

## Reed-Solomon Theory

### Error Correction Fundamentals

Reed-Solomon codes are non-binary cyclic codes that operate over Galois Fields GF(2^m). This implementation uses GF(2^8) = GF(256), allowing processing of 8-bit symbols (bytes).

**Key Properties:**
- **Minimum Distance**: d = N - K + 1
- **Error Correction**: Can correct up to t = ⌊(N-K)/2⌋ symbol errors
- **Error Detection**: Can detect up to N-K symbol errors
- **Erasure Correction**: Can correct up to N-K known erasures

### Galois Field GF(2^8)

Operations performed using:
- **Primitive Polynomial**: x^8 + x^7 + x^2 + x + 1 (0x187)
- **Generator Element**: α (alpha), primitive element of the field
- **Arithmetic**: Addition is XOR, multiplication uses log/antilog tables

### Encoding Process

1. **Generator Polynomial**: g(x) = ∏(x - α^i) for i = 1 to N-K
2. **Systematic Encoding**: Append parity symbols to information symbols
3. **Parity Calculation**: R(x) = x^(N-K) × I(x) mod g(x)

### Decoding Process

1. **Syndrome Calculation**: S_i = r(α^i) for i = 1 to N-K
2. **Error Locator Polynomial**: Find Λ(x) using Berlekamp-Massey algorithm
3. **Error Location**: Use Chien search to find roots of Λ(x)
4. **Error Correction**: Compute error values and correct received symbols

### 2D Reed-Solomon

2D implementation applies RS encoding/decoding in both row and column directions:
- **Product Code**: RS(N,K) × RS(N,K) 
- **Iterative Decoding**: Alternate between row and column corrections
- **Enhanced Correction**: Can handle burst errors and improve overall performance

## Directory Structure

```
gen_rs_sv/
├── README.md                   # This documentation
├── generate.sh                 # 1D RS generator shell script
├── generate_2d.sh              # 2D RS generator shell script
├── src/                        # Python source files
│   ├── generate_rs_1d.py       # 1D RS code generator
│   ├── generate_rs_2d.py       # 2D RS code generator
│   └── gf256.py                # Galois Field GF(2^8) operations
├── ref_1d/                     # Reference 1D RS(200,168) implementation
│   ├── encode.sv               # Reference encoder modules
│   ├── syndrome.sv             # Reference syndrome computation
│   ├── berlekamp.sv            # Reference Berlekamp-Massey
│   ├── chien-search.sv         # Reference Chien search
│   ├── decode.sv               # Reference decoder module
│   ├── rs_encode_wrapper.sv    # Reference encoder wrapper
│   ├── rs_decode_wrapper.sv    # Reference decoder wrapper
│   ├── inverse.sv              # GF(256) inverse lookup
│   ├── data-rom.sv             # Test data source
│   └── rs_1d_serdes_tb.sv      # Reference testbench
└── ref_2d/                     # Reference 2D RS(15,11) implementation
    ├── rs_2d_encode.sv         # 2D encoder top-level
    ├── rs_2d_decode.sv         # 2D decoder top-level
    ├── serial_to_parallel.sv   # Data conversion utilities
    ├── parallel_to_serial.sv   # Data conversion utilities
    ├── counter.sv              # Control logic
    ├── rs_2d_serdes_tb.sv      # 2D testbench
    └── [other 1D modules]      # Shared 1D components
```

## Usage Examples

### Telecommunications Applications

```bash
# DVB-S satellite communication: RS(204, 188)
./generate.sh 204 188 gen_dvb_s

# DVB-T terrestrial: RS(255, 239) 
./generate.sh 255 239 gen_dvb_t

# WiMAX: RS(255, 223)
./generate.sh 255 223 gen_wimax
```

### Storage Applications

```bash
# CD-ROM: RS(255, 251)  
./generate.sh 255 251 gen_cdrom

# Blu-ray outer code: RS(248, 216)
./generate.sh 248 216 gen_bluray_outer
```

### High-Reliability 2D Codes

```bash
# NASA deep space: Strong 2D code
./generate_2d.sh 63 51 gen_nasa_ds

# Military/aerospace: High redundancy
./generate_2d.sh 31 15 gen_mil_aero
```

## Troubleshooting

### Common Issues

1. **Permission Denied**: Make shell scripts executable
   ```bash
   chmod +x generate.sh generate_2d.sh
   ```

2. **Python Module Not Found**: Ensure you're in the correct directory
   ```bash
   cd gen_rs_sv/
   python3 src/generate_rs_1d.py --help
   ```

3. **Invalid Parameters**: Check N > K and N <= 255
   ```bash
   # Invalid: K >= N
   ./generate.sh 168 200  # Error!
   
   # Invalid: N > 255  
   ./generate.sh 300 250  # Error!
   ```

4. **Output Directory Exists**: Shell scripts clean output directories automatically
   - For Python scripts, manually remove existing files if needed

### Verification

Generated modules can be verified by:
1. **Interface Inspection**: Check module ports match expected interfaces
2. **Synthesis Testing**: Verify modules synthesize without errors
3. **Simulation**: Use generated testbenches for functional verification
4. **Hardware Testing**: Compare with reference implementations in hardware

The generator ensures mathematical correctness and interface compatibility, making generated modules reliable drop-in replacements for Reed-Solomon applications.