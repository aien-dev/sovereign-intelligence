#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# NVIDIA packages and everything outside the test's scratch folder stay untouched.
#
#   OMC=... DIST=... STAGE=... sh tests/host-untouched.sh SCRATCH
#
# 1. Records `dpkg --verify` for every installed NVIDIA/CUDA package and a listing (path, size,
#    mtime) of their files, the CUDA toolkit folders and libcuda.
# 2. Runs the whole tests/run.sh suite inside bubblewrap with the root filesystem read-only and
#    only SCRATCH writable, under strace. Any attempt to write elsewhere fails with EROFS, and
#    strace records it: the count must be 0.
# 3. Records the same NVIDIA state again; it must be byte-identical.
set -u
: "${OMC:?}" "${DIST:?}" "${STAGE:?}"
S=${1:?usage: host-untouched.sh SCRATCH}
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$S"
S=$(cd "$S" && pwd)

nvstate() {
    pk=$(dpkg-query -W -f '${Package} ${Status}\n' 2>/dev/null | awk '$4 == "installed" && $1 ~ /nvidia|cuda|libnv|cublas|cudnn|nccl/ { print $1 }' | LC_ALL=C sort)
    printf 'packages %s\n' "$(printf '%s\n' "$pk" | wc -l)"
    printf '%s\n' "$pk" | sed 's/^/package /'
    printf '%s\n' "$pk" | xargs -r dpkg --verify 2>&1 | sed 's/^/verify /'
    {
        printf '%s\n' "$pk" | xargs -r dpkg -L 2>/dev/null
        find /usr/local/cuda* /usr/lib/aarch64-linux-gnu -maxdepth 0 2>/dev/null
        find /usr/lib/aarch64-linux-gnu -maxdepth 1 -name 'libcuda*' 2>/dev/null
    } | LC_ALL=C sort -u | while read -r f; do
        [ -f "$f" ] && stat -c 'file %n %s %Y' "$f"
    done
    find /usr/local/cuda-13.0 -type f -printf 'cuda %p %s %T@\n' 2>/dev/null | LC_ALL=C sort | sha256sum | sed 's/^/cuda-tree /'
}

nvstate > "$S/nvidia-before.txt"
mkdir -p "$S/suite"
strace -f -qq -o "$S/strace.log" -e trace=openat,mkdirat,unlinkat,renameat,renameat2,symlinkat,linkat,fchmodat,truncate,ftruncate \
    bwrap --ro-bind / / --dev /dev --proc /proc --bind "$S" "$S" \
        --setenv TMPDIR "$S/tmp" --setenv PYTHONDONTWRITEBYTECODE 1 \
        sh -c 'mkdir -p "$TMPDIR" && exec sh "$0" "$1"' "$here/run.sh" "$S/suite" \
    > "$S/suite.log" 2>&1
suite=$?
nvstate > "$S/nvidia-after.txt"
erofs=$(grep -c 'EROFS' "$S/strace.log")
grep 'EROFS' "$S/strace.log" > "$S/erofs.txt"
same=no
cmp -s "$S/nvidia-before.txt" "$S/nvidia-after.txt" && same=yes
printf 'suite rc=%s (%s)\n' "$suite" "$(tail -1 "$S/suite.log")"
printf 'writes refused outside scratch (EROFS): %s\n' "$erofs"
printf 'NVIDIA state identical before and after: %s (%s)\n' "$same" "$(head -1 "$S/nvidia-before.txt")"
[ "$suite" -eq 0 ] && [ "$erofs" -eq 0 ] && [ "$same" = yes ]
