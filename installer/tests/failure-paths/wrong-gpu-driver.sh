#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: wrong GPU or wrong NVIDIA kernel driver version.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar. Host run against fake probe
#   roots (AIENOS_PROBE_ROOT, tests/fake-root.sh): nogpu, othergpu (10de:2684), olddrv
#   (570.86.10) and newdrv (a GB10 with 590.44.01, made here from the gb10 root). The wizard is a
#   test build whose engine port is a free high 127.0.0.1 port (never 18091/18100/18300) and whose
#   engine is tests/fake-engine.om; no GPU device is opened.
# Expected result:
#   1. install.sh on each wrong machine exits 0 with "Nothing was changed on this machine." and
#      the home folder stays empty.
#   2. A release installed on a GB10, then the GPU or the driver changes (a driver update after
#      install): `aienos doctor` exits 1 with a "no" line, and `aienos start` refuses (exit 2)
#      without starting an engine (no engine.pid, nothing listening on the engine port).
# Negative control: on the gb10 root install.sh installs, `aienos doctor` exits 0 and
#   `aienos start` starts the (fake) engine (opposite verdict).
# Status: EXERCISED(host, fake probe roots). A stock DGX Spark with another driver: NOT_RUN.
#
# usage: OMC=... sh wrong-gpu-driver.sh [SCRATCH]
set -u
FP_NAME=wrong-gpu-driver
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-gpu.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve
EP=$(fp_port)
fp_compile "$S/bin" "$EP" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
fp_release good "$S/bin"
newdrv=$S/root-newdrv
if [ ! -d "$newdrv" ]; then cp -a "$(fp_root gb10)" "$newdrv"; printf '590.44.01\n' > "$newdrv/sys/module/nvidia/version"; fi

listening() { python3 -c 'import socket,sys; s=socket.socket(); sys.exit(0 if s.connect_ex(("127.0.0.1",int(sys.argv[1])))==0 else 1)' "$1"; }

for k in nogpu othergpu olddrv newdrv; do
    r=$S/root-$k; [ -d "$r" ] || r=$(fp_root "$k")
    h=$(fp_home "boot-$k")
    fp_boot "$h" good "$r" > "$S/boot-$k.out" 2>&1; rc=$?
    check "$k: install.sh exit 0 (got $rc)" "$([ $rc -eq 0 ]; echo $?)"
    grep -q "Nothing was changed on this machine." "$S/boot-$k.out"; check "$k: says nothing was changed" $?
    fp_untouched "$h"; check "$k: home folder untouched" $?
done

# A release installed on the GB10, then the machine changes under it.
h=$(fp_home inst)
fp_boot "$h" good > "$S/inst.out" 2>&1
a=$h/.local/share/aienos/current/bin/aienos
for k in othergpu olddrv newdrv; do
    r=$S/root-$k; [ -d "$r" ] || r=$(fp_root "$k")
    env HOME="$h" AIENOS_PROBE_ROOT="$r" "$a" doctor > "$S/doctor-$k.out" 2>&1; rc=$?
    [ $rc -eq 1 ] && grep -q '\[  no  \]' "$S/doctor-$k.out"; check "$k: doctor exit 1 with a no line (got $rc)" $?
    env HOME="$h" AIENOS_PROBE_ROOT="$r" timeout 60 "$a" start > "$S/start-$k.out" 2>&1; rc=$?
    check "$k: aienos start refuses with exit 2 (got $rc)" "$([ $rc -eq 2 ]; echo $?)"
    [ ! -e "$h/.local/share/aienos/engine.pid" ] && ! listening "$EP"; check "$k: no engine started" $?
    env HOME="$h" "$a" stop > /dev/null 2>&1
done

# Negative control: the GB10 with the tested driver.
ctl=same
env HOME="$h" AIENOS_PROBE_ROOT="$(fp_root gb10)" "$a" doctor > "$S/doctor-gb10.out" 2>&1; drc=$?
env HOME="$h" AIENOS_PROBE_ROOT="$(fp_root gb10)" timeout 60 "$a" start > "$S/start-gb10.out" 2>&1; src=$?
if fp_installed "$h" && [ $drc -eq 0 ] && [ $src -eq 0 ] && [ -f "$h/.local/share/aienos/engine.pid" ] && listening "$EP"; then
    ctl=opposite
fi
env HOME="$h" "$a" stop > /dev/null 2>&1
check "negative control (gb10: installs, doctor 0, engine starts): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host, fake probe roots) cases=nogpu,othergpu,olddrv,newdrv control=$ctl spark=NOT_RUN"
