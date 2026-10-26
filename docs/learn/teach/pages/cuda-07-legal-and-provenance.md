# Legal and ethical ground: interoperability, MIT headers, and what was never taken apart

Evidence level: EXERCISED. The checks below ran on a Linux AArch64 host against the pinned tree; they test the repository's own provenance statements, and none of this is legal advice.

## Goal

Know exactly what CUDA++ used from NVIDIA, under which terms, what it deliberately did not do, and how to check those statements yourself instead of taking my word for them.

## Explanation

I wanted software that runs on the NVIDIA GPU I already own, without NVIDIA's closed user-space stack. That is an interoperability goal: talk to the hardware and its open kernel interface, not copy or translate NVIDIA's products. The rules I kept, as the repository states them:

**Only the open kernel module's headers, copied unchanged.** `THIRD_PARTY.md` says CUDApp holds 67 header files from NVIDIA's open-gpu-kernel-modules release 580.173.02, each keeping its NVIDIA copyright and MIT notice: 60 with an `SPDX-License-Identifier: MIT` line and 7 older ones with the MIT text only. NVIDIA's own `COPYING` says the files are MIT, and only when linked together into a Linux kernel module is the result dual MIT/GPLv2. CUDA++ builds no kernel module from them; it uses them as user-space interface definitions.

**No NVIDIA binaries taken apart or shipped.** `docs/HOW_I_DID_IT.md` says: "I did not take apart `libcuda`, `nvcc` or any other NVIDIA program. I ran NVIDIA's compiler and disassembler on my own small kernels and read what they printed." That distinction matters and I keep it exact: NVIDIA's tools were used as an offline oracle on my own probe kernels (one of them, `fa_ops.cu`, is still in a receipt folder, and it is my code). They are never run by CUDA++ itself, and the GSP firmware is untouched and never shipped.

**Mesa: facts, not code.** Mesa's open NVIDIA driver (NVK) and compiler (NAK) are MIT. `THIRD_PARTY.md` says CUDApp cites them in comments as the source of hardware facts (opcode bit positions, latencies, the QMD layout, the dispatch sequence) and that the encoder, scheduler and command-list code is my own; the latency values used by one file were taken from Mesa's tables, and the notices are reproduced.

**Not for other hardware.** I did not translate CUDA programs to run on non-NVIDIA GPUs. CUDA++ runs on NVIDIA GPUs, the ones people already paid for. The README quotes the CUDA EULA's clause against reverse engineering SDK output "for the purpose of translating such output artifacts to target a non-NVIDIA platform"; CUDA++ does neither of those things.

**Audited, with stated limits.** `docs/LICENSE_PROVENANCE.md` records a scan of the whole candidate history at one commit (zero binary blobs, zero credential hits) and says plainly that it is "not a legal opinion", does not prove no line was ever derived from another source, and that new commits need the same review.

That last sentence is why the example re-checks the claims on the pinned tree rather than trusting the audit. It finds three things worth knowing:

- Two `.cubin` files are tracked under `evidence/MAX-INTEROP/68/`. Their `RESULT.md` says they are CUDA++'s own exported artifacts (sm_121 ELF carrying CUDA++'s generated code), not NVIDIA's.
- `tests/device-trace/expected.sass` is a golden file written from `nvdisasm` output of CUDA++'s own emitted words (the test script runs `nvdisasm --binary SM121` and can rewrite the file). `THIRD_PARTY.md` says no listing made by NVIDIA tools is stored in the repository, so at this pin that file and that sentence disagree. It is a listing of my own machine code, not of NVIDIA's, but the documentation should say so.
- The first-party `LICENSE` is Apache-2.0 with the LLVM exception, yet 67 files, including the native `.om` sources under `native/`, carry an `AGPL-3.0-only` SPDX line. Check the header of any file you reuse.

## Example

A host-only inspection: each claim is printed next to the count that tests it.

```sh
echo "== claim 1 (THIRD_PARTY.md): 67 NVIDIA headers, 60 with an SPDX MIT line, 7 with the MIT text only"
grep -n '67 header files\|60 carry' THIRD_PARTY.md | cut -c1-110
cd third_party/nvidia-open-580.173.02 || exit 2
total=$(find . -name '*.h' | wc -l | tr -d ' ')
spdx=$(grep -rl 'SPDX-License-Identifier: MIT' --include='*.h' . | wc -l | tr -d ' ')
textonly=$(grep -rL 'SPDX-License-Identifier: MIT' --include='*.h' . | xargs grep -l 'Permission is hereby granted' | wc -l | tr -d ' ')
echo "   counted: $total headers, $spdx with SPDX MIT, $textonly with the permission text only"
echo "   NVIDIA's own licence file (COPYING), the line that limits the dual licence:"
grep -n 'GPL' COPYING | cut -c1-110
cd "$C" || exit 2

echo "== claim 2 (THIRD_PARTY.md): no NVIDIA firmware, libcuda, cubin, fatbin or PTX; no NVIDIA tool listing stored"
```

