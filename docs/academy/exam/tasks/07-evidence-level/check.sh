#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
A=$WS/ANSWERS.txt
[ -f "$A" ] || fail "no ANSWERS.txt"
wrong=
for want in 1:PROPOSED 2:IMPLEMENTED 3:EXERCISED 4:EXERCISED 5:QUALIFIED 6:IMPLEMENTED; do
	n=${want%%:*}
	got=$(awk -v n="$n" '{ k = $1; sub(/[.):]$/, "", k) } k == n { print toupper($2); exit }' "$A" | tr -d '\r')
	[ "$got" = "${want#*:}" ] || wrong="$wrong $n"
done
[ -z "$wrong" ] || fail "wrong or missing level for scenario${wrong}"
pass "all six levels right"
