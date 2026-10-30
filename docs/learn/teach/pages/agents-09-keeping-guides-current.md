# Keeping the guides current: part of every task

Evidence level: EXERCISED. The guide check ran as a compiled `.om` program on changes in a throwaway git repository on a Linux AArch64 host; the rule table is a teaching subset of the real one.

## Goal

Make sure that whoever changes the system also updates the guide that describes it, in the same piece of work, so agents never learn from a stale skill.

## Explanation

Skills and instruction files (lesson 2) are only useful while they are true. The day the compiler gains a word or a gate changes its command, every agent reading the old skill starts making confident mistakes, and nothing fails to warn you, because documentation has no test.

My rule is simple: **the agent that makes the change updates the guides.** Not a documentation pass later, not a note for someone else. A task that changes something a skill describes is not done until the skill matches the new reality.

To make that checkable, my harness skill keeps a table that maps a kind of change to the guide that must absorb it. For example: the language, compiler or its pin goes to the encoding skill; build, gate or verification commands go to the workflow skill; status vocabulary, receipts and handoff conventions go to the communication skill; repository purpose, ownership or status goes to the routing skill and the project's master index.

How it is done:

1. Edit the guide in the same piece of work as the change. Give the new source commit and date. Delete the rule the change made untrue; do not add a second rule that contradicts it.
2. If an example or its expected output changed, rerun it against the new pin and record what you observed. Never copy a predicted result into a guide.
3. Open the guide's pull request with the evidence, linked to the change that caused it. If that change is not merged yet, open it as a draft and say it is pending.
4. If you are not allowed to change the guide, open an issue describing exactly what is now stale. Silence is not an option.
5. The final report says which guides were updated, or that none was affected and why.

Never rewrite old evidence to match the new state. A receipt records what was true at its commit; the guide moves forward, the receipt stays.

## Example

`guides.om` reads the list of changed paths (from `git diff --name-only`) and applies a rule table: a change under `compiler/` needs `skills/omega-encoding/`, `gates/` needs `skills/omega-harness/`, `wire/` needs `skills/omega-communication/`. The rule part:

```
fn any k ulong n ulong to bool
s = ulong 0
while lt s n bound 65536
e = eol s n
if pmat s e k
ret true
end
s = add e 1
end
ret false
end
fn rule r ulong n ulong to ulong
t = mul r 2
if not any t n
ret 0
end
word t
word 6
word add t 1
if any add t 1 n
say 7
ret 1
end
say 8
ret 2
end
fn main to int
r = rdall
if lt r 0
ret 2
end
n = ulong r
hit = ulong 0
bad = ulong 0
for i ulong NR
v = rule i n
if ne v 0
hit = add hit 1
end
if eq v 2
bad = add bad 1
end
end
if eq hit 0
say 9
ret 0
end
if eq bad 0
say 10
ret 0
end
say 11
ret 1
end
```

The past host run made three commits in a throwaway repository and checked each one:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output. The first commit changes the compiler and leaves its guide alone, so it is stale (exit 1). The second changes both (exit 0). The third is a docs typo that no guide describes, and the checker says to state that in the report:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile guides.om rc=0

--- change: compiler change, guide left alone
changed paths:
compiler/lower.om
--- guides.om says
compiler/ changed; its guide skills/omega-encoding/ was NOT updated: STALE
GUIDES STALE: update the guide before calling this done
run rc=1 (expected 1)

--- change: compiler change with its guide
changed paths:
compiler/lower.om
skills/omega-encoding/SKILL.md
--- guides.om says
compiler/ changed; its guide skills/omega-encoding/ was updated in the same change
GUIDES CURRENT
run rc=0 (expected 0)

--- change: typo fix in docs
changed paths:
docs/intro.md
--- guides.om says
GUIDES: no guide affected (say why in the report)
run rc=0 (expected 0)

ALL EXIT STATUSES AS EXPECTED
```

In the real project the guides live in a separate repository from the compiler, so the "same change" is a linked pair of pull requests, not one commit. The checker here keeps both in one repository so it fits in a page; the rule is the same.

## Common mistake

Leaving the guide for later, or for "the docs owner". Later never comes, and the next agent reads the old rule with full confidence. The second mistake is appending a new rule under the old one ("Note: as of today, error 12 also means..."), so the guide now contradicts itself. Replace the untrue rule, cite the commit, rerun the example.

## Where to go deeper

- The change-to-guide map (section 6): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- "Keeping it current" and how pins are refreshed: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/README.md
- The project's master index, updated in the same piece of work as a repository change: https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/README.md
- The checker: [guides.om](../examples/agents-09-keeping-guides-current/guides.om)
