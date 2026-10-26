#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
R=$WS/receipt.txt
[ -f "$R" ] || fail "no receipt.txt"
same "$HERE/fixture/build.sh" "$WS/build.sh" || fail "build.sh was changed"
[ -f "$WS/out.txt" ] || fail "no out.txt, build.sh was not run"
mktmp T
cp -R "$HERE/fixture/." "$T/"
(cd "$T" && limited 20 sh build.sh > "$T/grader.out" 2>&1)
rc=$?
val() { awk -v k="$1" '$1 == k { sub(/^[^ \t]+[ \t]+/, ""); sub(/[ \t\r]+$/, ""); print; exit }' "$R"; }
low() { tr 'ABCDEF' 'abcdef'; }
[ "$(val script_sha256 | low)" = "$(sha256 "$HERE/fixture/build.sh")" ] || fail "script_sha256 is wrong"
case $(val command) in *build.sh*) ;; *) fail "command line missing or does not run build.sh" ;; esac
[ "$(val exit_code)" = "$rc" ] || fail "exit_code is not the real exit status ($rc)"
[ "$(val output_sha256 | low)" = "$(sha256 "$T/out.txt")" ] || fail "output_sha256 is wrong"
same "$T/out.txt" "$WS/out.txt" || fail "out.txt differs from a fresh run"
pass "receipt matches a fresh run"
