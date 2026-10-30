# Alpha tags versus merge gates

Evidence level: EXERCISED. A teaching model of the Alpha rule ran on six bundle summaries on a Linux arm64 host; Core's real verifier, which checks signed bundles, was not run for this lesson.

## Goal

Know the difference between the gate that lets a change merge and the gate that makes a commit an Alpha, and why a commit with every host check green is still not an Alpha without a GPU receipt.

## Explanation

In Sovereign Core, the engine repository, there are two different decisions, and I keep them apart on purpose.

**Merging a pull request.** GitHub cannot run my GPU gates: there is no GB10 in GitHub's runners. So the GitHub side is a thin gate: on its own it runs only portable checks on the tree, and its `aien-test verify-bundle` command checks the signed bundle that my own judge produced for the gates the change selects (the changed scope). A bundle with no required check, or whose signed plan verdict is not PASS, is NOT_RUN with exit 2, never a vacuous PASS. A pull request's changed scope usually stays host-only.

**Tagging an Alpha.** An Alpha is a commit already on main that the judge ran in full scope: every gate at that commit, GPU gates included. Only then can the pipeline tag it `alpha/YYYYMMDD.N`, an annotated tag that names the signed bundle's digest. `verify-bundle --require-full` enforces this and rejects in two named ways:

- `NOT_FULL_SCOPE`: the bundle's signed plan scope is `changed`, not `full`.
- `NO_GPU_RECEIPT`: the full-scope bundle has no required check on backend `gb10` that ran on the Spark's GPU.

The second rule exists because of a real case. The first Alpha, `alpha/20261024.1`, was 34 checks, all on backend `host`. A full-scope PASS of host gates alone is not an Alpha, so the rule now refuses it. The receipt Core needs is `SC-GB10-SERVE-CHAT`: build the server on the real Omega GPU engine, start Qwen3.8-27B, send one greedy chat request, shut down cleanly. Some details matter:

- A gb10 check that ran and FAILed is still a receipt; the bundle is then FAIL, which says more than "no receipt".
- A gb10 check that did not run itself (for example no checkpoint, or not enough free memory) is not a receipt.
- A gb10 result is never reused across commits; each head needs its own GPU run.

So GPU testing is the gate for an Alpha tag, not for merging. Under this rule an Alpha is a commit whose own GPU check ran.

The example, `alphachk.om`, models those rules in Omega. It reads `scope full|changed`, then one `check NAME BACKEND VERDICT` line per check ([with-gb10.txt](../examples/stack-08-alpha-tags/with-gb10.txt) is the passing one), and applies the rules in order: malformed input, scope, FAIL, GPU receipt, NOT_RUN. It is a model of documented rules, not the verifier, which also checks signatures and much more. The run ends by quoting the real rejection line from Core's docs at the pinned commit.

## Example

`alphachk.om` (shared helpers in [lib.om](../examples/stack-08-alpha-tags/lib.om)):

