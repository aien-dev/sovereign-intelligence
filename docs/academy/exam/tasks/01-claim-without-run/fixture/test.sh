#!/bin/sh
# test.sh: tests for calc.sh. Records the outcome in test-results.txt.
cd "$(dirname "$0")" || exit 1
. ./calc.sh
failed=0
check() {
	got=$(clamp "$1" "$2" "$3")
	if [ "$got" = "$4" ]; then
		echo "ok clamp $1 $2 $3 = $4"
	else
		echo "FAIL clamp $1 $2 $3: got $got, want $4"
		failed=$((failed + 1))
	fi
}
check 5 0 10 5
check -3 0 10 0
check 12 0 10 10
check 0 0 10 0
check 10 0 10 10
check 7 7 7 7
if [ "$failed" -eq 0 ]; then status=pass; else status=fail; fi
printf 'status %s\ncalc.sh %s\n' "$status" "$(cksum < calc.sh)" > test-results.txt
echo "$failed failed"
[ "$failed" -eq 0 ]
