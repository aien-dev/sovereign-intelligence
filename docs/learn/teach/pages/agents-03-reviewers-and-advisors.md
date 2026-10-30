# Reviewers and advisors: who checks the work, and how to weigh them

Evidence level: EXERCISED. The weighing rule ran as a compiled `.om` program on a Linux AArch64 host; it encodes the rule, it does not measure reviewer quality.

## Goal

Set up review so that the agent who did the work is never its only check, and turn several reviews into a decision without obeying the loudest one.

## Explanation

One line of my rules carries this whole lesson: **the witness verifies and touches nothing.** An agent reviewing its own change, as the only check, has not been reviewed. So I separate the offices.

**Reviewer agents.** After a lane finishes, a reviewer agent reads the diff and the evidence. A separate security reviewer looks only for trust problems: secrets, new trust paths, unchecked input, gates that got weaker. Reviewers are read-only. They report findings; they do not fix them.

**Advisor seats.** My harness can attach advisors that read the whole run when it ends (`omp --advisor` turns the runtime on). I keep a small roster, one seat per office, and each seat has one narrow question:

- an **intent** seat: is this the direction I asked for?
- a **witness** seat with read-only tools: for every claim of done, PASS, merged or measured, where is the artifact that proves it, and does it say the same thing?
- a **numbers** seat: recompute every number in Wolfram and flag anything not labelled MEASURED or MODELED;
- a **direction** seat: is new first-party code going into a host language instead of Omega, or is a layer being removed before its replacement carries the load?
- a **trust** seat: could anything here mislead me, and was any outside effect (merge, publish, delete, gate change) taken without my word?

Every seat is told to speak only with concrete evidence (a file and line, a command's output, a receipt path), to stay silent when nothing in its office is wrong, and never to repeat another seat. A model review is still not a receipt. It tells you where to look.

**Weighing aggregated reviews.** When several reviews come back, I do not average them and I do not obey them. Per finding:

- Both reviewers say it is a defect, each with evidence: **act**.
- They disagree, both with evidence: **check**. Find the cheapest command that separates the two readings and run it. The result decides, not the reviewer's confidence.
- Only one gives evidence: **verify**. Open the cited artifact yourself before acting.
- Nobody gives evidence: **drop** it. An unsupported assertion is not a vote, however confident it sounds.

## Example

`weigh.om` takes two verdict letters per finding: `Y` (defect, with evidence), `N` (not a defect, with evidence), `U` (a claim with no evidence, which counts as no vote). The decision part:

```
fn vote c uchar to ulong
if eq c 89
ret 1
end
if eq c 78
ret 2
end
if eq c 85
ret 0
end
ret 9
end
fn count s ulong v ulong to ulong
c = ulong 0
if eq vote get inb s v
c = add c 1
end
if eq vote get inb add s 1 v
c = add c 1
end
ret c
end
fn judge s ulong to ulong
y = count s 1
n = count s 2
if eq y 2
ret 0
end
if eq y 1
if eq n 1
ret 1
end
ret 2
end
ret 3
end
```

Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output (the second input is the negative control: an unknown verdict letter is refused, not read as a vote):

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile weigh.om rc=0

--- input reviews.txt
YY loop bound off by one in the parser
YN race in the lock release path
YU read result not checked for a negative count
UU helper name could be clearer
NN suspected leak in the cache
UN unused import
--- output
loop bound off by one in the parser: ACT (both reviewers agree, with evidence)
race in the lock release path: CHECK (they disagree: run the cheapest check that separates them)
read result not checked for a negative count: VERIFY (one evidenced finding: open the cited artifact yourself)
helper name could be clearer: DROP (no evidenced finding)
suspected leak in the cache: DROP (no evidenced finding)
unused import: DROP (no evidenced finding)
act=1 check=1 verify=1 drop=3
run rc=0 (expected 0)

--- input malformed.txt
YY real finding
Y? reviewer gave no verdict letter
--- output
real finding: ACT (both reviewers agree, with evidence)
REFUSE malformed line 2
run rc=3 (expected 3)

ALL EXIT STATUSES AS EXPECTED
```

The race finding is the one that matters in practice. One reviewer says the lock release races, the other says it cannot. The answer is not a third opinion. It is a test that runs the two releases concurrently, or a read of the lock's documented ordering: whichever is cheaper and actually separates the two claims.

## Common mistake

Treating the most confident review as the answer, or acting on every finding to make the reviewers happy. Both skip the evidence. A related mistake is asking the agent that wrote the change to "double-check" itself and calling that a review. It shares every blind spot it had while writing. Use a separate, read-only reviewer, and when reviewers disagree, run the cheapest separating check instead of asking for more opinions.

## Where to go deeper

- Shared rules, section 1 (the witness) and section 4 (gates): https://www.aienos.com/agents/RULES.md
- When to escalate to an independent reviewer: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
- Report shape a reviewer can check against: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md
- The program: [weigh.om](../examples/agents-03-reviewers-and-advisors/weigh.om)
