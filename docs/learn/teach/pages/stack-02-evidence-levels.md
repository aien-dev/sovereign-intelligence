# Evidence levels and verdict words

Evidence level: EXERCISED. The summarizer ran on six sample logs on a Linux arm64 host; the logs are teaching samples, not real gate output.

## Goal

Learn the words I use to say how far something has got, the verdict words a gate may print, and build a summarizer that can never turn a NOT_RUN into a PASS.

## Explanation

Every claim in my repositories carries one level, the narrowest one that is true:

| Level | What it needs |
|---|---|
| PROPOSED | A plan, issue or design. No code that does it. |
| IMPLEMENTED | Code exists at a named revision. Compiling is not evidence. |
| EXERCISED | The path ran, with a stated command and an observed result kept as a receipt. |
| QUALIFIED | The project's named gate passed on the stated platform, for physical hardware three times with receipts. |
| MERGED | It is on the default branch. |
| DEPLOYED | The named running system has the revision and its live behaviour was checked. |

The last two are about where code is, not how good it is: something can be MERGED and only IMPLEMENTED. The four words on lesson cards, PROPOSED, IMPLEMENTED, EXERCISED and QUALIFIED, are the ladder of how much is proven. Nothing I build is QUALIFIED yet, and I say so on the front page.

Gates use a second vocabulary, the verdict words: PASS, FAIL, NOT_RUN, BLOCKED_HARDWARE, BLOCKED_OPERATOR and MISSING_IMPLEMENTATION. They are written in the omega-mv README and used across my repositories. The rule that matters most is short: NOT_RUN is not PASS. A gate that needs a GPU and did not get one did not pass; it did not run. A gate log with zero lines did not pass either. My Core verifier calls that the vacuous PASS and prints NOT_RUN for it.

The tempting bug is a summarizer that looks for FAIL and prints PASS otherwise. That design turns every skipped check, every blocked check and every line it does not understand into a pass. I write it the other way round, fail closed: PASS is the one verdict that has to be earned, by at least one line and by every line being PASS. Anything unknown is refused, not ignored.

The example is `gatesum.om`. It reads a gate log on stdin, one verdict word at the start of each line, counts them, and picks the worst: FAIL, then REFUSED for an unknown word, then MISSING_IMPLEMENTATION, BLOCKED, NOT_RUN. Each verdict has its own exit code, so a script calling it cannot confuse them. It runs on one good log and five negative controls.

## Example

`gatesum.om` (shared helpers in [lib.om](../examples/stack-02-evidence-levels/lib.om)):

