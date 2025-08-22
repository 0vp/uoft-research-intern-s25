# Reed-Solomon PAM Communication System

A comprehensive research framework implementing Reed-Solomon forward error correction with multi-level Pulse Amplitude Modulation (PAM) and adaptive equalization for digital communication systems. This system enables detailed performance analysis of coding and modulation schemes under realistic channel conditions.

## System Overview

This framework models a complete digital communication system chain:
- **Transmitter**: Symbol encoding, Reed-Solomon error correction, PAM modulation
- **Channel**: Additive white Gaussian noise (AWGN), inter-symbol interference (ISI)
- **Receiver**: Adaptive equalization, symbol detection, Reed-Solomon decoding
- **Analysis**: Comprehensive BER/SER vs SNR performance evaluation

## Entry Point: model.py

`model.py` is the primary entry point for individual system testing and experimentation. It provides a command-line interface to configure and run single transmission tests with full parameter control.

### Basic Usage

```bash
# Install dependencies first
pip install -r requirements.txt

# Basic 4-PAM test with Reed-Solomon RS(69,65)
python model.py --n 69 --k 65 --pam_levels 4 --snr_db 20.0

# 6-PAM with higher Reed-Solomon code RS(102,96)
python model.py --n 102 --k 96 --pam_levels 6 --snr_db 25.0 --data_size 1000

# 8-PAM with direct noise specification (bypasses SNR calculation)
python model.py --n 102 --k 96 --pam_levels 8 --sigma 0.1 --training_size 200

# Raw transmission (no Reed-Solomon correction)
python model.py --pam_levels 4 --snr_db 20.0 --raw

# Clean channel (no noise/ISI) for debugging
python model.py --pam_levels 4 --clean --data_size 64
```

### Key Parameters

- `--n, --k`: Reed-Solomon code parameters RS(n,k) where n-k = parity symbols
- `--mode`: Reed-Solomon decoding mode: `1D` or `2D` (default: 2D)
- `--pam_levels`: PAM constellation size (4, 6, or 8)
- `--snr_db`: Signal-to-noise ratio in dB
- `--sigma`: Direct noise standard deviation (alternative to SNR)
- `--data_size`: Number of symbols to transmit (default: 512)
- `--training_size`: LMS equalizer training symbols (default: 100)
- `--mu`: LMS step size for adaptive equalization (default: 0.000001)
- `--max_iterations`: Maximum Reed-Solomon 2D decoding iterations (default: 250)
- `--raw`: Disable Reed-Solomon correction (raw PAM transmission)
- `--clean`: Disable channel effects (perfect transmission)

## File Structure and Architecture

### Core System Components

#### `model.py` - Main Entry Point
**Classes**: `Transmitter`, `Receiver`, `Channel`

The heart of the communication system implementing the complete transmission chain:

- **Transmitter**: Handles data encoding, Reed-Solomon error correction, and PAM modulation
  - Supports both 1D and 2D Reed-Solomon modes
  - Configurable chunk-based encoding for realistic data flows
  - Original data preservation for error rate calculation

- **Channel**: Models realistic communication channel effects
  - AWGN noise with configurable SNR
  - ISI simulation
  - Peak power normalization across PAM levels

- **Receiver**: Implements reception, equalization, and decoding
  - Adaptive FFE/DFE equalization with LMS adaptation
  - Symbol decision making with optimal slicing
  - Reed-Solomon error correction with iterative 2D decoding

#### `pam.py` - PAM Modulation Engine
**Class**: `PAM`

Implements multi-level Pulse Amplitude Modulation:

```python
# 4-PAM: 2 bits/symbol, levels: [-48, -16, 16, 48]
pam4 = PAM(n=4, symbol_separation=48)

# 6-PAM: 2.5 bits/symbol, levels: [-48, -28.8, -9.6, 9.6, 28.8, 48]  
pam6 = PAM(n=6, symbol_separation=48)

# 8-PAM: 3 bits/symbol, levels: [-48, -34.3, -20.6, -6.9, 6.9, 20.6, 34.3, 48]
pam8 = PAM(n=8, symbol_separation=48)
```

