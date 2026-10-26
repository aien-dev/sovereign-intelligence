#!/bin/sh
# stack-08-alpha-tags: a teaching model of the Alpha rule (aien-test verify-bundle --require-full) run on
# six small bundle summaries. Only with-gb10.txt may be an Alpha. This is not the real verifier, which is
# Rust in aien-sovereign-core-mv tools/aien-test and checks signed bundles; that tool is NOT_RUN here.
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

cat "$here/lib.om" "$here/alphachk.om" > "$tmp/unit.om"
"$OMC" < "$tmp/unit.om" > "$tmp/alphachk" 2> "$tmp/err"
rc=$?
echo "compile lib.om+alphachk.om rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/alphachk"

status=0
for pair in with-gb10:0 host-only:3 changed-scope:3 gb10-notrun:3 gb10-fail:1 malformed:4; do
    f=${pair%%:*}
    w=${pair#*:}
    echo "== $f.txt"
    "$tmp/alphachk" < "$here/$f.txt"
    rc=$?
    echo "run rc=$rc"
    [ "$rc" -eq "$w" ] || status=1
done

echo "== what the real verifier prints for a host-only full-scope bundle (quoted from its docs at the pin)"
grep -o 'REJECTED NO_GPU_RECEIPT: an Alpha needs[^`]*host=34; gb10 checks: none)' \
    "$SRC/aien-sovereign-core-mv/tools/aien-test/docs/LOCAL_VERIFICATION.md"

echo "every verdict as expected: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
