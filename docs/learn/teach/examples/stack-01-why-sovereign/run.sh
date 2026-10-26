#!/bin/sh
# stack-01-why-sovereign: compile elfinfo.om with the pinned omc and ask what each binary needs
# below it. The compiler and the program it builds need only the kernel; the host's /bin/sh needs a
# loader and libc (negative control); a text file is not an ELF at all (second negative control).
set -u
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" | cut -d' ' -f1)
if [ "$got" != "$PIN" ]; then
    echo "omc sha256 is not the pin $PIN"
    exit 90
fi
echo "omc sha256 $PIN"
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

cat "$here/lib.om" "$here/elfinfo.om" > "$tmp/unit.om"
"$OMC" < "$tmp/unit.om" > "$tmp/elfinfo" 2> "$tmp/err"
rc=$?
echo "compile lib.om+elfinfo.om rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/elfinfo"

status=0
echo "== the pinned compiler, omc"
"$tmp/elfinfo" < "$OMC"
rc=$?
echo "run rc=$rc"
[ "$rc" -eq 0 ] || status=1

echo "== elfinfo itself, as omc built it"
"$tmp/elfinfo" < "$tmp/elfinfo"
rc=$?
echo "run rc=$rc"
[ "$rc" -eq 0 ] || status=1

echo "== negative control: the host's /bin/sh (verdict line only; its sizes differ between hosts)"
"$tmp/elfinfo" < /bin/sh > "$tmp/sh.out"
rc=$?
grep '^verdict' "$tmp/sh.out"
echo "run rc=$rc"
[ "$rc" -eq 1 ] || status=1

echo "== negative control: elfinfo.om, a text file"
"$tmp/elfinfo" < "$here/elfinfo.om"
rc=$?
echo "run rc=$rc"
[ "$rc" -eq 3 ] || status=1

echo "every verdict as expected: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
