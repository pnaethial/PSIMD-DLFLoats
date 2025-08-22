# Packed SIMD Deep Learning Float16 Coprocessor

## Project Objective

The goal of this project is to implement a **Packed SIMD (Single Instruction Multiple Data) coprocessor** that offloads deep learning-related floating-point instructions from a **RISC-V core**. 

This coprocessor is optimized to handle lightweight yet high-performance computations commonly required in neural network inference, especially on embedded and edge devices with constrained resources.

By delegating floating-point computation to a dedicated coprocessor, the RISC-V core is relieved of intensive data-parallel operations, allowing it to focus on control flow and other general-purpose tasks. The coprocessor is designed to efficiently execute operations on a packed format of data using a custom 16-bit floating-point representation, referred to as `dlfloat16`.

## Progress
Integrated with Vex Riscv Core Using CFU Playground.
CFU Playground [Custum Function Unit]- Accelerates ML models

---
## Architecture
### PSIMD DL Float Coprocessor:
<img width="778" height="391" alt="image" src="https://github.com/user-attachments/assets/7699cfbb-47f2-453c-8796-9c83fb4474fb" />

### RISCV CORE:
<img width="821" height="361" alt="image" src="https://github.com/user-attachments/assets/b6f6af6e-8ef7-47e9-85e9-aba778fe1a3d" />

## Key Features

- **Parallel Execution**:  
  Executes operations on multiple floating-point values simultaneously using wide registers. This enhances performance for workloads such as matrix multiplications and convolutions which are central to deep learning inference.

- **Packed Data Operation**:  
  Operates on packed data types, where multiple smaller data items (e.g., 16-bit float values) are grouped into a larger register (e.g., 64-bit or 128-bit). For instance, a 64-bit register can hold four `dlfloat16` values, enabling four-way parallelism.

- **Efficient Memory Management**:  
  Optimized load-store unit (LSU) for handling packed data transfers between memory and registers, reducing memory access latency and improving throughput.

- **Reduced Power Consumption**:  
  Since data is processed in parallel within a single instruction and specialized logic, the design achieves better performance-per-watt compared to traditional scalar execution on the main processor.

---

## How Packed SIMD Works

Packed SIMD involves combining multiple data items of the same or different types into a single wide register. The coprocessor performs the same instruction on all items in parallel, using a single execution cycle.

For example:
- A 128-bit SIMD register may contain four 32-bit floating-point numbers.
- One SIMD add instruction can perform four additions in parallel.

Unlike traditional vector processors, **Packed SIMD is more flexible**, allowing operations across different data types (e.g., combining int and float operations) within the same instruction format, making it well-suited for diverse AI workloads.

---

## Integration

This module is intended to be integrated as a **tightly- or loosely-coupled coprocessor** with a RISC-V processor core. Communication between the core and the coprocessor is managed through instruction decoding and data exchange mechanisms such as register files and memory interfaces.

---

## Use Cases

- **Edge AI inference acceleration**
- **Energy-efficient embedded deep learning**
- **Parallel data processing on custom float formats**
- **FPGA-based coprocessor extension for AI applications**

---

## Final Thoughts

The Packed SIMD coprocessor design promotes scalable, modular, and power-aware computation for modern AI tasks. Its flexibility and performance benefits make it an excellent addition to any RISC-V-based SoC targeting machine learning at the edge.
