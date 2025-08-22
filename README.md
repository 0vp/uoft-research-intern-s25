# University of Toronto Research Internship - Summer 2025

This repository contains the code for my research internship at the University of Toronto.

## Table of Contents

- [Special Thanks](#special-thanks)
- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [2D Reed-Solomon Theory](#2d-reed-solomon-theory)
- [Configuration Parameters](#configuration-parameters)

## Special Thanks
- Professor Tony Chan Carusone for his guidance and supervision throughout the internship.
- Pooya Poolad for his help with setting up the FPGA environment and providing hardware insights.
- Richard Barrie for his base FPGA-FEC code in which the SV code was tested on and for his support with theoretical concepts.

## Project Overview



## Repository Structure

- `RS/` - Reed-Solomon PAM Communication System Python Model
- `gen_rs_sv/` - SystemVerilog Reed-Solomon Code Generator
- `Readings/` - Research papers and documentation

## 2D Reed-Solomon Theory

The framework implements advanced 2D Reed-Solomon decoding for enhanced error correction capability.

### Basic Concept

2D Reed-Solomon arranges data in a square matrix and applies error correction to both rows and columns:

```
RS(N, K) = RS(4, 3)

Step 1: Arrange data in k×k matrix
[d1  d2  d3]
[d4  d5  d6]  
[d7  d8  d9]

Step 2: Add parity to rows and columns
[d1  d2  d3  |  p1]
[d4  d5  d6  |  p2]
[d7  d8  d9  |  p3]
[p4  p5  p6  |  p7]

Step 3: Both rows and columns are now RS codewords

Important: p7 (parity-on-parity) must be consistent:
- Row calculation: p7 = RS_parity(p4, p5, p6)
- Column calculation: p7 = RS_parity(p1, p2, p3)
- Both methods MUST produce the same p7 value
```

### Iterative Decoding Process

The decoder alternates between row and column correction:

```
ITERATION LOOP:
1. Row Decoding             → Fix errors in each row
2. Column Decoding          → Fix errors in each column
3. Check Stop Condition     → If no changes or MAX_ITERATIONS reached, stop
4. Repeat                   → Continue until convergence
```

### Why 2D Works Better

**Burst Error Advantage:**
```
Original error pattern (hard to fix):
[1  X  X  X  5]  ← 3 errors in one row

After 2D arrangement (easier to fix):
[1  2  3]
[X  X  X]  ← Burst becomes 1 error per column
[4  5  6]

Result: 3 errors → 3×1 errors (correctable)
```