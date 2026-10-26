#!/bin/sh
# omega-05-seeded-compiler: rebuild omc from the 408-byte seed in a disposable copy and compare.
# Never touches the clone: the rebuild rewrites tracked files, so it runs in a mktemp copy of seed/.
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

echo "== 1. the committed compiler and the hash recorded beside it"
echo "seed/out/omc.sha256: $(cut -d' ' -f1 "$SRC/omega-mv/seed/out/omc.sha256")"
echo "seed0.bin bytes: $(wc -c < "$SRC/omega-mv/seed/rung0/seed0.bin")"
echo "omc bytes: $(wc -c < "$OMC")"
echo "omc.om lines: $(wc -l < "$SRC/omega-mv/seed/omc/omc.om")"

echo "== 2. birth: seed0 -> hex1 -> asm2 -> om4 -> omc -> omc -> omc, in a disposable copy"
mkdir "$T/m"
cp -R "$SRC/omega-mv/seed" "$T/m/seed"
(cd "$T/m" && sh seed/omega-from-seed.sh)
brc=$?
echo "omega-from-seed.sh rc=$brc"
want "birth" "$brc" 0
born=$(sha256sum "$T/m/seed/out/omc" | cut -d' ' -f1)
if [ "$born" = "$PIN" ]; then echo "rebuilt omc equals the pin: yes"; else echo "rebuilt omc equals the pin: no ($born)"; fail=1; fi

echo "== 3. the rebuilt compiler and the committed one make the same program bytes"
"$T/m/seed/out/omc" < "$here/hello.om" > "$T/h1"; r1=$?
"$OMC" < "$here/hello.om" > "$T/h2"; r2=$?
echo "compile rc=$r1 and rc=$r2"
if cmp -s "$T/h1" "$T/h2"; then echo "hello binaries identical: yes"; else echo "hello binaries identical: no"; fail=1; fi

echo "== 4. negative control: a changed compiler source reaches a fixpoint of its own"
cat "$here/extra.om" >> "$T/m/seed/omc/omc.om"
B=$T/m/b
mkdir "$B"
"$T/m/seed/rung4/om4.bin" < "$T/m/seed/omc/omc.om" > "$B/s1"; chmod +x "$B/s1"
"$B/s1" < "$T/m/seed/omc/omc.om" > "$B/s2"; chmod +x "$B/s2"
"$B/s2" < "$T/m/seed/omc/omc.om" > "$B/s3"
s1=$(sha256sum "$B/s1" | cut -d' ' -f1)
s2=$(sha256sum "$B/s2" | cut -d' ' -f1)
s3=$(sha256sum "$B/s3" | cut -d' ' -f1)
[ "$s1" = "$s2" ] && echo "om4-built equals omc-built: yes" || echo "om4-built equals omc-built: no"
[ "$s2" = "$s3" ] && echo "stage2 equals stage3 (a fixpoint): yes" || echo "stage2 equals stage3 (a fixpoint): no"
if [ "$s3" = "$PIN" ]; then echo "mutant fixpoint equals the pin: yes"; fail=1; else echo "mutant fixpoint equals the pin: no"; fi
want "mutant fixpoint" "$s2" "$s3"
finish
