#!/bin/sh
# Lesson cuda-08: read GPU machine code back. sass.om decodes the 32 instructions of the
# seed-built GB10 vector add (omega-mv seed/sm121/vecadd.bin) into fields, the names come from
# the hand-written table sm121.tbl, and the decoded add is compared with the listing's comment.
# Host only: the bytes are read as a file, never loaded onto a GPU.
set -u
export LC_ALL=C
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" 2>/dev/null | cut -c1-64)
if [ "$got" != "$PIN" ]; then
    echo "omc sha256 mismatch: refusing to run"
    exit 90
fi
echo "omc sha256 $PIN"
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
S=$SRC/omega-mv/seed/sm121
echo "vecadd.bin sha256 $(sha256sum < "$S/vecadd.bin" | cut -c1-64), $(wc -c < "$S/vecadd.bin" | tr -d ' ') bytes"

"$OMC" < "$here/sass.om" > "$tmp/ss" 2> "$tmp/err"
rc=$?
echo "compile rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/ss"
"$tmp/ss" < "$S/vecadd.bin" > "$tmp/out"
rc=$?
cat "$tmp/out"
echo "run rc=$rc"

echo "== names for each opcode, from the base words in sm121.tbl (word 0, bits 0..11)"
grep '^= [a-z0-9.]*\.0 ' "$S/sm121.tbl" | while read -r eq name base rest; do
    printf '%03x %s\n' $(( base & 4095 )) "${name%.0}"
done > "$tmp/names"
sed -n 's/^ *[0-9]* op=0x\([0-9a-f]*\) .*/\1/p' "$tmp/out" | sort -u | while read -r op; do
    echo "0x$op: $(grep "^$op " "$tmp/names" | cut -d' ' -f2 | tr '\n' ' ')"
done

echo "== oracle: the listing's own comment for this instruction (vecadd.s2)"
want=$(sed -n 's/^; \(IADD3 [^ ].*RZ\) .*/\1/p' "$S/vecadd.s2")
echo "listing: $want"
if grep -qF "decoded: $want" "$tmp/out"; then echo "decoded add: MATCH"; else echo "decoded add: DIFFERS"; fi

echo "== negative control: one bit changed in the add's destination register (byte 274)"
head -c 274 "$S/vecadd.bin" > "$tmp/mut.bin"
printf '\010' >> "$tmp/mut.bin"
tail -c +276 "$S/vecadd.bin" >> "$tmp/mut.bin"
"$tmp/ss" < "$tmp/mut.bin" > "$tmp/mut"
rc=$?
grep 'decoded' "$tmp/mut"
if grep -qF "decoded: $want" "$tmp/mut"; then echo "decoded add: MATCH"; else echo "decoded add: DIFFERS"; fi
echo "mutant run rc=$rc"
