# MI50/MI60 (gfx906) Architecture Baseline

This note captures the highest-value architectural facts I could verify from primary sources for optimization work on:

- `Radeon Instinct MI60 (gfx906)`
- `Radeon Instinct MI50 16GB (gfx906)`
- `Radeon Instinct MI50 32GB (gfx906)` (listed in current ROCm tables)

Data was cross-checked on **February 21, 2026**.

## 1) Ground-Truth SKU/Resource Table (ROCm Hardware Specs)

From AMD ROCm’s Instinct architecture table:

| GPU | LLVM target | VRAM (GiB) | CUs | Wavefront | LDS/CU | L2 | L1 Vector | L1 Scalar | L1 I$ | VGPR file | SGPR file | GFXIP |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| MI60 | gfx906 | 32 | 64 | 64 | 64 KiB | 4 MiB | 16 KiB | 16 KiB / 3 CUs | 32 KiB / 3 CUs | 256 KiB | 12.5 KiB | 9.0 |
| MI50 (32GB) | gfx906 | 32 | 60 | 64 | 64 KiB | 4 MiB | 16 KiB | 16 KiB / 3 CUs | 32 KiB / 3 CUs | 256 KiB | 12.5 KiB | 9.0 |
| MI50 (16GB) | gfx906 | 16 | 60 | 64 | 64 KiB | 4 MiB | 16 KiB | 16 KiB / 3 CUs | 32 KiB / 3 CUs | 256 KiB | 12.5 KiB | 9.0 |

Optimization implication:
- Treat MI60 and MI50 as the same ISA/feature family (`gfx906`) with CU-count and memory-capacity differences as the main SKU split.

## 2) Launch-Era Product Capabilities (AMD 2018 IR Release)

From AMD’s MI50/MI60 launch release (Nov 6, 2018):

- MI60 peak throughput (theoretical): FP16 29.5 TFLOPS, FP32 14.8 TFLOPS, FP64 7.4 TFLOPS.
- MI50 peak throughput (theoretical): FP16 26.8 TFLOPS, FP32 13.4 TFLOPS, FP64 6.7 TFLOPS.
- Both boards: 300W envelope.
- Memory/interconnect claims: up to 1 TB/s HBM2 bandwidth, MI60 at 32GB HBM2 ECC, MI50 at 16GB HBM2 ECC (launch), dual IF links up to 200 GB/s P2P, and PCIe Gen4 x16 up to 64 GB/s host link bandwidth.

Date clarification:
- The **2018** launch material lists MI50 as 16GB.
- The **current ROCm table** includes both MI50 16GB and MI50 32GB entries.

## 3) Compute-Unit and Scheduling Model (HIP Hardware Docs)

ROCm HIP hardware documentation (GCN-oriented model) highlights:

- Wavefront model is 64 lanes for this class of architecture.
- CU execution core is modeled as four SIMD16 vector units.
- Sequencer organization allows up to 40 resident wavefronts per CU (4 pools x up to 10 each), subject to resource limits.
- Per-cycle issue model can include one instruction to each SIMD path, plus scalar/branch/LDS paths.
- Resource constraints that gate occupancy: wave slots, VGPR, SGPR, LDS.

Optimization implication:
- Occupancy is constrained by register and LDS pressure before nominal wave-slot maxima in many real kernels.

## 4) Memory Hierarchy and Data Movement Facts

### 4.1 Caches/LDS behavior

From HIP hardware docs and Vega 7nm ISA:

- LDS is a software-managed on-CU scratchpad with 32 banks, 4-byte bank width.
- LDS bank conflicts are a first-order performance limiter for shared-memory-heavy kernels.
- Vector L1 is per-CU, write-through, with 64-byte line granularity and typical 16 KiB size.
- L2 is shared and is the coherence point for GPU memory traffic.
- Vega 7nm ISA documents a 4 MiB shared L2 and CU-array scalar/instruction front-end caches.

### 4.2 Interconnect and host link

From AMD 2018 release details:

