# User space and the kernel: what CUDA++ replaces and what it still needs

Evidence level: IMPLEMENTED. The driver client exists in source at the pin, but CUDApp's README records current native qualification as NOT_RUN; this lesson's example is a host-only inspection.

## Goal

Know which parts of NVIDIA's stack run in your process, which run in the kernel, and where I cut the line when I built CUDA++.

## Explanation

When you run a CUDA program on Linux, two very different kinds of NVIDIA software are involved.

**User space** is everything loaded into your own process: the compiler output (`nvcc`, `ptxas`), the runtime library `libcudart`, the driver library `libcuda`, and the maths libraries such as cuBLAS. These are closed. Your program calls `cudaMalloc` or `cuLaunchKernel`, and somewhere inside `libcuda` that turns into system calls.

**The kernel** side is NVIDIA's kernel modules, `nvidia.ko` and `nvidia-uvm.ko`. Since 2022 NVIDIA publishes their source as [open-gpu-kernel-modules](https://github.com/NVIDIA/open-gpu-kernel-modules) under the MIT licence. Below the modules sits the GSP firmware that runs inside the GPU itself.

The key observation is simple: a user-space library cannot touch the hardware except through the kernel. Everything `libcuda` does to the GPU goes through `ioctl` calls on three device files, `/dev/nvidiactl`, `/dev/nvidia0` and `/dev/nvidia-uvm`, plus `mmap` of memory the kernel hands back. The kernel module defines every one of those calls in its public headers. So I did not need `libcuda` at all. I wrote my own client for those ioctls (`nvrm/nvrm.c` and `m16/` in CUDApp) and my own encoder for the GPU's machine code, and skipped every closed layer:

```
CUDA:    your code -> nvcc/ptxas -> libcudart -> libcuda -> nvidia.ko -> GPU
CUDA++:  your code -> my encoder -------> my runtime -----> nvidia.ko -> GPU
```

What CUDA++ still depends on, and I say this plainly:

- **NVIDIA's open kernel module**, version 580.173.02. CUDA++ is built against its headers and speaks only that interface. The module boots the GPU, builds page tables and schedules channels. Aien's own GB10 driver (work item L332) is being built to replace it; the roadmap marks it BUILDING, not done.
- **The GSP firmware.** It stays NVIDIA's. The chip checks its signature and boots nothing else. CUDA++ never ships it; NVIDIA's module loads it from the system's firmware folder.

There is one more honest detail. The library never links `libcuda`, but one interop tool does: `tools/interop/cubin_probe.c` exists to test whether NVIDIA's own driver accepts a cubin that CUDA++ exported. It is a separate Makefile target, not part of `libomega_gpu.a`. The example below finds it with the same grep that proves the rest of the tree is clean.

Also note the state of the evidence. The README at this pin calls the imported M16 receipt (the chip proof of this driver client) an unauditable historical summary, because its raw logs are absent, and says current native qualification is NOT_RUN. Lesson 6 checks that yourself.

## Example

A host-only inspection of the pinned CUDApp tree. It opened no device. The shell listing is retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read [POINTER.md](../examples/cuda-01-user-space-and-kernel/POINTER.md). The recorded output below is that host run, not a new run and not a hardware result.

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (not needed by this inspection; checked so every lesson pins the same tools)
== 1. the build promise (Makefile header)
2:# CUDA++ build. Plain make + gcc; no CUDA toolkit, no NVIDIA user-space library.
== 2. files that include a CUDA header or link libcuda (first-party C, Makefile, mk/)
Makefile
tools/interop/cubin_probe.c
   the Makefile line that links it, and the target it belongs to:
65:	$(CC) $(CFLAGS) -I$(CUDA_INC) -o $@ tools/interop/cubin_probe.c $(OUT_DIR)/libomega_gpu.a -L$(CUDA_LIB) -lcuda -lpth
== 3. the three device files the driver client opens (kernel entry points)
nvrm/nvrm.c:233:    snprintf(path, sizeof path, "/dev/nvidia%u", rm->minor);
nvrm/nvrm.c:243:    int fd = system ? open("/dev/nvidiactl", O_RDWR | O_CLOEXEC) : open_dev_fd(rm);
nvrm/nvrm.c:299:    rm->fd_ctl = open("/dev/nvidiactl", O_RDWR | O_CLOEXEC);
nvrm/nvrm.c:300:    rm->fd_uvm = open("/dev/nvidia-uvm", O_RDWR | O_CLOEXEC);
nvrm/nvrm.c:301:    rm->fd_uvm2 = open("/dev/nvidia-uvm", O_RDWR | O_CLOEXEC);
native/nvrm/context.om:4:text nvctl "/dev/nvidiactl"
native/nvrm/context.om:5:text nvdev "/dev/nvidia0"
native/nvrm/context.om:6:text nvuvm "/dev/nvidia-uvm"
== 4. what came from the kernel side: the open module's headers, by folder
   5 headers in kernel-open/common/inc
   3 headers in kernel-open/nvidia-uvm
   57 headers in src/common/sdk/nvidia/inc
   2 headers in src/nvidia/arch/nvalloc/unix/include
   67 headers listed in SHA256SUMS
== 5. what still belongs to NVIDIA below the line (ROADMAP.md)
 `nvidia.ko` | AIEN's own GB10 driver (L332) | BUILDING 
 `nvidia-uvm.ko` | same driver: GPU page tables, allocator, channels (L193 cut D, L332) | BUILDING 
 GSP firmware (`gsp_*.bin`) | stays NVIDIA's: the chip checks its signature | not replaceable 
```

Read it top to bottom: the build promise, the single place that links `libcuda` (the interop probe), the three device files that are the whole kernel boundary (in the C client and in the native `.om` continuation `native/nvrm/context.om`), the 67 NVIDIA headers by folder, and the two kernel modules plus firmware that remain NVIDIA's.

## Common mistake

Saying "CUDA++ uses no NVIDIA software". It uses no NVIDIA **user-space** software at run time. The kernel modules and the signed firmware are still NVIDIA's, and the code is tied to one module version (580.173.02). A machine with another module version is refused by `make doctor` rather than guessed at. Say "no CUDA user-space libraries", and name the kernel module and firmware.

## Where to go deeper

- [docs/HOW_I_DID_IT.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/HOW_I_DID_IT.md): the whole method in four steps.
- [docs/DRIVER.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/DRIVER.md): every device file and call in order.
- [ROADMAP.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/ROADMAP.md): every NVIDIA piece on the Spark with its status.
- [docs/START_HERE.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/START_HERE.md): host checks versus real GB10 runs.
- [nvrm/nvrm.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/nvrm/nvrm.c) and its native Omega continuation [native/nvrm/context.om](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/native/nvrm/context.om).
