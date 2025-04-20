# PSIMD-DLFLoats
This project implements a Packed SIMD (Single Instruction, Multiple Data) Floating-Point Processor designed to accelerate parallel floating-point operations for deep learning

The processor supports:

64-bit vector registers, split into multiple 16-bit floating-point elements

A custom Execution Unit (EU) capable of handling vectorized arithmetic operations (e.g., add, sub, mul, div)

IEEE-754-like exception flags (invalid, inexact, overflow, underflow, div-by-zero) for precision tracking

A configurable instruction decoder for controlling ALU, muxes, and register file
