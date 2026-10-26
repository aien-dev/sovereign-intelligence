#!/bin/sh
# Lesson cuda-04: the RM object tree. objtree.om replays the allocation order of CUDApp's
# nvrm.c (class numbers read from the pinned NVIDIA headers) and refuses a wrong parent or a
# use after free. A host model only: it opens no device and makes no ioctl.
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
INC=$C/third_party/nvidia-open-580.173.02/src/common/sdk/nvidia/inc

echo "== oracle 1: the order and parents CUDApp nvrm/nvrm.c allocates with"
(cd "$C" && grep -n 'rm_alloc(rm, \|nvrm_alloc(rm, 0x\|nvrm_alloc_gpu_uncached(rm, 0x' nvrm/nvrm.c)

echo "== oracle 2: class numbers from the headers"
cl() {
    v=$(cd "$INC" && grep -rh "define *$1 " nvos.h class | sed -n '1s/.*(*\(0x[0-9A-Fa-f]*\)U*)*.*/\1/p')
    echo "$1 = $v" >&2
    printf '%d' "$v"
}
ROOT=$(cl NV01_ROOT_CLIENT 2>>"$tmp/legend")
DEV=$(cl NV01_DEVICE_0 2>>"$tmp/legend")
SUB=$(cl NV20_SUBDEVICE_0 2>>"$tmp/legend")
VMEM=$(cl NV01_MEMORY_VIRTUAL 2>>"$tmp/legend")
USR=$(cl HOPPER_USERMODE_A 2>>"$tmp/legend")
VAS=$(cl FERMI_VASPACE_A 2>>"$tmp/legend")
SMEM=$(cl NV01_MEMORY_SYSTEM 2>>"$tmp/legend")
CHG=$(cl KEPLER_CHANNEL_GROUP_A 2>>"$tmp/legend")
CTX=$(cl FERMI_CONTEXT_SHARE_A 2>>"$tmp/legend")
FIFO=$(cl BLACKWELL_CHANNEL_GPFIFO_A 2>>"$tmp/legend")
COMP=$(cl BLACKWELL_COMPUTE_B 2>>"$tmp/legend")
cat "$tmp/legend"

# Allowed (child, parent) pairs: exactly the call sites above, not the RM's full rule set.
{
    echo "3 $ROOT 0"; echo "3 $DEV $ROOT"; echo "3 $SUB $DEV"; echo "3 $VMEM $DEV"
    echo "3 $USR $SUB"; echo "3 $VAS $DEV"; echo "3 $SMEM $DEV"; echo "3 $CHG $DEV"
    echo "3 $CTX $CHG"; echo "3 $FIFO $CHG"; echo "3 $COMP $FIFO"
} > "$tmp/rules"
# nvrm_open, then one buffer, then nvrm_channel (ring + USERD buffer, error notifier buffer).
{
    echo "1 $ROOT 0"; echo "1 $DEV 1"; echo "1 $SUB 2"; echo "1 $VMEM 2"; echo "1 $USR 3"
    echo "1 $VAS 2"; echo "1 $SMEM 2"; echo "1 $CHG 2"; echo "1 $CTX 8"; echo "1 $SMEM 2"
    echo "1 $SMEM 2"; echo "1 $FIFO 8"; echo "1 $COMP 12"
} > "$tmp/open"

"$OMC" < "$here/objtree.om" > "$tmp/ot" 2> "$tmp/err"
rc=$?
echo "compile rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/ot"

echo "== run 1: open, channel, free the channel group, free the root client"
{ cat "$tmp/rules" "$tmp/open"; echo "4 0 0"; echo "2 8 0"; echo "4 0 0"; echo "2 1 0"; echo "0 0 0"; } | "$tmp/ot"
echo "run rc=$?"

echo "== negative 1: compute object allocated directly under the channel group"
{ cat "$tmp/rules"; sed '$d' "$tmp/open"; echo "1 $COMP 8"; echo "0 0 0"; } | "$tmp/ot" > "$tmp/n1"
r=$?
tail -n 1 "$tmp/n1"
echo "run rc=$r"

echo "== negative 2: compute object under a channel that was already freed"
{ cat "$tmp/rules"; sed '$d' "$tmp/open"; echo "2 8 0"; echo "1 $COMP 12"; echo "0 0 0"; } | "$tmp/ot" > "$tmp/n2"
r=$?
tail -n 1 "$tmp/n2"
echo "run rc=$r"
