# Packed SIMD Coprocessor for Deep Learning Float16 (dlfloat16)

This project implements a **Packed SIMD Coprocessor** designed for accelerating **deep learning floating-point operations (dlfloat16)**. The architecture supports vectorized (SIMD-style) operations on 16-bit floating-point numbers and is modular, extensible, and optimized for low-latency parallel computation.

---

## 🚀 Project Objective

The aim is to build a **custom SIMD coprocessor** capable of executing deep learning operations using a compact 16-bit floating-point format (`dlfloat16`). This coprocessor is designed to plug into a RISC-V-like SoC or custom CPU pipeline as an accelerator for neural network workloads.

---

## 🧩 Top-Level Module: `PSIMD`

The `PSIMD` module integrates all key components of the SIMD coprocessor pipeline, including instruction decoding, register file access, memory interaction, and the execution of vector operations. It receives 32-bit RISC-style instructions and handles vectorized data movement and computation.

---

## 📦 Module Breakdown

- ### 🔧 `dlfloat16_decoder`
  Decodes RISC-style 32-bit instructions and extracts control signals (like operation type, source/dest registers, immediate, and memory control).

- ### 📗 `p_reg_file`
  Implements the vector register file to support three input sources (`rs1`, `rs2`, `rs3`) and one writeback register (`rd`). Each register holds 64-bit data for 4x 16-bit floats.

- ### ⚙️ `Execution_unit`
  Main datapath block that processes vector floating-point operations (e.g., add, mul) on 16-bit `dlfloat16` values. Supports:
  - SIMD parallel execution
  - Floating-point exception flags (invalid, inexact, overflow, underflow, divide-by-zero)
  - Register-level pipelining and parallel lanes

- ### 📤 `LSU` (Load/Store Unit)
  Handles memory operations for vector data. Computes address from register values + immediate offsets and manages read/write control.

- ### 🧮 `mux_reg` and `demux_reg`
  Configurable multiplexers and demultiplexers to route data between execution, memory, and register file modules.

- ### 🧠 `memory`
  Abstracted memory interface for simulation and testing. Supports direct data reads and writes using computed addresses.

---

## 📐 Data Format

Each 64-bit register holds:
- 4 x `dlfloat16` values (16-bit custom floats)

All SIMD operations are performed in a **packed parallel** manner across these 4 lanes.

---

## 🧠 Project Highlights

- ✅ **Custom SIMD Architecture**
- ✅ **Deep Learning 16-bit Float Precision**
- ✅ **Parallel Vector Execution**
- ✅ **Modular Verilog Design**
- ✅ **Coprocessor-Ready Interface**

---

## 🧪 Simulation & Testing

We are using **testbenches** to verify:
- Instruction decoding accuracy
- Vector register file correctness
- Functional unit outputs for various opcodes
- Memory load/store interactions
- Exception flags on edge cases (e.g., NaNs, overflows)

---

## 🔮 Future Plans

- Integrate with a RISC-V core as a **coprocessor** via custom opcode ISA extensions
- Add support for matrix operations (e.g., fused multiply-accumulate)
- Optimize pipelining and timing (targeting 1-cycle throughput)
- Synthesize on FPGA for real-time validation

---

## 👥 Contributors

- Neha and team  
(Feel free to add more names and GitHub handles here)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

