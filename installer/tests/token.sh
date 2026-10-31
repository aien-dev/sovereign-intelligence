#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# The per-install bearer token (DRA-56, wizard side): where it lives and with which modes, that it
# comes from getrandom, that it reaches the engine as AIEN_SERVE_HTTP_BEARER_TOKEN and never through
# argv or a log, that every request carries "Authorization: Bearer <token>", and that a token file
# or folder with wider modes, a link or damaged contents is refused. Uses the fake GB10 tree, the
# fake engine (which, like Core main's engine, refuses to start without the token and answers 401
# without the right header) and a tiny model already in place. Listens on 127.0.0.1:18100 (the
# wizard's port) only; opens no GPU device.
#
#   OMC=/path/to/omc STAGE=/path/to/out/stage [CORE_ENGINE=/path/to/aien-serve-http] sh tests/token.sh [SCRATCH]
#
# CORE_ENGINE: an aien-serve-http built from aien-dev/aien-sovereign-core-mv main (it enforces the
# token; the shipped 59b05a71 engine does not). It runs only as "--engine stub", inside bwrap with
# no NVIDIA device nodes and CUDA_VISIBLE_DEVICES empty. Without it, or without bwrap, those cases
# print "NOT_RUN name". strace is optional too (the getrandom case). Prints "PASS name" /
# "FAIL name: why" / "NOT_RUN name: why", then "AIENOS-TOKEN-TESTS pass=N fail=N notrun=N".
set -u
here=$(cd "$(dirname "$0")" && pwd)
: "${OMC:?set OMC to the pinned omc}" "${STAGE:?set STAGE}"
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-token.XXXXXX")}
mkdir -p "$S"
S=$(cd "$S" && pwd)
TAG=alpha-20261029.1
PORT=18100
pass=0
fail=0
notrun=0
ok() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail + 1)); printf 'FAIL %s: %s\n' "$1" "$2"; }
nr() { notrun=$((notrun + 1)); printf 'NOT_RUN %s: %s\n' "$1" "$2"; }
verdict() { if [ "$2" -eq 0 ]; then ok "$1"; else no "$1" "condition false (see $S)"; fi; }
trap 'pkill -f "$S/" 2>/dev/null' EXIT INT TERM
up() { curl -s -o /dev/null -m 2 "http://127.0.0.1:$PORT/health"; }
if up; then echo "something already answers on 127.0.0.1:$PORT; stop it first"; exit 2; fi

sh "$here/fake-root.sh" "$S/root" gb10
"$OMC" < "$here/fake-engine.om" > "$S/fake-engine" 2> "$S/fake-engine.err" || { cat "$S/fake-engine.err"; exit 2; }
chmod +x "$S/fake-engine"
mkdir -p "$S/model"
head -c 200000 /dev/urandom > "$S/model/weights.bin"
printf '{"model_type":"test"}\n' > "$S/model/config.json"

# The test release (as in lend.sh): the build stage with the fake engine and the tiny model's manifest.
mkstage() { # dir
    rm -rf "$1"; cp -a "$STAGE" "$1"
    rm -f "$1/bin/oh-infer-volunteer" "$1/share/aienos/lend.conf"
    install -m 755 "$S/fake-engine" "$1/bin/aien-serve-http"
    {
        printf 'name test-model\nurl http://127.0.0.1:9/model/\n'
        printf 'bytes %s\nfiles 2\n' "$(cat "$S/model/weights.bin" "$S/model/config.json" | wc -c | tr -d ' ')"
        for f in config.json weights.bin; do
            printf '%s %s %s\n' "$(sha256sum "$S/model/$f" | cut -d' ' -f1)" "$(wc -c < "$S/model/$f" | tr -d ' ')" "$f"
        done
    } > "$1/share/aienos/model.manifest"
    (cd "$1" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)
}
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
# The same command from the mutant stage (the wizard with its two qauth calls removed).
mutant() { h=$1; shift; env HOME="$h" AIENOS_PROBE_ROOT="$S/root" "$S/stage-mutant/bin/aienos" "$@"; }
wiz() { # home
    printf '\n\n\nyes\n\n\n\n\n\n\n\n\n' | env HOME="$1" AIENOS_PROBE_ROOT="$S/root" \
        timeout 120 "$1/.local/share/aienos/current/bin/aienos" wizard --plain
    rc=$?
    aien "$1" stop > /dev/null 2>&1
    return $rc
}
chat() { printf 'hello\n/bye\n' | aien "$1" chat 2>&1; }
auth=.local/share/aienos/auth
tokf() { printf '%s/%s/bearer-token' "$1" "$auth"; }
tokv() { head -c 64 "$(tokf "$1")"; }
newtok() { od -An -tx1 -N32 /dev/urandom | tr -d ' \n'; }
logl() { grep -c "$2" "$1/.local/share/aienos/engine.log" 2>/dev/null || true; }
refused() { # output rc home: refused with the token message, no engine started
    [ "$2" -eq 1 ] && printf '%s' "$1" | grep -q "access token is missing, damaged or readable by others" \
        && [ ! -e "$3/.local/share/aienos/engine.pid" ] && ! up
}
mchat() { printf 'hello\n/bye\n' | mutant "$1" chat 2>&1; }
me=$(id -u)

