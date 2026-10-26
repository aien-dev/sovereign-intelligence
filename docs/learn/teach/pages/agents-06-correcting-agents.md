# Correcting and redirecting agents: how I steer

Evidence level: EXERCISED. The report check ran as a compiled `.om` program on a Linux AArch64 host; the steering patterns come from my own sessions and are not a measured study.

## Goal

Correct an agent in a way that changes what it does next, and give it rules that catch the same drift before you have to.

## Explanation

Most of my time with agents is not writing prompts. It is noticing what an agent just did and redirecting it in one or two sentences. Over many sessions the corrections fall into a few patterns. Each pattern below has a steer card (s01 to s13) that shows what the agent did, in my summary, and the lesson.

**Freedom is not permission to guess (s01, s13).** An agent with autonomy still looks facts up: in the documentation, in the source, in the vendor manual. When it writes a compiler backend for a chip, it works from the primary documentation, not from what it remembers.

**Verify it yourself (s02, s07).** If the agent's tools can check something, it checks it. It does not hand me a verification step, and it does not ask me what is on a screen after looking at one signal. It asks a person only for what its tools truly cannot reach.

**A missing piece is a task (s04, s09).** When an agent finds that a part it needs was designed but never built, the answer is to build it, not to plan a route around it. On new ground, it builds the thing instead of hunting for an outside answer. I call this *fix it, don't file it*: a defect you can reproduce is a defect you can fix, in the same piece of work, even in someone else's lane. Stop only for a real external gate: an authorization you do not have, a decision that is mine, or a check you have genuinely exhausted, and then name that gate.

**Aim for the limit (s05, s10).** "Better" is not the goal and 90 percent of the hardware limit is not a target. The physical limit is the target; measure how close you got.

**Search before you claim or brief (s06).** Before an agent says something is missing, new or done, it searches everywhere it could live. Once a lead agent briefed workers before searching, and a later sweep found the problem already solved in another repository.

**Check understanding before handing over work (s11).** Before a new agent takes over unfinished work, I ask it to explain what it is taking over, and I check the answer.

**Look at the real artifact (s12).** When something fails, the agent examines the actual output, log or receipt, not a general story about that kind of failure.

How I correct: I name what the agent did, the principle it missed, and the next concrete action. I never soften a correction into a suggestion, and I never repeat a correction an agent can read in its rules. When the same correction recurs, it moves into the shared rules or a skill, so it costs nothing next time.

## Example

The *fix it, don't file it* pattern can be checked mechanically on a report. Each line says `found N`, `fixed N`, `filed N` or `blocked N <gate>`. Every found defect must end fixed, or blocked by a named external gate. Filing an issue alone does not close it. The decision part of `fixfile.om`:

```
fn mark s ulong e ulong to bool
k = verb s e
if eq k 9
ret false
end
a = add s klen k
if ge a e
ret false
end
id = idnum a e
if eq id 999
ret false
end
b = uchar shl ulong 1 k
if eq k 3
if not gated a e
b = uchar 0
end
end
put st id or get st id b
ret true
end
fn show id ulong to ulong
f = get st id
word 4
emitu id
if ne and f 2 0
say 5
ret 0
end
if ne and f 8 0
say 6
ret 0
end
say 7
ret 1
end
```

Run it:

```sh
sh examples/agents-06-correcting-agents/run.sh
```

Recorded output. The first report is done. The second filed defect 2 and wrote `blocked 3` without naming a gate, so it is not done. The third is the negative control: an unknown verb is refused, not ignored:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile fixfile.om rc=0

--- input report-fixed.txt
found 1
fixed 1
found 2
fixed 2
found 3
blocked 3 hardware window not authorized
--- output
defect 1: FIXED
defect 2: FIXED
defect 3: BLOCKED by a named external gate
REPORT OK: nothing left that the agent could fix
run rc=0 (expected 0)

--- input report-filed.txt
found 1
fixed 1
found 2
filed 2
found 3
blocked 3
--- output
defect 1: FIXED
defect 2: UNFINISHED (found, not fixed, no external gate named)
defect 3: UNFINISHED (found, not fixed, no external gate named)
REPORT NOT DONE: unfinished defects=2
run rc=1 (expected 1)

--- input malformed.txt
found 1
wontfix 1
--- output
REFUSE malformed line 2
run rc=3 (expected 3)

ALL EXIT STATUSES AS EXPECTED
```

## Common mistake

Narrating obstacles instead of removing them: "I found a bug in the parser; I have filed issue 42 for the owner." That reads as diligence and leaves the work unfinished. Redirect with the specific principle and next action ("You can reproduce it; fix it here and show the rerun"), and if the agent claims a block, ask which external gate. The second mistake is correcting by mood rather than by rule. A correction an agent cannot turn into a check will drift back within a session.

## Where to go deeper

- The shared rules these corrections come from: https://www.aienos.com/agents/RULES.md
- Thinking forward instead of stopping at "impossible" (section 2): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- How the project reports what is and is not done: https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/docs/WHAT-I-AM-BUILDING.md
- The checker: [fixfile.om](../examples/agents-06-correcting-agents/fixfile.om)
