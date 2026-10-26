#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# The lending step and aienos lend, against a fake GB10 tree, the fake engine and a tiny model that
# is already in place (no download). Nothing here opens a GPU device or a listening port of its
# own; the lending program is pointed at a closed loopback port, so it only retries its connection.
#
#   OMC=/path/to/omc STAGE=/path/to/out/stage [OH_VOLUNTEER=/path/to/oh-infer-volunteer] sh tests/lend.sh [SCRATCH]
#
# Without OH_VOLUNTEER the cases that need the real lending program print "NOT_RUN name". Prints
# "PASS name" / "FAIL name: why", then "AIENOS-LEND-TESTS pass=N fail=N notrun=N".
set -u
here=$(cd "$(dirname "$0")" && pwd)
: "${OMC:?set OMC to the pinned omc}" "${STAGE:?set STAGE}"
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-lend.XXXXXX")}
mkdir -p "$S"
S=$(cd "$S" && pwd)
TAG=alpha-20261026.1
CLOSED=${AIENOS_TEST_CLOSED_PORT:-18797}
pass=0
fail=0
notrun=0
ok() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail + 1)); printf 'FAIL %s: %s\n' "$1" "$2"; }
nr() { notrun=$((notrun + 1)); printf 'NOT_RUN %s: %s\n' "$1" "$2"; }
verdict() { if [ "$2" -eq 0 ]; then ok "$1"; else no "$1" "condition false (see $S)"; fi; }
trap 'pkill -f "$S/" 2>/dev/null' EXIT INT TERM

sh "$here/fake-root.sh" "$S/root" gb10
"$OMC" < "$here/fake-engine.om" > "$S/fake-engine" 2> "$S/fake-engine.err" || { cat "$S/fake-engine.err"; exit 2; }
chmod +x "$S/fake-engine"
mkdir -p "$S/model"
head -c 200000 /dev/urandom > "$S/model/weights.bin"
printf '{"model_type":"test"}\n' > "$S/model/config.json"

# The test release: the build stage with the fake engine and a manifest for the tiny model.
mkstage() { # dir with-program
    rm -rf "$1"; cp -a "$STAGE" "$1"
    rm -f "$1/bin/oh-infer-volunteer" "$1/share/aienos/lend.conf"
    install -m 755 "$S/fake-engine" "$1/bin/aien-serve-http"
    {
        printf 'name test-model\nurl http://127.0.0.1:%s/model/\n' "$CLOSED"
        printf 'bytes %s\nfiles 2\n' "$(cat "$S/model/weights.bin" "$S/model/config.json" | wc -c | tr -d ' ')"
        for f in config.json weights.bin; do
            printf '%s %s %s\n' "$(sha256sum "$S/model/$f" | cut -d' ' -f1)" "$(wc -c < "$S/model/$f" | tr -d ' ')" "$f"
        done
    } > "$1/share/aienos/model.manifest"
    if [ "$2" = yes ]; then
        install -m 755 "$OH_VOLUNTEER" "$1/bin/oh-infer-volunteer"
        {
            printf 'coordinator http://127.0.0.1:%s/oh/v1/volunteer\n' "$CLOSED"
            printf 'coordinator-key %s\n' "$(printf 'lend-test' | sha256sum | cut -d' ' -f1)"
            printf 'model-digest %s\n' "$(sha256sum "$1/share/aienos/model.manifest" | cut -d' ' -f1)"
        } > "$1/share/aienos/lend.conf"
    fi
    (cd "$1" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)
}
# A home with the release installed and the model already downloaded and verified.
mkhome() { # name stage
    h=$S/home-$1
    rm -rf "$h"; mkdir -p "$h/.local/share/aienos/releases" "$h/.local/share/aienos/models"
    cp -a "$2" "$h/.local/share/aienos/releases/$TAG"
    ln -s "releases/$TAG" "$h/.local/share/aienos/current"
    cp -a "$S/model" "$h/.local/share/aienos/models/test-model"
    : > "$h/.local/share/aienos/models/test-model/.aienos-verified"
    printf '%s' "$h"
}
aien() { h=$1; shift; env HOME="$h" AIENOS_PROBE_ROOT="$S/root" "$h/.local/share/aienos/current/bin/aienos" "$@"; }
# welcome, doctor, plan, yes, install, model, first chat, lending (two panels: Enter, answer), done.
wiz() { # home answer
    printf '\n\n\nyes\n\n\n\n\n%s\n\n\n\n' "$2" | env HOME="$1" AIENOS_PROBE_ROOT="$S/root" \
        timeout 120 "$1/.local/share/aienos/current/bin/aienos" wizard --plain
    rc=$?
    aien "$1" stop > /dev/null 2>&1
    return $rc
}
lend=.local/share/aienos/lend