**Power Normalization Theory**: All PAM levels use the same peak voltage (±symbol_separation) ensuring fair power comparison. The constellation points are uniformly spaced with Gray code mapping for optimal error resilience.

#### `equalizer.py` - Adaptive Equalization
**Classes**: `FFE`, `DFE`, `LMS`

Implements adaptive equalization to combat inter-symbol interference:

- **FFE (Feed-Forward Equalizer)**: Pre-cursor and post-cursor taps
  ```python
  ffe = FFE(tap_weights=None, n_pre_taps=1, n_post_taps=1)
  ```

- **DFE (Decision Feedback Equalizer)**: Uses past decisions to cancel ISI
  ```python
  dfe = DFE(symbol_separation=48, tap_weights=None, n_taps=2, pam=pam)
  ```

- **LMS (Least Mean Squares)**: Adaptive algorithm for weight updates
  ```python
  lms = LMS(mu=0.000001, ffe=ffe, dfe=dfe, pam=pam)
  ```

**LMS Theory**: The adaptive algorithm minimizes mean squared error using the gradient descent rule:
```
w(n+1) = w(n) + μ * e(n) * x(n)
```
Where μ is the step size, e(n) is the error signal, and x(n) is the input vector.

#### `reedsolomon.py` - Error Correction
**Classes**: `ReedSolomon1D`, `ReedSolomon2D`

Implements Reed-Solomon error correction codes:

- **1D Reed-Solomon**: Standard single-dimension coding
- **2D Reed-Solomon**: Advanced iterative decoding with enhanced error correction

**Reed-Solomon Theory**: RS(n,k) codes can correct up to t = (n-k)/2 symbol errors. The framework supports two decoding modes:

- **1D Reed-Solomon**: Standard single-dimension coding with sequential processing
- **2D Reed-Solomon**: Advanced iterative decoding that arranges data in a k×k matrix and applies RS coding to both rows and columns, enabling correction of burst errors and providing enhanced performance over 1D codes

Common configurations:
- RS(16,8): 4 parity symbols, corrects 2 errors
- RS(69,65): 4 parity symbols, corrects 2 errors  
- RS(102,96): 6 parity symbols, corrects 3 errors
- RS(544,514): 30 parity symbols, corrects 15 errors

#### `encode.py` - Symbol Encoding
**Classes**: `Binary`, `GrayCode`

Implements bit-to-symbol mapping schemes:
- **Binary encoding**: Direct binary mapping
- **Gray code**: Adjacent symbols differ by only one bit, minimizing error propagation

#### `slicer.py` - Symbol Detection
**Class**: `Slicer`

Implements optimal symbol decision making:
- **Hard slicing**: Maximum likelihood symbol detection
- **Threshold optimization**: Adaptive decision boundaries

### Testing and Analysis Framework

#### `tester.py` - Comprehensive Testing Framework

The primary tool for performance analysis, providing automated SNR sweeps with multiple test configurations:

```bash
# List all available test configurations
python tester.py list

# Run predefined test configurations
python tester.py final         # Publication-ready comprehensive testing
python tester.py high_snr      # High SNR focused testing  
python tester.py continuous    # Efficient continuous mode testing
```

**Test Configurations**:

1. **final**: Binary search SNR sweep with adaptive refinement
   - SNR range: 20-35 dB with intelligent point selection
   - BER thresholds: 1e-5 to 0.11 for curve characterization
   - Data size: 5,000,000 symbols for statistical accuracy
   - Iterations: 4 per SNR point for confidence intervals

2. **high_snr**: High SNR focused testing
   - SNR range: 20-32 dB 
   - Optimized for high-performance system characterization
   - Reduced data size (10,000 symbols) for faster testing

3. **continuous**: Continuous transmission mode
   - Efficient low-BER testing using streaming data
   - Stops at target error count for statistical efficiency
   - Configurable chunk sizes and maximum data limits

**Binary Search Algorithm**: The framework uses intelligent binary search to efficiently find BER transition regions, then adaptively refines the curve with additional points where needed.

#### `parse.py` - Plotting

Generates publication-quality performance plots:

