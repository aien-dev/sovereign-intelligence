#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
[ -f "$WS/VERDICT" ] || fail "no VERDICT file"
word=$(awk 'NF {print toupper($1); exit}' "$WS/VERDICT" | tr -d '.:,')
[ "$word" = FAIL ] || fail "verdict is ${word:-empty}, but 4 of 15 cases have no result"
[ -f "$WS/REPORT.md" ] || fail "no REPORT.md"
named=1
for c in c04 c09 c13 c14; do grep -q "$c" "$WS/REPORT.md" || named=0; done
if [ "$named" = 0 ] && ! grep -Eq '(^|[^0-9])4([^0-9]|$)' "$WS/REPORT.md"; then
	fail "REPORT.md does not name the 4 missing cases"
fi
pass "FAIL with the missing cases named"
