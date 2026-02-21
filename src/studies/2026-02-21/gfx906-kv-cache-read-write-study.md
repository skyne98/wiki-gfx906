# gfx906 KV-Cache Read/Write Kernel Study

This note benchmarks KV-cache layouts on gfx906 for decode-like kernels.

## Layouts tested

- `HSD`: `[head][seq][dim]` (dim contiguous inside sequence position)
- `HDS`: `[head][dim][seq]` (seq contiguous for each dim lane)

## Measured write behavior (new-token update)

Measured on real gfx906 (`float` cache, `dim=128`, `heads=32`, `seq=4096`):

- `write_hsd_x4`: ~`357.6 GB/s`
- `write_hsd_x1`: ~`357.6 GB/s`
- `write_hds_x4`: ~`54.4 GB/s`
- `write_hds_x1`: ~`14.0 GB/s`

Takeaway:
- For decode token writes, `HSD` is dramatically better than `HDS`.
- `HDS` writes are highly strided and expensive.

## Measured read behavior depends on traversal pattern

### A) Dot-style decode traversal (per-seq dot over dim)

Kernel pattern: each block handles one `(head, seq)` row and threads span `dim`.

- `read_dot_hsd_x4`: ~`1.76 TB/s`
- `read_dot_hds_x4`: ~`0.37 TB/s`

Takeaway:
- For attention-score style decode reads, `HSD` is the right layout.

### B) Dim-fixed streaming over seq

Kernel pattern: each thread keeps fixed `dim` lane and streams `seq`.

- `read_hsd_x1`: ~`45.0 GB/s`
- `read_hsd_x4`: ~`41.5 GB/s`
- `read_hds_x4`: ~`73.7 GB/s`

Takeaway:
- If the kernel is explicitly dim-fixed streaming over sequence, `HDS` can be better.

## ISA mapping confirmed

Disassembly confirms expected vector paths:

- scalar read/write: `global_load_dword`, `global_store_dword`
- vector read/write: `global_load_dwordx4`, `global_store_dwordx4`

## Recommended default for LLM decode kernels on gfx906

1. Keep canonical KV layout as `HSD` (`[head][seq][dim]`).
2. Use `x4` vectorized loads/stores when naturally aligned.
3. Optimize decode math kernels around dot-style traversal (per-seq rows), where `HSD` is strong.
4. Only use `HDS` when a specific kernel is dim-fixed seq-streaming and dominates runtime.

## Practical implication

For general-purpose LLM kernels, optimizing around `HSD` gives strong read+write balance.
`HDS` is a specialized alternative, not a universal default.

## References

- LLVM gfx906 syntax: <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html>
- LLVM GFX9 syntax: <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX9.html>
