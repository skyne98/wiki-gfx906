# gfx906 Special ISA for Quant/Dequant (MI50/MI60)

This note focuses on `gfx906` instructions that are especially useful for quantization/dequantization and data movement pipelines.

## Verified instruction support on gfx906

I validated support with `llvm-mc -triple=amdgcn-amd-amdhsa -mcpu=gfx906`.

| Instruction | Status on gfx906 | Why it matters |
|---|---|---|
| `v_dot4_i32_i8` | supported | int8x4 dot-accumulate |
| `v_dot8_i32_i4` | supported | int4x8 dot-accumulate |
| `v_dot2_f32_f16` | supported | fp16x2 dot into fp32 |
| `v_dot4c_i32_i8` | **not supported** | cannot rely on `dot4c` lowering |
| `v_dot8c_i32_i4` | **not supported** | cannot rely on `dot8c` lowering |
| `v_pack_b32_f16` | supported | pack 2xf16 into one dword |
| `v_cvt_pkrtz_f16_f32` | supported | direct pack+convert f32->2xf16 |
| `v_pk_add_f16`/`v_pk_mul_f16`/`v_pk_fma_f16` | supported | packed fp16 math (2 lanes/op) |
| `v_mov_b32_dpp` | supported | wave-lane rearrange without LDS |
| `ds_bpermute_b32` / `ds_permute_b32` | supported | lane gather/scatter style exchange |
| `v_perm_b32` | supported | byte permutation within registers |
| `v_bfe_i32` | supported | fast nibble/bitfield extraction |
| `v_lshl_or_b32` | supported | pack/insert bits efficiently |
| SDWA forms (`*_sdwa`) | supported | byte/word select in ALU/convert ops |

## Complete SDWA variant sweep on gfx906

- I extracted all `v_*_sdwa` mnemonics from LLVM GFX9 syntax docs (`AMDGPUAsmGFX9`).
- Total mnemonics found: `239`.
- I assembled each mnemonic with `llvm-mc -triple=amdgcn-amd-amdhsa -mcpu=gfx906` using a multi-template operand probe.
- Result: `239/239` assembled successfully, `0` unsupported, `0` unresolved.
- Runtime spot checks on hardware passed for representative SDWA ops:
  - `v_cvt_f32_i32_sdwa`
  - `v_add_u32_sdwa`

Interpretation: all documented GFX9 SDWA opcode variants are available on `gfx906` at instruction level.
This is opcode-availability coverage, not an exhaustive test of every legal modifier combination.

## What the compiler emitted in real qdq kernels

Built and disassembled HIP kernels on real `gfx906` (`hipcc -O3 --offload-arch=gfx906 -S`).

- FP32 -> INT8 pack4 path emitted:
  - `v_rndne_f32`, `v_cvt_i32_f32`, `v_med3_i32` (saturating clamp to [-128,127])
  - `v_lshlrev_b32`, `v_perm_b32`, `v_or3_b32` (packing)
- INT8 unpack + dequant path emitted:
  - `v_cvt_f32_i32_sdwa ... src0_sel:BYTE_{0..3}` (byte extract + sign-extend + convert)
- INT4 unpack + dequant path emitted:
  - `v_bfe_i32` for nibble extraction + sign extension, then `v_cvt_f32_i32`
- Wave shuffle path (`__shfl_xor`) emitted:
  - `ds_bpermute_b32`
- Packed fp16 math path emitted:
  - `v_pk_fma_f16`
- FP32 -> packed fp16 storage path emitted:
  - `v_cvt_f16_f32` + `v_pack_b32_f16`

## High-value instruction families for qdq work

1. Dot instructions (`v_dot4_*`, `v_dot8_*`, `v_dot2_f32_f16`)
- Use when data is already packed/quantized (or conversion cost is amortized).

2. SDWA instructions (`*_sdwa`)
- Best for byte/word extraction directly inside ALU/convert op (helps i8 dequant).

3. Bitfield/pack ops (`v_bfe_*`, `v_lshl_or_b32`, `v_perm_b32`, shifts/ands)
- Core tools for nibble/byte unpack and repack (especially int4/int8 layouts).

4. Packed fp16 ops (`v_pack_b32_f16`, `v_cvt_pkrtz_f16_f32`, `v_pk_*_f16`)
- Useful bridge path when dequantizing into fp16 or doing fp16 pre/post transforms.

5. Wave data movement (`v_mov_b32_dpp`, `ds_bpermute_b32`, `ds_permute_b32`)
- Useful for lane remap/reorder without global memory traffic.

## Practical limits and caveats

- `dot4c`/`dot8c` are not available on `gfx906`; only use `dot4`/`dot8` forms.
- `gfx906` dot instructions are available, but `v_mfma*` instructions are not listed for this target.
- SDWA selects byte/word sublanes (`BYTE_0..3`, `WORD_0..1`, `DWORD`), not arbitrary bitfields.
- DPP/DS lane ops are wave-level operations; they are not global cross-wave data movement.
- `clamp` behavior matters for integer dot/arith overflow paths; enable only when required.

## References

- LLVM gfx906 syntax: <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html>
- LLVM GFX9 full syntax (instruction families + SDWA/DPP forms): <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX9.html>
- LLVM AMDGPU modifier syntax (DPP/SDWA/op_sel/clamp): <https://llvm.org/docs/AMDGPUModifierSyntax.html>
- LLVM AMDGPU usage (dot intrinsics and lowering notes): <https://llvm.org/docs/AMDGPUUsage.html>