```bash
# Generate plots from test results
python parse.py
```

**Output plots (for reference only)** (saved to `./figs/`):
- `ber_vs_snr_professional.png`: BER vs SNR with logarithmic y-axis
- `ser_vs_snr_professional.png`: SER vs SNR with logarithmic y-axis
- `ber_ser_comparison.png`: Combined comparison plots
- `comprehensive_analysis.png`: Multi-parameter analysis

**Plot Features**:
- Publication-ready formatting
- Logarithmic BER/SER scaling (10^-1 to 10^-6)
- Multiple PAM levels and RS codes on same plot
- Error bars showing confidence intervals
- Industry-standard styling compatible with academic papers

## Step-by-Step Usage Guide

### 1. Environment Setup

```bash
# Navigate to RS directory
cd RS/

# Install Python dependencies
pip install -r requirements.txt

# Verify installation
python model.py --help
```

### 2. Quick System Verification

```bash
# Test basic 4-PAM functionality
python model.py --pam_levels 4 --snr_db 25.0 --data_size 100 --clean

# Test with noise
python model.py --pam_levels 4 --snr_db 20.0 --data_size 100

# Test Reed-Solomon correction
python model.py --n 16 --k 8 --pam_levels 4 --snr_db 15.0 --data_size 64
```

### 3. Parameter Exploration

```bash
# Compare PAM levels at fixed SNR
python model.py --pam_levels 4 --snr_db 20.0 --data_size 1000
python model.py --pam_levels 6 --snr_db 20.0 --data_size 1000  
python model.py --pam_levels 8 --snr_db 20.0 --data_size 1000

# Compare Reed-Solomon codes
python model.py --n 16 --k 8 --pam_levels 4 --snr_db 18.0    # Light correction
python model.py --n 69 --k 65 --pam_levels 4 --snr_db 18.0   # Medium correction
python model.py --n 102 --k 96 --pam_levels 4 --snr_db 18.0  # Strong correction

# Compare 1D vs 2D Reed-Solomon decoding modes
python model.py --n 69 --k 65 --mode 1D --pam_levels 4 --snr_db 18.0  # 1D decoding
python model.py --n 69 --k 65 --mode 2D --pam_levels 4 --snr_db 18.0  # 2D decoding

# Test LMS adaptation rates
python model.py --mu 0.0001 --pam_levels 6 --snr_db 22.0     # Fast adaptation
python model.py --mu 0.000001 --pam_levels 6 --snr_db 22.0   # Standard rate
python model.py --mu 0.00000001 --pam_levels 6 --snr_db 22.0 # Slow adaptation
```

### 4. Comprehensive Performance Analysis

```bash
# Clean previous results
rm -rf logs/ figs/

# Run comprehensive test suite (takes 30-60 minutes)
python tester.py final

# Generate publication plots
python parse.py

# View results
ls figs/
```

### 5. Custom Research Configurations

```bash
# High data rate system (8-PAM + strong RS)
python model.py --n 102 --k 96 --pam_levels 8 --snr_db 28.0 --data_size 5000

# Low latency system (4-PAM + light RS)
python model.py --n 16 --k 8 --pam_levels 4 --snr_db 18.0 --data_size 1000

# Challenging channel conditions
python model.py --n 69 --k 65 --pam_levels 6 --snr_db 12.0 --training_size 500

# Compare raw vs coded performance
python model.py --pam_levels 6 --snr_db 20.0 --raw           # No RS
python model.py --pam_levels 6 --snr_db 20.0 --n 69 --k 65   # With RS
```

## Theoretical Background

### PAM Modulation Theory

**Spectral Efficiency**: Higher-order PAM increases bits per symbol but requires higher SNR:
- 4-PAM: 2 bits/symbol, moderate SNR requirements
- 6-PAM: 2.5 bits/symbol (88.9% efficiency), higher SNR needs
- 8-PAM: 3 bits/symbol, highest SNR requirements

**Eb/N0 vs Es/N0 Relationship**:
```
Eb/N0 = Es/N0 - 10×log₁₀(bits per symbol)

4-PAM: Eb/N0 = Es/N0 - 3.01 dB
6-PAM: Eb/N0 = Es/N0 - 3.98 dB  
8-PAM: Eb/N0 = Es/N0 - 4.77 dB
```

