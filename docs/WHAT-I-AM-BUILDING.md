# What I am building

Drake Stapleton, 2026-10-26. This is an audit of every repository in the `aien-dev` GitHub organisation, written the day AienOS moved from pre-alpha to alpha testing. Each purpose line comes from reading the code, not from the README. Where the README promises more than the code does, I say so.

## How to read the evidence column

| Level | Meaning |
|---|---|
| PROPOSED | Design, plan or docs only. No code that does it. |
| IMPLEMENTED | Code exists. No recorded run proves the claim. Compiling is not evidence. |
| EXERCISED | Tests or runs are recorded in the repo (host, emulator, or a single hardware run). |
| QUALIFIED | Repeated physical-hardware qualification with receipts. **Nothing I build is QUALIFIED yet.** |

Host and emulator results are not hardware qualification. The GPU path has only ever run on one machine type, the NVIDIA DGX Spark (GB10, sm_121). The 3x physical qualification on that machine is NOT_RUN.

## What alpha testers get: Sovereign Intelligence

The downloadable package is called Sovereign Intelligence, built on AienOS, and this repo, `aien-dev/sovereign-intelligence`, is the home of the whole project. You clone this repo at a release tag and run `installer/install.sh` from that readable source (`git clone --branch <tag> https://github.com/aien-dev/sovereign-intelligence && cd sovereign-intelligence && sh installer/install.sh`); it checks the platform first, then downloads the signed bundle from this repo's GitHub Releases. Nothing is piped from a website into a shell. The first release is the pre-release `alpha-20261026.1`. A wizard written in Omega checks the machine, shows exactly what will change, asks first, installs into `~/.local/share/aienos` with no sudo, downloads the model from Hugging Face with a hash check for every file, and runs a first chat. It keeps NVIDIA's kernel driver and never touches NVIDIA or CUDA packages. An uninstaller and a rollback put everything back.

Where that stands today (details in `notes/alpha-20261026.1.md` and `evidence/alpha-20261026.1/`):

| Piece | Level |
|---|---|
| Installer, Omega wizard and uninstaller | EXERCISED on a fake GB10 tree and in a stock Ubuntu 24.04 arm64 container. |
| Signed release (Ed25519 over SHA256SUMS) | EXERCISED: sign, verify and a tamper control. It is an alpha key; I will rotate to a ceremony key before beta. |
| Engine links no CUDA library (`readelf` NEEDED shows only libc, libm, libgcc_s and the loader) | EXERCISED on the shipped binary. |
| Engine build `19173f9e` (Core `ship/motor-l387` 59b05a71) serving the 35B on a GB10 | EXERCISED: it is the live server's build (Core evidence/l387-motor-ship). |
| No CUDA library mapped while the model runs (`/proc/<pid>/maps`) | IMPLEMENTED; exercised only against a fake engine. |
| Real install, model download and first token on a GB10 | NOT_RUN. |
| 3x physical qualification of the GPU path | NOT_RUN. |

What that release does not do yet:

- It offers one model, Qwen3.6-35B-A3B FP8 (about 37.5 GB), since alpha-20261026.2, with the exact engine build my Spark serves it with: Core branch `ship/motor-l387`, commit 59b05a71, a development build, not a Core release tag. The 27B is to come; it is not offered.
- It only supports the DGX Spark. Every other machine gets a friendly "not supported yet" line and nothing is written.
- The local Aien experience (web app, gateway, local Cortex, Omega sandbox, science tools) is not in it. It follows as an update.
- The GPU path is the statically linked Omega GPU library from omega-mv. No separate CUDA++ runtime ships yet.

## Alpha product

