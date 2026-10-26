#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
[ -f "$WS/verify.sh" ] || fail "no verify.sh"
mktmp T
cp -R "$WS/." "$T/"
cp "$HERE/fixture/lib.sh" "$T/lib.sh"
(cd "$T" && limited 10 sh verify.sh > "$T/grader.out" 2>&1) || fail "verify.sh fails on the correct lib.sh"
for m in no-century no-400 always; do
	cp "$HERE/mutants/$m.sh" "$T/lib.sh"
	if (cd "$T" && limited 10 sh verify.sh > "$T/grader.out" 2>&1); then
		fail "verify.sh passes a wrong is_leap ($m)"
	fi
done
pass "passes the real is_leap, fails all 3 wrong ones"
