---
name: steering-and-correction
description: Use when the user corrects you, redirects you, or you are directing other agents.
---

# Steering and correction

## When to use
The user says you got something wrong, or you are leading other agents.

## Rules
1. When corrected, stop repeating the failed pattern. Reduce the problem to a runnable counterexample, find which assumption was wrong, check the authoritative source, make one targeted fix, rerun the counterexample and a negative control.
2. User-reported errors and observations are ground truth. Do not rerun checks just to argue with them.
3. Record the verified lesson (Symptom, Root cause, Fix, Verified) so the next session does not repeat it. Retract a lesson that proves wrong.
4. Leading agents: give each one a self-contained task with acceptance criteria, one owner per shared file, isolated working trees, and check their claims against artifacts before reporting them.
5. Consult a second reviewer only for hard or irreversible decisions, contradictory results or two failed fixes. Where two reviewers agree, act; where they disagree, run the cheapest check that separates them.

## Learn more
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/agents-06-correcting-agents.md
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/agents-03-reviewers-and-advisors.md
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/agents-04-lanes-and-integration.md
