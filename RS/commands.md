# Enhanced model.py Commands (Verbose Arguments)

usage: model.py [-h] [--n N] [--k K] [--max_iterations MAX_ITERATIONS] [--mu MU] [--pam_levels {4,6,8}] [--snr_db SNR_DB | --sigma SIGMA] [--data_size DATA_SIZE] [--training_size TRAINING_SIZE] [--raw] [--clean]

## Basic syntax
python model.py [OPTIONS]

# Richard's PAM4_SNR.py Equivalent
python model.py --n 69 --k 65 --mu 0.0000001 --pam_levels 4 --snr_db 16.98970004336018746471 --data_size 62500 --training_size 1000

## Quick 4-PAM test  
python model.py --n 69 --k 65 --mu 0.0000001 --pam_levels 4 --snr_db 25.0 --data_size 10000 --training_size 1000
python model.py --n 69 --k 65 --mu 0.000001 --pam_levels 6 --snr_db 25.0 --data_size 10000 --training_size 1000
python model.py --n 69 --k 65 --mu 0.000001 --pam_levels 8 --snr_db 35.0 --data_size 10000 --training_size 1000

python model.py --n 102 --k 96 --mu 0.000001 --pam_levels 4 --snr_db 28.0 --data_size 10000 --training_size 1000
python model.py --n 102 --k 96 --mu 0.000001 --pam_levels 6 --snr_db 28.0 --data_size 10000 --training_size 1000
python model.py --n 102 --k 96 --mu 0.000001 --pam_levels 8 --snr_db 30.0 --data_size 10000 --training_size 1000
<!-- python model.py --n 15 --k 11 --mu 0.000001 --pam_levels 4 --sigma 20.0 --data_size 10000 --training_size 100 -->

## 6-PAM with RS(69,65) - matches your tester config
python model.py --n 69 --k 65 --mu 0.0000001 --pam_levels 6 --snr_db 25.0 --data_size 512 --training_size 100

## 8-PAM high performance test
python model.py --n 102 --k 96 --mu 0.0000001 --pam_levels 8 --snr_db 30.0 --data_size 25600 --training_size 200

## Low SNR stress test
python model.py --n 69 --k 65 --mu 0.0000001 --pam_levels 6 --snr_db 10.0 --data_size 128 --training_size 50

## High SNR clean test  
python model.py --n 15 --k 11 --mu 0.00001 --pam_levels 4 --snr_db 40.0 --data_size 1024 --training_size 200

## Alternative: Using direct sigma instead of SNR
python model.py --n 69 --k 65 --mu 0.0000001 --pam_levels 6 --sigma 0.075 --data_size 512

## Minimal test with defaults (only specify what you want to change)
python model.py --pam_levels 6 --snr_db 25.0

## High precision test with custom RS iterations
python model.py --n 102 --k 96 --max_iterations 500 --mu 0.0000001 --pam_levels 8 --snr_db 35.0

## Quick debug test
python model.py --data_size 32 --training_size 25 --pam_levels 4

## Raw transmission mode (no Reed-Solomon)
python model.py --pam_levels 4 --snr_db 20.0 --raw
python model.py --pam_levels 6 --snr_db 25.0 --raw --data_size 256

## Clean mode (no channel effects) for testing
python model.py --pam_levels 4 --clean --data_size 64
python model.py --pam_levels 6 --raw --clean  # Raw + Clean for baseline testing

## Combined raw and clean for perfect transmission test
python model.py --pam_levels 8 --raw --clean --data_size 128

## See all available options and defaults
python model.py --help

---

# tester.py - SNR Sweep Framework

## Available test configurations

### high_snr (Default RS-coded tests)
python tester.py high_snr
- Reed-Solomon coded transmission  
- SNR: 0-110 dB (step 10)
- PAM: 4, 6, 8
- RS codes: (69,65), (102,96)

### comparison (Raw vs Coded comparison)
python tester.py comparison  
- Compares Raw and RS-coded performance
- SNR: 0-28 dB (step 2)
- PAM: 4, 6, 8
- RS codes: (69,65), (102,96)

### raw_only (Raw transmission only)
python tester.py raw_only
- Raw transmission (no Reed-Solomon)
- SNR: 0-38 dB (step 2)  
- PAM: 4, 6, 8

## List all configurations
python tester.py list

## Generate plots from results
python parse.py

---

# Key Concepts

## Eb/N0 vs Es/N0
- **Es/N0**: Symbol Energy per Noise PSD (what we measure)
- **Eb/N0**: Bit Energy per Noise PSD (information-theoretic standard)

### Conversion:
```
Eb/N0 = Es/N0 - 10×log₁₀(bits per symbol)

4-PAM: Eb/N0 = Es/N0 - 3.01 dB  (2 bits/symbol)
6-PAM: Eb/N0 = Es/N0 - 3.98 dB  (2.5 bits/symbol)  
8-PAM: Eb/N0 = Es/N0 - 4.77 dB  (3 bits/symbol)
```

## Power Normalization
All PAM levels use normalized symbol separation for fair power comparison:
- 4-PAM: 48.0 (reference)
- 6-PAM: 31.4
- 8-PAM: 23.4

This ensures equal average power (2,880) across all modulation schemes.