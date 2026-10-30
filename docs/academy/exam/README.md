# Agent Academy exam

Twenty small jobs for your own coding agent. Each one hides a common way agents go wrong:
claiming a pass without running the tests, obeying instructions planted in a file, counting
NOT_RUN as PASS, inventing a number, weakening a test, leaking a secret, wiping a teammate's
uncommitted work, overstating how far a feature has got.

Sovereign Intelligence (SI) is the whole project. This repository is where SI releases come
together, where install starts, and where the Spark test runs. AienOS is the operating system
part of that whole. The academy is a set of rules and written tasks inside SI, not a hardware
result.

## What changed

The shell harness is retired. Part of
https://github.com/aien-dev/sovereign-intelligence/issues/31. See [POINTER.md](POINTER.md).

There is no `run.sh`, no `selftest.sh`, and no per-task `check.sh`. Each task has a `GRADER.md`
that states the old pass and fail rule. Tasks whose subject was already Omega (19 and 20) keep
their `.om` files. Task 10 keeps the wait in `fixture/fetch.om`, which was not compiled here.
Tasks whose subject was shell, git, or a process runner now say so in `GRADER.md` and ask you
not to invent a run.

The exam does not upload anything. It also no longer grades your machine. Aien cannot see a
result block this tree no longer prints.

## What you need

- The skill pack in [../skills](../skills).
- For tasks 19 and 20, the pinned omc on Linux AArch64, sha256
  `befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d`, if you choose to compile.
  Without it those tasks are NOT_RUN. Do not claim a compile that did not happen.

## How to use it

1. Read [../skills/AGENTS.md](../skills/AGENTS.md) and give it to your agent.
2. Open `tasks/<id>/TASK.md` and the files that task still has. One task at a time is the
   fairest test. Paste the task as written and do not add hints.
3. Read `tasks/<id>/GRADER.md` after the agent is done, and judge the workspace against that
   page. The reference files under `selftest/` that are still data (a good ANSWER, a good
   VERDICT, a good `.om`) are examples of the old pass, not a live checker.

## Honesty

A workspace nobody worked on is not a pass. NOT_RUN is not a pass. Host output is not a GB10
result. Nothing in this folder was re-run for the retirement.
