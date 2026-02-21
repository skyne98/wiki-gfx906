# gfx906 LDS Layout Standard for LLM Blocks

This note defines a practical LDS layout standard for gfx906 kernels (GEMM/attention-style tiles) based on measured bank-pressure behavior.

## Why this matters

Many LLM kernels read one operand row-wise and another operand effectively column-wise from LDS.
On gfx906, column-style accesses can collapse bandwidth if row stride aliases LDS banks.

## Measured result (key experiment)

Microbenchmark on real gfx906 using `ds_read_b128`/`ds_write_b128`:

- contiguous vec4 access baseline: ~`4257 GB/s`
- column-style access with `ld=32` vec4: ~`1865 GB/s`
- same column-style access with `ld=33` vec4 padding: ~`3974 GB/s`

Interpretation:
- `ld=32` (power-of-two stride) is a bad default for column-like LDS reads.
- adding one vec4 of padding per row (`ld=33`) recovers most bandwidth.

## Instruction forms confirmed

Disassembly for all variants used:
- `ds_write_b128`
- `ds_read_b128`

So the improvement is layout/bank behavior, not a different opcode path.

## Layout standard for gfx906

1. Use 16-byte vectorized LDS payloads (`uint4`/`float4`/packed int blocks).
2. Keep base LDS buffers 16-byte aligned.
3. For tiles consumed row-wise only: use natural row stride.
4. For tiles that will be consumed column-wise (or transposed access), use padded leading dimension in vec4 units:
`ld_vec = logical_ld_vec + 1`.
5. Prefer `ds_read/write_b128` staging paths over scalar LDS traffic.

## Recommended defaults

- A-like operand (row-consumed): no pad needed.
- B-like operand (column-consumed by waves): `+1` vec4 pad per row.
- If LDS budget is tight, test `+1` first before more complex swizzles.

## Practical formula

If a row has `K_vec` vec4 elements, allocate:
- `stride_vec = K_vec` for row-only reads
- `stride_vec = K_vec + 1` for column-like reuse

LDS footprint increase is modest (`~1/K_vec` fractional overhead) and often worth it.

## Caveat

Numbers come from controlled microbenchmarks; final kernel gains depend on occupancy, VMEM pressure, and math mix.
Still, this `+1` rule is a strong first choice on gfx906.

## References

- LLVM gfx906 syntax: <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html>
- LLVM GFX9 syntax: <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX9.html>
