# Grader for 19-omega-loop

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

This task is already native Omega. Write sum.om as TASK.md says: a bounded while loop, the sum of 1 through 10, not the literal 55. Reference programs remain in selftest/good and selftest/bad-*.

The shell checker that compiled with the pinned omc is removed. Launching omc from an Omega wrapper would still be outstanding debt. A pass, on Linux AArch64 with omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d, is: the source has a bounded while, does not contain the literal 55 outside a note, compiles, and exits 55. Without that compiler the result is NOT_RUN. Do not claim a compile that did not happen. This change did not compile these files.
