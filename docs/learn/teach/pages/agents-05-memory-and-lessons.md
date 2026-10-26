# Memory and lessons: keep what was verified, retract what was wrong

Evidence level: EXERCISED. The lesson validator ran as a compiled `.om` program on a Linux AArch64 host with one accepted entry and two refused ones; the memory system itself is not tested here.

## Goal

Give agents a long-term memory that makes the next session smarter instead of more confidently wrong.

## Explanation

Every agent session starts empty. Without memory, the next agent pays again for the bug the last one already solved. With careless memory it is worse: the next agent inherits a guess and treats it as a fact.

So my memory holds **lessons, not files**. Saving ten documents into a store is not learning. Each entry is one distilled lesson in four lines:

- **Symptom:** what you saw (the exact error, status or wrong output).
- **Root cause:** why it happened, as far as it was established.
- **Fix:** the one targeted change.
- **Verified:** how the fix was shown to work: the command, its status, the negative control. Name the source commit so a reader can tell when the lesson may have gone stale.

The `Verified` line is the gate. A lesson without it is a hypothesis, and a hypothesis stored as a lesson is how an untested workaround becomes an unconditional rule that every later agent obeys. My memory tool refuses debug lessons that lack those lines, and the example below does the same check in Omega.

Three more rules keep memory honest:

1. **Memory is navigation, not proof.** A recalled lesson tells an agent where to look. It never replaces reading the current source or running the check. If memory and the repository disagree, the repository wins and the memory gets corrected.
2. **Retract, don't pile on.** When a lesson turns out wrong, retract that entry by its id and record the corrected one. Adding a second, contradicting lesson leaves the next agent to guess which is true.
3. **Keep it where it survives.** A lesson in a temporary file is a lesson you pay for twice. My machine wipes its temporary directory at boot, which taught me to copy cited evidence and a resume note somewhere durable before any reboot.

The repeated-error routine in my harness skill ends the same way: reduce the problem to a runnable counterexample, check the authoritative source, make one correction, rerun the counterexample and the negative control, and only then record the verified causal lesson with its pin and the condition that would invalidate it.

## Example

`lesson.om` accepts an entry only when all four lines are present and each has text after its label. The checking part:

```
fn filled at ulong e ulong to bool
i = at
while lt i e bound 65536
if ne get inb i 32
ret true
end
i = add i 1
end
ret false
end
fn has k ulong n ulong to bool
s = ulong 0
while lt s n bound 65536
e = eol s n
if pmat s e k
if filled add s klen k e
ret true
end
end
s = add e 1
end
ret false
end
fn main to int
r = rdall
if lt r 0
ret 2
end
n = ulong r
miss = ulong 0
for k ulong NF
word k
if has k n
say MOK
else
say MMISS
miss = add miss 1
end
end
if eq miss 0
say MPASS
ret 0
end
say MFAIL
ret 1
end
```

Run it:

```sh
sh examples/agents-05-memory-and-lessons/run.sh
```

Recorded output. The first entry is accepted. The second has no `Verified` line, and the third has the label with nothing after it; both are refused with exit 1:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile lesson.om rc=0

--- input good.txt
Symptom: the seeded compiler exits 12 on a long function
Root cause: more live names than the 16-register pool
Fix: split the function into two helpers
Verified: recompiled with the pinned omc, compile rc=0, run rc=0
--- output
Symptom: ok
Root cause: ok
Fix: ok
Verified: ok
ACCEPT lesson
run rc=0 (expected 0)

--- input no-verified.txt
Symptom: the seeded compiler exits 12 on a long function
Root cause: probably the register pool
Fix: split the function
--- output
Symptom: ok
Root cause: ok
Fix: ok
Verified: MISSING
REFUSE lesson: every field needs text, and an unverified lesson is a guess
run rc=1 (expected 1)

--- input empty-verified.txt
Symptom: the seeded compiler exits 12 on a long function
Root cause: probably the register pool
Fix: split the function
Verified:
--- output
Symptom: ok
Root cause: ok
Fix: ok
Verified: MISSING
REFUSE lesson: every field needs text, and an unverified lesson is a guess
run rc=1 (expected 1)

ALL EXIT STATUSES AS EXPECTED
```

Look at the wording of the refused entries: "probably the register pool". That is what an unverified lesson usually sounds like. The accepted one names the command and both statuses.

## Common mistake

Treating "saved to memory" as "learned". An agent reports that it seeded memory with ten entries, and nobody checks whether any of them holds a lesson someone can act on. Check the content, not the count. The second mistake is trusting a recalled lesson over the current code. Memory was written at some commit; the code may have moved since. Recall, then verify against the source before acting.

## Where to go deeper

- The repeated-error routine and what to record (section 5): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- Corrections without rewriting old evidence: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md
- Skills and memory are navigation aids, not language authorities (section 1): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- The validator: [lesson.om](../examples/agents-05-memory-and-lessons/lesson.om)
