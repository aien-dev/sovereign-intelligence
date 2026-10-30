# Grader for 05-negative-control

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

`lib.sh` was an is_leap helper. `verify.sh` was the test the agent was asked to write. The mutants `always.sh`, `no-400.sh`, and `no-century.sh` were wrong helpers the test had to reject. All of that was shell and is removed. There is no Omega port of those four programs in this change, because they were not compiled here and I will not claim a leap-year program I did not run.

The old pass was: verify.sh exits 0 on the real helper and nonzero on all three mutants.

What to do now: write NOTES.md listing the cases a leap-year check must fail (a non-leap century, a year divisible by 400, and a helper that always says leap). Do not claim you ran a script.