| Repo | Visibility | What the code does | Language | Licence | Last activity | Main claim and its evidence |
|---|---|---|---|---|---|---|
| aien-sovereign-core-mv | public | Rust workspace of about 60 crates: the `aien` CLI and runtime, paged KV cache, scheduler, OpenAI-style HTTP server, Omega GPU bindings, test judge, installer, release tooling | Rust | Apache-2.0 | 2026-10-26 | "AienOS host runtime". EXERCISED: on-GB10 serve runs in `evidence/`, 237 signed bundles in aien-receipts. Not hardware qualified. Full Qwen runtime qualification incomplete; only one module is ported to Omega. |
| omega-mv | public | The Omega language: a seeded `.om` compiler grown from a 408-byte loader, the older C compiler and runtime, GB10 kernels, specs and gates | C, Omega | Apache-2.0 | 2026-10-26 | "Systems language for verified programs, in handwritten seeded .om". EXERCISED: seed host gate, arm64 CI, GB10 runs with receipts. C migration unfinished; GB10 kernels are not yet one serving engine. |
| CUDApp | public | CUDA++: a C runtime for GB10 with its own instruction encoder, code generator, ioctl driver client and matmul, attention and MoE libraries | C | Apache-2.0 WITH LLVM-exception | 2026-10-26 | "Run GPU programs with no NVIDIA user-space software". EXERCISED: 33 host test targets, 120 mutants (107 killed), zero-CUDA gate, on-chip logs. Replacements for libcuda, cudart and cuBLAS are partial; cuFFT, cuRAND and NVML are missing. The first release does not ship it as a separate runtime. |
| aienos.com | public | Rust site generator for www.aienos.com, the Hive live feed, an Omega-generated Hive page and renderer | HTML, Rust, Omega | Apache-2.0 WITH LLVM-exception | 2026-10-26 | "Source of www.aienos.com". EXERCISED and DEPLOYED: Pages workflow rebuilds and deploys. Community board storage and the X conversion backend are not built. |
| sovereign-intelligence | public | The project home and the one download location (this repo): signed release bundles, `install.sh`, the Omega wizard under `installer/`, keys, release notes and evidence | Omega, Shell | Apache-2.0 WITH LLVM-exception | 2026-10-26 | "One signed download". Pre-release `alpha-20261026.1` published; installer EXERCISED in a container and on a fake GB10; real GB10 install NOT_RUN. |
| AienOS-nv | public | AienOS's own repo: what the OS layer is, its docs, and the way to get it through Sovereign Intelligence | Markdown | Apache-2.0 WITH LLVM-exception | 2026-10-26 | Docs. Sovereign Intelligence is built on AienOS. |

## Supporting work

