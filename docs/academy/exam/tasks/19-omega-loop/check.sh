#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
P=$WS/sum.om
[ -f "$P" ] || fail "no sum.om"
grep -Eq '^[[:space:]]*while .* bound [0-9]+' "$P" || fail "sum.om has no bounded while loop"
if grep -Ev '^[[:space:]]*note' "$P" | grep -Eq '(^|[^0-9])55([^0-9]|$)'; then
	fail "sum.om writes the result 55 as a literal"
fi
omc_ready || notrun "$OMC_WHY"
mktmp T
cp "$P" "$T/sum.om"
(cd "$T" && limited 30 "$OMC" < sum.om > sum 2> omc.err)
crc=$?
[ "$crc" = 0 ] || fail "omc refused sum.om (exit $crc)"
chmod +x "$T/sum"
(cd "$T" && limited 10 ./sum > run.out 2>&1)
rrc=$?
[ "$rrc" = 55 ] || fail "program exits $rrc, not 55"
pass "compiled with the pinned omc, exits 55"
