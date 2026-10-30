# Asking for evidence

Evidence level: EXERCISED. The claim checker compiled and ran on a Linux ARM64 computer against an honest report, an overclaiming report and a malformed one; the reports are made-up examples.

## Goal

Know the four words that say how far a piece of work really got, ask your agent for the evidence behind each one, and never let "not run" pass as "passed".

## Explanation

"Done" means different things to different people. To an agent it often means "I wrote the code." To the person who will use it, it means "it works." Between those two there are several real steps, and most disappointments happen when someone skips one and still says "done".

I use four words, from weakest to strongest. Each needs specific evidence:

| Word | Means | Evidence it needs |
|---|---|---|
| PROPOSED | An idea or a plan. | Nothing yet. That is fine; just call it a plan. |
| IMPLEMENTED | The change exists. | A **commit** you can point to (a saved step in the project history). |
| EXERCISED | It ran. | The commit, the exact **command** that ran it, and the **output** it printed. |
| QUALIFIED | It passed the project's official check, its **gate**. | All of the above, and the gate's result: PASS. |

A **gate** is the check a project agrees must pass before something counts, like an inspection before a house is signed off. Gates report one of a few words: PASS, FAIL, or NOT_RUN.

**NOT_RUN is not PASS.** A check that did not run, crashed, was skipped or could not find its tools has told you nothing. It is not a quiet pass. It is a missing answer, and a missing answer counts as a failure until it runs.

The habit is simple: when an agent uses one of these words, ask for the evidence that goes with it. "You said it works. What command did you run, and what did it print?" If the evidence is not there, the honest word is the lower one. That is not a punishment. Calling something IMPLEMENTED instead of EXERCISED is just accurate, and accurate reports are how people come to trust your work.

## Example

`claims.om` reads one claim per line: three yes/no marks (commit named, command given, output given), the gate result (`P` pass, `F` fail, `N` not run, `-` no gate), the word the agent used, and what the claim is about. It works out the strongest word the evidence supports and compares. The rule:

```
fn support s ulong to ulong
if eq flag s 0 0
ret 0
end
if eq flag s 1 0
ret 1
end
if eq flag s 2 0
ret 1
end
if eq gate s 1
ret 3
end
ret 2
end
```

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile claims.om rc=0 (expected 0)

columns: commit named, command given, output given (1 yes, 0 no), gate (P pass, F fail, N not run, - none), claimed word, what

--- input honest.txt
0 0 0 - PROPOSED add a photo cache
1 0 0 - IMPLEMENTED resize photos on upload
1 1 1 - EXERCISED reject uploads over 10 MB
1 1 1 P QUALIFIED login page on the release gate
--- output
add a photo cache: claimed PROPOSED, evidence supports PROPOSED: OK
resize photos on upload: claimed IMPLEMENTED, evidence supports IMPLEMENTED: OK
reject uploads over 10 MB: claimed EXERCISED, evidence supports EXERCISED: OK
login page on the release gate: claimed QUALIFIED, evidence supports QUALIFIED: OK
HONEST: every claim is backed by the evidence attached
run rc=0 (expected 0)

--- input report.txt
1 0 0 - IMPLEMENTED resize photos on upload
0 0 0 - EXERCISED add a photo cache
1 1 0 F EXERCISED reject uploads over 10 MB
1 1 1 N QUALIFIED login page on the release gate
--- output
resize photos on upload: claimed IMPLEMENTED, evidence supports IMPLEMENTED: OK
add a photo cache: claimed EXERCISED, evidence supports PROPOSED: OVERCLAIM
reject uploads over 10 MB: claimed EXERCISED, evidence supports IMPLEMENTED: OVERCLAIM
  gate FAIL: a failed gate qualifies nothing
login page on the release gate: claimed QUALIFIED, evidence supports EXERCISED: OVERCLAIM
  gate NOT_RUN: NOT_RUN is not PASS
OVERCLAIMS=3
run rc=1 (expected 1)

--- input malformed.txt
1 1 1 P DONE everything works
--- output
REFUSE malformed line 1
run rc=3 (expected 3)

ALL EXIT STATUSES AS EXPECTED
```

The honest report uses every word at its right level, including PROPOSED for an idea, and passes. The second report has three overclaims. "Add a photo cache" is called EXERCISED with no commit at all. "Reject uploads over 10 MB" has a commit and a command but no output, and its gate failed. And "login page" claims QUALIFIED while its gate shows NOT_RUN, so the checker says what it is: exercised, not qualified. The last input is the negative control: "DONE" is not one of the four words, so the line is refused (exit 3), not guessed at.

## Common mistake

Accepting "done", "works" or "tested" without asking which word it really is. The fix is one question: "What is the evidence?" A commit means IMPLEMENTED. A command with its real output means EXERCISED. Only the gate's PASS means QUALIFIED. And when you see NOT_RUN anywhere in a report, treat it as unfinished, however green the rest looks.

## Where to go deeper

- Previous: [Reading what your agent changed](start-03-reading-the-diff.md). Next: [Steering with acceptance criteria](start-05-acceptance-criteria.md)
- The evidence words and gate verdicts in full: [stack-02-evidence-levels.md](stack-02-evidence-levels.md)
- Receipts, the files that hold the evidence: [stack-03-receipts.md](stack-03-receipts.md)
- Evidence on real hardware, and why a computer test is not a chip test: [cuda-06-chip-gates-and-receipts.md](cuda-06-chip-gates-and-receipts.md)
- How agents overclaim: [agents-07-failure-patterns.md](agents-07-failure-patterns.md)
- The claim ladder my agents use: https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-communication/SKILL.md
- The checker: [claims.om](../examples/start-04-asking-for-evidence/claims.om)