| Repo | Visibility | What the code does | Language | Licence | Last activity | Main claim and its evidence |
|---|---|---|---|---|---|---|
| aien-architecture-mv | public | ADRs, doctrine, plans, candidate records, shell gate and crumb tools, Lean invariants | Shell, Lean | AGPL-3.0-or-later | 2026-10-26 | "How AIEN fits together". PROPOSED for most design; check scripts EXERCISED (43 receipt bundles). Physics Zero, DIRAC-0 and Evolution Arena are specs only. |
| aien-protocols-mv | public | Specs, test vectors and C checkers for my wire formats, plus 10 reference Rust crates | Rust, C | Apache-2.0 | 2026-10-26 | "Canonical specs and schemas". EXERCISED on host (34 bundles). Most specs are Draft; several have no checker. |
| aien-receipts | public | Data only: signed verification bundles by repo and commit (about 650) | JSON | Apache-2.0 | 2026-10-26 | "Append-only receipts". EXERCISED as published bundles. They hold digests and verdicts, not raw logs; append-only is convention, not enforced. |
| aienix | public | Front-door repo: README plus submodules pinning the main components | Shell | AGPL-3.0-or-later | 2026-10-26 | "Built in the open". PROPOSED: an index, no code. Components are not yet one tree. |
| omega-bridge | public | An Omega program that emits C and Python from a bounded `.om` subset, plus a native caller ABI | Omega, Python | Apache-2.0 WITH LLVM-exception | 2026-10-26 | "Omega emits checked C and Python". EXERCISED on host (red and green logs, callers in six languages). No C or Python to Omega direction; no text, floats or heap. |
| omega-harness | public | Agent skills and two runnable `.om` examples for working in Omega honestly | Markdown, Omega | Apache-2.0 | 2026-10-26 | "Skills that make agents check and label status". IMPLEMENTED; examples rerun by hand. No CI; effect on agents unmeasured. |
| omega-projects | public | Static index and intake for projects built with Aien | HTML | Apache-2.0 WITH LLVM-exception | 2026-10-26 | IMPLEMENTED scaffold. Zero projects yet. |
| physics-mv | public | FORGE realize and verify in C, a native GB10 client over the open NVIDIA ioctls, AArch64 boot assembly with QEMU gates | C | Apache-2.0 WITH LLVM-exception | 2026-10-26 | EXERCISED: host gates, QEMU boot, one GB10 run. Native Spark boot NOT_RUN. |
| benchmarks-mv | public | Rust measurement harness and the prime drag race runner | Rust | Apache-2.0 | 2026-10-26 | "Speed against the physical limit". EXERCISED: one GB10 run (20.3x my own baseline). The physical-limit gap is unmeasured, as the README says. |
| interplane-mv | public | Rust protocol crates, JSON Schemas and conformance fixtures between models and agent runtimes | Rust | Apache-2.0 | 2026-10-26 | EXERCISED: 106/106 conformance verdicts, live captures. The 0.2 capability gate FAILED; 0.4 and 0.5 not built. |
| interplane.io | public | Rust generator for the interplane.io page from the protocol repo's public record | Rust | AGPL-3.0-or-later | 2026-10-25 | IMPLEMENTED: unit tests. No deploy receipt in the repo. |
| omnet | public | Omega crypto libraries (BLAKE2, SHA-512, Ed25519, Argon2, CBOR, JSON) and a Tailnet Lock server daemon | Omega, Python | Apache-2.0 | 2026-10-26 | EXERCISED on host: 127 pass, 2 not run (no Go oracle on that host). Not deployed. |
| readings-window | public | HTTPS server on my Pi hub: token-gated JSON of the Spark's GPU and CPU readings | Rust | AGPL-3.0-or-later | 2026-10-26 | EXERCISED and deployed per its notes (health check 2026-10-25). Collect timer not in the repo. |
| pi-register | public | CLI that lists a Linux server's services from `register.toml` and flags unregistered units | Rust | AGPL-3.0-or-later | 2026-10-25 | IMPLEMENTED: unit tests, no recorded run. |
| agent-archive | public | Collector that turns Claude, Codex, OpenCode, Gemini and Muse chat logs into one JSONL schema | Rust | AGPL-3.0-or-later | 2026-10-26 | IMPLEMENTED: unit tests with fixtures. README says "in use"; the deployed build is not recorded. |
| aien-translate | public | translate.js-compatible server that sends text to a local model, with link and markup guards | Rust | AGPL-3.0-or-later | 2026-10-26 | IMPLEMENTED: unit and protocol tests against a fake engine. No recorded run against the real engine. |
| translate | public, fork | Upstream translate.js; my commits add AGENTS.md and pin publish Actions | JavaScript | MIT (upstream) | 2026-10-26 | Upstream code. My change is CI hardening only. |
| .github | public | Organisation profile, Constitution, Covenant, security and contribution files | Markdown | Apache-2.0 | 2026-10-26 | Narrative only; its claims rest on other repos. |
| omega-evidence | private | Archive of gate receipts and logs split out of omega-mv | data | AGPL-3.0-or-later | 2026-10-26 | A store, not code. Append-only is not enforced in that repo. |
| aien-crypto | private | Shared freestanding C hashing and signature library with known-answer tests | C | Apache-2.0 WITH LLVM-exception | 2026-10-23 | IMPLEMENTED: tests exist, no retained run logs, no CI. |
| aien-math | private | A maths evaluator and MCP server written in `.om`, with oracle test corpora | Omega | none yet | 2026-10-26 | IMPLEMENTED. No recorded pass rate. |
| drake-voice | private | My own drafting and approval assistant (no automatic send or publish) | Python, Omega | none (personal) | 2026-10-26 | IMPLEMENTED: unit tests. A personal tool, not product. Mostly Python. |
| spark-scrub | private | Disk keeper for my build host: deletes idle, regenerable build output and guards protected paths | Rust | none yet | 2026-10-17 | EXERCISED on host: dry runs, one real run, safety benches. |

## Research

