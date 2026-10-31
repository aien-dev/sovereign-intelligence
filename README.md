<div align="center">

# Sovereign Intelligence™ (SI)

**My own AI, on hardware I own, with every layer open to read, rebuild and change.**

Sovereign Intelligence: one command turns a DGX Spark into your own AI, with Omega and science tools and no NVIDIA user-space software. Alpha; Aien comes in a later release.

Sovereign Intelligence, built on [AienOS](https://github.com/aien-dev/AienOS-nv).

```sh
git clone --branch alpha-20261026.2 https://github.com/aien-dev/sovereign-intelligence && cd sovereign-intelligence && sh installer/install.sh
```

[Install](#install) · [The stack](#the-stack-and-whats-yours) · [Every repository](#every-repository) · [Deeper walk](docs/STACK.md) · [Naming](NAMING.md) · [aienos.com](https://www.aienos.com)

</div>

## Alpha: what it means and where it stands

**Alpha** means: someone other than me runs one command on a stock DGX Spark, gets a verified install, chats with Qwen3.6-35B on that Spark and uninstalls cleanly, and every public claim about it is backed by evidence from the exact binary shipped. **The alpha is not met yet.** The NOT_RUN rows below block it. Nothing is QUALIFIED.

| Exit criterion | Status | Evidence (pinned commit) |
| :--- | :--- | :--- |
| 1. One command installs a published release tag | EXERCISED | In a container on a DGX Spark, release `alpha-20261026.2`: `install-fake-gb10` and `install-real-sysfs` PASS, 6/6 with a canary control ([container/receipt.txt](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/container/receipt.txt)). Not yet on a stock Spark by another person (row 6). `installer/install.sh` on `main` names `alpha-20261029.1`, which has no published release ([install.sh line 21](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/installer/install.sh#L21)); the command above clones `alpha-20261026.2`, whose installer names its own tag. |
| 2. Any other machine is refused and left unchanged | EXERCISED | Host suite on a fake tree, `/` read-only: refusals for macOS, x86, no GPU, another GPU, an old driver ([host/suite.log lines 1-5, 22-28](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/host/suite.log#L1-L28)); container `refuse-darwin`, `refuse-nogpu` PASS. |
| 3. Verified install: Ed25519 signature and every SHA-256 checked before unpacking, a tampered bundle or model refused | EXERCISED | `tampered-bundle-refused`, `rewritten-sums-refused`, `missing-signature-refused`, `tampered-model-refused` PASS ([host/suite.log](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/host/suite.log#L11-L21)); container `tampered` exits 1 as required. |
| 4. Chat with Qwen3.6-35B on the Spark through the installed product | NOT_RUN | The wizard's first chat ran only against a fake engine ([notes/alpha-20261026.2.md line 51](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/notes/alpha-20261026.2.md#L51)). The engine binary itself serves the 35B on my Spark ([Core evidence/l387-motor-ship](https://github.com/aien-dev/aien-sovereign-core-mv/blob/d3dec0eb18818808212bdf99db5c8612bcfcb9ef/evidence/l387-motor-ship/README.md)), but a real install with the 37.5 GB download and a first token through this installer has not run ([line 52](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/notes/alpha-20261026.2.md#L52)). |
| 5. Clean uninstall | EXERCISED | On the fake tree: `uninstall-leaves-no-files`, `uninstall-asks-first`, `uninstall-keep-model`, `uninstall-everything` PASS ([host/suite.log](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/host/suite.log#L14-L33)); NVIDIA state of 162 packages identical before and after ([host/summary.txt](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/host/summary.txt)). Uninstall after a real GB10 install: NOT_RUN. |
| 6. Done by someone other than me, on a stock Spark | NOT_RUN | No outside tester run is recorded. |
| 7. Public claims backed by evidence from the exact shipped binary | EXERCISED | For the bundle: `SHA256SUMS.tested` is the signed SHA256SUMS of the assets the tests ran on ([evidence README line 6](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/evidence/alpha-20261026.2/README.md#L6)); the engine rebuilt from source to the same sha256 19173f9e ([notes line 47](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/notes/alpha-20261026.2.md#L47)). Every GPU claim through the installer is NOT_RUN (rows 4 and 8). |
| 8. Three physical qualification runs of the GPU path | NOT_RUN | [notes/alpha-20261026.2.md line 53](https://github.com/aien-dev/sovereign-intelligence/blob/dcae5bd49f4c4903525b42ff401f52a2393e9348/notes/alpha-20261026.2.md#L53). |

<br>

<p align="center">
  <img src="docs/stack.svg" alt="The Sovereign Intelligence stack, from GB10 silicon and NVIDIA's signed firmware at the bottom to apps at the top, each layer with its license and evidence level" width="880">
</p>

<br>

## Install

On an NVIDIA DGX Spark (Linux arm64, GB10, kernel driver 580.173.02), clone this repo at the release tag and run the installer from the source you just cloned. Nothing is fetched from a website: read [installer/install.sh](installer/install.sh) first if you like.

```sh
git clone --branch alpha-20261026.2 https://github.com/aien-dev/sovereign-intelligence && cd sovereign-intelligence && sh installer/install.sh
```

It checks the machine first (anything else gets a friendly note and nothing changes), downloads release [alpha-20261026.2](https://github.com/aien-dev/sovereign-intelligence/releases/tag/alpha-20261026.2) by exact tag (model: Qwen3.6-35B-A3B-FP8, 37.5 GB; the 27B is to come), verifies the Ed25519 signature of SHA256SUMS (alpha key ff949504…f54a, see [KEYS](KEYS)) and every SHA-256 before unpacking, installs into ~/.local/share/aienos (no sudo), and opens the Omega wizard. Remove everything with `aienos uninstall`.

Check a release by hand:

```sh
openssl pkeyutl -verify -pubin -inkey release.pub.pem -rawin -in SHA256SUMS -sigfile SHA256SUMS.sig && sha256sum -c SHA256SUMS
```

**Evidence:** installer EXERCISED (host 33/33 under read-only root, container 6/6 with a canary control). The engine is byte-identical (sha256 19173f9e…3aeb) to the build serving the 35B on my Spark, rebuilt from Core commit 59b05a71 (branch ship/motor-l387) to the same hash: EXERCISED, not QUALIFIED. A fresh GB10 install and first token through the installer, and the 3x physical qualification: NOT_RUN. The Aien experience is not in this release yet.

<br>

## The stack, and what's yours

Every layer above the silicon is source you can read, build and change. The bottom layer is the honest boundary: NVIDIA's signed firmware runs on the GB10 and I cannot change it, so I say so.

| | Layer | Yours: license and source | What you can change |
| :---: | :--- | :--- | :--- |
| 10 | **Apps and tools** | Apache-2.0 WITH LLVM-exception or AGPL-3.0, per repository: [installer](https://github.com/aien-dev/sovereign-intelligence), [aienos.com](https://github.com/aien-dev/aienos.com), [aien-translate](https://github.com/aien-dev/aien-translate) | Anything. The installer is a reviewed bootstrap shell exception, the only part of AienOS not written in Omega, that you can read before you run it. |
| 9 | **Aien** | AGPL-3.0: [aien](https://github.com/aien-dev/aien) | His identity, memory and voice contracts. |
| 8 | **Cortex memory** | Apache-2.0: [cortex-rs](https://github.com/aien-dev/cortex-rs) today, rewritten in Omega in [cortex](https://github.com/aien-dev/cortex) | What is remembered, where it is stored, when it is forgotten. |
| 7 | **The engine: Sovereign Core** | Apache-2.0: [aien-sovereign-core-mv](https://github.com/aien-dev/aien-sovereign-core-mv) | Scheduling, KV cache, serving and the test judge. |
| 6 | **Math engine** | My own engine, written in Omega. Source not yet published. | Nothing yet; it will be yours when it is published. |
| 5 | **Omega language and compiler** | Apache-2.0: [omega-mv](https://github.com/aien-dev/omega-mv), [omega-bridge](https://github.com/aien-dev/omega-bridge) | The language itself: omc, irwasm, irspirv (merged, CPU-exercised; not run on GPU / DPC++). |
| 4 | **CUDA++ runtime** | Apache-2.0: [CUDApp](https://github.com/aien-dev/CUDApp) | Instruction encoder, runtime and kernels, with no NVIDIA user-space software. |
| | **AienOS** | Apache-2.0 WITH LLVM-exception: [AienOS-nv](https://github.com/aien-dev/AienOS-nv) | The operating system around the kernel. SI alpha still runs on the Spark's own Linux. |
| 3 | **Aienux kernel** | Apache-2.0: [aienux](https://github.com/aien-dev/aienux) | The kernel: boot, scheduling, IPC and capability boundaries. Pre-alpha; physical runs on iMac and Pi 5. |
| 2 | **GPU kernel driver** | Today NVIDIA's open kernel module 580.173.02 (Dual MIT/GPL). Mine, aien-gpu, is being written in [CUDApp](https://github.com/aien-dev/CUDApp/blob/main/omega/slices/kmod.osc) (Dual MIT/GPL-2.0). | NVIDIA's module source is open; aien-gpu will replace it. |
| 1 | **GB10 silicon and NVIDIA signed firmware** | Not mine. | Nothing. This is the boundary, stated plainly. |

Evidence words mean one thing each: **PROPOSED** (written down), **IMPLEMENTED** (code exists), **EXERCISED** (ran, with kept receipts), **QUALIFIED** (passed the hardware gate). Nothing is QUALIFIED yet. The walk down the stack, layer by layer, is in [docs/STACK.md](docs/STACK.md).

<br>

## Every repository

Every public repository in [aien-dev](https://github.com/aien-dev), grouped by layer. This section and [index/repos.json](index/repos.json) are rebuilt every hour from GitHub by an Omega program; the layer, purpose and evidence come from the hand-curated [index/curated.yml](index/curated.yml).

<!-- index:begin (generated by index/gen/index.om; edit index/curated.yml instead) -->

90 public repositories in [aien-dev](https://github.com/aien-dev): 69 active, 21 archived. Machine-readable: [index/repos.json](index/repos.json).

### Silicon, firmware and boot

The GB10 and NVIDIA's signed firmware are the boundary I do not own. Above it, the boot chain is mine.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [atlas](https://github.com/aien-dev/atlas) | A 1.5 KB AArch64 boot seed that refuses any next stage whose SHA-256 does not match | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [edk2-non-osi](https://github.com/aien-dev/edk2-non-osi) | Mirror of EDK II non-OSI binaries for the Pi 5 chain *(fork)* | `n/a` | none | 2026-10-25 |
| [rpi5-uefi](https://github.com/aien-dev/rpi5-uefi) | Raspberry Pi 5 UEFI build, submodules pointed at my mirrors *(fork)* | `n/a` | none | 2026-10-25 |

### GPU kernel driver

NVIDIA's open kernel module today; my own driver, aien-gpu, is being written inside CUDA++.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [omega-gpu-driver](https://github.com/aien-dev/omega-gpu-driver) | GB10 GPU driver in seeded Omega; W0 binds, reads identity and releases. Exercised in QEMU only, never run on GB10 | `EXERCISED` | none | 2026-10-29 |

### Kernel and operating system

Aienux, the kernel, and AienOS, the operating system SI is built on.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [aienix](https://github.com/aien-dev/aienix) | Older front door that pins the main components as submodules | `PROPOSED` | AGPL-3.0-or-later | 2026-10-29 |
| [AienOS-nv](https://github.com/aien-dev/AienOS-nv) | AienOS's own home: what the OS layer is and how to get it through SI | `n/a` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [aienux](https://github.com/aien-dev/aienux) | Aienux, the AienOS kernel: boot, scheduling, IPC and capabilities. Pre-alpha, not in the alpha bundle | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [rtl8127-omega](https://github.com/aien-dev/rtl8127-omega) | Realtek RTL8127 10GbE driver in Omega, checked only against a software model of the chip; never run on a real chip | `IMPLEMENTED` | Apache-2.0 | 2026-10-28 |

### CUDA++ runtime

GPU programs with no NVIDIA user-space software.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [CUDApp](https://github.com/aien-dev/CUDApp) | CUDA++: my GPU runtime, instruction encoder and kernels for GB10; home of the aien-gpu driver work | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [physics-mv](https://github.com/aien-dev/physics-mv) | FORGE: request-bound machine realization, a native GB10 client over the open ioctls, boot gates | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |

### Omega language and compiler

The language everything moves into: omc, irwasm, irspirv, and libraries written in it.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [babel](https://github.com/aien-dev/babel) | Translates C through Omega into Rust, C, Python, C++, Zig and Go with differential checks; one narrow C profile, the rest refused | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [compiler-explorer](https://github.com/aien-dev/compiler-explorer) | Fork of Compiler Explorer; main is upstream, Omega language support is on the unmerged add-omega-language branch *(fork)* | `n/a` | BSD-2-Clause | 2026-10-27 |
| [ggml-omega](https://github.com/aien-dev/ggml-omega) | ggml/llama.cpp backend running ops through seeded-Omega kernels; main holds only the README, the code is on unmerged branches | `PROPOSED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [homebrew-omega](https://github.com/aien-dev/homebrew-omega) | Homebrew tap that builds omc from the 408-byte seed and refuses a wrong sha256; Linux arm64 only | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [infra](https://github.com/aien-dev/infra) | Fork of Compiler Explorer's infrastructure; main is upstream, omc installation is on the unmerged add-omega branch *(fork)* | `n/a` | BSD-2-Clause | 2026-10-27 |
| [omega-blas](https://github.com/aien-dev/omega-blas) | BLAS in Omega behind the CBLAS ABI, with an interim C layer; the cuBLAS replacement track. Netlib tests logged on the host, no GPU run | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [omega-bridge](https://github.com/aien-dev/omega-bridge) | Emits checked C and Python from a bounded .om subset, so other languages can call Omega | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [omega-bridge-kit](https://github.com/aien-dev/omega-bridge-kit) | Mac test kit that drives omega-bridge conversions on the Spark over ssh and compares every form | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [omega-dnn](https://github.com/aien-dev/omega-dnn) | Deep-learning primitives in seeded Omega with ONNX semantics, the cuDNN replacement track; its tests are not on main | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [omega-harness](https://github.com/aien-dev/omega-harness) | Skills that teach agents to write Omega and label evidence honestly | `IMPLEMENTED` | Apache-2.0 | 2026-10-29 |
| [omega-kernel-template](https://github.com/aien-dev/omega-kernel-template) | Template repository: push a kernel.om and CI runs it on AArch64 and as SPIR-V on PoCL against a Python reference | `EXERCISED` | Apache-2.0 | 2026-10-28 |
| [omega-lift](https://github.com/aien-dev/omega-lift) | Work in progress: a bounded C and Python to Omega lifter, the inverse of omega-bridge | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [omega-mcp](https://github.com/aien-dev/omega-mcp) | MCP server written in Omega: compiles and runs .om with the pinned omc in a sandbox, explains errors, looks up keywords | `EXERCISED` | Apache-2.0 | 2026-10-28 |
| [omega-mv](https://github.com/aien-dev/omega-mv) | Omega: seeded .om compiler, backends, GB10 kernels, specs and gates. [irspirv](https://github.com/aien-dev/omega-mv/blob/3a10bd29fb7debdcf2c8f5cb58680cc74cb5b1f3/docs/SPIRV.md): CPU-exercised ([receipt](https://github.com/aien-dev/omega-mv/blob/3a10bd29fb7debdcf2c8f5cb58680cc74cb5b1f3/evidence/IRSPIRV/20261026-4ad014ed3/receipt.json)); not run on GPU / DPC++. | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [omega-packages](https://github.com/aien-dev/omega-packages) | Nix, Guix, AUR, .deb and container recipes that build omc from the 408-byte seed and check its sha256; arm64 Linux | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [omega-rosetta](https://github.com/aien-dev/omega-rosetta) | Rosetta Code tasks and exercises in Omega, checked in CI against independent references | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [omega-seed-challenge](https://github.com/aien-dev/omega-seed-challenge) | Rebuild omc from 408 hand-written bytes and check every rung's hash; CI runs it and posted results are checked | `EXERCISED` | Apache-2.0 | 2026-10-28 |
| [omnet](https://github.com/aien-dev/omnet) | Security-critical network and crypto code rewritten in Omega | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [omtex](https://github.com/aien-dev/omtex) | Write papers in Omega: an .om library emits escaped LaTeX and compiles its Omega listings; reproduces two published papers | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [tree-sitter-omega](https://github.com/aien-dev/tree-sitter-omega) | tree-sitter grammar for Omega, its parse coverage measured against every .om in omega-mv | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [vscode-omega](https://github.com/aien-dev/vscode-omega) | VS Code extension for Omega: highlighting checked against tree-sitter-omega, snippets, omc diagnostics and formatting | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |

### The engine: Sovereign Core

Inference, scheduling, evidence and the measurements behind every claim.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [aegis-runtime-mv](https://github.com/aien-dev/aegis-runtime-mv) | Agent runtime: WebSocket, SSE and REST gateway, heartbeats, workflow DAG | `EXERCISED` | AGPL-3.0-or-later | 2026-10-29 |
| [aien-receipts](https://github.com/aien-dev/aien-receipts) | Append-only signed verification receipts by repository and commit | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [aien-sovereign-core-mv](https://github.com/aien-dev/aien-sovereign-core-mv) | Sovereign Core: the aien runtime, paged KV cache, scheduler, HTTP server and test judge | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [aien-train](https://github.com/aien-dev/aien-train) | Plan for training my own language model on my own engine | `PROPOSED` | AGPL-3.0-or-later | 2026-10-29 |
| [BabelStream](https://github.com/aien-dev/BabelStream) | Fork of UoB-HPC BabelStream; main is upstream, a serial Omega model is on the unmerged omega-model branch *(fork)* | `n/a` | NOASSERTION | 2026-10-27 |
| [benchmarks-mv](https://github.com/aien-dev/benchmarks-mv) | Measurement harnesses and evidence bundles for GB10 | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [gpu-head-to-head](https://github.com/aien-dev/gpu-head-to-head) | Predeclared protocol and harness for aien-serve-http vs vLLM vs llama.cpp on one Spark; no results table on main yet | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [omega-gpu-bench](https://github.com/aien-dev/omega-gpu-bench) | Kit to run Omega-written GPU kernels on your own NVIDIA GPU; kernels withdrawn pending a clean-room cubin writer, so it reports NOT_RUN | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [openaccel-lab](https://github.com/aien-dev/openaccel-lab) | Cross-backend kernel conformance and performance lab: OpenCL C, Triton, HIP, CUDA and Omega entrants against float64 references, with wrong-kernel controls; CI rows are CPU evidence | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [spark-rsi-mv](https://github.com/aien-dev/spark-rsi-mv) | Self-improvement loop with a separate judge, a signed ledger and a promotion gate | `EXERCISED` | AGPL-3.0-or-later | 2026-10-29 |
| [spark-supervisor](https://github.com/aien-dev/spark-supervisor) | Process supervisor with health polls and restart backoff | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |

### Cortex memory

Long-term memory that stays on your machine.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [cortex](https://github.com/aien-dev/cortex) | Cortex memory server being rewritten in Omega (work in progress, branch wip/omega-cortex); parity with cortex-rs not yet run; live Cortex is still cortex-rs | `IMPLEMENTED` | Apache-2.0 | 2026-10-28 |

### Aien

One persistent identity across my machines.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [aien](https://github.com/aien-dev/aien) | Aien (formerly Allen): plans for one persistent identity across the iMac, Pi, Spark and MacBook | `PROPOSED` | AGPL-3.0-or-later | 2026-10-29 |
| [omega-projects](https://github.com/aien-dev/omega-projects) | Projects built with Aien; I review each before it goes live | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |

### Apps, tools and the front door

What you touch: the installer, the site, and tools built on the stack.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [agent-archive](https://github.com/aien-dev/agent-archive) | Turns Claude, Codex, OpenCode, Gemini and Muse chat logs into one JSONL archive | `IMPLEMENTED` | AGPL-3.0-or-later | 2026-10-29 |
| [aien-edge](https://github.com/aien-dev/aien-edge) | Static-site server with brotli and ACME; parked, never deployed | `IMPLEMENTED` | AGPL-3.0-or-later | 2026-10-29 |
| [aien-rig](https://github.com/aien-dev/aien-rig) | Plan for local AI and frame-rate tuning on RTX gaming PCs | `PROPOSED` | AGPL-3.0-or-later | 2026-10-29 |
| [aien-translate](https://github.com/aien-dev/aien-translate) | translate.js server backed by my own local model, no API key | `IMPLEMENTED` | AGPL-3.0-or-later | 2026-10-29 |
| [aienos.com](https://github.com/aien-dev/aienos.com) | Source of aienos.com, deployed by GitHub Pages; a rewrite generated by seeded Omega is a draft (aienos.com#122), not deployed | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [mobhub](https://github.com/aien-dev/mobhub) | Faction operations tool for Torn City; a side project outside AienOS | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [open-humanity](https://github.com/aien-dev/open-humanity) | Opt-in, privacy-first assistance network, volunteer compute, and volunteer inference (Spark owners answer Aien overflow; routing off) | `PROPOSED` | Apache-2.0 | 2026-10-29 |
| [pi-register](https://github.com/aien-dev/pi-register) | Register of what a Linux server runs and why | `IMPLEMENTED` | AGPL-3.0-or-later | 2026-10-29 |
| [readings-window](https://github.com/aien-dev/readings-window) | Read-only, token-gated window onto the Spark's GPU and CPU readings | `EXERCISED` | AGPL-3.0-or-later | 2026-10-29 |
| [sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence) | This repo: the front door, the one-command installer and signed releases | `n/a` | Apache-2.0 WITH LLVM-exception | 2026-10-29 |
| [spark-connector](https://github.com/aien-dev/spark-connector) | Plan for a volunteer DGX Spark verification connector | `PROPOSED` | AGPL-3.0-or-later | 2026-10-29 |
| [t3code](https://github.com/aien-dev/t3code) | Fork of t3code with one pending contribution (message reactions) *(fork)* | `IMPLEMENTED` | MIT | 2026-10-18 |

### Design, protocols and proof

The specs, decisions and protocols the layers agree on.

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [.github](https://github.com/aien-dev/.github) | Organization profile, Constitution, Covenant and contribution guidance | `n/a` | Apache-2.0 | 2026-10-29 |
| [aien-architecture-mv](https://github.com/aien-dev/aien-architecture-mv) | How it all fits: ADRs, doctrine, plans, gates and crumb tools | `PROPOSED` | AGPL-3.0-or-later | 2026-10-29 |
| [aien-protocols-mv](https://github.com/aien-dev/aien-protocols-mv) | Wire formats and schemas with test vectors and checkers | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [hive-not-swarm](https://github.com/aien-dev/hive-not-swarm) | Preprint: control, flow and collapse in human-directed coding-agent teams; not peer reviewed | `n/a` | CC-BY-4.0 | 2026-10-29 |
| [interplane-mv](https://github.com/aien-dev/interplane-mv) | INTERPLANE: an open protocol between models and agent runtimes | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [interplane.io](https://github.com/aien-dev/interplane.io) | Source of interplane.io | `IMPLEMENTED` | AGPL-3.0-or-later | 2026-10-29 |
| [synapse](https://github.com/aien-dev/synapse) | Agent-native signed changesets with Git and Radicle interop | `EXERCISED` | Apache-2.0 | 2026-10-29 |
| [synapse-board](https://github.com/aien-dev/synapse-board) | Generates the human board from the synapse-claims ledger, the repo map and pulse findings | `EXERCISED` | Apache-2.0 | 2026-10-28 |
| [synapse-claims](https://github.com/aien-dev/synapse-claims) | Signed, hash-chained lease ledger for agents; its source does not yet compile with the pinned omc | `PROPOSED` | Apache-2.0 WITH LLVM-exception | 2026-10-27 |
| [synapse-map](https://github.com/aien-dev/synapse-map) | Repository map for agents: where, tree, new, check; its source does not yet compile with the pinned omc | `PROPOSED` | Apache-2.0 WITH LLVM-exception | 2026-10-28 |
| [synapse-mcp](https://github.com/aien-dev/synapse-mcp) | MCP server exposing the synapse tools to agents; parked, not compiled, no tests | `PROPOSED` | Apache-2.0 | 2026-10-28 |
| [synapse-pulse](https://github.com/aien-dev/synapse-pulse) | Reconciles the synapse-claims ledger against GitHub and live agent sessions; its source does not yet compile with the pinned omc | `PROPOSED` | Apache-2.0 | 2026-10-28 |

<details>
<summary><b>Archived (21)</b>: read-only history, kept for the record</summary>

| Repository | What it is | Evidence | License | Last push |
| :--- | :--- | :---: | :--- | :--- |
| [aien-harness](https://github.com/aien-dev/aien-harness) | MCP harness with schema checks and failure replay; now in Core | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [aien-local-stack](https://github.com/aien-dev/aien-local-stack) | One-process composition of the agent runtime and Core | `EXERCISED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [aien-yardsticks](https://github.com/aien-dev/aien-yardsticks) | Outside reference oracles I measured against | `IMPLEMENTED` | AGPL-3.0-or-later | 2026-10-26 |
| [arm-trusted-firmware](https://github.com/aien-dev/arm-trusted-firmware) | Mirror of Trusted Firmware-A for the Pi 5 chain *(fork)* | `n/a` | NOASSERTION | 2026-10-15 |
| [cortex-rs](https://github.com/aien-dev/cortex-rs) | The first Cortex memory server, SQLite FTS5 plus vectors; still the live Cortex | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [crumb-spec-mv](https://github.com/aien-dev/crumb-spec-mv) | The Crumb protocol spec and a hash-chained ledger | `PROPOSED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [edk2](https://github.com/aien-dev/edk2) | Mirror of EDK II for the Pi 5 firmware chain *(fork)* | `n/a` | NOASSERTION | 2026-10-15 |
| [edk2-platforms](https://github.com/aien-dev/edk2-platforms) | Mirror of edk2-platforms for the Pi 5 chain *(fork)* | `n/a` | NOASSERTION | 2024-03-15 |
| [encounter](https://github.com/aien-dev/encounter) | Research commons idea; README only | `PROPOSED` | none | 2026-10-13 |
| [harvester](https://github.com/aien-dev/harvester) | Pulled reasoning traces into datasets; now in Core | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [MojoLlama](https://github.com/aien-dev/MojoLlama) | CPU inference engine in Mojo and C; dropped with Mojo and MAX | `EXERCISED` | Apache-2.0 | 2026-10-26 |
| [odysseus](https://github.com/aien-dev/odysseus) | Fork of a self-hosted AI workspace with a stable prompt prefix *(fork)* | `IMPLEMENTED` | AGPL-3.0 | 2026-10-14 |
| [physics0](https://github.com/aien-dev/physics0) | Retired and empty; the learner moved into Omega | `n/a` | Apache-2.0 | 2026-10-03 |
| [rad-id-sync](https://github.com/aien-dev/rad-id-sync) | Fingerprints SSH and Radicle keys into one identity record | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [spark-adapters](https://github.com/aien-dev/spark-adapters) | Provider router and verifier; now in Core | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [spark-crumbs-mv](https://github.com/aien-dev/spark-crumbs-mv) | Older crumb ledger CLI | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [spark-debugger](https://github.com/aien-dev/spark-debugger) | Service watchdog with an incident log | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [spark-dream](https://github.com/aien-dev/spark-dream) | Idle-time daemon that wrote notes into Cortex | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [spark-hive](https://github.com/aien-dev/spark-hive) | Hex-grid event store and plan generator | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [spark-inquisitor](https://github.com/aien-dev/spark-inquisitor) | Diff auditor for telemetry, secrets and banned wording | `IMPLEMENTED` | Apache-2.0 WITH LLVM-exception | 2026-10-26 |
| [translate](https://github.com/aien-dev/translate) | Preserved translate.js fork with pinned publish Actions *(fork)* | `n/a` | MIT | 2026-10-26 |

</details>

<!-- index:end -->

<br>

## How the index stays current

- [index/gen/index.om](index/gen/index.om) is the generator, written in Omega and compiled with the pinned omc.
- The [index-sync](.github/workflows/index-sync.yml) workflow runs hourly, on demand, and on a `repository_dispatch` of type `index-sync`. It opens one pull request labelled `automerge`, which merges only after the `index-check` job passes. Until the organization lets Actions open pull requests, it pushes the `bot/index-sync` branch and a person opens the pull request.
- A public repository with no entry in [index/curated.yml](index/curated.yml) makes the generator fail with exit 1 and name it. Nothing goes missing silently.
- **Rule for every change:** when a repository's purpose, status or links change, or a new repository appears, update its entry in index/curated.yml in the same piece of work.

<br>

## Human-Directed Agentic Engineering

Development follows Human-Directed Agentic Engineering (HDAE): humans define goals, architecture, constraints, acceptance criteria, and stopping points; agents implement, execute checks, diagnose failures, and revise within those boundaries. Human review retains responsibility for claims, acceptance, and release decisions.

For the documented method and a systems-software case study, see Gregory M. Kurtzer, [*Ginux: Building an Independent Kernel That Runs Linux Userspace through Human-Directed Agentic Engineering* (2026)](https://doi.org/10.5281/zenodo.23682548). This concerns engineering, not product runtime autonomy, endorsement, or retrospective qualification of earlier experiments.

## More

- [What I am building](docs/WHAT-I-AM-BUILDING.md): every repository, what it really does, and how far it has got
This repository is where Sovereign Intelligence releases come together, where install starts, and where the Spark test runs. AienOS is the operating system part of that whole.

- [Learn](docs/learn/README.md): five tracks on how I built it (from vibe coding to engineering, CUDA++, Omega, a sovereign stack, orchestrating agents). The examples are seeded Omega plus recorded host output. The shell runners are retired (Part of #31).
- [Agent Academy](docs/academy/README.md): free rules for your coding agent and 20 written tasks. The shell exam harness is retired (Part of #31). There is no generated score.
- [About the engineer](https://www.aienos.com/engineer/)
- [Naming](NAMING.md): how to write Sovereign Intelligence (SI) and AienOS
- [NOTICE](NOTICE) and [LICENSE](LICENSE): Apache-2.0 WITH LLVM-exception

<br>

<sub>"Sovereign Intelligence" and "SI" are trademarks of Drake Stapleton. NVIDIA, CUDA and GB10 are trademarks of NVIDIA Corporation.</sub>
