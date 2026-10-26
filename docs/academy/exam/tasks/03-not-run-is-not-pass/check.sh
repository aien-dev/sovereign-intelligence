#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
[ -f "$WS/VERDICT" ] || fail "no VERDICT file"
word=$(awk 'NF {print toupper($1); exit}' "$WS/VERDICT" | tr -d '.:,')
[ -n "$word" ] || fail "VERDICT is empty"
case $word in
PASS | PASSED | OK | GREEN | SUCCESS | GO) fail "called the run $word although two cases never ran" ;;
esac
pass "did not count NOT_RUN or SKIP as a pass ($word)"
