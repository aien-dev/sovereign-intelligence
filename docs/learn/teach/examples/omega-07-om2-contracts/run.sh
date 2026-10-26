#!/bin/sh
# omega-07-om2-contracts: the OM-2 profile. Layouts, fresh scratch and sealed types checked by omc.
# Host-only (Linux AArch64). Env: SRC (pinned clones), OMC (pinned compiler).
set -u
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" 2>/dev/null | cut -d' ' -f1)
[ "$got" = "$PIN" ] || { echo "omc sha256 mismatch (wanted $PIN)"; exit 90; }
echo "omc sha256 $PIN"
T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT HUP INT TERM
fail=0
# compile NAME WANT: compile NAME.om into $T/NAME, print status and stderr, check the status.
compile() {
    "$OMC" < "$here/$1.om" > "$T/$1" 2> "$T/$1.err"
    crc=$?
    echo "compile $1.om rc=$crc"
    cat "$T/$1.err"
    want "$1 compile" "$crc" "$2"
}
# runit NAME WANT: run a program that compiled with 0 (never a refused one), check its status.
runit() {
    if [ "$crc" -ne 0 ]; then echo "run $1 NOT_RUN (compile refused)"; fail=1; return; fi
    chmod +x "$T/$1"
    "$T/$1"
    rrc=$?
    echo "run $1 rc=$rrc"
    want "$1 run" "$rrc" "$2"
}
want() { [ "$2" = "$3" ] || { echo "UNEXPECTED $1: got $2, wanted $3"; fail=1; }; }
finish() { [ "$fail" -eq 0 ] && echo "RESULT PASS" || echo "RESULT FAIL"; exit "$fail"; }
TOUR=$SRC/omega-mv/examples/om2-tour.om
# tour NAME WANT: compile $T/NAME.om (a variant of the tour), print status and, on refusal, the first stderr line.
tour() {
    "$OMC" < "$T/$1.om" > "$T/$1" 2> "$T/$1.err"
    crc=$?
    echo "compile $1 rc=$crc"
    [ "$crc" -eq 0 ] || sed -n 1p "$T/$1.err"
    want "$1 compile" "$crc" "$2"
}

echo "== 1. an external byte layout, written through an edit parameter"
compile header 0
runit header 0
echo "== 2. error 29 (layout): two fields share a byte"
compile overlap 29
echo "== 3. error 27 (init): a fresh element is read before it is written"
compile fresh 27
echo "== 4. without the om2 line, rotr is an unknown word (error 3)"
compile oneline 3

echo "== 5. the repository's tour: examples/om2-tour.om"
cp "$TOUR" "$T/tour.om"
tour tour 0
runit tour 0
echo "== 6. the same tour under 'om2 diag': trap sites and the erased constructor check"
sed '2s/^om2$/om2 diag/' "$TOUR" > "$T/diag.om"
tour diag 0
echo "omc-site records: $(grep -c '^omc-site 1 ' "$T/diag.err")"
grep '^omc-check 1 ' "$T/diag.err"
echo "== 7. negative control: a predicate omc does not know (holds v32 dup31)"
sed 's/^holds v32 dup32$/holds v32 dup31/' "$TOUR" > "$T/dup31.om"
tour dup31 28
echo "== 8. negative control: one changed constant in stamp is caught by main"
sed 's/^put c lo 0x01020304$/put c lo 0x01020305/' "$TOUR" > "$T/stamp.om"
tour stamp 0
runit stamp 11
finish