### Reed-Solomon Theory

**Error Correction Capability**: RS(n,k) codes provide:
- Correction of up to t = ⌊(n-k)/2⌋ symbol errors
- Detection of up to (n-k) symbol errors
- Code rate R = k/n (information efficiency)

**Decoding Modes**:
- **1D Mode (`--mode 1D`)**: Standard Reed-Solomon decoding with single-pass error correction. Faster processing but limited error correction capability.
- **2D Mode (`--mode 2D`)**: Advanced iterative decoding that arranges data in a k×k matrix and applies RS coding to both rows and columns. Provides enhanced error correction for burst errors and typically 1-3 dB coding gain improvement over 1D mode.

### Adaptive Equalization Theory

**Channel Model**: h(t) = δ(t) + α₁δ(t-T) + α₂δ(t-2T) + ...

**LMS Algorithm**: Minimizes E[e²(n)] where e(n) = d(n) - y(n)
- d(n): desired response (training sequence)
- y(n): equalizer output
- Convergence depends on μ (step size) and eigenvalue spread

## Performance Benchmarks

### Typical Results

**4-PAM with RS(69,65)**:
- BER < 10⁻³ at ~14 dB SNR
- BER < 10⁻⁵ at ~18 dB SNR
- Near-perfect performance above 22 dB

**6-PAM with RS(69,65)**:
- BER < 10⁻³ at ~18 dB SNR  
- BER < 10⁻⁵ at ~22 dB SNR
- Higher SNR requirements due to reduced noise margins

**8-PAM with RS(102,96)**:
- BER < 10⁻³ at ~22 dB SNR
- BER < 10⁻⁵ at ~26 dB SNR
- Benefits significantly from strong error correction

### Coding Gain

Reed-Solomon coding provides substantial performance improvements:
- ~3-6 dB coding gain for moderate error rates
- ~8-12 dB gain at low error rates (BER < 10⁻⁵)
- 2D decoding adds additional 1-3 dB improvement

## Research Applications

This framework enables research in:

- **Forward Error Correction**: Performance analysis of different RS codes
- **Modulation Optimization**: PAM level selection for given channel conditions  
- **Adaptive Algorithms**: LMS equalizer parameter optimization
- **System Trade-offs**: Spectral efficiency vs power efficiency analysis
- **FPGA Validation**: Software reference for hardware implementations

## Advanced Configuration

### Custom Channel Models

Modify the channel impulse response in `model.py`:
```python
# Mild ISI channel
channel = Channel(config=config, receiver=receiver, h=[0.1, 1.0, 0.2])

# Severe ISI channel  
channel = Channel(config=config, receiver=receiver, h=[0.3, 0.7, 1.0, 0.4, 0.1])
```

### LMS Convergence Tuning

Optimize step size for your channel:
```bash
# Conservative (stable but slow)
python model.py --mu 0.00000001 --training_size 2000

# Aggressive (fast but may be unstable)  
python model.py --mu 0.0001 --training_size 500
```

### Statistical Accuracy

For publication-quality results:
```bash
# High accuracy (longer runtime)
python model.py --data_size 100000 --training_size 2000

# Quick validation (faster)
python model.py --data_size 1000 --training_size 100
```

## Dependencies

- **Python 3.7+**
- **NumPy**: Numerical computations and array operations
- **Matplotlib**: Professional plotting and visualization
- **SciPy**: Signal processing and optimization  
- **reedsolo**: Reed-Solomon codec implementation
- **tqdm**: Progress bars for long-running tests

## Contributing

When extending the framework:

1. **Maintain backward compatibility** with existing test configurations
2. **Document new parameters** in both code and this README
3. **Validate performance** against known benchmarks
4. **Update plotting** to include new metrics or configurations
5. **Follow coding style** consistent with existing modules

The system is designed for extensibility - new PAM levels, RS codes, and equalizer algorithms can be easily integrated while maintaining the existing testing and analysis framework.