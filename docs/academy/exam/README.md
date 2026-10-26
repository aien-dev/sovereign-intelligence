# Agent Academy exam v0

Twenty small, realistic jobs for your own coding agent. Each one hides a common way agents go
wrong: claiming a pass without running the tests, obeying instructions planted in a file or a
log, counting NOT_RUN as PASS, inventing a number, weakening a test, leaking a secret, wiping a
teammate's uncommitted work, overstating how far a feature has got. A deterministic grader checks
the workspace afterwards. Then you paste the result block to Aien at https://www.aienos.com and get
an honest scorecard with the skill and the lesson that fix each miss.

The exam is free, permanently. Everything runs on your machine; nothing is uploaded, and the
graders make no network calls.

## What you need

- A POSIX shell, coreutils, grep, sed, awk and git (Linux or macOS).
- A coding agent that can read and write files in a folder you choose.
- For tasks 19 and 20 (Omega): the pinned omc compiler on Linux AArch64, with sha256
  befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d, named by the OMC
  environment variable. Without it those two tasks grade NOT_RUN, never PASS.

## Run it

1. Build the workspaces in an empty folder:

       sh exam/run.sh setup ~/academy-run

   This creates one folder per task and ~/academy-run/PROMPTS.md.

2. Give the tasks in PROMPTS.md to your agent. Paste them one at a time (a fresh session per task
   is the fairest test) or all at once. Paste each prompt as written and do not add hints: the
   point is to see what your agent does on its own.

3. Grade:

       sh exam/run.sh grade ~/academy-run

   For the Omega tasks, set OMC first: `OMC=/path/to/omc sh exam/run.sh grade ~/academy-run`.

4. Copy the whole block that starts with `ACADEMY-RESULT v1` and ends with the `SCORE` line, and
   paste it to Aien at https://www.aienos.com. Aien explains each FAIL and NOT_RUN and points to
   the skill pack (skills/) and the lesson that fixes it. The mapping is in rubric.json.

Each grader line reads `<task> PASS|FAIL|NOT_RUN <reason>`. The `exam=` value identifies this
exact version of the tasks, so a result from an edited exam is visible as such.

## Honesty

The result you paste is self-reported. Aien grades what is pasted and cannot see your machine, so
a truthful scorecard needs an honest run: untouched graders and prompts given to the agent as
written. A workspace nobody worked on scores FAIL or NOT_RUN on every task.

## Checking the graders

`sh exam/selftest.sh` builds, for every task, the untouched workspace, a reference good state and
one or more bad states (the failure the task catches), and checks that good passes, every bad
fails and nothing untouched passes. It prints `ACADEMY-SELFTEST PASS tasks=20`, or
`omc_not_run=2` at the end when OMC is not the pinned compiler.
