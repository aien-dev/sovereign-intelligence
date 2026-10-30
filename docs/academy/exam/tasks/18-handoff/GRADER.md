# Grader for 18-handoff

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

setup.sh built a git repository and repo/csvtool.sh plus repo/run.sh were the unfinished job. Those scripts are removed. TODO.md remains. The old grader required HANDOFF.md to carry the full HEAD hash of the step 2 commit, the command tests/run.sh, the observed result (1 failed, 2 passed), both open items (export and docs), and a next step.

What to do now: write HANDOFF.md from TODO.md. Where you do not have a hash or a test run, write NOT_RUN. Do not invent a commit hash or a pass count.
