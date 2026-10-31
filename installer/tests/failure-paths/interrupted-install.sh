#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: the install is interrupted, then run again.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar. Host run in scratch homes on a
#   fake GB10 probe root, release served from 127.0.0.1. shim.sh stands in for curl, tar, mv and ln
#   and stops install.sh at five points: download (half the bundle written), unpack (bundle partly
#   unpacked), moved (release folder in place, no "current" link), linked (~/.local/bin/aienos
#   linked, nothing else outside the release folder), listed (every link and entry written,
#   installed-files not committed). Signals: KILL (power cut, closed terminal) at every point,
#   INT (Ctrl+C) at download and unpack.
# Expected result: an interrupted run is never a complete install (the checker says so: this is
#   the checker's negative control); after Ctrl+C no temporary or staging folder remains; running
#   the same install.sh again with nothing in the way gives a complete, verified install whose
#   files are exactly those of an uninterrupted install (no .new, .old or staging leftovers).
# Negative control: an uninterrupted install passes the same checker (opposite verdict).
# Status: EXERCISED(host). A power cut on a stock DGX Spark: NOT_RUN.
#
# usage: OMC=... sh interrupted-install.sh [SCRATCH]
set -u
FP_NAME=interrupted-install
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-int.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve
fp_compile "$S/bin" "$(fp_port)" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
fp_release good "$S/bin"

# The reference: one uninterrupted install.
ref=$(fp_home ref)
fp_boot "$ref" good > "$S/ref.out" 2>&1
ctl=same
fp_installed "$ref" && ctl=opposite
fp_files "$ref" > "$S/ref.files"

for c in download:KILL download:INT unpack:KILL unpack:INT moved:KILL linked:KILL listed:KILL; do
    k=${c%:*} sig=${c#*:}
    h=$(fp_home "$k-$sig")
    rm -rf "$S/tmp"; mkdir -p "$S/tmp"
    export FP_KILL="$k" FP_SIG="$sig"
    fp_boot "$h" good > "$S/$k-$sig.out" 2>&1; rc=$?
    unset FP_KILL FP_SIG
    check "$k/$sig: install.sh stopped (exit $rc)" "$([ $rc -ne 0 ]; echo $?)"
    ! fp_installed "$h"; check "$k/$sig: checker says not installed" $?
    if [ "$sig" = INT ]; then
        [ -z "$(ls -A "$S/tmp")" ] && [ ! -e "$h/.local/share/aienos/releases/.$TAG.new" ]
        check "$k/$sig: no temporary or staging folder left" $?
    fi
    fp_boot "$h" good > "$S/$k-$sig.rerun.out" 2>&1; rc=$?
    check "$k/$sig: re-run exit 0 (got $rc)" "$([ $rc -eq 0 ]; echo $?)"
    fp_installed "$h"; check "$k/$sig: re-run gives a complete verified install" $?
    fp_files "$h" | sed "s|$h|HOME|g" > "$S/$k-$sig.files"
    sed "s|$ref|HOME|g" "$S/ref.files" | cmp -s - "$S/$k-$sig.files"
    check "$k/$sig: same files as an uninterrupted install" $?
done
check "negative control (uninterrupted install passes the checker): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host) cases=download/KILL,download/INT,unpack/KILL,unpack/INT,moved/KILL,linked/KILL,listed/KILL control=$ctl spark=NOT_RUN"
