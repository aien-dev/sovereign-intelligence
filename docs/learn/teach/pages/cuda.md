# Reverse-engineering CUDA, the CUDA++ way

I built CUDA++ alone on one DGX Spark, directing AI coding agents, to run my own machine code on an NVIDIA GB10 with no NVIDIA user-space software in the process: no `nvcc`, no PTX, no `libcuda`, no cuBLAS. This track teaches how, from the first question (what even is the boundary between my program and the GPU?) down to single bits of machine code. Every lesson has an example you can run on an ordinary Linux AArch64 machine with no GPU, its real recorded output, and a negative control that shows the check can fail.

## Who it is for

- Programmers who use CUDA and want to know what happens below `cudaMalloc` and `cuLaunchKernel`.
- People who want to build their own GPU stack on hardware they own, and want the method, not just the result.
- Anyone who wants to learn how to make claims about low-level systems that survive a stranger re-checking them.

You do not need a GPU for any of it. You do need to keep two things apart, as I do throughout: a host result (a decoder, a model, a re-hashed receipt) is never hardware qualification, and at the pinned commit CUDApp's own README records its native GPU path as NOT_RUN, with the older M16 receipt kept as an unauditable historical summary. Historical chip receipts are cited as historical, with their dates.

## Prerequisites

- Comfortable reading C and shell; hexadecimal and bit fields.
- A Linux AArch64 host with `git`, `sh`, `grep`, `sed`, `jq` and coreutils.
- Clones of [CUDApp](https://github.com/aien-dev/CUDApp/tree/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb) and [omega-mv](https://github.com/aien-dev/omega-mv/tree/19f014f2178ca9cd3473728fe00a475a2398c409) at the pinned commits, and the pinned Omega compiler `seed/out/omc` (every `run.sh` checks its sha256 and refuses to run with another one).
- For the Omega in lessons 2 to 6 and 8: the Omega track's first lessons, or [OMEGESE.md](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md).

## Lessons

1. [User space and the kernel: what CUDA++ replaces and what it still needs](cuda-01-user-space-and-kernel.md). Where the line runs, the three device files, the kernel module and firmware that stay NVIDIA's.
2. [Reading the open kernel module's headers: escapes, classes and controls](cuda-02-reading-the-headers.md). The three kinds of number in the RM API, and splitting control commands in Omega.
3. [ioctl request numbers: four fields, one 32-bit word](cuda-03-ioctl-numbers.md). Compute them from the header, including struct padding, and check them against CUDApp's own literals and the Omega compiler's `devctl` rule.
4. [GPU objects: the resource-manager tree, handles and classes](cuda-04-rm-object-tree.md). The allocation order from root client to compute object, modelled with refusals.
5. [The command ring: GPFIFO entries, method headers and the QMD](cuda-05-gpfifo-and-methods.md). Build and decode a real pushbuffer and ring entry; a header disagreement found on the way.
6. [Verifying with chip gates: receipts, mutants, and why a host run is not qualification](cuda-06-chip-gates-and-receipts.md). Re-check receipts yourself with a fail-closed verdict.
7. [Legal and ethical ground: interoperability, MIT headers, and what was never taken apart](cuda-07-legal-and-provenance.md). What the repository says, checked against the tree.
8. [Machine code: reading 16-byte GB10 instructions and their scheduling bits](cuda-08-sass-words.md). Decode the seed-built vector add, scoreboards included.

Start with lesson 1 even if you know CUDA well: the rest of the track hangs on its distinction between user space and the kernel.

## Run every example

```sh
SRC=/path/to/clones sh examples/cuda-03-ioctl-numbers/run.sh
```

Each `run.sh` takes `SRC` (the clone root) and `OMC` (the compiler, default `$SRC/omega-mv/seed/out/omc`), works in its own temporary directory, prints every exit status, and produces the same bytes on every run.
