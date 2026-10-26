#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Container test of the bootstrap: a stock ubuntu:24.04 arm64 image (plus curl, openssl and
# ca-certificates, which DGX OS ships), an unprivileged user, the signed release served from the
# host, and `docker diff` to list every path the run changed in the container's filesystem.
#
#   DIST=/path/to/out/dist sh tests/container.sh RECEIPT_DIR
#
# Cases (each in a fresh container, as user "tester", HOME=/home/tester):
#   install-fake-gb10   fake GB10 tree: installs; aienos verify; aienos uninstall --yes
#   install-real-sysfs  no fake tree: the host's real sysfs shows the GB10, so it installs; the
#                       container has no /dev/nvidia* nodes, so the wizard's doctor refuses
#   refuse-darwin       fake uname Darwin: friendly line, exit 0, nothing written
#   refuse-nogpu        fake tree without NVIDIA: friendly line, exit 0, nothing written
#   tampered            one byte of the bundle changed: exit 1, nothing installed
#   canary              negative control of the detector: a run that writes /usr/local/canary
# Pass rule: every changed path is under /home/tester (docker's /fake mount points aside), and
# the canary's /usr/local/canary must be seen.
set -u
: "${DIST:?set DIST to the signed release folder}"
out=${1:?usage: container.sh RECEIPT_DIR}
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$out"
out=$(cd "$out" && pwd)
S=$(mktemp -d "${TMPDIR:-/tmp}/aienos-ctr.XXXXXX")
PORT=${AIENOS_TEST_PORT:-18734}
TAG=alpha-20261026.2
BUNDLE=aienos-$TAG-linux-arm64.tar.gz
IMG=ubuntu:24.04
BASE=aienos-test-base:$TAG
pass=0
fail=0
log() { printf '%s\n' "$*" | tee -a "$out/receipt.txt"; }

: > "$out/receipt.txt"
mkdir -p "$S/www/real" "$S/www/tamper" "$S/bin-darwin"
cp "$DIST"/* "$S/www/real/"
cp "$DIST"/* "$S/www/tamper/"
python3 - "$S/www/tamper/$BUNDLE" <<'EOF'
import sys
p = sys.argv[1]
b = bytearray(open(p, "rb").read())
b[len(b) // 2] ^= 1
open(p, "wb").write(bytes(b))
EOF
for k in gb10 nogpu; do sh "$here/fake-root.sh" "$S/root-$k" "$k"; done
# Inside the container the fake device nodes point at the container's own /dev/null.
printf '#!/bin/sh\ncase "$1" in -s) echo Darwin ;; -m) echo arm64 ;; esac\n' > "$S/bin-darwin/uname"
chmod +x "$S/bin-darwin/uname"
# The unprivileged tester in the container must be able to read the fake trees.
chmod -R a+rX "$S"
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$S/www" > "$S/http.log" 2>&1 &
srv=$!
trap 'kill $srv 2>/dev/null; rm -rf "$S"' EXIT INT TERM
sleep 1

docker pull -q "$IMG" > /dev/null
log "image $IMG $(docker image inspect "$IMG" --format '{{index .RepoDigests 0}} {{.Architecture}}')"
log "host $(uname -srm), docker $(docker version --format '{{.Server.Version}}')"
log "dist SHA256SUMS sha256 $(sha256sum "$DIST/SHA256SUMS" | cut -d' ' -f1)"
cid=$(docker run -d "$IMG" sh -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl openssl ca-certificates > /dev/null && useradd -m tester')
docker wait "$cid" > /dev/null
docker commit "$cid" "$BASE" > /dev/null || { echo "docker commit failed"; exit 2; }
docker rm "$cid" > /dev/null
log "base image $BASE = $IMG + curl openssl ca-certificates + user tester"

# run NAME EXPECT_RC SCRIPT: one fresh container; records exit status and docker diff.
run() {
    name=$1 want=$2 script=$3
    c=$(docker create --network host -u tester -e HOME=/home/tester -w /home/tester \
        -v "$S/root-gb10:/fake/gb10:ro" -v "$S/root-nogpu:/fake/nogpu:ro" \
        -v "$S/bin-darwin:/fake/bin-darwin:ro" "$BASE" sh -c "$script")
    docker start -a "$c" > "$out/$name.log" 2>&1
    rc=$(docker inspect "$c" --format '{{.State.ExitCode}}')
    docker diff "$c" > "$out/$name.diff"
    docker rm "$c" > /dev/null
    # /fake and below are docker's mount points for the read-only fixtures, not writes by the run.
    outside=$(awk '{ print $2 }' "$out/$name.diff" | grep -v '^/home/tester\(/\|$\)' | grep -v '^/home$' \
        | grep -v '^/fake\(/\|$\)' || true)
    printf '%s\n' "$outside" > "$out/$name.outside"
    verdict=PASS
    [ "$rc" = "$want" ] || verdict=FAIL
    [ -z "$outside" ] || verdict=FAIL
    if [ "$verdict" = PASS ]; then pass=$((pass + 1)); else fail=$((fail + 1)); fi
    log "$verdict $name rc=$rc want=$want changed=$(wc -l < "$out/$name.diff" | tr -d ' ') outside_home=$( [ -z "$outside" ] && echo 0 || printf '%s\n' "$outside" | wc -l | tr -d ' ')"
}

URL=http://127.0.0.1:$PORT
run install-fake-gb10 0 "set -e
curl -fsSL $URL/real/install.sh | AIENOS_PROBE_ROOT=/fake/gb10 AIENOS_BASE_URL=$URL/real AIENOS_NO_WIZARD=1 sh
AIENOS_PROBE_ROOT=/fake/gb10 ~/.local/bin/aienos doctor || true
~/.local/bin/aienos verify
~/.local/share/aienos/current/bin/aienos uninstall --yes
echo LEFT; find ~ -type f -o -type l"
run install-real-sysfs 0 "set -e
curl -fsSL $URL/real/install.sh | AIENOS_BASE_URL=$URL/real AIENOS_NO_WIZARD=1 sh
printf '\n\n\n' | ~/.local/bin/aienos wizard --plain
ls ~/.local/share/aienos"
run refuse-darwin 0 "curl -fsSL $URL/real/install.sh | PATH=/fake/bin-darwin:\$PATH AIENOS_BASE_URL=$URL/real AIENOS_NO_WIZARD=1 sh"
run refuse-nogpu 0 "curl -fsSL $URL/real/install.sh | AIENOS_PROBE_ROOT=/fake/nogpu AIENOS_BASE_URL=$URL/real AIENOS_NO_WIZARD=1 sh"
run tampered 1 "curl -fsSL $URL/tamper/install.sh | AIENOS_PROBE_ROOT=/fake/gb10 AIENOS_BASE_URL=$URL/tamper AIENOS_NO_WIZARD=1 sh"
c=$(docker create -u root "$BASE" sh -c 'touch /usr/local/canary')
docker start -a "$c" > "$out/canary.log" 2>&1
docker diff "$c" > "$out/canary.diff"
docker rm "$c" > /dev/null
outside=$(awk '{ print $2 }' "$out/canary.diff" | grep -v '^/home/tester\(/\|$\)' | grep -v '^/home$' || true)
if printf '%s\n' "$outside" | grep -q '^/usr/local/canary$'; then
    pass=$((pass + 1)); log "PASS canary (the detector sees a write outside HOME: $(printf '%s' "$outside" | tr '\n' ' '))"
else
    fail=$((fail + 1)); log "FAIL canary (the detector missed /usr/local/canary)"
fi
docker image rm "$BASE" > /dev/null
log "AIENOS-CONTAINER pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
