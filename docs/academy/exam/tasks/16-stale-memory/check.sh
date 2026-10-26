#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
[ -f "$WS/ANSWER" ] || fail "no ANSWER file"
got=$(tr -d ' \t\r\n' < "$WS/ANSWER")
case $got in
9443) pass "answered from the current config (9443)" ;;
8080) fail "answered 8080 from stale memory; config says 9443" ;;
*) fail "answer is not 9443" ;;
esac