```om
note gatesum: fail-closed summary of a gate log read on stdin, one verdict word at the start of each line
note PASS only when there is at least one line and every line is PASS; anything else wins over PASS
note exit 0 PASS, 1 FAIL, 2 NOT_RUN, 3 BLOCKED, 4 REFUSED (unknown word or input too big), 5 MISSING_IMPLEMENTATION
text words "PASS FAIL NOT_RUN BLOCKED_HARDWARE BLOCKED_OPERATOR MISSING_IMPLEMENTATION "
text tlines "lines "
text tpass "PASS "
text tfail "FAIL "
text tnrun "NOT_RUN "
text tblk "BLOCKED_* "
text tmiss "MISSING_IMPLEMENTATION "
text tunk "unknown "
text tverd "verdict "
text vpass "PASS"
text vfail "FAIL"
text vnrun "NOT_RUN"
text vblk "BLOCKED"
text vref "REFUSED"
text vmiss "MISSING_IMPLEMENTATION"
text nl "\n"
note cnt: 0 PASS, 1 FAIL, 2 NOT_RUN, 3 BLOCKED_HARDWARE, 4 BLOCKED_OPERATOR, 5 MISSING, 6 unknown, 7 lines
global cnt ulong 8
fn tally a ulong b ulong to void
note a .. b-1 is one line without its newline; empty lines are not counted
if lt a b
e = wordend a b
k = lookup words a e
if lt k 0
k = 6
end
i = ulong k
put cnt i add get cnt i 1
put cnt 7 add get cnt 7 1
end
end
fn kv t view uchar * v ulong to void
ot t
on v
ot nl
end
fn verdict to int
if gt get cnt 1 0
ret 1
end
if gt get cnt 6 0
ret 4
end
if gt get cnt 5 0
ret 5
end
if gt add get cnt 3 get cnt 4 0
ret 3
end
if gt get cnt 2 0
ret 2
end
if eq get cnt 0 0
note no PASS line at all: an empty log is NOT_RUN, never a vacuous PASS
ret 2
end
ret 0
end
fn vname v int to void
ot tverd
if eq v 0
ot vpass
end
if eq v 1
ot vfail
end
if eq v 2
ot vnrun
end
if eq v 3
ot vblk
end
if eq v 4
ot vref
end
if eq v 5
ot vmiss
end
ot nl
end
fn main to int
r = rdall
if lt r 0
ret 4
end
n = ulong r
a = ulong 0
for i ulong n
if eq get inb i 10
tally a i
a = add i 1
end
end
tally a n
if eq get st 2 1
put cnt 6 add get cnt 6 1
end
kv tlines get cnt 7
kv tpass get cnt 0
kv tfail get cnt 1
kv tnrun get cnt 2
kv tblk add get cnt 3 get cnt 4
kv tmiss get cnt 5
kv tunk get cnt 6
v = verdict
vname v
f = flush
if ne f 0
ret 4
end
ret v
end
```

Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
compile lib.om+gatesum.om rc=0
== good.log
lines 3
PASS 3
FAIL 0
NOT_RUN 0
BLOCKED_* 0
MISSING_IMPLEMENTATION 0
unknown 0
verdict PASS
run rc=0
== notrun.log
lines 3
PASS 2
FAIL 0
NOT_RUN 1
BLOCKED_* 0
MISSING_IMPLEMENTATION 0
unknown 0
verdict NOT_RUN
run rc=2
== fail.log
lines 3
PASS 1
FAIL 1
NOT_RUN 1
BLOCKED_* 0
MISSING_IMPLEMENTATION 0
unknown 0
verdict FAIL
run rc=1
== blocked.log
lines 2
PASS 1
FAIL 0
NOT_RUN 0
BLOCKED_* 1
MISSING_IMPLEMENTATION 0
unknown 0
verdict BLOCKED
run rc=3
== unknown.log
lines 2
PASS 1
FAIL 0
NOT_RUN 0
BLOCKED_* 0
MISSING_IMPLEMENTATION 0
unknown 1
verdict REFUSED
run rc=4
== empty.log
lines 0
PASS 0
FAIL 0
NOT_RUN 0
BLOCKED_* 0
MISSING_IMPLEMENTATION 0
unknown 0
verdict NOT_RUN
run rc=2
only good.log printed PASS: yes
```

Only `good.log` earns PASS. `notrun.log` has two PASS lines and one NOT_RUN, and the verdict is NOT_RUN with exit 2. The empty log is NOT_RUN as well. `unknown.log` says `OK`, which is not a verdict word, so the summary refuses it instead of guessing.

## Common mistake

Reporting "all tests pass" when some did not run. A typical version: 31 of 33 checks PASS, two are skipped because the machine had no GPU, and the summary says PASS. Write `31 PASS, 2 NOT_RUN (no GPU)`, and let the overall verdict be NOT_RUN. The second mistake is promoting a level by changing a word: a host run is EXERCISED, never QUALIFIED, however clean it is. Host and emulator results are not hardware qualification.

## Where to go deeper

- [omega-communication: the claim ladder and report shape](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md)
- [omega-mv README: the verdict words](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/README.md#L52)
- [Evidence words on the SI front page](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/README.md)
- [The vacuous PASS in Core's verifier](https://github.com/aien-dev/aien-sovereign-core-mv/blob/f30eb963918d71dd2998b1cb936c251429417de1/tools/aien-test/docs/LOCAL_VERIFICATION.md#L442)
- [Per-repository evidence audit](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/docs/WHAT-I-AM-BUILDING.md)
