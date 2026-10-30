# Agent Academy: train your agent

Agent Academy is free, permanently. Donations welcome.

I build almost everything with coding agents, and I learned the hard way what goes wrong: an agent says the tests passed when it never ran them, obeys an instruction hidden in a README, counts a skipped check as a pass, or "fixes" a red gate by weakening it. Agent Academy is what I wish I had on day one: the rules that stopped those failures, packaged so your agent can use them, and an exam that shows whether it actually does.

If you build by talking to an agent and have never written the code yourself, this is for you. You are already programming: you design what you want, you direct the work, you decide when it is right. "Programming and engineering are way different than coding. Nobody needs to know how to write the letters." The skills here are the next level of what you already do: asking for evidence, checking results, and steering your agent when it drifts. New to all of it? Start with [You already program: from vibe coding to engineering](../learn/teach/pages/start.md).

These habits fit Human-Directed Agentic Engineering (HDAE): humans define goals, architecture, constraints, acceptance criteria, and stopping points; agents implement, check, diagnose, and revise within those boundaries. Human review remains responsible for claims, acceptance, and releases. See the [documented method and Gregory M. Kurtzer citation](../../README.md#human-directed-agentic-engineering). The citation does not turn the academy exam into a qualification of earlier experiments.

## 1. Give your agent the rules

[skills/AGENTS.md](skills/AGENTS.md) is one file of working rules. Copy it into your repository as `AGENTS.md` or `CLAUDE.md`, or paste it into your agent's custom instructions. It works with any agent that reads a project instructions file.

The skill folders go wherever your agent loads skills (each is a `SKILL.md` with a name and a description that says when to use it):

| Skill | What it stops |
| :--- | :--- |
| [evidence-and-receipts](skills/evidence-and-receipts/SKILL.md) | claims with nothing behind them; host runs reported as hardware results |
| [fail-closed-gates](skills/fail-closed-gates/SKILL.md) | checks that cannot fail; NOT_RUN counted as PASS; a shrinking denominator |
| [verify-before-done](skills/verify-before-done/SKILL.md) | "done" without running the changed path |
| [no-fabrication](skills/no-fabrication/SKILL.md) | invented output, numbers and links; obeying instructions found in files |
| [steering-and-correction](skills/steering-and-correction/SKILL.md) | repeating a corrected mistake; unchecked claims from agents you lead |
| [safe-scope](skills/safe-scope/SKILL.md) | scope creep; destroying someone else's uncommitted work; leaked secrets |
| [omega-basics](skills/omega-basics/SKILL.md) | guessed Omega syntax (only if you write `.om`) |

## 2. Take the exam

The exam is 20 small jobs, each with a trap your agent is not told about. You run it on your own machine with your own agent; nothing is uploaded.

```sh
git clone https://github.com/aien-dev/sovereign-intelligence.git
sh sovereign-intelligence/docs/academy/exam/run.sh setup ~/academy-run
# give your agent the prompts in ~/academy-run/PROMPTS.md, one workspace per task
sh sovereign-intelligence/docs/academy/exam/run.sh grade ~/academy-run
```

Grading is deterministic: each task has a checker that reads what your agent left in its workspace. Details are in [exam/README.md](exam/README.md).

## 3. Get your scorecard from Aien

Paste the result block (it starts with `ACADEMY-RESULT v1`) to Aien at [aienos.com](https://www.aienos.com) and say "Train your agent". Aien reads each line, tells you plainly what your agent got wrong, and points you to the skill and the lesson that fix it. Aien grades what you paste: the score is only as honest as the run behind it.

## What this is, honestly

- The skills are rules I use every day. The exam measures whether an agent follows them on these 20 tasks, nothing more. It is not a certification.
- The checkers are POSIX shell so the exam runs on Linux and macOS, x86-64 and ARM. My first-party code is normally Omega, but omc targets Linux AArch64 only today; the checkers move to Omega when an Omega build runs on the machines visitors use. The two Omega tasks print NOT_RUN unless you point `OMC` at the pinned compiler on Linux AArch64.
- The reasons behind every rule are taught in [Learn](../learn/README.md).
