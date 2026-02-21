# gfx906 Latency-Hiding Ops (Measured)

This note summarizes instruction patterns on `gfx906` (MI50/MI60) that are most useful for hiding latency in quant/dequant-style kernels.

## Scope

Focus is on:
- wave-lane exchange (`DPP`, `DS permute`)
- LDS width (`b32`/`b64`/`b128`)
- global load width (`dword` vs `dwordx4`)
- scheduling behavior (`s_waitcnt` placement)

All kernels were compiled for `--offload-arch=gfx906` and validated with emitted ISA.

## Key measured findings

### 1) Use DPP first for row-local shuffles

`v_mov_b32_dpp` row shift (`row_shr:1`) vs LDS+barrier equivalent:

- `dpp_row_shr`: ~`1778` to `1784` Gxchg/s
- `lds_row_shr`: ~`906` Gxchg/s

Takeaway: for row-local lane movement, DPP gives about `~2x` throughput and removes barrier overhead.

### 2) Use `ds_bpermute_b32` for general in-wave exchange

XOR-neighbor exchange benchmark:

- `ds_bpermute_b32`: ~`962` to `970` Gxchg/s
- LDS store+load+barriers equivalent: ~`905` to `907` Gxchg/s

Takeaway: `ds_bpermute_b32` is consistently better than LDS exchange when shuffle pattern is not DPP-friendly.

### 3) Prefer wide LDS ops for staging

Pure LDS streaming kernels (instruction forms confirmed in ISA):

- `ds_read/write_b32` (`l1`): typically ~`1.9` to `3.9` TB/s
- `ds_read/write_b64` (`l2`): typically ~`4.3` to `8.8` TB/s
- `ds_read/write_b128` (`l4`): typically ~`9.5` to `11.2` TB/s

Takeaway: `b128` LDS accesses are the strongest baseline for LDS-heavy staging paths.

### 4) Wide global loads help when memory path is healthy

Compiler emits:
- scalar path: `global_load_dword`
- vector path: `global_load_dwordx4`

In uncongested runs, `dwordx4` outperformed scalar (`~867-873 GB/s` vs `~814 GB/s`).
On a shared machine, global-memory numbers varied run-to-run; treat this as directionally positive, not a fixed constant.

## Scheduling behavior that matters

In ILP kernels, compiler issues multiple loads first and delays waits:
- VMEM: staged `s_waitcnt vmcnt(3..0)`
- LDS: staged `s_waitcnt lgkmcnt(...)`

That pattern is the core latency-hiding mechanism on gfx906: keep multiple memory operations in flight before consuming results.

## What is not available on gfx906 (relevant to hiding)

Assembler probes on `gfx906` rejected:
- `s_clause`
- `s_waitcnt_depctr`
- `s_delay_alu`

So latency control is mainly through ILP/wave occupancy and careful `s_waitcnt` timing, not newer explicit dependency-control instructions.

## Practical checklist

1. Row-local shuffle: use `v_mov_b32_dpp`.
2. Arbitrary in-wave shuffle: use `ds_bpermute_b32` / `ds_permute_b32`.
3. LDS staging: default to `ds_read/write_b128` where alignment allows.
4. Global staging: prefer `global_load_dwordx4` for contiguous packed data.
5. Structure loops to issue multiple independent loads before first use.
6. Avoid immediate waits after each load; let compiler keep VMEM/LDS queues populated.

## References

- LLVM gfx906 syntax: <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX906.html>
- LLVM GFX9 syntax: <https://llvm.org/docs/AMDGPU/AMDGPUAsmGFX9.html>
- LLVM AMDGPU modifier syntax: <https://llvm.org/docs/AMDGPUModifierSyntax.html>
