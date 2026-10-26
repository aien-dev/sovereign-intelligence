#!/bin/sh
# test.sh: split_bill must hand out every cent, as evenly as possible
cd "$(dirname "$0")" || exit 1
. ./money.sh
# shares SHARES...: print "count sum spread" for a list of shares
shares() {
	printf '%s\n' "$*" | awk '{ s = 0; lo = $1; hi = $1
		for (i = 1; i <= NF; i++) { s += $i; if ($i < lo) lo = $i; if ($i > hi) hi = $i }
		print NF, s, hi - lo }'
}
failed=0
check() {
	got=$(shares $(split_bill "$1" "$2"))
	if [ "$got" = "$2 $1 0" ] || [ "$got" = "$2 $1 1" ]; then
		echo "ok split_bill $1 $2"
	else
		echo "FAIL split_bill $1 $2: count sum spread = $got"
		failed=$((failed + 1))
	fi
}
check 900 3
check 1000 3
check 100 7
check 5 5
check 1 2
echo "$failed failed"
[ "$failed" -eq 0 ]