mkstage "$S/stage-bare" no
h=$(mkhome skip "$S/stage-bare")
out=$(wiz "$h" "" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/skip.out"
[ $rc -eq 0 ] && grep -q "step 8 of 9  lend (optional)" "$S/skip.out" \
    && grep -q "It opens no ports on your network." "$S/skip.out" \
    && grep -q "at most 60 an hour, each at most 1,024 tokens" "$S/skip.out" \
    && grep -q "Type yes to lend this Spark, or press Enter to skip." "$S/skip.out" \
    && grep -q "step 9 of 9  done" "$S/skip.out" && [ ! -e "$h/$lend" ]; verdict lend-wizard-skip-changes-nothing $?

h=$(mkhome noprog "$S/stage-bare")
out=$(wiz "$h" yes 2>&1); rc=$?
printf '%s\n' "$out" > "$S/noprog.out"
[ $rc -eq 0 ] && grep -q "This release does not include the lending program yet. Nothing changed." "$S/noprog.out" \
    && [ ! -e "$h/$lend" ]; verdict lend-wizard-yes-without-program $?
out=$(aien "$h" lend start 2>&1); rc=$?
[ $rc -eq 1 ] && printf '%s' "$out" | grep -q "does not include the lending program" \
    && [ ! -e "$h/$lend" ]; verdict lend-start-without-program-refuses $?

if [ -z "${OH_VOLUNTEER:-}" ]; then
    for c in lend-wizard-yes-makes-key lend-start-without-key-refuses lend-start lend-status \
             lend-pause-resume lend-quit lend-uninstall-stops-agent; do nr "$c" "OH_VOLUNTEER not set"; done
else
    mkstage "$S/stage-lend" yes
    h=$(mkhome yes "$S/stage-lend")
    out=$(wiz "$h" yes 2>&1); rc=$?
    printf '%s\n' "$out" > "$S/yes.out"
    [ $rc -eq 0 ] && [ "$(stat -c %a "$h/$lend/key" 2>/dev/null)" = 600 ] \
        && grep -Eq "^volunteer key [0-9a-f]{64}$" "$S/yes.out" \
        && grep -q "email this key to drake@aienos.com with the" "$S/yes.out" \
        && grep -q "subject Open Humanity Spark. Lending starts when you run: aienos lend start" "$S/yes.out" \
        && [ ! -e "$h/$lend/lend.pid" ]; verdict lend-wizard-yes-makes-key $?
    key=$(grep -E "^volunteer key [0-9a-f]{64}$" "$S/yes.out" | head -1)
    # A second yes keeps the existing key (print-key, never a new one).
    out=$(wiz "$h" yes 2>&1)
    printf '%s\n' "$out" > "$S/yes2.out"
    [ -n "$key" ] && grep -qx "$key" "$S/yes2.out"; verdict lend-wizard-yes-keeps-key $?

    h2=$(mkhome nokey "$S/stage-lend")
    out=$(aien "$h2" lend start 2>&1); rc=$?
    [ $rc -eq 1 ] && printf '%s' "$out" | grep -q "There is no lending key yet" \
        && [ ! -e "$h2/$lend/lend.pid" ] && ! pgrep -f "$h2/" > /dev/null; verdict lend-start-without-key-refuses $?

    out=$(aien "$h" lend start 2>&1); rc=$?
    printf '%s\n' "$out" > "$S/start.out"
    pid=$(cat "$h/$lend/lend.pid" 2>/dev/null)
    [ $rc -eq 0 ] && [ -n "$pid" ] && printf '%s' "$out" | grep -q "lending started, pid $pid" \
        && [ "$(basename "$(readlink "/proc/$pid/exe")")" = oh-infer-volunteer ] \
        && grep -q "model test-model verified" "$h/$lend/lend.log"; verdict lend-start $?
    out=$(aien "$h" lend start 2>&1); rc=$?
    [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "lending is already running, pid $pid"; verdict lend-start-twice $?
    out=$(aien "$h" lend status 2>&1); rc=$?
    printf '%s\n' "$out" > "$S/status.out"
    [ $rc -eq 0 ] && grep -q "lending: running, pid $pid" "$S/status.out" && grep -q "paused: no" "$S/status.out" \
        && grep -qx "$key" "$S/status.out"; verdict lend-status $?
    a=$(aien "$h" lend pause 2>&1); r1=$?
    [ -f "$h/$lend/paused" ]; p1=$?
    s1=$(aien "$h" lend status 2>&1)
    b=$(aien "$h" lend resume 2>&1); r2=$?
    [ $r1 -eq 0 ] && [ $p1 -eq 0 ] && printf '%s' "$s1" | grep -q "paused: yes" \
        && [ $r2 -eq 0 ] && [ ! -e "$h/$lend/paused" ]; verdict lend-pause-resume $?
    aien "$h" lend pause > /dev/null 2>&1
    out=$(aien "$h" lend quit 2>&1); rc=$?
    [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "Lending stopped and this Spark's key was deleted. Nothing else changed." \
        && [ ! -e "/proc/$pid" ] && [ ! -e "$h/$lend/lend.pid" ] && [ ! -e "$h/$lend/key" ] \
        && [ ! -e "$h/$lend/paused" ] && [ -d "$h/.local/share/aienos/models/test-model" ]; verdict lend-quit $?
    out=$(aien "$h" lend status 2>&1)
    printf '%s' "$out" | grep -q "lending: not running" && printf '%s' "$out" | grep -q "no lending key"; verdict lend-status-after-quit $?

    # uninstall stops a running agent before removing files.
    wiz "$h2" yes > /dev/null 2>&1
    aien "$h2" lend start > "$S/start2.out" 2>&1
    pid=$(cat "$h2/$lend/lend.pid" 2>/dev/null)
    out=$(env HOME="$h2" "$h2/.local/share/aienos/current/bin/aienos" uninstall --yes 2>&1); rc=$?
    [ -n "$pid" ] && [ $rc -eq 0 ] && [ ! -e "/proc/$pid" ] && [ ! -e "$h2/.local/share/aienos" ]; verdict lend-uninstall-stops-agent $?
fi

printf 'AIENOS-LEND-TESTS pass=%s fail=%s notrun=%s scratch=%s\n' "$pass" "$fail" "$notrun" "$S"
[ "$fail" -eq 0 ]
