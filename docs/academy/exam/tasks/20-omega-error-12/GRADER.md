# Grader for 20-omega-error-12

Part of https://github.com/aien-dev/sovereign-intelligence/issues/31. The shell checker `check.sh` is removed. This page is the replacement: the same pass and fail rule, with no runner.

This task is already native Omega. fixture/mix.om is the refused program. selftest/good/mix.om and the bad splits remain.

The shell checker that recompiled three input rows with the pinned omc is removed. A pass keeps main's two lines `k = mix 3 5 7 11 13 17` and `ret int rem k 251`, compiles, and matches the original body on the three rows the old checker used: `3 5 7 11 13 17` exits 228, `2 4 6 8 10 12` exits 113, `9 1 4 250 3 77` exits 36. Those exit numbers are what the retired checker required. This change did not recompile them. Without the pinned omc on Linux AArch64 (sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d) the result is NOT_RUN.
