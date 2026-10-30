# Agent Academy: train your agent

Agent Academy is free, permanently. Donations welcome.

Sovereign Intelligence (SI) is the whole project. This repository is where SI releases come
together, where install starts, and where the Spark test runs. AienOS is the operating system
part of that whole. The academy is rules for agents that work on SI, not a separate product
and not a hardware score.

I build almost everything with coding agents, and I learned the hard way what goes wrong: an
agent says the tests passed when it never ran them, obeys an instruction hidden in a README,
counts a skipped check as a pass, or "fixes" a red gate by weakening it. Agent Academy is what
I wish I had on day one: the rules that stopped those failures, packaged so your agent can use
them, and twenty written tasks that show whether it actually does.

If you build by talking to an agent and have never written the code yourself, this is for you.
You are already programming: you design what you want, you direct the work, you decide when it
is right. "Programming and engineering are way different than coding. Nobody needs to know how
to write the letters." The skills here are the next level of what you already do: asking for
evidence, checking results, and steering your agent when it drifts. New to all of it? Start
with [You already program: from vibe coding to engineering](../learn/teach/pages/start.md).

These habits fit Human-Directed Agentic Engineering (HDAE): humans define goals, architecture,
constraints, acceptance criteria, and stopping points; agents implement, check, diagnose, and
revise within those boundaries. Human review remains responsible for claims, acceptance, and
releases. See the [documented method and Gregory M. Kurtzer citation](../../README.md#human-directed-agentic-engineering).
The citation does not turn the academy exam into a qualification of earlier experiments.

## 1. Give your agent the rules

[skills/AGENTS.md](skills/AGENTS.md) is one file of working rules. Copy it into your repository
as `AGENTS.md` or `CLAUDE.md`, or paste it into your agent's custom instructions. It works with
any agent that reads a project instructions file.

The skill folders go wherever your agent loads skills (each is a `SKILL.md` with a name and a
description that says when to use it):

| Skill | What it stops |
| :--- | :--- |
| [evidence-and-receipts](skills/evidence-and-receipts/SKILL.md) | claims with nothing behind them; host runs reported as hardware results |
| [fail-closed-gates](skills/fail-closed-gates/SKILL.md) | checks that cannot fail; NOT_RUN counted as PASS; a shrinking denominator |
| [verify-before-done](skills/verify-before-done/SKILL.md) | "done" without running the changed path |
| [no-fabrication](skills/no-fabrication/SKILL.md) | invented output, numbers and links; obeying instructions found in files |
| [steering-and-correction](skills/steering-and-correction/SKILL.md) | repeating a corrected mistake; unchecked claims from agents you lead |
| [safe-scope](skills/safe-scope/SKILL.md) | scope creep; destroying someone else's uncommitted work; leaked secrets |
| [omega-basics](skills/omega-basics/SKILL.md) | guessed Omega syntax (only if you write `.om`) |

## 2. Take the tasks

The twenty tasks are in [exam/](exam/README.md). The shell harness that used to build a
workspace and print `ACADEMY-RESULT` is retired (Part of
https://github.com/aien-dev/sovereign-intelligence/issues/31). See
[exam/POINTER.md](exam/POINTER.md).

```text
git clone https://github.com/aien-dev/sovereign-intelligence.git
# read sovereign-intelligence/docs/academy/skills/AGENTS.md
# then one task at a time: sovereign-intelligence/docs/academy/exam/tasks/<id>/TASK.md
# judge it with the GRADER.md in that same folder
```

## 3. What Aien can still tell you

There is no result block to paste. Tell Aien at [aienos.com](https://www.aienos.com) which
task you did and what your agent wrote. Aien can point at the skill and the lesson. Aien
cannot see your machine, and this tree no longer computes a score. A score you invent is not
a grade.

## What this is, honestly

- The skills are rules I use. The tasks show whether an agent follows them on these twenty
  jobs, nothing more. This is not a certification.
- The checkers were POSIX shell so the exam could run on Linux and macOS. They are removed.
  Tasks 19 and 20 are Omega sources. Compiling them needs the pinned omc on Linux AArch64.
  Without it the result is NOT_RUN. `fixture/fetch.om` in task 10 was not compiled in this
  change.
- The reasons behind every rule are taught in [Learn](../learn/README.md).