mkstage "$S/stage"
mkstage "$S/stage-mutant"
sed '/^qauth$/d' "$S/stage-mutant/share/aienos/aienos.om" > "$S/mutant.om"
[ "$(grep -c '^qauth$' "$S/stage-mutant/share/aienos/aienos.om")" = 2 ] || { echo "expected two qauth calls in aienos.om"; exit 2; }
"$OMC" < "$S/mutant.om" > "$S/stage-mutant/bin/aienos" 2> "$S/mutant.err" || { cat "$S/mutant.err"; exit 2; }

# ---- the wizard makes the token at install time and uses it for the first chat ----
h=$(mkhome w1 "$S/stage")
out=$(wiz "$h" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/w1.out"
[ $rc -eq 0 ] && grep -q "auth/bearer-token   the engine's private access token" "$S/w1.out"; verdict token-plan-lists-file $?
[ "$(stat -c '%a %u %F' "$h/$auth")" = "700 $me directory" ] \
    && [ "$(stat -c '%a %u %F %s' "$(tokf "$h")")" = "600 $me regular file 65" ]; verdict token-file-0600-dir-0700 $?
[ "$(wc -l < "$(tokf "$h")")" = 1 ] && grep -qxE '[0-9a-f]{64}' "$(tokf "$h")"; verdict token-64-hex-one-line $?
grep -q 'Hello from the fake engine' "$S/w1.out" && [ "$(logl "$h" 'POST authorized')" -ge 1 ] \
    && [ "$(logl "$h" 'POST refused')" = 0 ]; verdict token-wizard-chat-authorized $?
tok=$(tokv "$h")
# Positive control first: the search does find the token in its own file.
grep -rlF "$tok" "$h" > "$S/w1.hits"
[ "$(cat "$S/w1.hits")" = "$(tokf "$h")" ] && ! grep -qF "$tok" "$S/w1.out"; verdict token-not-in-logs-or-output $?

# ---- aienos start: the token reaches the engine by its environment, not argv ----
out=$(aien "$h" start 2>&1); rc=$?
pid=$(cat "$h/.local/share/aienos/engine.pid" 2>/dev/null || echo 0)
[ $rc -eq 0 ] && [ "$pid" -gt 0 ] \
    && [ "$(readlink "/proc/$pid/exe")" = "$h/.local/share/aienos/releases/$TAG/bin/aien-serve-http" ] \
    && tr '\0' '\n' < "/proc/$pid/environ" | grep -qx "AIEN_SERVE_HTTP_BEARER_TOKEN=$tok" \
    && ! tr '\0' '\n' < "/proc/$pid/cmdline" | grep -qF "$tok"; verdict token-in-engine-env-not-argv $?
s1=$(sha256sum < "$(tokf "$h")")
aien "$h" stop > /dev/null 2>&1
out=$(aien "$h" start 2>&1); rc=$?
[ $rc -eq 0 ] && [ "$(sha256sum < "$(tokf "$h")")" = "$s1" ]; verdict token-kept-across-starts $?
# Wrong token: the engine holds the old one; the file now holds another valid token.
newtok > "$S/other"; printf '\n' >> "$S/other"
cp "$(tokf "$h")" "$S/w1.tok"; cat "$S/other" > "$(tokf "$h")"
out=$(chat "$h"); printf '%s\n' "$out" > "$S/w1-wrong.out"
printf '%s' "$out" | grep -q "request failed: 401" && ! printf '%s' "$out" | grep -q "Hello from the fake engine" \
    && [ "$(logl "$h" 'POST refused')" -ge 1 ]; verdict control-wrong-token-401 $?
cat "$S/w1.tok" > "$(tokf "$h")"
# No header at all: the mutant wizard against the same engine.
out=$(printf 'hello\n/bye\n' | mutant "$h" chat 2>&1); printf '%s\n' "$out" > "$S/w1-mutant.out"
printf '%s' "$out" | grep -q "request failed: 401"; verdict control-missing-header-401 $?
out=$(chat "$h"); printf '%s\n' "$out" > "$S/w1-right.out"
printf '%s' "$out" | grep -q "model> Hello from the fake engine"; verdict token-chat-command-authorized $?
aien "$h" stop > /dev/null 2>&1
out=$(env -i "$S/fake-engine" 2>&1); rc=$?
[ $rc -eq 3 ] && printf '%s' "$out" | grep -q "must be set" && ! up; verdict control-engine-without-token-refuses $?

# ---- the request bytes, captured by a plain listener on 127.0.0.1:18100 ----
cat > "$S/capture.py" <<'EOF'
import socket, sys
out = open(sys.argv[1], "ab")
s = socket.socket()
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", int(sys.argv[2])))
s.listen(8)
open(sys.argv[3], "w").close()
while True:
    c, _ = s.accept()
    c.settimeout(5)
    data = b""
    while b"\r\n\r\n" not in data:
        d = c.recv(65536)
        if not d:
            break
        data += d
    head, _, body = data.partition(b"\r\n\r\n")
    n = 0
    for line in head.split(b"\r\n"):
        if line.lower().startswith(b"content-length:"):
            n = int(line.split(b":", 1)[1])
    while len(body) < n:
        d = c.recv(65536)
        if not d:
            break
        body += d
    out.write(b"=== request\n" + head + b"\r\n\r\n")
    out.flush()
    if data.startswith(b"GET"):
        c.sendall(b"HTTP/1.0 200 OK\r\n\r\nok")
    else:
        c.sendall(b"HTTP/1.0 200 OK\r\nContent-Type: text/event-stream\r\n\r\n"
                  b'data: {"choices":[{"delta":{"content":"captured"}}]}\r\n\r\ndata: [DONE]\r\n\r\n')
    c.close()
EOF
capture() { # name command...
    n=$1; shift
    rm -f "$S/$n.req" "$S/$n.ready"
    python3 "$S/capture.py" "$S/$n.req" "$PORT" "$S/$n.ready" > "$S/$n.cap.log" 2>&1 &
    cp=$!
    i=0; while [ ! -e "$S/$n.ready" ] && [ $i -lt 50 ]; do i=$((i + 1)); sleep 0.1; done
    "$@" > "$S/$n.out" 2>&1
    kill $cp 2>/dev/null; wait $cp 2>/dev/null
    tr -d '\r' < "$S/$n.req" > "$S/$n.txt"
}
capture cap chat "$h"
reqs=$(grep -c '^=== request$' "$S/cap.txt")
[ "$reqs" -ge 2 ] && grep -q '^POST /v1/chat/completions ' "$S/cap.txt" && grep -q '^GET /health ' "$S/cap.txt" \
    && [ "$(grep -cx "Authorization: Bearer $tok" "$S/cap.txt")" = "$reqs" ] \
    && [ "$(grep -c '^Authorization:' "$S/cap.txt")" = "$reqs" ] \
    && [ "$(grep -cx "Host: 127.0.0.1:$PORT" "$S/cap.txt")" = "$reqs" ]; verdict token-header-in-every-request $?
capture capm mchat "$h"
[ "$(grep -c '^=== request$' "$S/capm.txt")" -ge 2 ] && ! grep -q '^Authorization:' "$S/capm.txt"; verdict control-capture-sees-missing-header $?

# ---- the entropy source: getrandom, 32 bytes, blocking flags 0 ----
h=$(mkhome w2 "$S/stage")
# No -f: the token is drawn by the aienos process itself, and -f would wait on the engine it leaves running.
if command -v strace > /dev/null 2>&1 && strace -qq -e trace=getrandom -o "$S/strace0.txt" true 2> /dev/null; then
    env HOME="$h" AIENOS_PROBE_ROOT="$S/root" strace -qq -e trace=getrandom -o "$S/strace1.txt" \
        "$h/.local/share/aienos/current/bin/aienos" start > "$S/w2-start.out" 2>&1
    aien "$h" stop > /dev/null 2>&1
    grep -qE 'getrandom\(.*, 32, 0\) += 32$' "$S/strace1.txt" && [ -s "$(tokf "$h")" ]; verdict token-from-getrandom-32-bytes $?
    env HOME="$h" AIENOS_PROBE_ROOT="$S/root" strace -qq -e trace=getrandom -o "$S/strace2.txt" \
        "$h/.local/share/aienos/current/bin/aienos" start > /dev/null 2>&1
    aien "$h" stop > /dev/null 2>&1
    ! grep -qE 'getrandom\(.*, 32, 0\)' "$S/strace2.txt"; verdict control-existing-token-not-redrawn $?
else
    nr token-from-getrandom-32-bytes "strace missing or not permitted"
    nr control-existing-token-not-redrawn "strace missing or not permitted"
    aien "$h" start > /dev/null 2>&1; aien "$h" stop > /dev/null 2>&1
fi
[ -s "$(tokf "$h")" ] && [ "$(tokv "$h")" != "$tok" ]; verdict token-differs-per-install $?

# ---- refusals: wider modes, a link, damaged contents ----
f=$(tokf "$h")
chmod 644 "$f"
out=$(aien "$h" start 2>&1); rc=$?
refused "$out" $rc "$h"; verdict control-file-0644-refused $?
chmod 600 "$f"
chmod 755 "$h/$auth"
out=$(aien "$h" start 2>&1); rc=$?
refused "$out" $rc "$h"; verdict control-dir-0755-refused $?
chmod 700 "$h/$auth"
mv "$f" "$S/w2.tok"; ln -s "$S/w2.tok" "$f"
out=$(aien "$h" start 2>&1); rc=$?
refused "$out" $rc "$h"; verdict control-symlink-refused $?
rm "$f"; mv "$S/w2.tok" "$f"
cp "$f" "$S/w2.tok"
printf 'G' | dd of="$f" bs=1 seek=10 conv=notrunc 2>/dev/null
out=$(aien "$h" start 2>&1); rc=$?
refused "$out" $rc "$h"; verdict control-non-hex-refused $?
head -c 32 "$S/w2.tok" > "$f"; printf '\n' >> "$f"
out=$(aien "$h" start 2>&1); rc=$?
refused "$out" $rc "$h"; verdict control-short-token-refused $?
cat "$S/w2.tok" > "$f"
out=$(aien "$h" start 2>&1); rc=$?
[ $rc -eq 0 ] && up && [ "$(tokv "$h")" = "$(head -c 64 "$S/w2.tok")" ]; verdict token-restored-starts $?
aien "$h" stop > /dev/null 2>&1
# The remedy the message gives: remove the folder; the next start makes a new token.
rm -rf "$h/$auth"
out=$(aien "$h" start 2>&1); rc=$?
[ $rc -eq 0 ] && [ "$(stat -c %a "$(tokf "$h")")" = 600 ] && [ "$(tokv "$h")" != "$(head -c 64 "$S/w2.tok")" ]; verdict token-remade-after-removal $?
aien "$h" stop > /dev/null 2>&1
# The wizard's install step refuses a folder that others can open, and starts nothing.
h=$(mkhome w3 "$S/stage")
mkdir -m 755 "$h/$auth"
out=$(wiz "$h" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/w3.out"
[ $rc -eq 1 ] && grep -q "access token is missing, damaged or readable by others" "$S/w3.out" \
    && [ ! -e "$(tokf "$h")" ] && [ ! -e "$h/.local/share/aienos/engine.log" ]; verdict control-wizard-refuses-open-folder $?
# Uninstall removes the token with everything else.
h=$S/home-w1
out=$(env HOME="$h" "$S/stage/bin/aienos" uninstall --yes 2>&1); rc=$?
[ $rc -eq 0 ] && [ ! -e "$h/$auth" ]; verdict token-removed-by-uninstall $?

# ---- Core main's engine (stub engine, sandboxed): it enforces what the wizard sends ----
if [ -z "${CORE_ENGINE:-}" ] || ! command -v bwrap > /dev/null 2>&1; then
    for c in core-refuses-without-token core-matrix-401-401-200 core-wizard-chat-200 core-wizard-wrong-token-401 core-wizard-missing-header-401; do
        nr "$c" "set CORE_ENGINE (Core main aien-serve-http) and install bwrap"
    done
else
    install -m 755 "$CORE_ENGINE" "$S/core-engine"
    mkdir -p "$S/core-model"
    box() { # port log [token]
        if [ $# -ge 3 ]; then set -- "$1" "$2" "AIEN_SERVE_HTTP_BEARER_TOKEN=$3"; else set -- "$1" "$2" "AIENOS_NO_TOKEN=1"; fi
        env -i PATH=/usr/bin:/bin CUDA_VISIBLE_DEVICES= NVIDIA_VISIBLE_DEVICES=none "$3" \
            bwrap --die-with-parent --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp \
            "$S/core-engine" --engine stub --bind 127.0.0.1 --port "$1" --model-dir "$S/core-model" \
            --stub-reply "Hello from the Core stub engine" > "$2" 2>&1
    }
    boxup() { # log -> port, or empty
        i=0; while [ $i -lt 100 ]; do
            p=$(sed -n 's|.*serving .* at http://127\.0\.0\.1:\([0-9]*\)/v1.*|\1|p' "$1" | head -n 1)
            [ -n "$p" ] && { printf '%s' "$p"; return 0; }
            i=$((i + 1)); sleep 0.1
        done
        return 1
    }
    h=$(mkhome core "$S/stage")
    aien "$h" start > /dev/null 2>&1; aien "$h" stop > /dev/null 2>&1
    ct=$(tokv "$h")
    box 0 "$S/core0.log"; rc=$?
    [ $rc -ne 0 ] && grep -q "AIEN_SERVE_HTTP_BEARER_TOKEN must be set" "$S/core0.log"; verdict core-refuses-without-token $?
    box 0 "$S/core1.log" "$ct" & bp=$!
    if p=$(boxup "$S/core1.log"); then
        req() { curl -s -o /dev/null -w '%{http_code}' -H 'Content-Type: application/json' "$@" \
            -d '{"stream":true,"max_tokens":8,"messages":[{"role":"user","content":"hi"}]}' \
            "http://127.0.0.1:$p/v1/chat/completions"; }
        a=$(req); b=$(req -H "Authorization: Bearer $(newtok)"); c=$(req -H "Authorization: Bearer $ct")
        printf 'missing=%s wrong=%s right=%s\n' "$a" "$b" "$c" > "$S/core-matrix.txt"
        [ "$a" = 401 ] && [ "$b" = 401 ] && [ "$c" = 200 ]; verdict core-matrix-401-401-200 $?
    else
        no core-matrix-401-401-200 "engine did not start (see $S/core1.log)"
    fi
    kill $bp 2>/dev/null; wait $bp 2>/dev/null; pkill -f "$S/core-engine" 2>/dev/null; sleep 0.3
    # The wizard's own chat against it, on the wizard's port.
    box "$PORT" "$S/core2.log" "$ct" & bp=$!
    if boxup "$S/core2.log" > /dev/null; then
        out=$(chat "$h"); printf '%s\n' "$out" > "$S/core-right.out"
        printf '%s' "$out" | grep -q "model> Hello from the Core stub engine"; verdict core-wizard-chat-200 $?
        cp "$(tokf "$h")" "$S/core.tok"; cat "$S/other" > "$(tokf "$h")"
        out=$(chat "$h"); printf '%s\n' "$out" > "$S/core-wrong.out"
        printf '%s' "$out" | grep -q "request failed: 401"; verdict core-wizard-wrong-token-401 $?
        cat "$S/core.tok" > "$(tokf "$h")"
        out=$(printf 'hello\n/bye\n' | mutant "$h" chat 2>&1); printf '%s\n' "$out" > "$S/core-mutant.out"
        printf '%s' "$out" | grep -q "request failed: 401"; verdict core-wizard-missing-header-401 $?
    else
        for c in core-wizard-chat-200 core-wizard-wrong-token-401 core-wizard-missing-header-401; do
            no "$c" "engine did not start on $PORT (see $S/core2.log)"
        done
    fi
    kill $bp 2>/dev/null; wait $bp 2>/dev/null
fi

printf 'AIENOS-TOKEN-TESTS pass=%s fail=%s notrun=%s scratch=%s\n' "$pass" "$fail" "$notrun" "$S"
[ "$fail" -eq 0 ]
