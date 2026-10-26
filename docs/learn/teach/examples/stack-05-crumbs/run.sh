#!/bin/sh
# stack-05-crumbs: read real public .crumb files from the pinned clones and judge their shape with
# crumbchk.om. Two mutants are negative controls: a renamed key and a missing purpose.
# This checks shape only; the real tool is `crumb validate` / `crumb verify` in aien-architecture-mv.
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

cat "$here/lib.om" "$here/crumbchk.om" > "$tmp/unit.om"
"$OMC" < "$tmp/unit.om" > "$tmp/crumbchk" 2> "$tmp/err"
rc=$?
echo "compile lib.om+crumbchk.om rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/crumbchk"

wasm=$SRC/omega-mv/seed/wasm/.crumb
learner=$SRC/omega-mv/evidence/physics0/learner/.crumb
core=$SRC/aien-sovereign-core-mv/.crumb
sed 's/"purpose":/"status":/' "$wasm" > "$tmp/renamed.crumb"
grep -v '"purpose"' "$learner" > "$tmp/nopurpose.crumb"

status=0
run() {
    # run LABEL FILE WANT_RC
    echo "== $1"
    "$tmp/crumbchk" < "$2"
    rc=$?
    echo "run rc=$rc"
    [ "$rc" -eq "$3" ] || status=1
}
run "omega-mv seed/wasm/.crumb" "$wasm" 0
run "omega-mv evidence/physics0/learner/.crumb" "$learner" 0
run "aien-sovereign-core-mv .crumb (root)" "$core" 3
run "negative control: seed/wasm/.crumb with purpose renamed to status" "$tmp/renamed.crumb" 5
run "negative control: learner .crumb with its purpose line removed" "$tmp/nopurpose.crumb" 4

echo "== a generated field you can recompute: children_root of a directory with no child crumbs"
grep '"children_root"' "$wasm" | tr -d ' ,'
echo "sha256 of zero bytes: $(printf '' | sha256sum | cut -d' ' -f1)"

echo "every verdict as expected: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
