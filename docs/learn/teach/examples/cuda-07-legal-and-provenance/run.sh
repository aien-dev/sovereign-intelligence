#!/bin/sh
# Lesson cuda-07: check CUDApp's provenance claims against its own tree with grep and git.
# Each claim from THIRD_PARTY.md or HOW_I_DID_IT.md is printed next to the count that tests it.
# An inspection only: no first-party logic, no device, no network.
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

echo "== claim 1 (THIRD_PARTY.md): 67 NVIDIA headers, 60 with an SPDX MIT line, 7 with the MIT text only"
grep -n '67 header files\|60 carry' THIRD_PARTY.md | cut -c1-110
cd third_party/nvidia-open-580.173.02 || exit 2
total=$(find . -name '*.h' | wc -l | tr -d ' ')
spdx=$(grep -rl 'SPDX-License-Identifier: MIT' --include='*.h' . | wc -l | tr -d ' ')
textonly=$(grep -rL 'SPDX-License-Identifier: MIT' --include='*.h' . | xargs grep -l 'Permission is hereby granted' | wc -l | tr -d ' ')
echo "   counted: $total headers, $spdx with SPDX MIT, $textonly with the permission text only"
echo "   NVIDIA's own licence file (COPYING), the line that limits the dual licence:"
grep -n 'GPL' COPYING | cut -c1-110
cd "$C" || exit 2

echo "== claim 2 (THIRD_PARTY.md): no NVIDIA firmware, libcuda, cubin, fatbin or PTX; no NVIDIA tool listing stored"
grep -n 'No NVIDIA firmware, no libcuda\|No listing made by NVIDIA tools' THIRD_PARTY.md | cut -c1-110
echo "   tracked files named *.cubin *.fatbin *.ptx *.sass libcuda* *.so or *.bin under firmware paths:"
git ls-files '*.cubin' '*.fatbin' '*.ptx' '*.sass' 'libcuda*' '*.so' '*gsp*.bin' | sed 's/^/     /'
echo "   where the two cubins come from (CUDA++'s own exporter):"
grep -n 'Both cubins are sm_121 ELF\|generated text byte-for-byte' evidence/MAX-INTEROP/68/RESULT.md | sed 's/^/     /'
echo "   how expected.sass is made (the emitter test's own script):"
grep -n 'nvdisasm --binary\|nvdisasm decode matches\|rewrite expected.sass' tests/device-trace/run-emitter-checks.sh | sed 's/^/     /'
grep -n 'headerflags' tests/device-trace/expected.sass | sed -n '1p' | sed 's/^/     /'

echo "== claim 3 (HOW_I_DID_IT.md): NVIDIA tools were run on my own probe kernels, nothing was taken apart"
grep -n 'I did not take apart' docs/HOW_I_DID_IT.md | cut -c1-140
grep -n 'One CUDA C++ source remains' docs/AUDIT.md | cut -c1-150
echo "   the one CUDA C++ file in the tree:"
git ls-files '*.cu'

echo "== claim 4 (THIRD_PARTY.md): Mesa facts cited in comments, no Mesa code copied"
echo "   files under src/ that name a Mesa source file: $(git grep -l 'sm70_encode.rs\|qmd.rs\|nvk_cmd_dispatch.c\|sm120_instr_latencies.rs' -- src | wc -l | tr -d ' ')"

echo "== what the licence of first-party code says at this pin"
sed -n '2,3p' LICENSE | sed 's/^ *//'
echo "   files whose SPDX line says Apache-2.0 WITH LLVM-exception: $(git grep -l 'SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception' | wc -l | tr -d ' ')"
echo "   files whose SPDX line says AGPL-3.0-only: $(git grep -l 'SPDX-License-Identifier: AGPL-3.0-only' | wc -l | tr -d ' '), for example:"
git grep -l 'SPDX-License-Identifier: AGPL-3.0-only' -- native | sed -n '1,3p'
