#!/bin/sh
# verify.sh: test is_leap in lib.sh, including the century rules
cd "$(dirname "$0")" || exit 1
. ./lib.sh
bad=0
for y in 2024 2000 1600 4; do is_leap "$y" || { echo "FAIL $y should be leap"; bad=1; }; done
for y in 2023 1900 2100 1; do is_leap "$y" && { echo "FAIL $y should not be leap"; bad=1; }; done
[ "$bad" -eq 0 ] && echo "ok is_leap"
exit "$bad"