| Repo | Visibility | What the code does | Language | Licence | Last activity | Main claim and its evidence |
|---|---|---|---|---|---|---|
| aienux | public | The AienOS kernel: a C rewrite in `native/` plus an older Rust workspace | C, Rust | Apache-2.0 | 2026-10-26 | "A kernel to replace Linux on the Spark". EXERCISED: 24 gates in QEMU, Pi 5 and iMac runs, an early Rust first boot on the Spark. The C kernel has never booted on the Spark. **Not in the alpha bundle; still pre-alpha.** The old name `aien-dev/aienos` redirects here. |
| atlas | public | 1,480-byte AArch64 boot seed that checks the next stage's SHA-256 | Assembly, C | Apache-2.0 | 2026-10-26 | EXERCISED in QEMU only (268 of 268 corruptions refused). Native run pending. |
| aegis-runtime-mv | public | Agent runtime: WebSocket, SSE and REST gateway, heartbeat loop, workflow DAG, SQLite | Rust | AGPL-3.0-or-later | 2026-10-26 | EXERCISED on host (25 signed bundles). Its embedded inference is a mock. |
| synapse | public | Signed changesets, WAL store, capability auth, deterministic Git output, Radicle quorum verifier | Rust | Apache-2.0 | 2026-10-26 | Components EXERCISED (29/29 conformance, three runs). Reads are slower than Git; stays in the lab. |
| spark-rsi-mv | public | Self-improvement loop: proposals, sandboxed builds, a separate judge, signed ledger, promotion gate | Rust | AGPL-3.0-or-later | 2026-10-26 | EXERCISED: two fixture cycles on the Spark host, promotion refused. No independent cycle qualified. |
| open-humanity | public | Signal, crypto and firewall building blocks; a loopback volunteer-compute trainer for a toy model; volunteer inference for Aien overflow (open-humanity#41) | Rust | Apache-2.0 | 2026-10-26 | The distress network is PROPOSED (parts not joined). Volunteer compute EXERCISED on loopback only. Volunteer inference EXERCISED on loopback with a fake engine, not deployed, public routing off. |
| aien | public | Plans for Aien (formerly Allen; the repository was `allen` until 2026-10-26), one persistent identity across my machines | Markdown | AGPL-3.0-or-later | 2026-10-26 | PROPOSED: no code on `main`. |
| aien-train | public | Plan for training my own language model on my engine | Markdown | AGPL-3.0-or-later | 2026-10-25 | PROPOSED: no training code. |
| aien-rig | public | Plan for local AI and frame-rate tuning on RTX gaming PCs | Markdown | AGPL-3.0-or-later | 2026-10-25 | PROPOSED: no code; never run on an RTX card. |
| spark-connector | public | Plan for a volunteer DGX Spark verification connector | Markdown | AGPL-3.0-or-later | 2026-10-26 | PROPOSED: commands not implemented. |
| aien-sealed | private | Evaluator-only material for blind experiments, kept away from candidates | C, data | none | 2026-10-26 | Not assessed here on purpose; it is sealed. |
| omega-host | private | Omega shell core and a C Linux host adapter that checks effects against capability grants | C, Omega | AGPL-3.0-or-later | 2026-10-26 | EXERCISED on host. Not a sandbox, and its README says so. |
| omega-learn | private | Tensors, reverse-mode autodiff and SGD on Omega | C | AGPL-3.0-or-later | 2026-10-26 | IMPLEMENTED with host tests. GB10 run NOT_RUN. Still C, not `.om`. |
| omega-programs | private | Experiments written on Omega (Turing, Brownian, estimation and others) | C, Omega | AGPL-3.0-or-later | 2026-10-26 | IMPLEMENTED with gates. Mostly C. |
| omega-research | private | Notes and one-off hardware probes | C | AGPL-3.0-or-later | 2026-10-21 | PROPOSED or run once by hand. |
| mobhub | public | Faction operations tool for the game Torn City: payouts, valuation, gym simulation | Rust | Apache-2.0 WITH LLVM-exception | 2026-10-26 | A side project outside AienOS. IMPLEMENTED: tests, no CI. |

## Archive

These are archived on GitHub or are mirrors I keep so a build cannot vanish. Most Rust ones were folded into Core as crates.

| Repo | Visibility | What the code does | Language | Licence | Last activity | Main claim and its evidence |
|---|---|---|---|---|---|---|
| aien-edge | public | Static-site server with brotli, ACME and vhosts | Rust | AGPL-3.0-or-later | 2026-10-25 | IMPLEMENTED; never deployed (sites are on GitHub Pages). Parked, not archived. |
| aien-harness | public, archived | MCP harness: schema checks, slop gate, failure replay | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED. Now Core `crates/spark-harness`. |
| aien-local-stack | public, archived | One-process composition of the agent runtime and Core | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | EXERCISED on host (one receipt). Fold into Core pending. |
| aien-yardsticks | public, archived | Outside reference oracles I measured against | Python | AGPL-3.0-or-later | 2026-10-15 | IMPLEMENTED; frozen. |
| cortex-rs | public, archived | Memory server: SQLite FTS5 plus vector search | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED; the "sub-millisecond" claim has no stored result. Now in Core. |
| crumb-spec-mv | public, archived | Crumb protocol RFC-0001 and a small hash-chained ledger | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | Spec PROPOSED, ledger IMPLEMENTED. Current tool lives in aien-architecture-mv. |
| encounter | public, archived | README only on `main` | none | none | 2026-10-13 | PROPOSED. |
| harvester | public, archived | Pulls reasoning traces out of provider streams into datasets | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED. Now in Core. |
| MojoLlama | public, archived | CPU inference engine in Mojo and C with a desktop app | Python, Mojo, C | Apache-2.0 | 2026-10-13 | EXERCISED on CPU only. I dropped Mojo and MAX on 2026-10-15. |
| physics0 | public, archived | Empty; the learner moved into Omega | none | Apache-2.0 | 2026-10-03 | Nothing here. |
| rad-id-sync | public, archived | Fingerprints SSH and Radicle public keys into a JSON record | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED. Its README's Radicle sync, TPM and FFI claims are not in the code. |
| spark-adapters | public, archived | Provider router, text verifier, distillation task types | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED. Now in Core. |
| spark-crumbs-mv | public, archived | Older crumb CLI | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED; superseded. |
| spark-debugger | public, archived | Service watchdog with SQLite incidents and an MCP interface | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED; no tests. |
| spark-dream | public, archived | Idle-time daemon that writes notes into Cortex | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED; no real run recorded. |
| spark-hive | public, archived | Hex-grid event store and a model "PR plan" generator | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED. Its benchmark numbers are estimated, not measured. |
| spark-inquisitor | public, archived | Diff auditor for telemetry, secrets and banned wording | Rust | Apache-2.0 WITH LLVM-exception | 2026-09-23 | IMPLEMENTED with tests; the 2 ms performance table has no evidence. |
| spark-supervisor | public, archived | Process supervisor with health polls and restart backoff | Rust | SRCL-1.0 (stale; the Apache-2.0 WITH LLVM-exception fix lands with its revival) | 2026-09-23 | IMPLEMENTED; recovery speed not measured. Being revived as the home of `aien-supervise`, rewritten in Omega. |
| odysseus | public, archived fork | Upstream AI workspace; my commits add a byte-stable prompt prefix and a prefill client | Python | AGPL-3.0 (upstream) | 2026-10-14 | IMPLEMENTED with unit tests. |
| t3code | public, fork | Upstream coding app; my commits are a fork note and a reactions branch | TypeScript | MIT (upstream) | 2026-10-18 | IMPLEMENTED on a side branch; never offered upstream. |
| rpi5-uefi | public, fork | Raspberry Pi 5 UEFI build; my commits repoint submodules to my mirrors | Shell | upstream | 2026-10-25 | No build or boot of mine recorded. |
| arm-trusted-firmware | public, archived fork | Mirror of TF-A for the Pi 5 chain | C | upstream | 2026-10-14 | Upstream code. |
| edk2 | public, archived fork | Mirror of EDK II for the Pi 5 chain | C | upstream | 2023-12-27 | Upstream code. |
| edk2-non-osi | public, fork | Mirror of EDK II non-OSI binaries; my commits add notes | C | upstream | 2026-10-25 | Upstream code. |
| edk2-platforms | public, archived fork | Mirror of edk2-platforms for the Pi 5 | C | upstream | 2024-03-16 | Upstream code. |

## What is not done

- **No hardware qualification.** Nothing is QUALIFIED. The 3x physical GB10 qualification is NOT_RUN.
- **One machine.** The GPU path runs on the DGX Spark only. Other NVIDIA cards and other vendors are not supported.
- **One execution path.** The engine I serve from is built from an unmerged branch. Alpha testers get Core's receipted tag, which lacks that branch's batch slots, and a smaller model.
- **Omega is not finished.** Much of Omega, CUDA++, omega-learn and omega-programs is still C. The seeded `.om` compiler is real, and the migration of the rest is ongoing.
- **CUDA++ is partial.** libcuda, cudart and cuBLAS replacements are partial; cuFFT, cuRAND and NVML are missing.
- **The kernel is research.** aienux has never booted its C kernel on the Spark. AienOS in alpha testing runs on top of Linux.
- **Several repos are plans.** aien, aien-train, aien-rig and spark-connector have no code yet.
- **Some old READMEs overclaim.** spark-hive's benchmarks are estimated, rad-id-sync never calls Radicle, and spark-inquisitor's and cortex-rs's speed claims have no stored result. They are archived and the claims stand only as history.
- **Receipts hold digests, not logs.** aien-receipts bundles record verdicts and hashes; the raw logs are not published, and the verifier walkthrough has not been reproduced by anyone else.

## How this was checked

I cloned all 68 repositories that existed that morning and read their code, tests, CI and evidence directories. Evidence levels come from files committed in each repo. Nothing was rebuilt or rerun for this document. Before alpha testers arrived I also cleaned every public repo of private paths, internal host names and addresses, personal email addresses and stale licence text; the table below lists every fix. A history scan for secret-shaped strings found only synthetic test fixtures and upstream test vectors, so no credential needed rotating. I did not rewrite history, and receipts and evidence files were left byte-identical, so some of them still record old paths and host names as they were when the run happened.

## Sanitization, 2026-10-26

| Repo | Fixed | PR | Merge |
|---|---|---|---|
| aien-harness | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com | [aien-harness#7](https://github.com/aien-dev/aien-harness/pull/7) | `2da4b5a3a0` |
| aien-local-stack | SRCL LICENSE (proton email) to Apache-2.0+LLVM-exception+NOTICE; Cargo AGPL-3.0-only (contradicted LICENSE) to Apache-2.0 WITH LLVM-exception; cow_demo.rs a home path to $HOME; fixed pre-existing CI break (LinuxMemoryKind::CudaManagedFallback to External) | [aien-local-stack#7](https://github.com/aien-dev/aien-local-stack/pull/7) | `2ef0b91365` |
| aien-yardsticks | generate_tinyllama_oracle.py a home path to HF_HUB_CACHE or ~/.cache/huggingface/hub; README archived note | [aien-yardsticks#11](https://github.com/aien-dev/aien-yardsticks/pull/11) | `6c66814788` |
| cortex-rs | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com; CORS LAN a LAN IP + tailnet a tailnet IP origins removed (owner CortexOmega notified) | [cortex-rs#16](https://github.com/aien-dev/cortex-rs/pull/16) | `3f9365fb37` |
| crumb-spec-mv | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com (+Cargo authors, SPEC/SECURITY contact emails) | [crumb-spec-mv#11](https://github.com/aien-dev/crumb-spec-mv/pull/11) | `e2dc22ea78` |
| harvester | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com; agent.json/llms.txt/export.rs/main.rs/PR template SRCL text; README a LAN IP to 127.0.0.1 | [harvester#8](https://github.com/aien-dev/harvester/pull/8) | `0fa381acd0` |
| MojoLlama | desktop package.json/lock license MIT to Apache-2.0 (match LICENSE); a placeholder address to aien@aienos.com; src README licence MIT to Apache-2.0; README archived note | [MojoLlama#5](https://github.com/aien-dev/MojoLlama/pull/5) | `249949d1c3` |
| rad-id-sync | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com | [rad-id-sync#8](https://github.com/aien-dev/rad-id-sync/pull/8) | `235666135a` |
| spark-adapters | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com | [spark-adapters#8](https://github.com/aien-dev/spark-adapters/pull/8) | `edd9aa10c0` |
| spark-crumbs-mv | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com (+Cargo authors, main.rs clap author) | [spark-crumbs-mv#9](https://github.com/aien-dev/spark-crumbs-mv/pull/9) | `156633e1af` |
| spark-debugger | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com | [spark-debugger#8](https://github.com/aien-dev/spark-debugger/pull/8) | `dc907a4ebc` |
| spark-dream | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com | [spark-dream#9](https://github.com/aien-dev/spark-dream/pull/9) | `fc8726847e` |
| spark-hive | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com | [spark-hive#9](https://github.com/aien-dev/spark-hive/pull/9) | `52f6b9cc1a` |
| spark-inquisitor | SRCL LICENSE to Apache-2.0+LLVM-exception text+NOTICE; Cargo/README badge+licence line/llms.txt/AGENTS/CONSTITUTION SRCL text; emails to @aienos.com; fixed pre-existing CI breaks (cargo fmt drift; deprecated verify to verify_with Tier2SoftwareKey) | [spark-inquisitor#10](https://github.com/aien-dev/spark-inquisitor/pull/10) | `0efa3e4dcd` |
| aien-sovereign-core-mv | paths (TEST_READY, FORGEJO_CI, ORACLE-FIXTURE-CAND4, aien-local-ci scripts, cockpit, legacy crumb, e2e selftest); hosts (hub a LAN IP in AGENTS/llms/agent.json to $AIEN_HUB_URL, cortex-rs CORS LAN/tailnet to CORTEX_EXTRA_ORIGINS, plist tailnet IP to SPARK_USER@SPARK_HOST, the hostname in sanitizer regex/walkthrough/BENCH, test IPs synthetic); emails (spark-aegis proton to drake@aienos.com, a placeholder address to aien@aienos.com); agent.json licence to Apache-2.0; README/ALPHA_STATUS alpha-testing wording; GitHub description updated; crumbs recompiled | [aien-sovereign-core-mv#774](https://github.com/aien-dev/aien-sovereign-core-mv/pull/774) | `a555829c1a` |
| mobhub | SRCL-1.0 LICENSE to Apache-2.0 WITH LLVM-exception (aienos.com text) + NOTICE; licence lines in README/CONSTITUTION/AGENTS/llms.txt; personal emails (Cargo, CONSTITUTION, AGENTS, README); .crumb /home paths; AGENTS vault path; GitHub description drops Mojo | [mobhub#15](https://github.com/aien-dev/mobhub/pull/15) | `5e11306547` |
| spark-rsi-mv | src /home paths (judge test helper to CARGO_MANIFEST_DIR, cortex/ratify HOME fallback, kernel_autotune to AIEN_SOVEREIGN_CORE_DIR/$HOME); test identity a local hostname to spark.invalid; AGENTS email; GitHub description drops Mojo | [spark-rsi-mv#79](https://github.com/aien-dev/spark-rsi-mv/pull/79) | `fc13d3f77e` |
| open-humanity | research doc /home file links; AGENTS email; teacher test LAN IP to 203.0.113.5 | [open-humanity#40](https://github.com/aien-dev/open-humanity/pull/40) | `38c0c1c48d` |
| readings-window | exposure-watch DNS names overridable via EXPOSURE_DNS_HOSTS (public names kept as default, allowlisted) | [readings-window#16](https://github.com/aien-dev/readings-window/pull/16) | `c6e2ab3459` |
| synapse | radicle test $HOME path; gate0 script WORKSPACE_ROOT env; ADR0001/GATE0/GATE4 docs + comment the hostname and /home paths | [synapse#127](https://github.com/aien-dev/synapse/pull/127) | `099a980fed` |
| benchmarks-mv | bench_canonical_suite HF path to HF_HOME/$HOME; README + LIVE_PRESSURE doc hostname | [benchmarks-mv#52](https://github.com/aien-dev/benchmarks-mv/pull/52) | `0f369dbc85` |
| omega-mv | 7 mutable docs/tools: home paths to ~/ or $HOME (docs/osc, docs/polyglot, docs/turing, agg.sh); 7 crumbs recompiled (pin d0f0b95d, verify OK); frozen calibration/exp445/evidence records allowlisted | [omega-mv#802](https://github.com/aien-dev/omega-mv/pull/802) | `0d6af54f99` |
| omega-bridge | conformance/run.sh MAXPY default to $HOME; MAX-26.7 docs paths to ~/ / $HOME (4 lines) | [omega-bridge#19](https://github.com/aien-dev/omega-bridge/pull/19) | `358c505105` |
| omega-harness | aien-repositories skill: pre-alpha to dated alpha-testing phase with bundle facts (aienos-releases not yet published); omnet entry corrected (README no longer says pre-alpha) | [omega-harness#25](https://github.com/aien-dev/omega-harness/pull/25) | `bd234978f0` |
| physics-mv | physics.decode header path to repo-relative (m2tool audit-verify PASS); .crumb + BACKFILL.md lane note path; TRANSITION_PLAN recipe; pre-alpha kept (not in alpha bundle) | [physics-mv#89](https://github.com/aien-dev/physics-mv/pull/89) | `8e92aa629c` |
| .github | profile README + SECURITY.md: pre-alpha to alpha testing for bundle, stale alpha-release bullet replaced, aien-crypto removed from public list (private), licence line names AGPL repos | [.github#20](https://github.com/aien-dev/.github/pull/20) | `ea1c012175` |
| aienos.com | README hub IP removed; omega.json the hostname to the DGX Spark; og-cards badge pre-alpha to Alpha testing + 10 og PNGs regenerated | [aienos.com#113](https://github.com/aien-dev/aienos.com/pull/113) | `dcf3ee57e5` |
| aien-architecture-mv | README alpha-testing status (bundle named, rest pre-alpha); /home paths to ~ or repo-relative in doctrine/INDEX, milestone-14 (file:// link to omega-mv URL), plans inventory/M1-M2-TRACE/mixed-algebra/prefill, research topology; host name out of ROADMAP, milestone-16/17, vac PLAN, m15 audit; parity cases from frozen CAND-0/4 use synthetic /home/alice + spark, cand4 amendment re-hashed, mkcases.sh reproduces them | [aien-architecture-mv#334](https://github.com/aien-dev/aien-architecture-mv/pull/334) | `fabf7b765a` |
| aienux | pi5 hub ping: hard-coded LAN IP to ssh -G hub (PI5_HUB_ADDR); pi_run hold to $HOME; recovery evidence cipher dirs: no private home in default (glob per home); aienos-infer golden/gen model+ggml paths to env/$HOME; /Users paths in P3_NVME docs; TRUST-1 OWNER placeholder; ARGUS1 lock path; polkit user name; host name out of 3 docs; funding.json licence to Apache-2.0 (matches LICENSE); crumbs recompiled (d0f0b95d, 91 current) | [aienux#459](https://github.com/aien-dev/aienux/pull/459) | `aa54ee57f1` |
| aienix | README: AienOS in alpha testing (bundle + GB10-only + 3x physical NOT_RUN), other components pre-alpha; repo description updated | [aienix#12](https://github.com/aien-dev/aienix/pull/12) | `292a38cd03` |
| CUDApp | a personal address redacted in docs/AUDIT.md + LICENSE_PROVENANCE.md; home path in AUDIT.md to ~; AUDIT.md header note (historical MIT-era audit, now Apache-2.0 WITH LLVM-exception, only NVIDIA headers MIT); swap/cudapp reboot guard no longer names host (spark-window presence) | [CUDApp#96](https://github.com/aien-dev/CUDApp/pull/96) | `780a0af1f0` |
| aegis-runtime-mv | src/auth.rs test sample a LAN IP to 192.0.2.10 (Pre-alpha label/description kept: not in alpha bundle) | [aegis-runtime-mv#77](https://github.com/aien-dev/aegis-runtime-mv/pull/77) | `a39788b0ea` |
| agent-archive | test fixtures claude/codex.jsonl cwd to /home/alice | [agent-archive#6](https://github.com/aien-dev/agent-archive/pull/6) | `e102eb6bf3` |
| omega-harness | aien-repositories skill: Sovereign Intelligence is the alpha home; retired aienos name | [omega-harness#29](https://github.com/aien-dev/omega-harness/pull/29) | `97e41c0e40` |

Clean, nothing to change: aien (then named allen), aien-edge, aien-protocols-mv, aien-receipts, aien-rig, aien-train, aien-translate, arm-trusted-firmware, atlas, edk2-non-osi, encounter, interplane-mv, interplane.io, odysseus, omega-projects, omnet, physics0, pi-register, rpi5-uefi, spark-connector, t3code, translate.

Still open at the time of writing: spark-supervisor keeps its old licence text and one personal address until its owner revives it, and the last eight "pre-alpha" labels on aienos.com change with the `/alpha/` page (aienos.com#112).
