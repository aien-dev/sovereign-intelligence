#!/bin/sh
# Lesson cuda-02: reading the open module's headers. Escape codes (nv_escape.h), class numbers
# (class/clXXXX.h) and control commands (ctrl/...) are found with grep; ctrl.om splits each
# control command into the fields ctrlxxxx.h defines, and grep names the class it belongs to.
# Host only: nothing is opened but text files.
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
INC=$SRC/CUDApp/third_party/nvidia-open-580.173.02/src/common/sdk/nvidia/inc

echo "== 1. a class header is named after its class number"
for h in cl0080 cl2080 clc96f clcec0; do
    (cd "$INC" && grep -Hn '^#define *[A-Z0-9_]* *(*0x0*[0-9A-Fa-f]*U*)* *\(/\*.*\)*$' "class/$h.h" | sed -n 1p | cut -c1-90)
done

echo "== 2. the control-command layout (ctrl/ctrlxxxx.h)"
(cd "$INC" && grep -n 'define NVXXXX_CTRL_CMD_CLASS\|define NVXXXX_CTRL_CMD_CATEGORY\|define NVXXXX_CTRL_CMD_INDEX' ctrl/ctrlxxxx.h)

echo "== 3. the control commands CUDApp nvrm.c sends, as the headers define them"
for n in NV0000_CTRL_CMD_GPU_GET_ID_INFO_V2 NV0080_CTRL_CMD_GPU_GET_CLASSLIST NV2080_CTRL_CMD_GR_GET_INFO \
         NV2080_CTRL_CMD_GPU_GET_GID_INFO NVC36F_CTRL_CMD_GPFIFO_GET_WORK_SUBMIT_TOKEN NVA06C_CTRL_CMD_GPFIFO_SCHEDULE; do
    v=$(cd "$INC" && grep -rh "define *$n " ctrl | sed -n '1s/.*(\(0x[0-9A-Fa-f]*\)U*).*/\1/p')
    used=$(grep -c "$n" "$SRC/CUDApp/nvrm/nvrm.c")
    echo "$n = $v (named $used time(s) in nvrm.c)"
    printf '%d\n' "$v" >> "$tmp/in"
done

"$OMC" < "$here/ctrl.om" > "$tmp/ct" 2> "$tmp/err"
rc=$?
echo "compile rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/ct"
echo "== 4. ctrl.om splits them"
"$tmp/ct" < "$tmp/in" > "$tmp/out"
rc=$?
cat "$tmp/out"
echo "run rc=$rc"

echo "== 5. which object class does each command talk to? (class/cl<class>.h, if vendored)"
sed -n 's/.* class=0x\([0-9a-f]*\) .*/\1/p' "$tmp/out" | sort -u | while read -r c; do
    h=$(echo "$c" | sed 's/^0*//')
    f=$INC/class/cl$c.h
    if [ -f "$f" ]; then
        name=$(grep -i "^#define *[A-Z0-9_]* *(*0x0*${h:-0}U*)*\( \|$\)" "$f" | sed -n 's/^#define *\([A-Z0-9_]*\).*/\1/p' | grep -v '_MESSAGE_ID$' | tr '\n' ' ')
        echo "0x$c: class/cl$c.h defines $name"
    else
        echo "0x$c: class/cl$c.h is not among the 67 vendored headers"
    fi
done

echo "== 6. negative control: a number with bit 14 set"
printf '%d\n' $(( 0x20801201 | 0x4000 )) | "$tmp/ct"
echo "run rc=$?"
