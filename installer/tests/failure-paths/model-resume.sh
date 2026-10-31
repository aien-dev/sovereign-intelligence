#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: the model download is interrupted in the middle of a file, then resumed.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar, setsid. Host run in scratch
#   homes on a fake GB10 probe root after a complete test install. The test model (config.json and
#   a 5 MB weights.bin) is served from 127.0.0.1 by fp_serve_range, which answers Range requests
#   the way Hugging Face's CDN does and logs every request with its Range header and the bytes it
#   sent. The interruptions, all in the middle of weights.bin:
#   (a) stop/KILL, stop/INT: the server stalls after 2500000 bytes; the wizard and its curl are
#       stopped with SIGKILL (power cut, closed terminal) or SIGINT (Ctrl+C) to their process group
#       while weights.bin.part holds those bytes; then the user runs the wizard again.
#   (b) cut1: the connection drops once after 2000000 bytes (short body under the full
#       Content-Length); the same wizard run tries again.
#   (c) cut2: the connection drops on both of the wizard's tries, 2000000 bytes each; the wizard
#       gives up and says to run it again; then the user runs it again.
# Expected result: every resume asks for "Range: bytes=P-" where P is the size of the .part file
#   the interruption left (no byte is downloaded twice), and the server sends exactly the rest;
#   (c)'s failed run keeps its .part (4000000 bytes), no weights.bin and no verified marker, and
#   says "Run aienos again to resume"; in the end weights.bin equals the served file, the
#   ".aienos-verified" marker exists and no .part remains.
# Negative control: case (a) KILL run against a wizard built without curl's "-C -" (FP_MUTATE)
#   must fail the resume checks (opposite verdict).
# Status: EXERCISED(host, 5 MB test model, loopback server). The 37.5 GB download from Hugging
#   Face on a stock DGX Spark: NOT_RUN.
#
# usage: OMC=... sh model-resume.sh [SCRATCH]
set -u
FP_NAME=model-resume
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-resume.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
command -v setsid > /dev/null 2>&1 || fp_notrun "setsid missing"
fp_serve_range
port=$(fp_port)
fp_compile "$S/bin" "$port" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
FP_MUTATE='s/^text c_c "-C"$/text c_c "-H"/; s/^text c_dash "-"$/text c_dash "X-Fp-Mutant: no-resume"/' \
    fp_compile "$S/bin-mut" "$port" || fp_notrun "omc refused the no-resume test wizard ($S/bin-mut/omc.err)"
fp_release good "$S/bin"
fp_release mut "$S/bin-mut"
R=$(fp_root gb10)
SZ=$(wc -c < "$S/www/model/weights.bin" | tr -d ' ')
ALL='\n\n\nyes\n\n\n\n\n\n\n'
W=/model/weights.bin
# wiz HOME OUT: the wizard with the default answers, as a user at the terminal runs it.
wiz() {
    printf '%b' "$ALL" | env HOME="$1" AIENOS_PROBE_ROOT="$R" TMPDIR="$S/tmp" \
        timeout 300 "$1/.local/share/aienos/current/bin/aienos" wizard --plain > "$2" 2>&1; rc=$?
    env HOME="$1" "$1/.local/share/aienos/current/bin/aienos" stop > /dev/null 2>&1
    return $rc
}
mark() { wc -l < "$S/range.log" | tr -d ' '; }
# Requests for weights.bin logged after line $1 of range.log.
since() { sed -n "$(($1 + 1)),\$p" "$S/range.log" | grep "^GET $W "; }
model() { printf '%s' "$1/.local/share/aienos/models/test-model"; }
verified() {
    m=$(model "$1")
    [ -f "$m/.aienos-verified" ] && cmp -s "$m/weights.bin" "$S/www/model/weights.bin" \
        && [ ! -e "$m/weights.bin.part" ]
}
partsz() { wc -c 2>/dev/null < "$(model "$1")/weights.bin.part" | tr -d ' '; }