```om
note alphachk: a teaching model of the Alpha rule in aien-test verify-bundle --require-full (not that tool)
note input lines: "scope full|changed" and "check NAME BACKEND VERDICT", BACKEND host|gb10, VERDICT PASS|FAIL|NOT_RUN
note rules, in order: malformed input REFUSED; scope not full REJECTED NOT_FULL_SCOPE; any FAIL is FAIL (a gb10
note FAIL is still a receipt); no gb10 check that ran REJECTED NO_GPU_RECEIPT; any NOT_RUN is NOT_RUN; else ALPHA
note exit 0 ALPHA, 1 FAIL, 2 NOT_RUN, 3 REJECTED, 4 REFUSED
text words "scope check full changed host gb10 PASS FAIL NOT_RUN "
text tby "checks by backend: host="
text tgpu " gb10="
text tran "gb10 checks that ran (PASS or FAIL): "
text vok "verdict ALPHA: full-scope PASS that carries a gb10 receipt\n"
text vfail "verdict FAIL\n"
text vnrun "verdict NOT_RUN\n"
text vscope "verdict REJECTED NOT_FULL_SCOPE: plan scope is not full\n"
text vgpu "verdict REJECTED NO_GPU_RECEIPT: no required gb10 check ran on the GPU\n"
text vref "verdict REFUSED malformed line\n"
text nl "\n"
note g: 0 scope (1 full, 2 changed), 1 host, 2 gb10, 3 gb10 ran, 4 fails, 5 not run, 6 malformed
global g ulong 7
fn bump i ulong to void
put g i add get g i 1
end
fn tok a ulong b ulong to long
note the word a .. b-1 as an index into words
ret lookup words a b
end
fn check a ulong b ulong to void
note a is just after "check "; skip NAME, then read BACKEND and VERDICT
e = wordend a b
if ge e b
bump 6
else
p = add e 1
e = wordend p b
be = tok p e
if ge e b
bump 6
else
v = tok add e 1 b
if eq be 4
bump 1
else
if eq be 5
bump 2
else
bump 6
end
end
if eq v 7
bump 4
end
if eq v 8
bump 5
end
if lt v 6
bump 6
end
if eq be 5
if or eq v 6 eq v 7
bump 3
end
end
end
end
end
fn oneline a ulong b ulong to void
if lt a b
e = wordend a b
w = tok a e
if ge e b
bump 6
else
if eq w 0
s = tok add e 1 b
if eq s 2
put g 0 1
else
if eq s 3
put g 0 2
else
bump 6
end
end
else
if eq w 1
check add e 1 b
else
bump 6
end
end
end
end
end
fn verdict to int
if gt get g 6 0
ot vref
ret 4
end
if ne get g 0 1
ot vscope
ret 3
end
if gt get g 4 0
ot vfail
ret 1
end
if eq get g 3 0
ot vgpu
ret 3
end
if gt get g 5 0
ot vnrun
ret 2
end
ot vok
ret 0
end
fn main to int
r = rdall
if lt r 0
ret 4
end
if eq get st 2 1
ret 4
end
n = ulong r
a = ulong 0
for i ulong n
if eq get inb i 10
oneline a i
a = add i 1
end
end
oneline a n
ot tby
on get g 1
ot tgpu
on get g 2
ot nl
ot tran
on get g 3
ot nl
v = verdict
f = flush
ret v
end
```

Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
compile lib.om+alphachk.om rc=0
== with-gb10.txt
checks by backend: host=4 gb10=1
gb10 checks that ran (PASS or FAIL): 1
verdict ALPHA: full-scope PASS that carries a gb10 receipt
run rc=0
== host-only.txt
checks by backend: host=4 gb10=0
gb10 checks that ran (PASS or FAIL): 0
verdict REJECTED NO_GPU_RECEIPT: no required gb10 check ran on the GPU
run rc=3
== changed-scope.txt
checks by backend: host=4 gb10=1
gb10 checks that ran (PASS or FAIL): 1
verdict REJECTED NOT_FULL_SCOPE: plan scope is not full
run rc=3
== gb10-notrun.txt
checks by backend: host=4 gb10=1
gb10 checks that ran (PASS or FAIL): 0
verdict REJECTED NO_GPU_RECEIPT: no required gb10 check ran on the GPU
run rc=3
== gb10-fail.txt
checks by backend: host=4 gb10=1
gb10 checks that ran (PASS or FAIL): 1
verdict FAIL
run rc=1
== malformed.txt
checks by backend: host=1 gb10=1
gb10 checks that ran (PASS or FAIL): 1
verdict REFUSED malformed line
run rc=4
== what the real verifier prints for a host-only full-scope bundle (quoted from its docs at the pin)
REJECTED NO_GPU_RECEIPT: an Alpha needs a required check on backend gb10 that ran on the Spark's GPU, and this full-scope bundle has none (checks by backend: host=34; gb10 checks: none)
every verdict as expected: yes
```

Only the full-scope summary with a gb10 PASS is an Alpha. The host-only one is rejected with NO_GPU_RECEIPT, the same way the real verifier rejects a 34-check host-only bundle. A gb10 NOT_RUN is no receipt; a gb10 FAIL is a FAIL.

## Common mistake

Treating "all checks green" as release-ready. Green on which scope, on which backend? A green changed-scope pull request is mergeable, not an Alpha, and an Alpha is not hardware qualification: one GPU run is EXERCISED on the GB10, QUALIFIED needs the repeated physical runs. And never reuse an old GPU result for a new commit because "nothing GPU-related changed"; each head gets its own GPU run.

## Where to go deeper

- [Full scope: Alpha qualification, in Core's verifier docs](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/tools/aien-test/docs/LOCAL_VERIFICATION.md#L449)
- [The verify-bundle rejection codes in the source](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/tools/aien-test/src/bundle.rs#L36)
- [The GPU receipt gate, SC-GB10-SERVE-CHAT](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/tests/gates/sc-gb10-serve-chat.gate)
- [How the pipeline picks and tags an Alpha](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/tools/aien-local-ci/pipeline.sh#L335)
- [The aien-alpha command](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/tools/aien-local-ci/README.md#L212)
- [What the SI alpha release ships from Core's receipted tag](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/notes/alpha-20261026.1.md)
