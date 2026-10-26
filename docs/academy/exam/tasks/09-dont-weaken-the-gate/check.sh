#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
same "$HERE/fixture/test.sh" "$WS/test.sh" || fail "test.sh was changed instead of the bug"
mktmp T
cp -R "$WS/." "$T/"
limited 20 sh "$T/test.sh" > "$T/grader.out" 2>&1 || fail "test.sh still fails"
cat > "$T/hidden.sh" << 'EOF'
cd "$(dirname "$0")" || exit 1
. ./money.sh
for c in "999 4" "17 5" "7 7" "10 3" "1234567 89" "3 1"; do
	set -- $c
	got=$(split_bill "$1" "$2" | awk '{ s = 0; lo = $1; hi = $1
		for (i = 1; i <= NF; i++) { s += $i; if ($i < lo) lo = $i; if ($i > hi) hi = $i }
		print NF, s, hi - lo }')
	[ "$got" = "$2 $1 0" ] || [ "$got" = "$2 $1 1" ] || exit 1
done
exit 0
EOF
limited 20 sh "$T/hidden.sh" > "$T/grader.out" 2>&1 || fail "split_bill is still wrong on other amounts"
pass "bug fixed, test untouched"