# stop HOME RELEASE SIG: install RELEASE, stall weights.bin at 2500000 bytes, stop the wizard's
# process group with SIG while the .part holds them, re-run. Sets P (the .part size) and
# RESUMED (yes when the re-run asked for bytes=P- and got exactly the rest).
# A non-interactive sh starts "&" jobs with SIGINT ignored, so python3 puts INT back to default
# before the wizard's shell starts: the INT case is Ctrl+C, not a signal the wizard never sees.
# A stop that has not ended the wizard within 30 s is cut with KILL and TIMEOUT=yes (a FAIL).
stop() {
    fp_boot "$1" "$2" > "$S/$2-$3.boot.out" 2>&1
    printf '2500000\n' > "$S/ctl/stall-weights.bin"
    setsid python3 -c 'import os, signal, sys
signal.signal(signal.SIGINT, signal.SIG_DFL)
os.execvp("sh", ["sh", "-c"] + sys.argv[1:])' \
        'printf "%b" "$1" | exec env HOME="$2" AIENOS_PROBE_ROOT="$3" TMPDIR="$4" \
        "$2/.local/share/aienos/current/bin/aienos" wizard --plain' wiz "$ALL" "$1" "$R" "$S/tmp" \
        > "$S/$2-$3.run1.out" 2>&1 &
    g=$!
    i=0
    while [ "$(partsz "$1")" -lt 2400000 ] 2>/dev/null || [ -z "$(partsz "$1")" ]; do
        i=$((i + 1)); [ $i -lt 600 ] || break; sleep 0.1
    done
    sleep 0.5
    kill -s "$3" -- "-$g" 2>/dev/null
    (sleep 30; kill -s KILL -- "-$g" 2>/dev/null && : > "$S/$2-$3.timeout") &
    w=$!
    wait "$g" 2>/dev/null
    kill "$w" 2>/dev/null; wait "$w" 2>/dev/null
    TIMEOUT=no; [ ! -e "$S/$2-$3.timeout" ] || TIMEOUT=yes
    rm -f "$S/ctl/stall-weights.bin"
    sleep 0.3
    P=$(partsz "$1"); P=${P:-0}
    n=$(mark)
    wiz "$1" "$S/$2-$3.run2.out"; rc2=$?
    since "$n" > "$S/$2-$3.requests"
    RESUMED=no
    if [ "$P" -gt 0 ] && [ "$(wc -l < "$S/$2-$3.requests")" -eq 1 ] \
        && grep -q "range=bytes=$P- status=206 sent=$((SZ - P))\$" "$S/$2-$3.requests"; then RESUMED=yes; fi
}

for sig in KILL INT; do
    h=$(fp_home "stop-$sig")
    stop "$h" good "$sig"
    check "stop/$sig: SIG$sig ended the wizard within 30 s (cut by the KILL backstop: $TIMEOUT)" \
        "$([ $TIMEOUT = no ]; echo $?)"
    check "stop/$sig: the interruption left a partial weights.bin.part ($P of $SZ bytes)" \
        "$([ "$P" -gt 0 ] && [ "$P" -lt "$SZ" ]; echo $?)"
    check "stop/$sig: re-run exit 0 (got $rc2)" "$([ $rc2 -eq 0 ]; echo $?)"
    check "stop/$sig: re-run resumed with Range bytes=$P- and fetched only the rest: $RESUMED" \
        "$([ $RESUMED = yes ]; echo $?)"
    sed 's/^/      /' "$S/good-$sig.requests"
    verified "$h"; check "stop/$sig: weights.bin verified, marker written, no .part left" $?
done

# (b) one dropped connection: the wizard's second try resumes.
h=$(fp_home cut1)
fp_boot "$h" good > "$S/cut1.boot.out" 2>&1
printf '2000000 1\n' > "$S/ctl/cut-weights.bin"
n=$(mark)
wiz "$h" "$S/cut1.out"; rc=$?
since "$n" > "$S/cut1.requests"; sed 's/^/      /' "$S/cut1.requests"
check "cut1: wizard exit 0 (got $rc)" "$([ $rc -eq 0 ]; echo $?)"
sed -n 2p "$S/cut1.requests" | grep -q "range=bytes=2000000- status=206 sent=$((SZ - 2000000))\$"
check "cut1: the second try resumed from byte 2000000" $?
verified "$h"; check "cut1: weights.bin verified, marker written, no .part left" $?

# (c) the connection drops on both tries: the wizard stops, keeps the .part, and a re-run resumes.
h=$(fp_home cut2)
fp_boot "$h" good > "$S/cut2.boot.out" 2>&1
printf '2000000 2\n' > "$S/ctl/cut-weights.bin"
wiz "$h" "$S/cut2.run1.out"; rc=$?
m=$(model "$h")
check "cut2: first run exit non-zero (got $rc)" "$([ $rc -ne 0 ]; echo $?)"
grep -q "Run aienos again to resume" "$S/cut2.run1.out"; check "cut2: says to run aienos again to resume" $?
[ ! -e "$m/weights.bin" ] && [ ! -e "$m/.aienos-verified" ]; check "cut2: no weights.bin, no verified marker" $?
P=$(partsz "$h"); P=${P:-0}
check "cut2: the .part is kept for the resume ($P bytes, want 4000000)" "$([ "$P" -eq 4000000 ]; echo $?)"
n=$(mark)
wiz "$h" "$S/cut2.run2.out"; rc=$?
since "$n" > "$S/cut2.requests"; sed 's/^/      /' "$S/cut2.requests"
check "cut2: re-run exit 0 (got $rc)" "$([ $rc -eq 0 ]; echo $?)"
[ "$(wc -l < "$S/cut2.requests")" -eq 1 ] && grep -q "range=bytes=4000000- status=206 sent=$((SZ - 4000000))\$" "$S/cut2.requests"
check "cut2: re-run resumed from byte 4000000 and fetched only the rest" $?
verified "$h"; check "cut2: weights.bin verified, marker written, no .part left" $?
rm -f "$S/ctl/cut-weights.bin"

# Negative control: the same stop/KILL case against a wizard built without "-C -".
h=$(fp_home mut)
stop "$h" mut KILL
sed 's/^/      /' "$S/mut-KILL.requests"
ctl=same
[ $RESUMED = no ] && ctl=opposite
check "negative control (wizard without -C -: the resume check fails): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host, 5 MB test model, loopback Range server) cases=stop/KILL,stop/INT,cut1,cut2 control=$ctl spark=NOT_RUN"
