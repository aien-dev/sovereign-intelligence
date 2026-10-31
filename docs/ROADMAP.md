# Roadmap: the stack, from the silicon up

Sovereign Intelligence (SI) is meant to grow into the ten layers below, with AienOS as its operating
system. This page is the roadmap, not a description of the alpha. What the alpha ships today, and
its exit criteria, are at the top of the [README](../README.md). Only layer 10 (the installer) and
the layer 7 engine binary are in the alpha release.

What the alpha contains, by owner:

- **Mine, source published:** the installer and Omega wizard (layer 10, this repository) and the
  engine binary `aien-serve-http`, sha256 19173f9e, built from
  [aien-sovereign-core-mv](https://github.com/aien-dev/aien-sovereign-core-mv) commit 59b05a71
  with omega-mv's `libomega_gpu.a` linked in (layer 7; see [NOTICE](../NOTICE)).
- **Qwen's:** the Qwen/Qwen3.6-35B-A3B-FP8 weights (revision 95a723d0, 37.5 GB), which the wizard
  downloads from Hugging Face under their own Apache-2.0 licence. They are not part of the release.
- **NVIDIA's:** DGX OS Linux, the open kernel module 580.173.02 (layer 2 today) and the signed
  firmware on the GB10 (layer 1).
- **Not in the alpha:** Aien (9), Cortex (8), the math engine (6), Omega on the GPU (5), CUDA++ as
  a separate runtime (4), Aienux and AienOS (3a, 3b) and my own driver aien-gpu (2).

Evidence words: **PROPOSED** (written down), **IMPLEMENTED** (code exists), **EXERCISED** (ran,
receipts kept), **QUALIFIED** (passed the hardware gate). **NOT_RUN** means the check exists or is
named but has not been run. Nothing is QUALIFIED yet; the three-run physical GB10 qualification has
not been run.

Every status below names the repository, the commit it was read at and the evidence file. A status
is only as current as that commit: when a layer moves, the citation moves with it. Statuses were
read on 2026-10-31.

![The stack](stack.svg)

| | Layer | Status | Repository at commit | Evidence file |
| :---: | :--- | :--- | :--- | :--- |
| 10 | Apps and tools: the installer | EXERCISED (host and container, not on a GB10) | [sovereign-intelligence@dcae5bd4](https://github.com/aien-dev/sovereign-intelligence/tree/dcae5bd49f4c4903525b42ff401f52a2393e9348) | [evidence/alpha-20261026.2/host/summary.txt](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/host/summary.txt), [container/receipt.txt](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/container/receipt.txt) |
| 9 | Aien | PROPOSED (Aien himself); programme tooling EXERCISED offline on host | [aien@c149760e](https://github.com/aien-dev/aien/tree/c149760e8722ed943abcc5e3c7a33e2065b4036c) | [docs/MISSION.md](https://github.com/aien-dev/aien/blob/c149760e8722ed943abcc5e3c7a33e2065b4036c/docs/MISSION.md); [goal-microjobs receipt.json](https://github.com/aien-dev/aien/blob/c149760e8722ed943abcc5e3c7a33e2065b4036c/evidence/goal-microjobs/offline-20261024T182027Z-rdcMbK/receipt.json) |
| 8 | Cortex memory (Omega rewrite) | EXERCISED on host (claims parity) | [cortex@ab7343ef](https://github.com/aien-dev/cortex/tree/ab7343ef427c40dc2820c93074defb5920ae545a) (default branch `wip/omega-cortex`) | [evidence/claims/summary.txt](https://github.com/aien-dev/cortex/blob/ab7343ef427c40dc2820c93074defb5920ae545a/evidence/claims/summary.txt) |
| 7 | The engine: Sovereign Core | EXERCISED on GB10 | [aien-sovereign-core-mv@d3dec0eb](https://github.com/aien-dev/aien-sovereign-core-mv/tree/d3dec0eb18818808212bdf99db5c8612bcfcb9ef) | [evidence/l387-motor-ship/README.md](https://github.com/aien-dev/aien-sovereign-core-mv/blob/d3dec0eb18818808212bdf99db5c8612bcfcb9ef/evidence/l387-motor-ship/README.md) |
| 6 | Math engine | PROPOSED (no public source, no receipt) | none published | none |
| 5 | Omega language and compiler | EXERCISED on CPU | [omega-mv@474197e4](https://github.com/aien-dev/omega-mv/tree/474197e4fa0207e0e2fb3c0494594a975f5031fa) | [seed/out/omc.sha256](https://github.com/aien-dev/omega-mv/blob/474197e4fa0207e0e2fb3c0494594a975f5031fa/seed/out/omc.sha256); [evidence/IRSPIRV/20261026-4ad014ed3/receipt.json](https://github.com/aien-dev/omega-mv/blob/474197e4fa0207e0e2fb3c0494594a975f5031fa/evidence/IRSPIRV/20261026-4ad014ed3/receipt.json) |
| 4 | CUDA++ runtime | EXERCISED on GB10 | [CUDApp@e7cc7d69](https://github.com/aien-dev/CUDApp/tree/e7cc7d69e4bac9e867c52afe37d3b7522cd7618c) | [evidence/CHIP-BATTERY-20261025/RECEIPT.md](https://github.com/aien-dev/CUDApp/blob/e7cc7d69e4bac9e867c52afe37d3b7522cd7618c/evidence/CHIP-BATTERY-20261025/RECEIPT.md) |
| 3b | AienOS | PROPOSED | [AienOS-nv@72c0cfa1](https://github.com/aien-dev/AienOS-nv/tree/72c0cfa17132c2f1ae94430c10090a4341e56c51) | none: the repository holds a README, LICENSE and NOTICE only |
| 3a | Aienux kernel | EXERCISED in QEMU, on a Pi 5 and on an iMac; never booted on the Spark | [aienux@edac0f1b](https://github.com/aien-dev/aienux/tree/edac0f1b14dcc469fceb18783aa92ff6d92645b2) | [pi5_hardware_runs_2026-10-13/README.md](https://github.com/aien-dev/aienux/blob/edac0f1b14dcc469fceb18783aa92ff6d92645b2/evidence/pi5_hardware_runs_2026-10-13/README.md), [imac_kernel1_2026-10-17/README.md](https://github.com/aien-dev/aienux/blob/edac0f1b14dcc469fceb18783aa92ff6d92645b2/evidence/imac_kernel1_2026-10-17/README.md) |
| 2 | GPU kernel driver: my own (aien-gpu, Omega GB10 driver) | IMPLEMENTED; W0 EXERCISED in QEMU only; never run on a GB10 | [CUDApp@e7cc7d69](https://github.com/aien-dev/CUDApp/tree/e7cc7d69e4bac9e867c52afe37d3b7522cd7618c), [omega-gpu-driver@07781415](https://github.com/aien-dev/omega-gpu-driver/tree/07781415c72719468f3cc2d76d10b4360bdb6979) | [omega/slices/kmod.osc](https://github.com/aien-dev/CUDApp/blob/e7cc7d69e4bac9e867c52afe37d3b7522cd7618c/omega/slices/kmod.osc); [qemu/w0-edu.log](https://github.com/aien-dev/omega-gpu-driver/blob/07781415c72719468f3cc2d76d10b4360bdb6979/qemu/w0-edu.log) |
| 1 | GB10 silicon and NVIDIA signed firmware | not mine; no status | none | none |

---

## 10. Apps and tools

What you touch. The one-command installer and the Omega wizard live in this repository under
`installer/`; it checks the machine, verifies the signed release and installs without sudo.
Around it are tools built on the same stack:
[aienos.com](https://github.com/aien-dev/aienos.com) (the site),
[aien-translate](https://github.com/aien-dev/aien-translate) (translation on my own model, no API key),
[readings-window](https://github.com/aien-dev/readings-window) (read-only GPU and CPU readings),
[omega-projects](https://github.com/aien-dev/omega-projects) (projects built with Aien).

- **Licence:** Apache-2.0 WITH LLVM-exception for the installer and site; AGPL-3.0 for several tools.
- **Status:** the installer is EXERCISED on host (33/33 under a read-only root) and in a container
  (6/6 with a canary control) for release `alpha-20261026.2`. A real install with a first token
  on a GB10 is NOT_RUN ([release notes, evidence table](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/notes/alpha-20261026.2.md#L42-L53)).
  The installer bootstrap is a reviewed shell exception; `installer/tools/` also holds two Python
  capture helpers. The tools beside it carry their own status in the [README index](../README.md#every-repository).

## 9. Aien

One persistent identity across my machines: the iMac, the Pi, the Spark and the MacBook. Aien
is the guide you talk to; he will speak through the engine and remember through Cortex. Allen has
now evolved into the final Aien (2026-10-26).

- **Source:** [aien](https://github.com/aien-dev/aien), AGPL-3.0.
- **Status:** Aien himself is PROPOSED: the mission and phase ledger are written
  ([docs/MISSION.md](https://github.com/aien-dev/aien/blob/c149760e8722ed943abcc5e3c7a33e2065b4036c/docs/MISSION.md)).
  The programme tooling on `main` (`src/goal_microjobs/*.om`, `src/bots/bots.om`) ran offline on
  host with a kept receipt
  ([goal-microjobs receipt.json](https://github.com/aien-dev/aien/blob/c149760e8722ed943abcc5e3c7a33e2065b4036c/evidence/goal-microjobs/offline-20261024T182027Z-rdcMbK/receipt.json)).
  The Aien experience is not in the alpha.

## 8. Cortex memory

Long-term memory on your own disk: lessons, decisions and facts, searched by keyword and meaning.
The Cortex running today is [cortex-rs](https://github.com/aien-dev/cortex-rs) (Rust, archived
repository). Its replacement is being rewritten in Omega in
[cortex](https://github.com/aien-dev/cortex).

- **Source:** [cortex](https://github.com/aien-dev/cortex) and [cortex-rs](https://github.com/aien-dev/cortex-rs), Apache-2.0.
- **Status:** the Omega rewrite is EXERCISED on host: the claims parity gate of 2026-10-26 passed
  332 of 332 requests against a cortex-rs oracle on a copy of a cortex-rs database
  ([evidence/claims/summary.txt](https://github.com/aien-dev/cortex/blob/ab7343ef427c40dc2820c93074defb5920ae545a/evidence/claims/summary.txt),
  default branch `wip/omega-cortex` at ab7343ef). It is not in the alpha.

## 7. The engine: Sovereign Core

The runtime that serves the model: the `aien` command, paged KV cache, scheduler, an OpenAI-style
HTTP server, Omega GPU bindings and the test judge that checks every change. It calls CUDA++ and
Omega's GPU kernels below it.

- **Source:** [aien-sovereign-core-mv](https://github.com/aien-dev/aien-sovereign-core-mv), Apache-2.0.
  Receipts: [aien-receipts](https://github.com/aien-dev/aien-receipts).
  Measurements: [benchmarks-mv](https://github.com/aien-dev/benchmarks-mv).
- **Status:** EXERCISED on GB10. The alpha ships engine sha256 19173f9e, built from Core commit
  59b05a71 (branch `ship/motor-l387`, not `main` or a tag); it is the build serving the 35B on my
  Spark, and its merge train passed goldens 5/5 and 3 of 3 red controls on the same commit
  ([evidence/l387-motor-ship/README.md](https://github.com/aien-dev/aien-sovereign-core-mv/blob/d3dec0eb18818808212bdf99db5c8612bcfcb9ef/evidence/l387-motor-ship/README.md)).
  Not hardware qualified.

## 6. Math engine

My own math engine, written entirely in Omega, for Aien's science answers. The rule for Aien
is that he shows a result only when the engine succeeds and prints one; otherwise he says it is
not supported yet. The model never fills in numbers.

- **Source:** not published.
- **Status:** PROPOSED. There is no public source and no public receipt, so no stronger word can
  be checked by anyone else. Until it is published this layer is not "yours to read".

## 5. Omega language and compiler

The language everything moves into. `omc`, the compiler, is written in Omega and grows from a
408-byte seed loader; it compiles itself to the same bytes. Backends: AArch64 native code,
`irwasm` (WebAssembly) and `irspirv` (SPIR-V, merged).
[omega-bridge](https://github.com/aien-dev/omega-bridge) emits checked C and Python from a
bounded subset so other languages can call Omega. [omnet](https://github.com/aien-dev/omnet)
rewrites security-critical network code in it. This repository's index generator is Omega too:
[index/gen/index.om](../index/gen/index.om).

- **Source:** [omega-mv](https://github.com/aien-dev/omega-mv), Apache-2.0.
- **Status:** EXERCISED on CPU. The seed chain's compiler hash is pinned in
  [seed/out/omc.sha256](https://github.com/aien-dev/omega-mv/blob/474197e4fa0207e0e2fb3c0494594a975f5031fa/seed/out/omc.sha256),
  and the `om-units` and `AIEN Checks` CI jobs passed on 474197e4
  ([om-units run](https://github.com/aien-dev/omega-mv/actions/runs/41197952008/job/124527830385)).
  `irspirv` matched 129 of 129 baseline cases on an AArch64 CPU with PoCL and no GPU
  ([receipt.json](https://github.com/aien-dev/omega-mv/blob/474197e4fa0207e0e2fb3c0494594a975f5031fa/evidence/IRSPIRV/20261026-4ad014ed3/receipt.json));
  it has not run on a GPU. The migration of the older C is unfinished.

## 4. CUDA++ runtime

GPU programs with no NVIDIA user-space software: its own instruction encoder, code generator,
driver client over the kernel module's device files, and matmul, attention and MoE libraries.

- **Source:** [CUDApp](https://github.com/aien-dev/CUDApp), Apache-2.0.
  Related: [physics-mv](https://github.com/aien-dev/physics-mv) (FORGE, a native GB10 client).
- **Status:** EXERCISED on GB10. The 2026-10-25 chip battery ran the host suite (33 targets), the
  zero-CUDA gate with its self-test and a first kernel with 0 wrong elements
  ([evidence/CHIP-BATTERY-20261025/RECEIPT.md](https://github.com/aien-dev/CUDApp/blob/e7cc7d69e4bac9e867c52afe37d3b7522cd7618c/evidence/CHIP-BATTERY-20261025/RECEIPT.md),
  source 60d6c57 on `feat/device-trace-emitter`). Replacements for libcuda, cudart and cuBLAS are
  partial; cuFFT, cuRAND and NVML are missing.

## 3b. AienOS

AienOS is the operating system around the kernel, with its own home in
[AienOS-nv](https://github.com/aien-dev/AienOS-nv). SI alpha runs on the Spark's own Linux, not on
AienOS.

- **Licence:** Apache-2.0 WITH LLVM-exception.
- **Status:** PROPOSED. AienOS-nv at 72c0cfa1 holds a README, LICENSE and NOTICE and no code. The
  installer in this repository is part of SI, not of AienOS, so its receipts do not count here.

## 3a. Aienux kernel

[Aienux](https://github.com/aien-dev/aienux) is the kernel: boot, scheduling, IPC and capability
boundaries.

- **Licence:** Apache-2.0.
- **Status:** EXERCISED in QEMU, on a Pi 5
  ([pi5_hardware_runs_2026-10-13](https://github.com/aien-dev/aienux/blob/edac0f1b14dcc469fceb18783aa92ff6d92645b2/evidence/pi5_hardware_runs_2026-10-13/README.md))
  and on a 2017 iMac
  ([imac_kernel1_2026-10-17](https://github.com/aien-dev/aienux/blob/edac0f1b14dcc469fceb18783aa92ff6d92645b2/evidence/imac_kernel1_2026-10-17/README.md)).
  It has not booted on the Spark. It is pre-alpha and not in the alpha.

## 2. GPU kernel driver

Today SI talks to NVIDIA's open kernel module (580.173.02, Dual MIT/GPL) through its device files;
that module is NVIDIA's, not mine. My own driver is being written in Omega in two places: the
aien-gpu policy slices in
[CUDApp omega/slices/kmod.osc](https://github.com/aien-dev/CUDApp/blob/e7cc7d69e4bac9e867c52afe37d3b7522cd7618c/omega/slices/kmod.osc)
(to be Dual MIT/GPL-2.0) and the VFIO driver in
[omega-gpu-driver](https://github.com/aien-dev/omega-gpu-driver).

- **Status:** IMPLEMENTED. omega-gpu-driver W0 (bind, read identity, release) is EXERCISED in QEMU
  only, against the QEMU `edu` device
  ([qemu/w0-edu.log](https://github.com/aien-dev/omega-gpu-driver/blob/07781415c72719468f3cc2d76d10b4360bdb6979/qemu/w0-edu.log)).
  Neither has run on a GB10.

## 1. GB10 silicon and NVIDIA signed firmware

The hardware, and the firmware NVIDIA signs and loads onto it. I do not own this layer and cannot
change it. Everything above it is meant to be yours; layers 6 and 3b are not yet.

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
