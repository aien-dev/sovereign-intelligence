# Failure patterns: how agents overclaim, and how to catch it

Evidence level: EXERCISED. The runner-log tally ran as a compiled `.om` program on a Linux AArch64 host against one passing log and three failing controls; it is a teaching checker, not a project gate.

## Goal

Recognize the handful of ways agent reports go wrong, and put a mechanical check in front of each.

## Explanation

Agents rarely lie on purpose. They overclaim because a fluent summary is cheaper to produce than a checked one. These are the patterns I see most, and the check for each:

**Fabricated or unbacked receipts.** A report says PASS, merged, or "measured faster than before", and there is no artifact. The check: every claim of done, PASS, merged or measured names its artifact (the log, the commit, the PR state), and someone other than the author opens it. If it was not measured, it was not done.

**Silent test loss.** The runner reports zero failures, but it ran fewer cases than exist: case files went missing, a loader skipped rows, a crash ended the run early. The pass rate looks perfect because the denominator shrank. The check: fix the expected case count *before* the run, and compare against it. Fewer results than expected is a failure, not a smaller success.

**NOT_RUN counted as PASS.** A skipped check, a missing toolchain or a crashed step is not a pass. It is a failure until it runs. Report it under its own name.

**Compile success taken as behavior.** A program that compiles has shown nothing about what it does. Run the changed path, compare expected and observed output and status, and run a negative control that must fail.

**Overclaiming status.** Keep proposed, implemented, exercised, qualified, merged and deployed separate. A host or emulator run is not hardware qualification. A merged pull request is not a deployment. An open pull request is not current behavior.

**Config restored before the child starts.** A subtle one from my own setup. To run one child agent on a different model, a lead agent changed the model setting, spawned the child, and restored the setting in the same step. The child read its model when it actually started, after the restore, so it ran on the default model while the lead reported otherwise. The check: confirm from the child's own session record which model it ran before claiming it, and restore only after that.

The common thread: the report is not the evidence. Something independent has to look.

## Example

`tally.om` reads a runner log whose first line is `expect N`, the case count fixed before the run. It counts `PASS`, `FAIL`, and `NOT_RUN` or `SKIP` lines, ignores runner noise, and passes only if every expected case produced a PASS. The decision part:

```
fn flags x ulong m ulong to void
if lt m x
shout 9 sub x m
say 10
end
if gt m x
shout 11 sub m x
say 12
end
if gt get cnt 2 0
shout 13 get cnt 2
say 14
end
end
fn main to int
r = rdall
if lt r 0
ret 2
end
n = ulong r
e = eol 0 n
x = expn 0 e
if eq x 0
say 15
ret 3
end
s = add e 1
while lt s n bound 65536
e = eol s n
k = kind s e
put cnt k add get cnt k 1
s = add e 1
end
m = add add get cnt 0 get cnt 1 get cnt 2
shout 5 x
shout 6 m
shout 7 get cnt 0
shout 8 get cnt 1
shout 16 get cnt 2
shout 17 get cnt 3
say 18
flags x m
if eq get cnt 0 x
if eq m x
say 19
ret 0
end
end
say 20
ret 1
end
```

`run.sh` first shows the naive reading (count FAIL lines, call zero green), then runs the tally on four logs:

```sh
sh examples/agents-07-failure-patterns/run.sh
```

Recorded output:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile tally.om rc=0

naive reading first: count FAIL lines and call zero a green run
full.log: FAIL lines=0
shrunk.log: FAIL lines=0
notrun.log: FAIL lines=0
noexpect.log: FAIL lines=0

--- input full.log
expect 5
PASS parse_empty
PASS parse_long
runner: cache warm
PASS trap_bounds
PASS trap_div0
PASS io_short_read
--- output
expected=5 results=5 pass=5 fail=0 not_run=0 noise=1
VERDICT PASS
run rc=0 (expected 0)

--- input shrunk.log
expect 5
PASS parse_empty
PASS parse_long
PASS trap_bounds
runner: 2 case files not found, continuing
--- output
expected=5 results=3 pass=3 fail=0 not_run=0 noise=1
SHRUNK: denominator lost 2 case(s): they produced no result, so they did not pass
VERDICT FAIL
run rc=1 (expected 1)

--- input notrun.log
expect 5
PASS parse_empty
PASS parse_long
PASS trap_bounds
NOT_RUN trap_div0
SKIP io_short_read
--- output
expected=5 results=5 pass=3 fail=0 not_run=2 noise=0
NOT_RUN or SKIP=2 (NOT_RUN is not PASS)
VERDICT FAIL
run rc=1 (expected 1)

--- input noexpect.log
PASS parse_empty
PASS parse_long
PASS trap_bounds
--- output
REFUSE: no expected case count, so no pass rate can be trusted
run rc=3 (expected 3)

ALL EXIT STATUSES AS EXPECTED
```

All four logs have zero FAIL lines, so the naive reading calls every one of them green. Only the first is. `shrunk.log` lost two cases while the runner said "continuing"; `notrun.log` has two cases that never ran; `noexpect.log` has no fixed denominator, so no rate from it can be trusted, and the tally refuses it with exit 3 instead of guessing.

## Common mistake

Trusting the summary line a runner prints. "0 failed" is true in every one of the failing logs above. Always ask how many cases were expected, how many produced a result, and how many never ran, and treat any gap as a failure. In your own runners, fail closed: a missing case file or a crash should end the run with a nonzero status, never "continuing".

## Where to go deeper

- Fail closed, NOT_RUN is not PASS (section 4): https://www.aienos.com/agents/RULES.md
- The claim ladder and gate words: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md
- Compile, execute, challenge, with a negative control (section 3): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- The tally: [tally.om](../examples/agents-07-failure-patterns/tally.om)
