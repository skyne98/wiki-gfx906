# FP32 vs Quant-Dequant + Dot on gfx906 (Measured)

Date: 2026-02-21  
Hardware: AMD Instinct MI50/MI60 (`gfx906`), 60 CUs, 1725 MHz  
Host: `fox@192.168.1.28` (ROCm installed)

Question:
- If activations start in FP32, is it worth quantizing/dequantizing them on gfx906 to compute with `dot4`/`dot2`, or is pure FP32 better?

## Experiment Setup

Three paths were benchmarked on-device with HIP:

1. `pure_fp32`
- FP32 values stay FP32.
- Compute via FP32 FMA only.

2. `qdq_int8_dot4`
- In kernel hot loop: FP32 activation -> INT8 quantize (pack) -> `__builtin_amdgcn_sdot4` -> dequantize.

3. `qdq_fp16_dot2`
- In kernel hot loop: FP32 activation -> FP16 conversion -> `__builtin_amdgcn_fdot2`.

All paths were normalized to the same arithmetic payload per loop iteration (8 MACs/thread/iter), and reported as effective TOPS (counting MAC as 2 ops).

## Core Result (On-the-Fly QDQ in Hot Loop)

Stable best results across cards (after reruns):

- `pure_fp32`: ~5.95 TOPS
- `qdq_fp16_dot2`: ~4.19 TOPS
- `qdq_int8_dot4`: ~2.00 TOPS

Conclusion for this scenario:
- When activations start as FP32 and conversion is done in the hot loop, **pure FP32 wins**.
- `dot2` is slower than FP32.
- `dot4` is much slower than FP32.

## Amortized Conversion Check (Conversion Once, Reuse Many Times)

A second benchmark converted once outside the hot loop, then reused converted values:

- `fp32_reuse`: ~13.0 TOPS
- `dot4_reuse`: ~21.7 TOPS
- `dot2_reuse`: ~21.9 TOPS

Interpretation:
- If conversion cost is amortized by reuse (GEMM-like behavior), dot paths can outperform pure FP32.
- If conversion/deconversion is paid every use, they do not.

## Practical Recommendation

1. For per-use FP32 activations:
- Use pure FP32 on gfx906.

2. For high-reuse kernels (where conversion is amortized):
- Dot paths (`dot4`/`dot2`) can be worthwhile.
- Optimize for reuse depth before deciding.

3. Do not rely on theoretical dot throughput alone:
- End-to-end cost is dominated by conversion/packing when done in the hot path.

## Instruction Validation Notes

Codegen validation on `gfx906`:
- `__builtin_amdgcn_sdot4` -> `v_dot4_i32_i8`
- `__builtin_amdgcn_fdot2` -> `v_dot2_f32_f16`

Related references:
- LLVM AMDGPU usage/reference: https://llvm.org/docs/AMDGPUUsage.html
- LLVM gfx906 syntax: https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html