- Dual Infinity Fabric Links (xGMI) per GPU with stated up to 200 GB/s aggregate P2P bandwidth.
- PCIe Gen4 x16 stated up to 64 GB/s host-device transport peak.

Optimization implication:
- Multi-GPU collectives can benefit significantly when topology actually uses IF links.
- Host-staging and transfer overlap should assume PCIe constraints unless direct GPU-GPU paths are active.

## 5) ISA/Compiler-Surface Constraints Specific to gfx906

From LLVM AMDGPU usage/reference and per-target assembler docs:

- `gfx906` target IDs are published as:
  - `gfx906:sramecc-:xnack-`
  - `gfx906:sramecc-:xnack+`
- `sramecc` not available on `gfx906` in this target model.
- `xnack` is compiler-visible and relevant for demand-paging/page-migration behavior.
- `wavefrontsize64` is the relevant mode for this generation.
- Current LLVM gfx906 assembler syntax docs list `v_dot*` instructions (for example `v_dot2_f32_f16`, `v_dot4_i32_i8`, `v_dot8_i32_i4`).
- `v_mfma*` instructions are not listed on the LLVM gfx906 instruction page; they are listed on newer targets (for example gfx908 docs).

Optimization implication:
- Build artifacts must match the intended XNACK mode (`xnack-` vs `xnack+`) for predictable paging/fault behavior and performance.
- Prefer instruction paths actually listed for gfx906 (`v_dot*` and standard vector paths), and do not assume MFMA availability on MI50/MI60.

## 6) Deep-Learning Instruction Path (gfx906-safe view)

From LLVM gfx906 assembler docs and AMD launch material:

- gfx906 shows mixed-precision/dot instruction forms (`v_dot*`) in LLVM assembler syntax docs.
- AMD launch material describes optimized deep-learning operations (DLOPS) for MI50/MI60.
- MFMA (`v_mfma*`) should not be assumed for gfx906 based on current per-target LLVM docs.

Optimization implication:
- For MI50/MI60, prioritize kernels that exploit documented gfx906 dot/mixed-precision instruction paths plus efficient memory behavior.

## 7) Practical Optimization Baseline Checklist

Use this as the default starting point for kernel tuning on MI50/MI60:

1. Target compile:
   Use `--offload-arch=gfx906:xnack-` or `gfx906:xnack+` explicitly (do not leave ambiguous across environments).
2. Launch geometry:
   Workgroup sizes in multiples of 64. Sweep occupancy-sensitive block sizes while watching VGPR/LDS pressure.
3. Register/LDS budget:
   Keep LDS layouts bank-friendly (avoid many lanes hitting same bank). Track whether VGPR or LDS is the first occupancy limiter.
4. Memory behavior:
   Coalesce global accesses for L1/L2 efficiency. Prefer data reuse in LDS where bank conflicts remain controlled.
5. Multi-GPU:
   Verify actual IF-link topology; optimize collectives/partitioning for P2P when present.
6. Math path:
   Prefer gfx906-documented dot/mixed-precision paths (`v_dot*`) and avoid assuming MFMA availability.

## 8) References (Primary Sources)

- AMD ROCm GPU architecture specs (Instinct table):  
  https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html
- AMD ROCm HIP hardware implementation:  
  https://rocm.docs.amd.com/projects/HIP/en/latest/understand/hardware_implementation.html
- LLVM AMDGPU usage/reference (target features, restrictions, target IDs):  
  https://llvm.org/docs/AMDGPUUsage.html
- LLVM gfx906 instruction syntax (per-target assembler reference):  
  https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html
- LLVM gfx908 instruction syntax (contrast target showing MFMA forms):  
  https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX908.html
- AMD IR launch release (Nov 6, 2018), MI60/MI50:
  https://ir.amd.com/news-events/press-releases/detail/859/amd-unveils-worlds-first-7nm-datacenter-gpus----powering-the-next-era-of-artificial-intelligence-cloud-computing-and-high-performance-computing-hpc
- AMD Vega 7nm Shader ISA PDF:
  https://gpuopen.com/wp-content/uploads/2019/11/Vega_7nm_Shader_ISA_26November2019.pdf
