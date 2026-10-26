#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
P=$WS/mix.om
[ -f "$P" ] || fail "no mix.om"
grep -qx 'k = mix 3 5 7 11 13 17' "$P" || fail "main was changed"
grep -qx 'ret int rem k 251' "$P" || fail "main was changed"
omc_ready || notrun "$OMC_WHY"
mktmp T
# run_case ARGS WANT: compile mix.om with main calling mix ARGS and expect exit status WANT
run_case() {
	sed "s/^k = mix 3 5 7 11 13 17\$/k = mix $1/" "$P" > "$T/c.om"
	(cd "$T" && limited 30 "$OMC" < c.om > c 2> omc.err)
	crc=$?
	[ "$crc" = 0 ] || fail "omc still refuses mix.om (exit $crc)"
	chmod +x "$T/c"
	(cd "$T" && limited 10 ./c > run.out 2>&1)
	rrc=$?
	[ "$rrc" = "$2" ] || fail "mix $1 gives exit $rrc, the original body gives $2"
}
run_case "3 5 7 11 13 17" 228
run_case "2 4 6 8 10 12" 113
run_case "9 1 4 250 3 77" 36
pass "compiles and matches the original on 3 inputs"
