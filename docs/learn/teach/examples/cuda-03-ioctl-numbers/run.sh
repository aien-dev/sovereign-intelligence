#!/bin/sh
# Lesson cuda-03: NVIDIA ioctl request numbers computed in Omega, checked three ways:
# against the pinned open-module headers, against the literals CUDApp's own context.om uses,
# and against the pinned omc's devctl rule. Host only: the one ioctl it issues goes to /dev/null.
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
H=$SRC/CUDApp/third_party/nvidia-open-580.173.02
NUM=kernel-open/common/inc/nv-ioctl-numbers.h
ESC=src/nvidia/arch/nvalloc/unix/include/nv_escape.h

echo "== oracle 1: the header lines (CUDApp third_party, NVIDIA 580.173.02, MIT)"
(cd "$H" && grep -n 'define NV_IOCTL_MAGIC\|define NV_IOCTL_BASE\|define NV_ESC_CARD_INFO\|define NV_ESC_REGISTER_FD' "$NUM")
(cd "$H" && grep -n 'define NV_ESC_RM_FREE \|define NV_ESC_RM_CONTROL \|define NV_ESC_RM_ALLOC ' "$ESC")
magic=$(sed -n "s/^#define NV_IOCTL_MAGIC *'\(.\)'.*/\1/p" "$H/$NUM")
base=$(sed -n 's/^#define NV_IOCTL_BASE *\([0-9]*\).*/\1/p' "$H/$NUM")
esc() { sed -n "s/^#define $1 *\(0x[0-9A-Fa-f]*\).*/\1/p" "$H/$ESC"; }
printf '%d\n%d\n%d\n%d\n%d\n' "'$magic" "$base" "$(esc NV_ESC_RM_FREE)" "$(esc NV_ESC_RM_CONTROL)" "$(esc NV_ESC_RM_ALLOC)" > "$tmp/in"
echo "input to ioctl.om (decimal): $(tr '\n' ' ' < "$tmp/in")"

echo "== compute: ioctl.om"
"$OMC" < "$here/ioctl.om" > "$tmp/ioctl" 2> "$tmp/err"
rc=$?
echo "compile rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/ioctl"
"$tmp/ioctl" < "$tmp/in" > "$tmp/out"
rc=$?
cat "$tmp/out"
echo "run rc=$rc"

echo "== oracle 2: does CUDApp native/nvrm/context.om use the same literal?"
sed -n 's/^\(.*[^ ]\) *nr=.* request=\([0-9]*\) .*/\2 \1/p' "$tmp/out" | while read -r req name; do
    n=$(grep -c "uint $req " "$SRC/CUDApp/native/nvrm/context.om")
    echo "$req used $n time(s): $name"
done

echo "== oracle 3: the pinned omc's devctl rule, compiled (never opens a GPU device)"
mk() {
    printf 'global hdr uchar 32\nfn main to int\nr = devctl 0 uint %s hdr 0 %s\nret int neg r\nend\n' "$1" "$2" > "$tmp/d.om"
    "$OMC" < "$tmp/d.om" > "$tmp/d" 2> "$tmp/derr"
    crc=$?
    echo "$3: compile rc=$crc"
    cat "$tmp/derr"
    if [ "$crc" -eq 0 ]; then
        chmod +x "$tmp/d"
        "$tmp/d" < /dev/null
        echo "$3: run on /dev/null rc=$?"
    fi
}
alloc=$(sed -n 's/^NV_ESC_RM_ALLOC .* request=\([0-9]*\) .*/\1/p' "$tmp/out")
mk "$alloc" 32 "RM_ALLOC read/write, 32-byte span"
wonly=$(( (1 << 30) | (32 << 16) | ($(printf '%d' "'$magic") << 8) | $(printf '%d' "$(esc NV_ESC_RM_ALLOC)") ))
mk "$wonly" 32 "negative: same fields, write-only direction ($wonly)"
mk "$alloc" 16 "negative: RM_ALLOC with a 16-byte span"
