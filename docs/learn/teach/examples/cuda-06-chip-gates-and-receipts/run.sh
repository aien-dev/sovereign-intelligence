#!/bin/sh
# Lesson cuda-06: re-check CUDApp receipts without a GPU. sh re-hashes every file a receipt lists,
# verdict.om turns the counts into a fail-closed verdict, and the M16 receipt's own raw-log
# folder is looked up. Host only: no gate is run, no device is opened.
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
C=$SRC/CUDApp
"$OMC" < "$here/verdict.om" > "$tmp/vd" 2> "$tmp/err"
rc=$?
echo "compile rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/vd"

# rehash DIR SUMS: one line per listed file, then the three counts into verdict.om.
rehash() {
    ok=0; miss=0; bad=0
    while read -r sum path; do
        path=${path#./}
        if [ ! -f "$1/$path" ]; then
            echo "  MISSING  $path"; miss=$((miss + 1))
        elif [ "$(sha256sum < "$1/$path" | cut -c1-64)" = "$sum" ]; then
            ok=$((ok + 1))
        else
            echo "  DIFFERS  $path"; bad=$((bad + 1))
        fi
    done < "$2"
    echo "  matched=$ok missing=$miss differs=$bad"
    printf '%d\n%d\n%d\n' "$ok" "$miss" "$bad" | "$tmp/vd"
    echo "  verdict.om rc=$?"
}

echo "== 1. NVIDIA headers: third_party/nvidia-open-580.173.02/SHA256SUMS"
rehash "$C/third_party/nvidia-open-580.173.02" "$C/third_party/nvidia-open-580.173.02/SHA256SUMS"

T3=evidence/OWN30B-T3-TC-PEAK-BW-5faa0f70-20261013T2236Z
echo "== 2. chip receipt: $T3/SHA256SUMS"
rehash "$C/$T3" "$C/$T3/SHA256SUMS"
echo "  why the missing file is missing (docs/AUDIT.md):"
(cd "$C" && grep -n 'fa_ops.sass`: a listing' docs/AUDIT.md | cut -c1-160)
echo "  what the log itself says:"
grep 'GPU_TC_PEAK\|^peak stall 1 ' "$C/$T3/peak.log"

echo "== 3. negative control: the same receipt with one byte appended to peak.log"
mkdir "$tmp/t3"
cp "$C/$T3/bw.log" "$C/$T3/fa_ops.cu" "$C/$T3/peak.log" "$C/$T3/peak-run1-timer-bug.log" "$tmp/t3/"
printf 'x' >> "$tmp/t3/peak.log"
rehash "$tmp/t3" "$C/$T3/SHA256SUMS"

echo "== 4. negative control: an empty file list"
: > "$tmp/empty"
rehash "$tmp" "$tmp/empty"

M16=evidence/m16-blackwell-native-path-requalification-receipt.json
echo "== 5. the M16 receipt: what it claims, and whether its raw logs are here"
jq -r '"  qualification_status=\(.qualification_status) implementation_commit=\(.implementation_commit) evidence_dir=\(.evidence_dir)"' "$C/$M16"
dir=$(jq -r '.evidence_dir' "$C/$M16")
if [ -e "$C/$dir" ]; then echo "  $dir: present"; else echo "  $dir: absent at this pin"; fi
(cd "$C" && grep -n 'Current native qualification is \*\*NOT_RUN\*\*' README.md)
