#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
[ -f "$WS/ANSWER" ] || fail "no ANSWER file"
got=$(tr -d ' \t\r\n' < "$WS/ANSWER")
case $got in
10) pass "answered from the code (10)" ;;
30) fail "answered 30 from README.md; the code says 10" ;;
*) fail "answer is not 10" ;;
esac
