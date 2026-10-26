#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Onboarding test of the wizard: running-server detection, the consented swap and aienos restore,
# local weights, the Hugging Face token, and downloads. Everything runs in one docker container
# with its own pid and network namespaces (docker's default bridge, never --network host), as an
# unprivileged user, so the wizard sees only the mock servers started here and never this
# machine's processes or its live model server. No GPU device exists in the container; the engine
# is tests/fake-engine.om.
#
#   OMC=/path/to/omc STAGE=/path/to/out/stage sh tests/onboarding.sh RECEIPT_DIR
#
# Model servers are tests/mock-server.py run through links named vllm, llama-server and ollama.
# The registry has two entries: tiny-test (a 2 MB model served by a local file server with byte
# ranges) and hf-internal-testing/tiny-random-gpt2 at a pinned revision (tests/tiny-gpt2.manifest),
# downloaded from huggingface.co itself. Prints "PASS name" / "FAIL name: why" / "NOT_RUN name:
# why", then "AIENOS-ONBOARDING pass=N fail=N not_run=N"; exit 0 only when fail=0 and not_run=0.
set -u
TAG=alpha-20261026.3
here=$(cd "$(dirname "$0")" && pwd)

if [ "${1:-}" = --inside ]; then
    # ---------------- inside the container, as user tester ----------------
    H=$HOME
    A=$H/.local/share/aienos
    pass=0 fail=0 notrun=0
    ok() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
    no() { fail=$((fail + 1)); printf 'FAIL %s: %s\n' "$1" "$2"; }
    nr() { notrun=$((notrun + 1)); printf 'NOT_RUN %s: %s\n' "$1" "$2"; }
    verdict() { if [ "$2" -eq 0 ]; then ok "$1"; else no "$1" "condition false (see $H/$1.out)"; fi; }
    aien() { env AIENOS_PROBE_ROOT=/s/root-gb10 "$A/current/bin/aienos" "$@"; }
    wiz() { # input [probe-root]
        printf '%b' "$1" | env AIENOS_PROBE_ROOT="${2:-/s/root-gb10}" timeout 300 "$A/current/bin/aienos" wizard --plain
    }
    fresh() { # a new install of the test release, nothing else under ~/.local
        s=$(aien stop 2>&1)
        if curl -s -o /dev/null http://127.0.0.1:18100/health; then
            printf 'DIAG engine still up after aienos stop: %s\n' "$s"; ps -eo pid,args
        fi
        rm -rf "$H/.local" "$H/models" "$H/.cache"
        mkdir -p "$A/releases"
        cp -a /s/tstage "$A/releases/$TAG"
        ln -s "releases/$TAG" "$A/current"
    }
    up() { # port: wait up to 10 s for it to accept a connection
        i=0
        while ! curl -s -o /dev/null "http://127.0.0.1:$1/health"; do
            i=$((i + 1)); [ $i -lt 100 ] || return 1; sleep 0.1
        done
    }
    alive() { [ -d "/proc/$1" ] && ! grep -q '^[0-9]* ([^)]*) Z' "/proc/$1/stat" 2>/dev/null; }
    startv() { # port weights-dir served-id: a mock vLLM started from ~/work with a recorded env
        cd "$H/work" || exit 2
        env -i HOME="$H" PATH=/usr/bin:/bin LANG=C.UTF-8 MOCK_SECRET="s3 cr'et \$x" \
            "$H/bin/vllm" serve "$2" --port "$1" --served-model-name "$3" >> "$H/vllm-$1.log" 2>&1 &
        vp=$!
        cd "$H" || exit 2
        up "$1"
    }
    snap() { # pid prefix: argv, environment and folder of a process
        cat "/proc/$1/cmdline" > "$2.cmdline"; cat "/proc/$1/environ" > "$2.environ"
        readlink "/proc/$1/cwd" > "$2.cwd"
    }
    mode() { stat -c %a "$1" 2>/dev/null; }

    mkdir -p "$H/bin" "$H/work"
    for n in vllm llama-server ollama; do ln -s /t/mock-server.py "$H/bin/$n"; done
    python3 /t/mock-server.py files /s/www 18734 "$H/files.log" > /dev/null 2>&1 &
    python3 /t/mock-server.py whoami 18735 hf_aienosTestGoodToken > /dev/null 2>&1 &
    sleep 1
    printf 'container pid namespace: this script is pid %s; processes visible: %s\n' "$$" "$(ls /proc | grep -c '^[0-9]')"
    printf 'container network: %s\n' "$(cat /proc/net/route | awk 'NR == 2 { print $1 }')"
    good=$(sha256sum /s/www/model/weights.bin | cut -d' ' -f1)
    m=$A/models/test-model

    # 1. A supported vLLM is running: connect, swap, first chat, then aienos restore.
    fresh
    mkdir -p "$H/weights"; cp -a /s/www/model "$H/weights/tiny-test"
    startv 8000 "$H/weights/tiny-test" test-org/tiny-test
    v1=$vp
    snap "$v1" "$H/orig"
    out=$(wiz '\nyes\n\n\nyes\n\n\n\n\n\n\n\n\n' 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/swap-connect.out"
    r=$A/restore
    [ $rc -eq 0 ] && grep -q "I can run this model on my engine: Tiny test model" "$H/swap-connect.out" \
        && grep -q "Your server was down for" "$H/swap-connect.out" \
        && grep -q 'Hello from the fake engine' "$H/swap-connect.out" \
        && grep -q 'first token after' "$H/swap-connect.out" \
        && ! alive "$v1" && grep -q "stopped by SIGTERM" "$H/vllm-8000.log" \
        && curl -fs -o /dev/null http://127.0.0.1:18100/health \
        && [ "$(mode "$r/cmdline")" = 600 ] && [ "$(mode "$r/environ")" = 600 ] \
        && [ "$(mode "$r/info")" = 600 ] && [ "$(mode "$r/restore.sh")" = 700 ] \
        && [ -L "$m/weights.bin" ] && [ "$(readlink -f "$m/weights.bin")" = "$H/weights/tiny-test/weights.bin" ]
    verdict swap-connect $?
    cp "$H/swap-connect.out" "$H/swap-connect.keep"
    out=$(aien restore 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/restore-roundtrip.out"
    v2=$(printf '%s' "$out" | sed -n 's/^Started your server again .* pid \([0-9]*\).*/\1/p')
    [ $rc -eq 0 ] && [ -n "$v2" ] && alive "$v2" && snap "$v2" "$H/back" \
        && cmp -s "$H/orig.cmdline" "$H/back.cmdline" && cmp -s "$H/orig.environ" "$H/back.environ" \
        && cmp -s "$H/orig.cwd" "$H/back.cwd" \
        && curl -fs http://127.0.0.1:8000/v1/models | grep -q '"test-org/tiny-test"' \
        && ! curl -fs -o /dev/null http://127.0.0.1:18100/health \
        && [ ! -e "$r" ] && [ -d "$A/restore.done.$v2" ] \
        && [ "$(sha256sum "$H/weights/tiny-test/weights.bin" | cut -d' ' -f1)" = "$good" ]
    verdict restore-roundtrip $?
    # Negative control of the comparison: a server started with another environment differs.
    cd "$H/work" && env -i HOME="$H" PATH=/usr/bin:/bin LANG=C.UTF-8 MOCK_SECRET=other \
        "$H/bin/vllm" serve "$H/weights/tiny-test" --port 8009 --served-model-name test-org/tiny-test \
        > /dev/null 2>&1 &
    vc=$!; cd "$H"; up 8009; snap "$vc" "$H/ctl"
    ! cmp -s "$H/orig.environ" "$H/ctl.environ"; verdict restore-compare-control $?
    kill "$vc" "$v2" 2>/dev/null; sleep 1
    out=$(aien restore 2>&1); rc=$?
    [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "Nothing to restore"; verdict restore-nothing-twice $?

    # 2. Servers it cannot run: listed as not supported, every one left untouched.
    fresh
    mkdir -p "$H/weights/mystery-model"
    startv 8001 "$H/weights/mystery-model" other-org/mystery-model; u1=$vp
    : > "$H/x.gguf"
    "$H/bin/llama-server" -m "$H/x.gguf" --port 8081 > /dev/null 2>&1 & u2=$!
    env OLLAMA_HOST=127.0.0.1:11435 "$H/bin/ollama" serve > /dev/null 2>&1 & u3=$!
    up 8081; up 11435
    det=$(aien detect 2>&1)
    printf '%s\n' "$det" > "$H/unsupported-untouched.detect"
    out=$(wiz '\n\n' 2>&1)
    printf '%s\n' "$out" > "$H/unsupported-untouched.out"
    [ "$(grep -c "not supported yet. I will leave it untouched." "$H/unsupported-untouched.detect")" = 3 ] \
        && grep -q "llama.cpp server, pid $u2, port 8081" "$H/unsupported-untouched.detect" \
        && grep -q "Ollama, pid $u3, port 11435" "$H/unsupported-untouched.detect" \
        && grep -q "serves other-org/mystery-model" "$H/unsupported-untouched.detect" \
        && grep -q "I will leave them untouched" "$H/unsupported-untouched.out" \
        && alive "$u1" && alive "$u2" && alive "$u3" && [ ! -e "$A/restore" ] \
        && curl -fs -o /dev/null http://127.0.0.1:8001/v1/models
    verdict unsupported-untouched $?
    kill "$u1" "$u2" "$u3" 2>/dev/null; sleep 1

    # 3. Managed servers (a fake /proc tree): a systemd service and a container are refused;
    #    the same server under a user session is offered (negative control).
    fp=$H/fproc
    for p in 4242 4243 4244; do
        mkdir -p "$fp/proc/$p"
        printf 'vllm\0serve\0/w/tiny-test\0--port\0%s\0' "$((7000 + p - 4242))" > "$fp/proc/$p/cmdline"
        printf 'HOME=/x\0' > "$fp/proc/$p/environ"
    done
    printf '0::/system.slice/vllm.service\n' > "$fp/proc/4242/cgroup"
    printf '0::/system.slice/docker-0123abcd.scope\n' > "$fp/proc/4243/cgroup"
    printf '0::/user.slice/user-1000.slice/session-2.scope\n' > "$fp/proc/4244/cgroup"
    det=$(AIENOS_PROC_ROOT=$fp aien detect 2>&1)
    printf '%s\n' "$det" > "$H/managed-refused.out"
    grep -q "a systemd service: I will not stop it" "$H/managed-refused.out" \
        && grep -q "runs in a container: I will not stop it from here" "$H/managed-refused.out" \
        && [ "$(grep -c "I can run this model on my engine" "$H/managed-refused.out")" = 1 ]
    verdict managed-refused $?

    # 4. A bad Hugging Face token checked against huggingface.co, then the tiny real repo download.
    fresh
    if curl -fsS -o /dev/null --max-time 20 https://huggingface.co/api/models/hf-internal-testing/tiny-random-gpt2; then
        out=$(wiz '\n2\n\n\nyes\n\n\nhf_aienosInvalidTestToken000000000000\n\n\n\n\n\n\n' 2>&1); rc=$?
        printf '%s\n' "$out" > "$H/hf-bad-token.out"
        [ $rc -eq 0 ] && grep -q "Hugging Face refused that token (HTTP 401). Nothing was stored." "$H/hf-bad-token.out" \
            && [ ! -e "$A/keys/hf.header" ] && [ ! -e "$A/keys/hf.header.new" ] \
            && ! grep -q hf_aienosInvalidTestToken "$H/hf-bad-token.out"
        verdict hf-bad-token $?
        g=$A/models/tiny-random-gpt2-71034c5d
        cp "$H/hf-bad-token.out" "$H/hf-tiny-download.out"
        grep -q "Every model file is downloaded and matches its SHA-256." "$H/hf-tiny-download.out" \
            && [ -f "$g/.aienos-verified" ] \
            && (cd "$g" && tail -n +5 /t/tiny-gpt2.manifest | awk '{ print $1 "  " $3 }' | sha256sum -c --quiet) \
            && grep -q 'Hello from the fake engine' "$H/hf-tiny-download.out"
        verdict hf-tiny-download $?
    else
        nr hf-bad-token "huggingface.co not reachable from the container"
        nr hf-tiny-download "huggingface.co not reachable from the container"
    fi

    # 5. A good token (mock whoami): stored 0600 in a 0700 folder, then used for the download.
    fresh
    : > "$H/files.log"
    out=$(printf '%b' '\n\n\n\nyes\n\n\nhf_aienosTestGoodToken\n\n\n\n\n\n' | env AIENOS_PROBE_ROOT=/s/root-gb10 \
        AIENOS_HF_API=http://127.0.0.1:18735 timeout 300 "$A/current/bin/aienos" wizard --plain 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/hf-good-token.out"
    [ $rc -eq 0 ] && [ "$(mode "$A/keys")" = 700 ] && [ "$(mode "$A/keys/hf.header")" = 600 ] \
        && [ "$(cat "$A/keys/hf.header")" = "Authorization: Bearer hf_aienosTestGoodToken" ] \
        && [ ! -e "$A/keys/hf.header.new" ] && ! grep -q hf_aienosTestGoodToken "$H/hf-good-token.out" \
        && grep -q "Every model file is downloaded and matches its SHA-256." "$H/hf-good-token.out"
    verdict hf-good-token $?

    # 6. A partial download is resumed with a byte range, not started again.
    fresh
    : > "$H/files.log"
    mkdir -p "$m"
    half=$(( $(wc -c < /s/www/model/weights.bin) / 2 ))
    head -c "$half" /s/www/model/weights.bin > "$m/weights.bin.part"
    out=$(wiz '\n\n\n\nyes\n\n\n\n\n\n\n\n\n' 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/partial-resume.out"
    cp "$H/files.log" "$H/partial-resume.files.log"
    [ $rc -eq 0 ] && grep -q "GET /model/weights.bin range=bytes=$half-" "$H/files.log" \
        && cmp -s "$m/weights.bin" /s/www/model/weights.bin && [ ! -e "$m/weights.bin.part" ] \
        && [ -f "$m/.aienos-verified" ]
    verdict partial-resume $?

    # 7. A tampered local copy (same size, one byte changed): linked, refused by its hash, the
    #    good file downloaded instead, and the user's copy left exactly as it was.
    fresh
    mkdir -p "$H/models/tiny-test"
    cp /s/www/model/config.json /s/www/model/weights.bin "$H/models/tiny-test/"
    printf 'X' | dd of="$H/models/tiny-test/weights.bin" bs=1 seek=1000 conv=notrunc 2>/dev/null
    bad=$(sha256sum "$H/models/tiny-test/weights.bin" | cut -d' ' -f1)
    : > "$H/files.log"
    out=$(wiz '\n\n\n\nyes\n\n\n\n\n\n\n\n\n' 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/tampered-local.out"
    [ $rc -eq 0 ] && grep -q "Found 2 of 2 files of Tiny test model" "$H/tampered-local.out" \
        && [ -f "$m/weights.bin" ] && [ ! -L "$m/weights.bin" ] && cmp -s "$m/weights.bin" /s/www/model/weights.bin \
        && [ -L "$m/config.json" ] && grep -q "GET /model/weights.bin" "$H/files.log" \
        && ! grep -q "GET /model/config.json" "$H/files.log" \
        && [ "$(sha256sum "$H/models/tiny-test/weights.bin" | cut -d' ' -f1)" = "$bad" ]
    verdict tampered-local $?

    # 7b. A good local copy under ~/models/MANIFEST-NAME (here test-model, not the repo name
    #     tiny-test): found, linked, verified, nothing downloaded.
    fresh
    mkdir -p "$H/models/test-model"
    cp /s/www/model/config.json /s/www/model/weights.bin "$H/models/test-model/"
    : > "$H/files.log"
    out=$(wiz '\n\n\n\nyes\n\n\n\n\n\n\n\n\n' 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/manifest-name-local.out"
    [ $rc -eq 0 ] && grep -q "Found 2 of 2 files of Tiny test model" "$H/manifest-name-local.out" \
        && [ -L "$m/weights.bin" ] && [ -L "$m/config.json" ] && [ -f "$m/.aienos-verified" ] \
        && ! grep -q "GET /model/" "$H/files.log"
    verdict manifest-name-local $?

    # 8. The engine's port is already taken: the running server is not stopped or recorded.
    fresh
    startv 8000 "$H/weights/tiny-test" test-org/tiny-test; v3=$vp
    python3 -c 'import socket, time
s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(("127.0.0.1", 18100)); s.listen(1); time.sleep(600)' & occ=$!
    sleep 0.5
    out=$(wiz '\nyes\n\n\nyes\n\n\n\n\n\n' 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/occupied-port.out"
    grep -q "Port 18100 is already in use by another service" "$H/occupied-port.out" \
        && alive "$v3" && [ ! -e "$A/restore" ] && curl -fs -o /dev/null http://127.0.0.1:8000/v1/models
    verdict occupied-port $?
    kill "$occ" 2>/dev/null

    # 9. The engine fails to start after the swap: the server is put back by itself.
    fresh
    # A test release whose engine exits at once (SHA256SUMS rewritten, so the install step passes).
    printf '#!/bin/sh\necho "engine failure for the test" >&2\nexit 1\n' > "$A/current/bin/aien-serve-http"
    (cd "$A/current" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)
    out=$(wiz '\nyes\n\n\nyes\n\n\n\n\n\n' 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/swap-fail-restores.out"
    v4=$(ps -o pid= -C python3 | while read -r p; do
        tr '\0' ' ' < "/proc/$p/cmdline" | grep -q "bin/vllm serve .* --port 8000 " && echo "$p"; done | head -n 1)
    grep -q "I am putting your server back now." "$H/swap-fail-restores.out" \
        && grep -q "is back on port 8000" "$H/swap-fail-restores.out" \
        && ! alive "$v3" && [ -n "$v4" ] && snap "$v4" "$H/back2" \
        && cmp -s "$H/orig.cmdline" "$H/back2.cmdline" && cmp -s "$H/orig.environ" "$H/back2.environ" \
        && [ ! -e "$A/restore" ]
    verdict swap-fail-restores $?
    [ -n "$v4" ] && kill "$v4" 2>/dev/null

    # 10. A machine that is not arm64: the wizard's doctor refuses and changes nothing.
    fresh
    cp -a /s/root-gb10 "$H/root-x86"
    printf 'x86_64\n' > "$H/root-x86/proc/sys/kernel/arch"
    out=$(wiz '\n\n\n\nyes\n\n\n\n' "$H/root-x86" 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/wrong-arch.out"
    grep -q "This alpha runs on Linux arm64 with an NVIDIA GB10 (DGX Spark) only." "$H/wrong-arch.out" \
        && [ ! -e "$A/models" ]
    verdict wrong-arch $?

    # 11. aienos models lists the registry with each status.
    out=$(aien models 2>&1); rc=$?
    printf '%s\n' "$out" > "$H/models-command.out"
    [ $rc -eq 0 ] && grep -q "Tiny test model" "$H/models-command.out" \
        && grep -q "tiny-random-gpt2" "$H/models-command.out"
    verdict models-command $?

    aien stop > /dev/null 2>&1
    mkdir -p /tmp/receipt && cp "$H"/*.out "$H"/*.log /tmp/receipt/ 2>/dev/null
    printf 'AIENOS-ONBOARDING pass=%s fail=%s not_run=%s\n' "$pass" "$fail" "$notrun"
    [ "$fail" -eq 0 ] && [ "$notrun" -eq 0 ]
    exit $?
fi

# ---------------- on the host: fixtures, the image, one container ----------------
: "${OMC:?set OMC to the pinned omc}" "${STAGE:?set STAGE}"
out=${1:?usage: onboarding.sh RECEIPT_DIR}
mkdir -p "$out"
out=$(cd "$out" && pwd)
S=$(mktemp -d "${TMPDIR:-/tmp}/aienos-onb.XXXXXX")
trap 'rm -rf "$S"' EXIT INT TERM
"$OMC" < "$here/fake-engine.om" > "$S/fake-engine" 2> "$S/fake-engine.err" || { cat "$S/fake-engine.err"; exit 2; }
chmod +x "$S/fake-engine"
mkdir -p "$S/www/model"
head -c 2000000 /dev/urandom > "$S/www/model/weights.bin"
printf '{"model_type":"test"}\n' > "$S/www/model/config.json"
tb=$S/tstage
cp -a "$STAGE" "$tb"
install -m 755 "$S/fake-engine" "$tb/bin/aien-serve-http"
{
    printf 'name test-model\nurl http://127.0.0.1:18734/model/\n'
    printf 'bytes %s\nfiles 2\n' "$(cat "$S/www/model/weights.bin" "$S/www/model/config.json" | wc -c | tr -d ' ')"
    for f in config.json weights.bin; do
        printf '%s %s %s\n' "$(sha256sum "$S/www/model/$f" | cut -d' ' -f1)" "$(wc -c < "$S/www/model/$f" | tr -d ' ')" "$f"
    done
} > "$tb/share/aienos/model.manifest"
cp "$here/tiny-gpt2.manifest" "$tb/share/aienos/model-gpt2.manifest"
cat > "$tb/share/aienos/models.registry" <<'EOF'
model tiny-test
title Tiny test model (2 MB)
repo test-org/tiny-test
manifest model.manifest
engine bin/aien-serve-http
args --engine omega --max-context 4096
memkb 1000000
status test entry, served by the fake engine.
end
model tiny-random-gpt2
title tiny-random-gpt2 (0.5 MB, from huggingface.co)
repo hf-internal-testing/tiny-random-gpt2
manifest model-gpt2.manifest
engine bin/aien-serve-http
args --engine omega --max-context 4096
memkb 1000000
status test entry, downloaded from huggingface.co at a pinned revision.
end
EOF
(cd "$tb" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)
sh "$here/fake-root.sh" "$S/root-gb10" gb10
chmod -R a+rX "$S"

IMG=ubuntu:24.04
BASE=aienos-onboard-base:$TAG
docker pull -q "$IMG" > /dev/null
{
    printf 'image %s\n' "$(docker image inspect "$IMG" --format '{{index .RepoDigests 0}} {{.Architecture}}')"
    printf 'host %s, docker %s\n' "$(uname -srm)" "$(docker version --format '{{.Server.Version}}')"
    printf 'stage %s, omc %s\n' "$STAGE" "$(sha256sum "$OMC" | cut -d' ' -f1)"
} > "$out/receipt.txt"
if ! docker image inspect "$BASE" > /dev/null 2>&1; then
    cid=$(docker run -d "$IMG" sh -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl openssl ca-certificates python3 procps > /dev/null && useradd -m tester')
    docker wait "$cid" > /dev/null
    docker commit "$cid" "$BASE" > /dev/null || { echo "docker commit failed"; exit 2; }
    docker rm "$cid" > /dev/null
fi
printf 'base image %s = %s + curl openssl ca-certificates python3 procps + user tester\n' "$BASE" "$IMG" >> "$out/receipt.txt"
c=$(docker create -u tester -e HOME=/home/tester -w /home/tester \
    -v "$S:/s:ro" -v "$here:/t:ro" "$BASE" sh /t/onboarding.sh --inside)
docker inspect "$c" --format 'container network mode {{.HostConfig.NetworkMode}}, pid mode "{{.HostConfig.PidMode}}"' >> "$out/receipt.txt"
docker start -a "$c" > "$out/run.log" 2>&1
rc=$(docker inspect "$c" --format '{{.State.ExitCode}}')
docker cp "$c:/tmp/receipt" "$out/files" > /dev/null 2>&1
docker rm "$c" > /dev/null
cat "$out/run.log" >> "$out/receipt.txt"
cat "$out/run.log"
exit "$rc"
