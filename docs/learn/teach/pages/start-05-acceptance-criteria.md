# Steering with acceptance criteria

Evidence level: EXERCISED. The spec checker compiled and ran on a Linux ARM64 computer against one ready task and two weak ones; it checks the shape of a task, not whether the goal is a good idea.

## Goal

Hand an agent a task it can finish and you can check: a goal, an acceptance check you can observe, a negative control, and what is out of scope.

## Explanation

The previous four lessons were about checking work after the agent did it. This one moves the checking to the start, where it is cheapest. Most wasted agent time comes from tasks like "make uploads better": the agent cannot know when it is finished, so it keeps going, and you cannot know whether it succeeded, so you argue with it.

A task an agent can actually finish has four parts:

- **Goal**: one sentence about what should be true afterwards. "Refuse photo uploads larger than 10 MB with a clear message."
- **Acceptance**: how you will know, written as something you can *observe*: an exit code, an output, what it prints. "A 12 MB upload exits 1 and prints 'too large'; a 2 MB upload exits 0." The phrase "it works" is not acceptance; it is a hope.
- **Negative control**: one way to prove the acceptance check can fail (lesson 2). "Set the limit to 20 MB and confirm the 12 MB test now fails." If the check still passes, the check is broken.
- **Out of scope**: what must not change (lesson 3). "Do not change the login page or settings.txt." This one line prevents most surprise diffs.

These are called **acceptance criteria**: the conditions the work must meet to be accepted. Writing them takes two minutes. It also gives the agent something it badly needs: a way to check itself before it reports back, so its report comes with evidence (lesson 4) instead of "I think it's done".

A good test of your own spec: could a stranger read it and tell, without asking you anything, whether the result passed? If not, add what they would have to ask.

## Example

`spec.om` reads a task and holds it until all four parts have text, and until the acceptance line names something observable (an exit status, an output, or what it prints). The decision part:

```
fn observ n ulong to bool
s = ulong 0
while lt s n bound 65536
e = eol s n
if pmat s e KACC
for k ulong 3
if within s e add KOBS k
ret true
end
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
if has KACC n
if not observ n
say MVAGUE
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

```sh
sh examples/start-05-acceptance-criteria/run.sh
```

Recorded output:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile spec.om rc=0 (expected 0)

--- input ready.txt
Goal: refuse photo uploads larger than 10 MB with a clear message
Acceptance: a 12 MB upload exits 1 and prints "too large"; a 2 MB upload exits 0
Negative control: set the limit to 20 MB and confirm the 12 MB test now fails
Out of scope: do not change the login page or settings.txt
--- output
Goal: ok
Acceptance: ok
Negative control: ok
Out of scope: ok
READY: an agent can start, and you can tell when it is done
run rc=0 (expected 0)

--- input vague.txt
Goal: make uploads better
Acceptance: it works and looks good
Negative control: none needed
Out of scope: nothing
--- output
Goal: ok
Acceptance: ok
Negative control: ok
Out of scope: ok
Acceptance: nothing you could observe (name an exit status, an output, or what it prints)
NOT READY: tighten the spec before you hand it to an agent
run rc=1 (expected 1)

--- input no-control.txt
Goal: refuse photo uploads larger than 10 MB with a clear message
Acceptance: a 12 MB upload exits 1 and prints "too large"
--- output
Goal: ok
Acceptance: ok
Negative control: MISSING
Out of scope: MISSING
NOT READY: tighten the spec before you hand it to an agent
run rc=1 (expected 1)

ALL EXIT STATUSES AS EXPECTED
```

The first task is ready. The second has all four headings filled in, and it is still held, because "it works and looks good" names nothing anyone could observe. Look closely and you will also see what the checker cannot catch: "Negative control: none needed" counts as filled in. A checker narrows what you need to read; it does not replace reading. The third task has a good goal and acceptance but no negative control and no scope, so the agent would be free to change anything and you could not prove the check works.

## Common mistake

Steering only after the fact: giving a vague task, then correcting the agent round after round until the result feels right. Each correction is acceptance criteria you could have written at the start. The fix is to spend two minutes up front on the four parts, then hold the agent to them: "Show me the 12 MB run and the 2 MB run, and the negative control." That is engineering. You did not have to write a single line of code to do it.

## Where to go deeper

- Previous: [Asking for evidence](start-04-asking-for-evidence.md). Back to the [track overview](start.md)
- The full handoff I give my own agents: [agents-08-evidence-handoff.md](agents-08-evidence-handoff.md)
- How I correct an agent that drifts: [agents-06-correcting-agents.md](agents-06-correcting-agents.md)
- When to ask a stronger model for help: [agents-01-roles-and-models.md](agents-01-roles-and-models.md)
- The handoff checklist my agents use: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md
- The checker: [spec.om](../examples/start-05-acceptance-criteria/spec.om)
