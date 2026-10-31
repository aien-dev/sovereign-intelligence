#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: a corrupted model file. The SHA-256 check against the release's model.manifest
# must refuse it; nothing corrupt may be kept or used. (The corrupted bundle is bad-signature.sh.)
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar. Host run in scratch homes on a
#   fake GB10 probe root after a complete test install; the test model (config.json and a 5 MB
#   weights.bin) is served from 127.0.0.1 by fp_serve_range. "Corrupt" = one byte of weights.bin
#   changed, the size unchanged, so only the hash can tell.
#   (a) served: the server sends a corrupted weights.bin (a bad mirror, a proxy, bit errors).
#   (b) on-disk: a corrupted weights.bin of the right size is already in the model folder, not yet
#       verified (a copy from elsewhere, an earlier run cut before its check); the server is good.
#   (c) after: the model was downloaded and verified, then weights.bin was corrupted on disk
#       (bit rot, an editor, a bad copy back from a backup).
# Expected result: (a) the wizard exits non-zero and says "The download or a hash check failed";
#   no weights.bin, no .part and no verified marker are kept; the engine is not started.
#   (b) the wizard hashes the file, drops it, downloads it again and verifies it.
#   (c) "aienos verify" exits non-zero naming the bad model file and withdraws the verified marker;
#   the next wizard run downloads the file again and verifies it.
# Negative control: case (a) against a wizard whose download hash check is removed (FP_MUTATE:
#   mget's "if dgis o" becomes "if true") must fail the refusal checks (opposite verdict).
# Status: EXERCISED(host, 5 MB test model, loopback server). Stock DGX Spark with the 37.5 GB
#   model: NOT_RUN.
#
# usage: OMC=... sh model-corrupt.sh [SCRATCH]
set -u
FP_NAME=model-corrupt
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-corrupt.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve_range
port=$(fp_port)
fp_compile "$S/bin" "$port" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
FP_MUTATE='s/^if dgis o$/if true/' fp_compile "$S/bin-mut" "$port" \
    || fp_notrun "omc refused the no-hash test wizard ($S/bin-mut/omc.err)"
fp_release good "$S/bin"
fp_release mut "$S/bin-mut"
R=$(fp_root gb10)
G=$S/www/model/weights.bin
cp "$G" "$S/weights.good"
# flip FILE: change one byte in the middle, keeping the size.
flip() {
    python3 -c 'import sys; f = open(sys.argv[1], "r+b"); f.seek(2500000); b = f.read(1); f.seek(2500000); f.write(bytes([b[0] ^ 0xff]))' "$1"
}
cp "$G" "$S/weights.bad"
flip "$S/weights.bad"
cmp -s "$S/weights.bad" "$G" && fp_notrun "could not make a corrupted copy"
ALL='\n\n\nyes\n\n\n\n\n\n\n'
wiz() {
    printf '%b' "$ALL" | env HOME="$1" AIENOS_PROBE_ROOT="$R" TMPDIR="$S/tmp" \
        timeout 300 "$1/.local/share/aienos/current/bin/aienos" wizard --plain > "$2" 2>&1; rc=$?
    env HOME="$1" "$1/.local/share/aienos/current/bin/aienos" stop > /dev/null 2>&1
    return $rc
}
mark() { wc -l < "$S/range.log" | tr -d ' '; }
since() { sed -n "$(($1 + 1)),\$p" "$S/range.log" | grep '^GET /model/weights.bin '; }
model() { printf '%s' "$1/.local/share/aienos/models/test-model"; }
verified() {
    m=$(model "$1")
    [ -f "$m/.aienos-verified" ] && cmp -s "$m/weights.bin" "$S/weights.good" && [ ! -e "$m/weights.bin.part" ]
}

