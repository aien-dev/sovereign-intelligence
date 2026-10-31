#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: the disk fills up during the install or the model download.
#
# Preconditions: OMC = the pinned omc; bash (its ulimit -f counts 1024-byte blocks), python3,
#   openssl, curl, tar. No root and no user namespaces are needed: a small tmpfs is not available
#   to an unprivileged user here, so the full disk is stood in for by a file-size limit
#   (ulimit -f, SIGXFSZ ignored), which makes the next write fail with EFBIG where a full disk
#   gives ENOSPC. Both reach install.sh and the wizard as a failed write.
#   (a) install: the bundle carries 8 MiB of zeros (share/aienos/test-padding.bin); it downloads
#       (it compresses to a few KiB) and unpacking it hits the 2 MiB limit.
#   (b) model: after a full install, the wizard downloads the 5 MB test model under a 1 MiB limit.
# Expected result: (a) install.sh exits non-zero and says the bundle could not be unpacked; no
#   "current" link, no command link, no installed-files, no staging folder and no temporary
#   folder remain; the same install.sh with the limit lifted installs and verifies.
#   (b) the wizard exits non-zero, says the download failed, keeps no weights.bin and no verified
#   marker, starts no engine; with the limit lifted the same wizard input verifies the model.
# Negative control: the lifted-limit runs above (opposite verdict for each case).
# Status: EXERCISED(host, EFBIG stand-in). A really full disk (ENOSPC) on a stock DGX Spark,
#   and the doctor's free-space check there: NOT_RUN.
#
# usage: OMC=... sh disk-full.sh [SCRATCH]
set -u
FP_NAME=disk-full
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-disk.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
command -v bash > /dev/null 2>&1 || fp_notrun "bash is needed for ulimit -f in 1024-byte blocks"
fp_serve
fp_compile "$S/bin" "$(fp_port)" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
fp_release pad "$S/bin" 8388608
fp_release good "$S/bin"
R=$(fp_root gb10)
# limited KIB CMD...: CMD with writes capped at KIB KiB per file.
limited() { bash -c 'ulimit -f "$1"; trap "" XFSZ; shift; exec "$@"' limited "$@"; }

# (a) the install.
h=$(fp_home inst)
rm -rf "$S/tmp"; mkdir -p "$S/tmp"
limited 2048 env HOME="$h" AIENOS_PROBE_ROOT="$R" AIENOS_BASE_URL="http://127.0.0.1:$FP_HTTP/pad" \
    AIENOS_NO_WIZARD=1 TMPDIR="$S/tmp" sh "$S/www/pad/install.sh" > "$S/inst.out" 2>&1; rc=$?
b=$h/.local/share/aienos
check "install: exit non-zero (got $rc)" "$([ $rc -ne 0 ]; echo $?)"
grep -q "Could not unpack the bundle" "$S/inst.out"; check "install: says the bundle could not be unpacked" $?
[ ! -e "$b/current" ] && [ ! -e "$h/.local/bin/aienos" ] && [ ! -e "$b/installed-files" ]
check "install: no current link, no command, no installed-files" $?
[ ! -e "$b/releases/.$TAG.new" ]; check "install: no staging folder left" $?
[ -z "$(ls -A "$S/tmp")" ]; check "install: no temporary folder left" $?
fp_boot "$h" pad > "$S/inst-ctl.out" 2>&1; rc=$?
ctl1=same
if [ $rc -eq 0 ] && fp_installed "$h"; then ctl1=opposite; fi
check "negative control (limit lifted: installs and verifies): $ctl1" "$([ $ctl1 = opposite ]; echo $?)"

# (b) the model download.
ALL='\n\n\nyes\n\n\n\n\n\n\n'
h=$(fp_home model)
fp_boot "$h" good > "$S/model-boot.out" 2>&1
a=$h/.local/share/aienos/current/bin/aienos
m=$h/.local/share/aienos/models/test-model
printf '%b' "$ALL" | limited 1024 env HOME="$h" AIENOS_PROBE_ROOT="$R" TMPDIR="$S/tmp" \
    timeout 300 "$a" wizard --plain > "$S/model.out" 2>&1; rc=$?
env HOME="$h" "$a" stop > /dev/null 2>&1
check "model: wizard exit non-zero (got $rc)" "$([ $rc -ne 0 ]; echo $?)"
grep -q "The download or a hash check failed" "$S/model.out"; check "model: says the download failed" $?
[ ! -e "$m/weights.bin" ] && [ ! -e "$m/.aienos-verified" ]; check "model: no model file, no verified marker" $?
[ ! -e "$h/.local/share/aienos/engine.pid" ]; check "model: no engine started" $?
printf '%b' "$ALL" | env HOME="$h" AIENOS_PROBE_ROOT="$R" TMPDIR="$S/tmp" \
    timeout 300 "$a" wizard --plain > "$S/model-ctl.out" 2>&1; rc=$?
env HOME="$h" "$a" stop > /dev/null 2>&1
ctl2=same
if [ $rc -eq 0 ] && [ -f "$m/.aienos-verified" ] && cmp -s "$m/weights.bin" "$S/www/model/weights.bin"; then ctl2=opposite; fi
check "negative control (limit lifted: model verifies): $ctl2" "$([ $ctl2 = opposite ]; echo $?)"
fp_result "EXERCISED(host, EFBIG stand-in for ENOSPC) cases=install,model control=$ctl1/$ctl2 spark=NOT_RUN"
