#!/bin/sh
# Lesson cuda-01: where the line between user space and the kernel runs in CUDApp, read from the
# pinned sources with grep (an inspection, no first-party logic, no device opened).
set -u
export LC_ALL=C
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" 2>/dev/null | cut -c1-64)
if [ "$got" != "$PIN" ]; then
    echo "omc sha256 mismatch: refusing to run"
    exit 90
fi
echo "omc sha256 $PIN (not needed by this inspection; checked so every lesson pins the same tools)"
C=$SRC/CUDApp
cd "$C" || exit 2

echo "== 1. the build promise (Makefile header)"
grep -n 'no CUDA toolkit, no NVIDIA user-space library' Makefile

echo "== 2. files that include a CUDA header or link libcuda (first-party C, Makefile, mk/)"
git grep -l '#include <cuda\|#include "cuda\|-lcuda' -- '*.c' '*.h' Makefile mk
echo "   the Makefile line that links it, and the target it belongs to:"
grep -n -- '-lcuda' Makefile | cut -c1-120

echo "== 3. the three device files the driver client opens (kernel entry points)"
grep -n '"/dev/nvidia' nvrm/nvrm.c native/nvrm/context.om

echo "== 4. what came from the kernel side: the open module's headers, by folder"
cd third_party/nvidia-open-580.173.02 || exit 2
for d in kernel-open/common/inc kernel-open/nvidia-uvm src/common/sdk/nvidia/inc src/nvidia/arch/nvalloc/unix/include; do
    echo "   $(find "$d" -name '*.h' | wc -l | tr -d ' ') headers in $d"
done
echo "   $(grep -c '\.h$' SHA256SUMS) headers listed in SHA256SUMS"
cd "$C" || exit 2

echo "== 5. what still belongs to NVIDIA below the line (ROADMAP.md)"
grep -n '^| `nvidia.ko`\|^| `nvidia-uvm.ko`\|^| GSP firmware' ROADMAP.md | cut -d'|' -f2,4,5
