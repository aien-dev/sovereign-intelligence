# Roles and models: who does the work, who gets consulted

Evidence level: EXERCISED. The decision rule below ran as a compiled `.om` program on a Linux AArch64 host; how much it improves real agents is not measured.

## Goal

Run one default worker for almost everything, and know exactly when to stop and ask a stronger model, and when to ask two of them independently.

## Explanation

I run my coding agents in a harness called omp (oh-my-pi). It lets me give each job a role, and each role a model. I keep the roles boring on purpose:

- **One default worker.** Most work is reading code, editing, running a check and reporting. One model does all of it, in every lane, so I always know what produced a change.
- **Consultants for hard calls.** I keep two read-only consultant roles backed by stronger models. They advise; they never edit. The worker stays responsible for the decision and the work.
- **Reviewer and advisor seats.** These read the finished work and judge it. Lesson 3 covers them.
- **A fast role and a slow role** for cheap lookups and deep reasoning, which the harness can switch to (`omp --smol`, `omp --slow`, `omp --plan` set them per run).

The interesting part is not the roles. It is the rule for when to consult, because consulting by default wastes money and hides who decided what, and never consulting lets a confident worker walk into an irreversible mistake. My rule lists five triggers. A worker consults only when one is true:

1. It has tried two different fixes and the problem is still there, or the root cause is unknown.
2. The next step is hard to reverse: a merge or admin override, deleting work, a gate or trust change, stopping a live service, a schema or protocol change.
3. Results contradict each other, or a measured number surprises it by more than its noise.
4. It is about to tell me something is done or safe and it is not sure.
5. (Modifier, not a trigger.) There is a real fork between two approaches.

Never consult for routine edits, lookups, or anything one more tool call can settle. That last clause matters most: an agent asking a consultant what a file contains is an agent that did not open the file.

When there is a real fork, I spawn **both** consultants in one batch with the same facts and file paths, and without the worker's own conclusion. Their answers are then independent readings. Where they agree, the worker acts. Where they disagree, it runs the cheapest check that separates them, or brings the choice to me with both positions. Note what "independent" means here: a fresh context gives another reading of the same facts. It does not prove the two consultants are different models or vendors. Check which model each role actually resolved to before you claim that.

The same discipline applies to asking me. Before an agent asks a person for information or a physical action, it exhausts its own tools: logs, device state, the network, existing instructions. Then it asks only for the smallest thing tools cannot provide.

## Example

I wrote the trigger list as a small Omega program so it can be checked instead of argued about. Each input line is six fields and a label: failed fixes (0 to 9), root cause unknown, hard to reverse, contradiction, unsure it is done, real fork. The core of `consult.om`:

```
fn reasons s ulong to void
if ge fld s 0 2
why 4
end
for i ulong 4
if eq fld s add i 1 1
why add i 5
end
end
end
fn decide s ulong e ulong to ulong
emiti add s 12 sub e add s 12
word 10
if lt fld s 0 2
if eq fld s 1 0
if eq fld s 2 0
if eq fld s 3 0
if eq fld s 4 0
say 0
ret 0
end
end
end
end
end
if eq fld s 5 1
say 2
else
say 1
end
reasons s
ret 1
end
```

The full program, with its input reader and printer, is `examples/agents-01-roles-and-models/consult.om`. Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output (the second input is the negative control: a malformed line must be refused, never guessed):

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile consult.om rc=0

--- input cases.txt
0 0 0 0 0 0 rename a local variable in my own lane
1 0 0 0 0 0 first fix for a failing test did not work
2 0 0 0 0 0 flaky test still fails after two different fixes
0 1 0 0 0 0 crash with no known cause
0 0 1 0 0 0 delete an old branch with unmerged work
0 0 0 1 0 0 benchmark moved more than its noise
0 0 1 0 0 1 change a wire format: two designs both look right
0 0 0 0 1 0 about to tell the owner a gate is safe
--- output
rename a local variable in my own lane: WORK alone (no trigger: routine work)
first fix for a failing test did not work: WORK alone (no trigger: routine work)
flaky test still fails after two different fixes: CONSULT one consultant
  why: two different fixes failed
crash with no known cause: CONSULT one consultant
  why: root cause unknown
delete an old branch with unmerged work: CONSULT one consultant
  why: hard to reverse
benchmark moved more than its noise: CONSULT one consultant
  why: results contradict or surprise
change a wire format: two designs both look right: CONSULT two independent consultants, same facts (real fork)
  why: hard to reverse
about to tell the owner a gate is safe: CONSULT one consultant
  why: unsure it is done or safe
consult=6 work=2
run rc=0 (expected 0)

--- input malformed.txt
0 0 0 0 0 0 routine edit
0 0 maybe 0 0 change the gate
--- output
routine edit: WORK alone (no trigger: routine work)
REFUSE malformed line 2
run rc=3 (expected 3)

ALL EXIT STATUSES AS EXPECTED
```

Two lines are worth reading closely. One failed fix is not a trigger: the worker tries a second, different fix first. And the wire-format change is both hard to reverse and a real fork, so it gets two consultants with the same facts.

## Common mistake

Consulting as a habit. A worker that asks a stronger model about every step hands off its judgement, burns budget and makes the record unclear about who decided. The fix is the trigger list: no trigger, no consult. The opposite mistake is just as real: a worker that never consults and then reports "done and safe" on a change it was unsure about. Trigger 4 exists for that moment.

A second mistake is assuming two consultants are independent because they have different names. Brief them with the same facts, never your conclusion, and check which models they actually ran.

## Where to go deeper

- The public agent rules these roles come from: https://www.aienos.com/agents/RULES.md
- The harness skill, section 4 (when to escalate to an independent reviewer): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- How the skills are packaged for omp and other agents: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/README.md
- The rule program itself: [consult.om](../examples/agents-01-roles-and-models/consult.om)
