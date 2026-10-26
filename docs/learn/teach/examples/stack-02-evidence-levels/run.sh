#!/bin/sh
# stack-02-evidence-levels: compile lib.om + gatesum.om with the pinned omc, then summarize six
# sample gate logs. Only good.log may print PASS; every other log is a negative control.
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

cat "$here/lib.om" "$here/gatesum.om" > "$tmp/unit.om"
"$OMC" < "$tmp/unit.om" > "$tmp/gatesum" 2> "$tmp/err"
rc=$?
echo "compile lib.om+gatesum.om rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/gatesum"

status=0
for log in good notrun fail blocked unknown empty; do
    echo "== $log.log"
    "$tmp/gatesum" < "$here/$log.log"
    rc=$?
    echo "run rc=$rc"
    case "$log" in
        good) [ "$rc" -eq 0 ] || status=1 ;;
        *) [ "$rc" -ne 0 ] || status=1 ;;
    esac
done
echo "only good.log printed PASS: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
