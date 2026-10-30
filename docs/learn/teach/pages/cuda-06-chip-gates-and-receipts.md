# Verifying with chip gates: receipts, mutants, and why a host run is not qualification

Evidence level: EXERCISED. The receipt re-check below ran on a Linux AArch64 host with no GPU; it checks recorded bytes, and it shows that CUDApp's own native qualification at this pin is NOT_RUN.

## Goal

Know what it takes before I say a GPU path works, how to re-check a receipt yourself without a GPU, and how to tell PASS, INCOMPLETE, FAIL and NOT_RUN apart.

## Explanation

Nothing in CUDA++ counts until the chip agrees. Each piece has three kinds of check.

**Host tests.** `make test` builds and runs everything that needs no GPU: encoder golden words, warp simulators, tensor-core models, refusal cases. They catch a lot, and they open no device. They are not hardware qualification: a simulator PASS proves the simulator agrees with my model of the chip, not that the chip agrees.

**Mutants.** A check that never fails is decoration. `tools/gpu_engine_mutations.sh` copies the engine to a scratch directory, breaks one protection at a time, rebuilds the test and requires it to **fail**. A mutant that is not caught fails the sweep. The examples in this track do the same on a small scale: every lesson has a negative control with its exit code.

**Chip gates with receipts.** A gate runs on the GB10 on a named commit and leaves a receipt with its raw logs. The M16 gate (`m16/m16_requalify.c`) is a good model of the idea: queue a semaphore release **without** ringing the doorbell and check the marker stays 0 for 100 ms (so nothing else could have written it), ring it and check the marker becomes 0x16c0ffee, then read `/proc/self/maps` to prove `libcuda` was never loaded. A negative control on hardware, a positive result, and a check of the claim "no CUDA".

A receipt is only as good as what it lets you re-check. So I read receipts the way a stranger would:

1. Re-hash every file the receipt lists. All match: the bytes are the recorded ones (integrity, not truth).
2. A listed file missing: INCOMPLETE. Find out why before trusting the rest.
3. A hash differs: FAIL.
4. Nothing checked: NOT_RUN. Zero cases is never a PASS.
5. Then ask whether the run was on **this** commit. A dated receipt does not qualify an unrelated later commit.

At this pin CUDApp's README is explicit: the imported M16 receipt is an unauditable historical summary, because the raw logs it names are absent, and current native qualification is NOT_RUN. It needs a new authorized GPU run with retained logs. The same discipline applies to gate scripts: `tests/run_nvrm_lifecycle_gates.sh` at this pin sources `tests/gb10_lock.sh`, which is not in the tree, so that runner cannot be started from this checkout as it stands. NOT_RUN is not PASS, and a runner that cannot start is NOT_RUN.

GPU windows themselves are shared and scheduled: on the DGX Spark a chip gate runs only inside an authorized quiet window, never beside a live serving model. That is why every example in this track is host-only.

## Example

`verdict.om` turns three counts into a fail-closed verdict. The past host run re-hashed each listed file itself. The decision:

```om
fn main to int
if not slurp
ret 3
end
ok = nextnum
miss = nextnum
bad = nextnum
if eq bad 18446744073709551615
ret 3
end
if gt bad 0
puts sfail
flush
ret 11
end
if gt miss 0
puts sinc
flush
ret 10
end
if eq ok 0
puts snr
flush
ret 12
end
puts sok
flush
ret 0
end
```

Command: the retired runner; see `examples/cuda-06-chip-gates-and-receipts/POINTER.md`

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
compile rc=0
== 1. NVIDIA headers: third_party/nvidia-open-580.173.02/SHA256SUMS
  matched=68 missing=0 differs=0
verdict: PASS (integrity only: these are the recorded bytes)
  verdict.om rc=0
== 2. chip receipt: evidence/OWN30B-T3-TC-PEAK-BW-5faa0f70-20261013T2236Z/SHA256SUMS
  MISSING  fa_ops.sass
  matched=4 missing=1 differs=0
verdict: INCOMPLETE (a listed file is absent; the receipt cannot be re-checked in full)
  verdict.om rc=10
  why the missing file is missing (docs/AUDIT.md):
60:- `evidence/OWN30B-T3-TC-PEAK-BW-5faa0f70-20261013T2236Z/fa_ops.sass`: a listing of machine code produced by NVIDIA's compiler (see section 5). That receipt'
  what the log itself says:
peak stall 1 chains 16 threads 256 ctas 384 (declared 88): median 7162.2 us, 115.14 TFLOPS, 0 wrong values
GPU_TC_PEAK: PASS
== 3. negative control: the same receipt with one byte appended to peak.log
  MISSING  fa_ops.sass
  DIFFERS  peak.log
  matched=3 missing=1 differs=1
verdict: FAIL (a file differs from its recorded hash)
  verdict.om rc=11
== 4. negative control: an empty file list
  matched=0 missing=0 differs=0
verdict: NOT_RUN (nothing was checked; zero files is not a pass)
  verdict.om rc=12
== 5. the M16 receipt: what it claims, and whether its raw logs are here
  qualification_status=PASS implementation_commit=a2c0d7fbc03f7ce91fcb6389312a0ee8630322cd evidence_dir=evidence/m16-requalification
  evidence/m16-requalification: absent at this pin
119:missing logs has been established. Current native qualification is **NOT_RUN**;
```

1. The 67 NVIDIA headers plus `COPYING` all match their `SHA256SUMS`: PASS, integrity only.
2. The tensor-core ceiling receipt from 2026-10-13 (`OWN30B-T3-...`) has four of five files. The fifth, `fa_ops.sass`, is a listing made by NVIDIA's compiler; `docs/AUDIT.md` records that it was deliberately kept out of CUDApp. INCOMPLETE is the honest verdict, with the reason next to it. The log it does contain says `GPU_TC_PEAK: PASS` with 115.14 TFLOPS on that date and commit.
3. One appended byte: FAIL.
4. An empty list: NOT_RUN, never PASS.
5. The M16 receipt claims PASS, but its `evidence_dir` is absent at this pin, and the README line beside it says NOT_RUN.

## Common mistake

Quoting a PASS from a receipt you did not re-check, or from a different commit, or from a host simulator. Re-hash the receipt's files, confirm the raw logs exist, confirm the commit, and keep host results, historical chip results and current qualification in separate sentences.

## Where to go deeper

- [README.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/README.md) (the M16 evidence limitation) and [docs/START_HERE.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/START_HERE.md), section 4.
- The M16 proof: [m16/m16_requalify.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/m16/m16_requalify.c) and its [historical receipt](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/evidence/m16-blackwell-native-path-requalification-receipt.json).
- A complete chip receipt folder: [evidence/OWN30B-T3-TC-PEAK-BW-5faa0f70-20261013T2236Z](https://github.com/aien-dev/CUDApp/tree/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/evidence/OWN30B-T3-TC-PEAK-BW-5faa0f70-20261013T2236Z).
- Mutation testing: [tools/gpu_engine_mutations.sh](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/tools/gpu_engine_mutations.sh) and [tools/mutation_runner.sh](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/tools/mutation_runner.sh).
- The lifecycle gate runner: [tests/run_nvrm_lifecycle_gates.sh](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/tests/run_nvrm_lifecycle_gates.sh).
