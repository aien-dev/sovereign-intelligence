#!/bin/sh
# Lesson cuda-05: the command ring. gpfifo.om builds CUDApp's M16 semaphore-release pushbuffer
# and its GPFIFO entry, then decodes both; the pinned NVIDIA class headers name every field.
# Host only: nothing is submitted, no device is opened.
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
CLS=third_party/nvidia-open-580.173.02/src/common/sdk/nvidia/inc/class
REC=evidence/m16-blackwell-native-path-requalification-receipt.json

echo "== oracle: header fields (NVIDIA 580.173.02 clc96f.h, clcec0.h; MIT)"
(cd "$C" && grep -n 'GP_ENTRY0_GET \|GP_ENTRY1_GET_HI \|GP_ENTRY1_LEVEL\|GP_ENTRY1_LENGTH \|GP_ENTRY1_SYNC \|SEM_EXECUTE_OPERATION \|SEM_EXECUTE_OPERATION_RELEASE\|SEM_EXECUTE_RELEASE_WFI ' "$CLS/clc96f.h")
(cd "$C" && grep -n 'define BLACKWELL_COMPUTE_B' "$CLS/clcec0.h")
cls=$(sed -n 's/^#define BLACKWELL_COMPUTE_B *\(0x[0-9A-Fa-f]*\).*/\1/p' "$C/$CLS/clcec0.h")
mva=$(jq -r '.concurrency_result.contexts[0].marker_va' "$C/$REC")
pay=$(jq -r '.causality_result.positive_control.expected' "$C/$REC")
echo "from the M16 receipt: context A marker_va $mva, expected marker $pay"
pva=0x1000010000
echo "pushbuffer VA (illustrative, not from a receipt): $pva"
printf '%d\n%d\n%d\n%d\n' "$cls" "$mva" "$pay" "$pva" > "$tmp/in"

echo "== build and decode: gpfifo.om"
"$OMC" < "$here/gpfifo.om" > "$tmp/gp" 2> "$tmp/err"
rc=$?
echo "compile rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/gp"
{ cat "$tmp/in"; echo 0; } | "$tmp/gp" > "$tmp/out"
rc=$?
cat "$tmp/out"
echo "run rc=$rc"

echo "== oracle: name each decoded method offset from clc96f.h"
sed -n 's/.*method \(0x[0-9a-f]*\)$/\1/p; s/.* method=\(0x[0-9a-f]*\)$/\1/p' "$tmp/out" | sort -u | while read -r m; do
    name=$(grep "($m)" "$C/$CLS/clc96f.h" | sed -n '1s/^#define \([A-Z0-9_]*\).*/\1/p')
    echo "$m ${name:-NO NAME IN HEADER}"
done

echo "== read the code against the header: CUDApp nvrm/nvrm.c says"
(cd "$C" && grep -n 'GP entry per clc96f.h\|LEVEL 9:9 = MAIN\|<< 41' nvrm/nvrm.c)

echo "== negative control: method offset written in bytes, the >> 2 forgotten"
{ cat "$tmp/in"; echo 1; } | "$tmp/gp" > "$tmp/bad"
rc=$?
grep 'header\|round trip' "$tmp/bad"
echo "mutant run rc=$rc"
