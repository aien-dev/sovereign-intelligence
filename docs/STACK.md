# The stack, walked from the top down

Sovereign Intelligence (SI), built on AienOS, is ten layers. This page walks them from what you
touch down to the silicon: what each layer does, what it talks to below it, where its source is,
and how far it has really got.

Evidence words: **PROPOSED** (written down), **IMPLEMENTED** (code exists), **EXERCISED** (ran,
receipts kept), **QUALIFIED** (passed the hardware gate). Nothing is QUALIFIED yet; the three-run
physical GB10 qualification has not been run. Every repository's own evidence line is in the
[README index](../README.md#every-repository).

![The stack](stack.svg)

---

## 10. Apps and tools

What you touch. The one-command installer and the Omega wizard live in this repository under
`installer/`; it checks the machine, verifies the signed release and installs without sudo.
Around it are tools built on the same stack:
[aienos.com](https://github.com/aien-dev/aienos.com) (the site),
[aien-translate](https://github.com/aien-dev/aien-translate) (translation on my own model, no API key),
[readings-window](https://github.com/aien-dev/readings-window) (read-only GPU and CPU readings),
[omega-projects](https://github.com/aien-dev/omega-projects) (projects built with Aien).

- **Yours:** Apache-2.0 WITH LLVM-exception for the installer and site; AGPL-3.0 for several tools.
- **Evidence:** installer EXERCISED on host (33/33 under a read-only root, 6/6 in a container).
  A first token through the installer on a GPU is NOT_RUN.

## 9. Aien

One persistent identity across my machines: the iMac, the Pi, the Spark and the MacBook. Aien
is the guide you talk to; he speaks through the engine and remembers through Cortex. Allen has now
evolved into the final Aien (2026-10-26).

- **Source:** [aien](https://github.com/aien-dev/aien), AGPL-3.0.
- **Evidence:** PROPOSED. The programme, acceptance contract and data contracts are written; there
  is no code on `main` yet, and the Aien experience is not in the first release.

## 8. Cortex memory

Long-term memory on your own disk: lessons, decisions and facts, searched by keyword and meaning.
The Cortex running today is [cortex-rs](https://github.com/aien-dev/cortex-rs) (Rust, archived
repository). Its replacement is being rewritten in Omega in
[cortex](https://github.com/aien-dev/cortex).

- **Source:** [cortex](https://github.com/aien-dev/cortex) and [cortex-rs](https://github.com/aien-dev/cortex-rs), Apache-2.0.
- **Evidence:** IMPLEMENTED. In the Omega rewrite, the importer and the JSON number handling are
  EXERCISED on host against independent references; the server has not answered a real request
  yet, and parity with cortex-rs has not been run.

## 7. The engine: Sovereign Core

The runtime that serves the model: the `aien` command, paged KV cache, scheduler, an OpenAI-style
HTTP server, Omega GPU bindings and the test judge that checks every change. It calls CUDA++ and
Omega's GPU kernels below it.

- **Source:** [aien-sovereign-core-mv](https://github.com/aien-dev/aien-sovereign-core-mv), Apache-2.0.
  Receipts: [aien-receipts](https://github.com/aien-dev/aien-receipts).
  Measurements: [benchmarks-mv](https://github.com/aien-dev/benchmarks-mv).
- **Evidence:** EXERCISED on GB10 (serve runs with signed receipts; engine commit cf239078 passed
  SC-GB10-SERVE-CHAT once). Not hardware qualified; only one module is ported to Omega so far.

## 6. Math engine

My own math engine, written entirely in Omega, for Aien's science answers. The rule for Aien
is that he shows a result only when the engine succeeds and prints one; otherwise he says it is
not supported yet. The model never fills in numbers.

- **Source:** not yet published, so there is no link here yet.
- **Evidence:** no public receipt yet.

## 5. Omega language and compiler

The language everything moves into. `omc`, the compiler, is written in Omega and grows from a
408-byte seed loader; it compiles itself to the same bytes. Backends: AArch64 native code,
`irwasm` (WebAssembly) and `irspirv` (SPIR-V, in review).
[omega-bridge](https://github.com/aien-dev/omega-bridge) emits checked C and Python from a
bounded subset so other languages can call Omega. [omnet](https://github.com/aien-dev/omnet)
rewrites security-critical network code in it. This repository's index generator is Omega too:
[index/gen/index.om](../index/gen/index.om).

- **Source:** [omega-mv](https://github.com/aien-dev/omega-mv), Apache-2.0.
- **Evidence:** EXERCISED (seed gate, arm64 CI, GB10 runs with receipts). The migration of the
  older C is unfinished.

## 4. CUDA++ runtime

GPU programs with no NVIDIA user-space software: its own instruction encoder, code generator,
driver client over the kernel module's device files, and matmul, attention and MoE libraries.

- **Source:** [CUDApp](https://github.com/aien-dev/CUDApp), Apache-2.0.
  Related: [physics-mv](https://github.com/aien-dev/physics-mv) (FORGE, a native GB10 client).
- **Evidence:** EXERCISED (33 host test targets, on-chip logs, a zero-CUDA gate). Replacements for
  libcuda, cudart and cuBLAS are partial; cuFFT, cuRAND and NVML are missing.

## 3. Aienux kernel and AienOS

[Aienux](https://github.com/aien-dev/aienux) is the kernel: boot, scheduling, IPC and capability
boundaries. AienOS is the operating system around it, with its own home in
[AienOS-nv](https://github.com/aien-dev/AienOS-nv).

- **Yours:** Apache-2.0.
- **Evidence:** EXERCISED in QEMU, on a Pi 5 and on an iMac. The kernel has not booted on the
  Spark, so the SI alpha runs on the Spark's own Linux today. It is pre-alpha and not in the
  first release.

## 2. GPU kernel driver

Today SI talks to NVIDIA's open kernel module (580.173.02, Dual MIT/GPL) through its device
files. My own driver, aien-gpu, is being written in Omega inside
[CUDApp](https://github.com/aien-dev/CUDApp/blob/main/omega/slices/kmod.osc) and will be Dual
MIT/GPL-2.0.

- **Evidence:** PROPOSED for aien-gpu.

## 1. GB10 silicon and NVIDIA signed firmware

The hardware, and the firmware NVIDIA signs and loads onto it. I do not own this layer and cannot
change it. Saying so plainly is the point: everything above it is yours.

Beside the Spark, the Raspberry Pi 5 boot chain is open too:
[atlas](https://github.com/aien-dev/atlas) (a 1.5 KB boot seed that refuses an unverified next
stage) and the firmware mirrors listed in the index.

---

## How the layers agree

The specifications and decisions live in
[aien-architecture-mv](https://github.com/aien-dev/aien-architecture-mv) and
[aien-protocols-mv](https://github.com/aien-dev/aien-protocols-mv);
[INTERPLANE](https://github.com/aien-dev/interplane-mv) is the open protocol between models and
agent runtimes.