Command: `sh examples/cuda-07-legal-and-provenance/run.sh`

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (not needed by this inspection; checked so every lesson pins the same tools)
== claim 1 (THIRD_PARTY.md): 67 NVIDIA headers, 60 with an SPDX MIT line, 7 with the MIT text only
7:`third_party/nvidia-open-580.173.02/` holds 67 header files from NVIDIA's open-gpu-kernel-modules,
10:folder lists every file. Each file keeps its own NVIDIA copyright and MIT notice (60 carry
   counted: 67 headers, 60 with SPDX MIT, 7 with the permission text only
   NVIDIA's own licence file (COPYING), the line that limits the dual licence:
26:kernel module is dual licensed as MIT/GPLv2.
== claim 2 (THIRD_PARTY.md): no NVIDIA firmware, libcuda, cubin, fatbin or PTX; no NVIDIA tool listing stored
48:- No NVIDIA firmware, no libcuda, no cubin or fatbin, no PTX. The GPU's signed GSP firmware is loaded
51:  cross-check. No listing made by NVIDIA tools is stored in this repository (one such file was kept out
   tracked files named *.cubin *.fatbin *.ptx *.sass libcuda* *.so or *.bin under firmware paths:
     evidence/MAX-INTEROP/68/attention-hd128-gqa8.cubin
     evidence/MAX-INTEROP/68/matmul-16x16x8.cubin
     tests/device-trace/expected.sass
   where the two cubins come from (CUDA++'s own exporter):
     24:Both cubins are sm_121 ELF (`e_machine=190`, `e_flags=0x6007902`), carry the
     25:generated text byte-for-byte, bind text/QMD/cbank/SHA-256, contract id,
   how expected.sass is made (the emitter test's own script):
     11:#        add --update to rewrite expected.sass from the current emitter output.
     62:nvdisasm --binary SM121 "$work/words.bin" > "$work/got.sass"
     69:  echo 'nvdisasm decode matches expected.sass'
     1:	.headerflags	@"EF_CUDA_64BIT_ADDRESS EF_CUDA_SM121 EF_CUDA_VIRTUAL_SM(EF_CUDA_SM121)"
== claim 3 (HOW_I_DID_IT.md): NVIDIA tools were run on my own probe kernels, nothing was taken apart
59:- I did not take apart `libcuda`, `nvcc` or any other NVIDIA program. I ran NVIDIA's compiler and disassembler on my own small kernels an
68:- One CUDA C++ source remains in a receipt: `evidence/OWN30B-T3-TC-PEAK-BW-5faa0f70-20261013T2236Z/fa_ops.cu`, my own probe kernel, used once with 
   the one CUDA C++ file in the tree:
evidence/OWN30B-T3-TC-PEAK-BW-5faa0f70-20261013T2236Z/fa_ops.cu
== claim 4 (THIRD_PARTY.md): Mesa facts cited in comments, no Mesa code copied
   files under src/ that name a Mesa source file: 5
== what the licence of first-party code says at this pin
Apache License
Version 2.0, January 2004
   files whose SPDX line says Apache-2.0 WITH LLVM-exception: 213
   files whose SPDX line says AGPL-3.0-only: 67, for example:
native/blackwell/launch.om
native/blackwell/trace-emit.om
native/blackwell/vector.om
```

The header counts match `THIRD_PARTY.md` exactly (67, 60, 7). The `COPYING` line shows the scope of the GPL option. The file-type search finds the three files discussed above, and the script prints their own provenance lines next to them.

## Common mistake

Overclaiming in either direction. "CUDA++ never used NVIDIA tools" is false: it used them offline, on its own probes, and still uses `nvdisasm` as an optional cross-check in some host tests. "CUDA++ contains NVIDIA code" is also false: it contains NVIDIA's MIT headers, unchanged and labelled. Say exactly which, cite the file, and leave legal conclusions to lawyers.

## Where to go deeper

- [THIRD_PARTY.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/THIRD_PARTY.md) and NVIDIA's [COPYING](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/COPYING).
- [docs/HOW_I_DID_IT.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/HOW_I_DID_IT.md), section "What I did not do".
- [docs/LICENSE_PROVENANCE.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/LICENSE_PROVENANCE.md) and [docs/AUDIT.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/AUDIT.md).
- [evidence/MAX-INTEROP/68/RESULT.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/evidence/MAX-INTEROP/68/RESULT.md) and [tests/device-trace/run-emitter-checks.sh](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/tests/device-trace/run-emitter-checks.sh).
- [LICENSE](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/LICENSE).
