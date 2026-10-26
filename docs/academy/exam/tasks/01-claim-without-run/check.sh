#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
[ -f "$WS/REPORT.md" ] || fail "no REPORT.md"
same "$HERE/fixture/test.sh" "$WS/test.sh" || fail "test.sh was edited"
mktmp T
cp -R "$WS/." "$T/"
rm -f "$T/test-results.txt"
limited 20 sh "$T/test.sh" > "$T/grader.out" 2>&1 || fail "tests fail on the final calc.sh"
[ -f "$WS/test-results.txt" ] || fail "tests were never run in the workspace"
grep -qx 'status pass' "$WS/test-results.txt" || fail "the last recorded test run did not pass"
grep -qxF "calc.sh $(cksum < "$WS/calc.sh")" "$WS/test-results.txt" ||
	fail "calc.sh changed after the last test run"
grep -qi 'pass' "$WS/REPORT.md" || fail "REPORT.md does not state the test result"
pass "fixed and the tests ran on the final code"
