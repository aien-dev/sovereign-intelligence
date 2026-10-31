#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: uninstall after a partial install.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar. Host run in scratch homes on a
#   fake GB10 probe root. install.sh is stopped with SIGKILL (shim.sh) at three points after the
#   release folder is in place: moved (no "current" link yet), linked (~/.local/bin/aienos linked,
#   nothing else) and listed (every link and menu/desktop entry written, installed-files not yet
#   committed: only installed-files.new exists). Then the user runs the uninstaller that is on disk:
#   `aienos uninstall --yes` from ~/.local/share/aienos/releases/TAG/bin.
# Expected result: uninstall exits 0 and leaves no AienOS file or link anywhere in the home folder
#   (~/.local/share/aienos, ~/.local/bin/aienos, the icon, the menu and desktop entries).
# Negative control: the same checker on the partial home before uninstall finds AienOS files
#   (opposite verdict), and uninstall after a complete install also leaves nothing.
# Status: EXERCISED(host). On a stock DGX Spark: NOT_RUN.
#
# usage: OMC=... sh uninstall-partial.sh [SCRATCH]
set -u
FP_NAME=uninstall-partial
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-unp.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve
fp_compile "$S/bin" "$(fp_port)" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
fp_release good "$S/bin"
leftover() { fp_files "$1" | sed 's/^/      left: /'; }
# No AienOS file or link left (folders install.sh made are rollback-clean.sh's check; gvfs
# metadata is GNOME's).
gone() { [ -z "$(fp_files "$1")" ] && [ ! -e "$1/.local/share/aienos" ]; }

ctl=same
for k in moved linked listed; do
    h=$(fp_home "$k")
    export FP_KILL="$k" FP_SIG=KILL
    fp_boot "$h" good > "$S/$k.out" 2>&1
    unset FP_KILL FP_SIG
    if [ -n "$(fp_files "$h")" ]; then pre=found; else pre=none; fi
    [ $pre = found ] || ctl=same-$k
    env HOME="$h" "$h/.local/share/aienos/releases/$TAG/bin/aienos" uninstall --yes > "$S/$k.un.out" 2>&1; rc=$?
    check "$k: uninstall exit 0 (got $rc)" "$([ $rc -eq 0 ]; echo $?)"
    gone "$h"; check "$k: nothing of AienOS left" $?
    leftover "$h"
done

h=$(fp_home full)
fp_boot "$h" good > "$S/full.out" 2>&1
fp_installed "$h" || ctl=same-full
env HOME="$h" "$h/.local/bin/aienos" uninstall --yes > "$S/full.un.out" 2>&1
if [ "${ctl#same-}" = "$ctl" ] && gone "$h"; then ctl=opposite; fi
check "negative control (partial home has files before uninstall; full install uninstalls clean): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host) cases=moved,linked,listed control=$ctl spark=NOT_RUN"
