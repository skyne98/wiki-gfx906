# gfx906 dot4/dot8 Exploration (2026-02-21)

This page documents how `dot4`/`dot8` instructions behave on `gfx906` (MI50/MI60 class), including semantics, limits, theoretical TOPS, and real measurements.

## 1) Instruction Mapping and Semantics

Primary source:
- LLVM AMDGPU usage/reference: https://llvm.org/docs/AMDGPUUsage.html

Mapped intrinsics:
- `llvm.amdgcn.sdot4` -> `v_dot4_i32_i8`
- `llvm.amdgcn.udot4` -> `v_dot4_u32_u8`
- `llvm.amdgcn.sdot8` -> `v_dot8_i32_i4`
- `llvm.amdgcn.udot8` -> `v_dot8_u32_u4`

Semantics:
- dot4 uses two packed `i32` operands that each hold 4x8-bit values.
- dot8 uses two packed `i32` operands that each hold 8x4-bit values.
- Both add into a 32-bit accumulator (`src2`).
- Fourth intrinsic operand is clamp enable (`i1`).

Per-target syntax confirms availability on gfx906:
- https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html

Contrast:
- `v_mfma*` is not listed on gfx906 syntax page (but appears on gfx908):  
  https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX908.html

## 2) Codegen Validation on Real Host

Host:
- `fox@192.168.1.28` (ROCm installed)
- `rocminfo`: 4x `gfx906`, each 60 CUs, 1725 MHz

Direct compile test:
- `clang -target amdgcn-amd-amdhsa -mcpu=gfx906 -nogpulib -O3 -S`

Observed lowering:
- `__builtin_amdgcn_sdot4` -> `v_dot4_i32_i8`
- `__builtin_amdgcn_udot4` -> `v_dot4_u32_u8`
- `__builtin_amdgcn_sdot8` -> `v_dot8_i32_i4`
- `__builtin_amdgcn_udot8` -> `v_dot8_u32_u4`
- clamp flag emits `... clamp` modifier.

## 3) Clamp and Overflow Behavior (Measured)

Measured with small HIP kernels on gfx906:

- `sdot4` positive overflow:
  - no clamp: wraps
  - clamp: saturates to `INT_MAX` (`0x7fffffff`)
- `sdot4` negative overflow:
  - no clamp: wraps
  - clamp: saturates to `INT_MIN` (`0x80000000`)
- `udot4` overflow:
  - no clamp: wraps
  - clamp: saturates to `UINT_MAX` (`0xffffffff`)
- `sdot8` overflow-ish case:
  - no clamp: wraps
  - clamp: saturates to `INT_MAX`

Takeaway:
- Accumulator is 32-bit and can overflow.
- Use clamp when saturating behavior is required.

## 4) Theoretical Throughput (MI50 config from host)

Using measured host-reported config (60 CUs @ 1725 MHz):

- dot4 theoretical:
  - `26.496 TMAC/s`
  - `52.992 TOPS` (counting MAC as 2 ops)
- dot8 theoretical:
  - `52.992 TMAC/s`
  - `105.984 TOPS` (counting MAC as 2 ops)

Formula used:
- `TMAC/s = CU * 64 lanes * MACs_per_instruction * clock`
- `TOPS = 2 * TMAC/s`

## 5) Real Throughput Measurements (All 4 GPUs)

Benchmark A: dependency-chained accumulator
- `blocks=2048`, `threads=256`, `iters=65536`
- Across all 4 cards:
  - `sdot4`: ~21.7 to 22.3 TOPS
  - `udot4`: ~22.25 to 22.63 TOPS
  - `sdot8`: ~43.5 to 44.4 TOPS
  - `udot8`: ~44.5 to 44.6 TOPS

Benchmark B: ILP4 (4 independent accumulators)
- same launch geometry
- Across all 4 cards:
  - `sdot4_ilp4`: ~43.0 to 44.4 TOPS
  - `sdot8_ilp4`: ~85.3 to 86.2 TOPS

Interpretation:
- dot8 is ~2x dot4 throughput in both patterns.
- ILP materially improves achieved throughput by reducing dependency stalls.
- ILP4 results are roughly ~81% of simple theoretical peak.

## 6) Practical Optimization Guidance

1. Use dot8 when quantization/layout supports 4-bit packing; it delivers about 2x dot4 arithmetic density.
2. Keep multiple independent accumulators per thread to reduce dependency throttling.
3. Track 32-bit accumulator range; enable clamp where saturation is needed.
4. On gfx906, optimize around `v_dot*` and memory behavior; do not assume MFMA.

## References

- LLVM AMDGPU usage/reference:  
  https://llvm.org/docs/AMDGPUUsage.html
- LLVM gfx906 instruction syntax:  
  https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html
- LLVM gfx908 instruction syntax (contrast):  
  https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX908.html
- ROCm GPU architecture specs:  
  https://rocm.docs.amd.com/en/latest/reference/gpu-arch-specs.html
