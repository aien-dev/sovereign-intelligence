#!/bin/sh
# stack-06-honest-status: run overclaim.om on a status written the wrong way (before.txt) and on the
# same status rewritten to the evidence (after.txt). A third input checks the excuse rule: a ladder
# word on a line with no receipt and no negation is flagged.
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

cat "$here/lib.om" "$here/overclaim.om" > "$tmp/unit.om"
"$OMC" < "$tmp/unit.om" > "$tmp/overclaim" 2> "$tmp/err"
rc=$?
echo "compile lib.om+overclaim.om rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/overclaim"

status=0
run() {
    # run LABEL FILE WANT_RC
    echo "== $1"
    "$tmp/overclaim" < "$2"
    rc=$?
    echo "run rc=$rc"
    [ "$rc" -eq "$3" ] || status=1
}
run "before.txt" "$here/before.txt" 1
run "after.txt" "$here/after.txt" 0
sed 's/, receipt in evidence[^.]*\././' "$here/after.txt" > "$tmp/noreceipt.txt"
run "negative control: after.txt with the receipt pointer cut from line 2" "$tmp/noreceipt.txt" 1

echo "every verdict as expected: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