# see NAME RC: one refusal check; in the control run (CTL set) only logged, as it must break.
see() {
    if [ -n "${CTL:-}" ]; then
        fp_log "ctl  $1: $([ "$2" -eq 0 ] && echo held || echo broken)"
    else
        check "$1" "$2"
    fi
    [ "$2" -eq 0 ] || REFUSED=no
}
# served HOME RELEASE: case (a). Sets REFUSED=yes when every refusal check held.
served() {
    fp_boot "$1" "$2" > "$S/served-$2.boot.out" 2>&1
    cp "$S/weights.bad" "$G"
    n=$(mark)
    wiz "$1" "$S/served-$2.out"; rc=$?
    since "$n" | sed 's/^/      /'
    cp "$S/weights.good" "$G"
    m=$(model "$1")
    REFUSED=yes
    see "served/$2: wizard exit non-zero (got $rc)" "$([ $rc -ne 0 ]; echo $?)"
    grep -q "The download or a hash check failed" "$S/served-$2.out"
    see "served/$2: says the download or a hash check failed" $?
    [ ! -e "$m/weights.bin" ] && [ ! -e "$m/weights.bin.part" ] && [ ! -e "$m/.aienos-verified" ]
    see "served/$2: no weights.bin, no .part, no verified marker kept" $?
    [ ! -e "$1/.local/share/aienos/engine.log" ]
    see "served/$2: the engine was never started (no engine.log)" $?
}

h=$(fp_home served)
served "$h" good

# (b) a corrupted, unverified file already in place.
h=$(fp_home ondisk)
fp_boot "$h" good > "$S/ondisk.boot.out" 2>&1
m=$(model "$h")
mkdir -p "$m"
cp "$S/weights.bad" "$m/weights.bin"
n=$(mark)
wiz "$h" "$S/ondisk.out"; rc=$?
since "$n" > "$S/ondisk.requests"; sed 's/^/      /' "$S/ondisk.requests"
check "on-disk: wizard exit 0 (got $rc)" "$([ $rc -eq 0 ]; echo $?)"
grep -q "range=- status=200 sent=$(wc -c < "$G" | tr -d ' ')\$" "$S/ondisk.requests"
check "on-disk: the corrupted file was dropped and weights.bin downloaded again" $?
verified "$h"; check "on-disk: weights.bin verified, marker written" $?

# (c) corrupted after it was verified.
h=$(fp_home after)
fp_boot "$h" good > "$S/after.boot.out" 2>&1
wiz "$h" "$S/after.run1.out"; rc=$?
m=$(model "$h")
check "after: first run exit 0 and model verified (got $rc)" "$([ $rc -eq 0 ] && verified "$h"; echo $?)"
flip "$m/weights.bin"
env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" verify > "$S/after.verify.out" 2>&1; rc=$?
sed 's/^/      verify: /' "$S/after.verify.out"
check "after: aienos verify exit non-zero (got $rc)" "$([ $rc -ne 0 ]; echo $?)"
grep -q "weights.bin" "$S/after.verify.out"; check "after: aienos verify names weights.bin" $?
[ ! -e "$m/.aienos-verified" ]; check "after: the verified marker was withdrawn" $?
n=$(mark)
wiz "$h" "$S/after.run2.out"; rc=$?
since "$n" > "$S/after.requests"; sed 's/^/      /' "$S/after.requests"
check "after: re-run exit 0 (got $rc)" "$([ $rc -eq 0 ]; echo $?)"
grep -q "range=- status=200 sent=$(wc -c < "$G" | tr -d ' ')\$" "$S/after.requests"
check "after: re-run downloaded weights.bin again" $?
verified "$h"; check "after: weights.bin verified, marker written" $?
env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" verify > "$S/after.verify2.out" 2>&1
check "after: aienos verify exit 0 again" $?

# Negative control: case (a) against the wizard without its download hash check.
h=$(fp_home mut)
CTL=1 served "$h" mut
ctl=same
[ $REFUSED = no ] && ctl=opposite
check "negative control (no download hash check: the refusal checks fail): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host, 5 MB test model, loopback server) cases=served,on-disk,after control=$ctl spark=NOT_RUN"
