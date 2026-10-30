#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# The AienOS alpha test suite: the bootstrap, the Omega wizard and the uninstaller, against a
# fake hardware tree (AIENOS_PROBE_ROOT) and a local HTTP server. Nothing here opens a GPU device,
# uses sudo, or writes outside its own scratch folder.
#
#   OMC=/path/to/omc DIST=/path/to/out/dist STAGE=/path/to/out/stage sh tests/run.sh [SCRATCH]
#
# DIST and STAGE are build.sh's output (DIST signed with tools/sign.sh). OMC compiles the fake
# engine (tests/fake-engine.om). Prints one line per case, "PASS name" or "FAIL name: why", then
# "AIENOS-TESTS pass=N fail=N"; exit 0 only when every case passed.
set -u
here=$(cd "$(dirname "$0")" && pwd)
top=$(cd "$here/.." && pwd)
: "${OMC:?set OMC to the pinned omc}" "${DIST:?set DIST}" "${STAGE:?set STAGE}"
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-tests.XXXXXX")}
mkdir -p "$S"
S=$(cd "$S" && pwd)
TAG=alpha-20261029.1
BUNDLE=aienos-$TAG-linux-arm64.tar.gz
pass=0
fail=0
ok() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail + 1)); printf 'FAIL %s: %s\n' "$1" "$2"; }
verdict() { if [ "$2" -eq 0 ]; then ok "$1"; else no "$1" "condition false (see $S)"; fi; }

# ---- shared fixtures ----
PORT=${AIENOS_TEST_PORT:-18733}
mkdir -p "$S/www/real" "$S/www/test" "$S/www/model" "$S/bin-darwin" "$S/bin-x86"
cp "$DIST"/* "$S/www/real/"
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$S/www" > "$S/http.log" 2>&1 &
srv=$!
trap 'kill $srv 2>/dev/null; pkill -f "$S/" 2>/dev/null' EXIT INT TERM
i=0
while ! curl -fs "http://127.0.0.1:$PORT/" >/dev/null 2>&1; do
    i=$((i + 1)); [ $i -lt 50 ] || { echo "http server did not start"; exit 2; }; sleep 0.1
done
for k in gb10 gb10-busy nogpu othergpu olddrv; do sh "$here/fake-root.sh" "$S/root-$k" "$k"; done
printf '#!/bin/sh\ncase "$1" in -s) echo Darwin ;; -m) echo arm64 ;; esac\n' > "$S/bin-darwin/uname"
printf '#!/bin/sh\ncase "$1" in -s) echo Linux ;; -m) echo x86_64 ;; esac\n' > "$S/bin-x86/uname"
chmod +x "$S/bin-darwin/uname" "$S/bin-x86/uname"

newhome() { rm -rf "$S/home-$1"; mkdir -p "$S/home-$1/Desktop"; printf '%s' "$S/home-$1"; }
# Files and links under a home folder. GNOME's shared metadata store (.local/share/gvfs-metadata,
# written by gio when install.sh marks the desktop icon trusted) is not an AienOS file and is
# left out; uninstall removes the icon itself, and gvfsd drops entries of deleted files.
files() { (cd "$1" && find . \( -type f -o -type l \) ! -path './.local/share/gvfs-metadata/*' | LC_ALL=C sort); }
requests() { wc -l < "$S/http.log" | tr -d ' '; }

# install.sh with the real release key against the real, signed dist.
boot() { # home probe-root base-url [PATH prefix]
    env HOME="$1" AIENOS_PROBE_ROOT="$2" AIENOS_BASE_URL="$3" AIENOS_NO_WIZARD=1 \
        PATH="${4:+$4:}$PATH" sh "$S/www/real/install.sh"
}

# ---- A: the bootstrap with the real release ----
for k in darwin x86 nogpu othergpu olddrv; do
    h=$(newhome "a1-$k")
    before=$(requests)
    case $k in
        darwin) out=$(boot "$h" "$S/root-gb10" "http://127.0.0.1:$PORT/real" "$S/bin-darwin" 2>&1); rc=$? ;;
        x86) out=$(boot "$h" "$S/root-gb10" "http://127.0.0.1:$PORT/real" "$S/bin-x86" 2>&1); rc=$? ;;
        *) out=$(boot "$h" "$S/root-$k" "http://127.0.0.1:$PORT/real" 2>&1); rc=$? ;;
    esac
    printf '%s\n' "$out" > "$S/a1-$k.out"
    if [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "runs on Linux arm64 with an NVIDIA GB10 (DGX Spark) only" \
            && printf '%s' "$out" | grep -q "https://www.aienos.com/alpha/" \
            && [ -z "$(files "$h")" ] && [ "$(requests)" = "$before" ]; then
        ok "bootstrap-refuses-$k"
    else
        no "bootstrap-refuses-$k" "rc=$rc, files=$(files "$h" | wc -l), requests $before->$(requests)"
    fi
done

h=$(newhome a2)
out=$(boot "$h" "$S/root-gb10" "http://127.0.0.1:$PORT/real" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/a2.out"
base=$h/.local/share/aienos
[ $rc -eq 0 ] && [ -x "$base/current/bin/aienos" ] && [ -L "$h/.local/bin/aienos" ] \
    && [ -f "$h/.local/share/applications/aienos.desktop" ] && [ -f "$h/Desktop/aienos.desktop" ] \
    && [ -f "$base/installed-files" ]; verdict bootstrap-installs $?
grep -q "kernel driver 580.173.02" "$S/a2.out"; verdict bootstrap-reports-driver $?
grep -q "^Exec=\"$base/current/bin/aienos\" wizard\$" "$h/.local/share/applications/aienos.desktop"; verdict desktop-entry-points-at-wizard $?
out=$(env HOME="$h" AIENOS_PROBE_ROOT="$S/root-gb10" "$base/current/bin/aienos" verify 2>&1); rc=$?
[ $rc -eq 0 ] && printf '%s' "$out" | grep -q "files match SHA256SUMS"; verdict omega-verify-installed-release $?
snap1=$(files "$h"); sum1=$(cd "$base/current/" && cat bin/aienos | sha256sum)
out=$(boot "$h" "$S/root-gb10" "http://127.0.0.1:$PORT/real" 2>&1); rc=$?
[ $rc -eq 0 ] && printf '%s' "$out" | grep -q "already installed and intact" \
    && [ "$(files "$h")" = "$snap1" ] && [ "$(cd "$base/current/" && cat bin/aienos | sha256sum)" = "$sum1" ]; verdict bootstrap-idempotent $?

# Tampered bundle: one byte changed, SHA256SUMS and its signature left as released.
mkdir -p "$S/www/tamper" "$S/www/resign" "$S/www/nosig"
cp "$DIST"/* "$S/www/tamper/"
python3 - "$S/www/tamper/$BUNDLE" <<'EOF'
import sys
p = sys.argv[1]
b = bytearray(open(p, "rb").read())
b[len(b) // 2] ^= 1
open(p, "wb").write(bytes(b))
EOF
h=$(newhome a3)
out=$(boot "$h" "$S/root-gb10" "http://127.0.0.1:$PORT/tamper" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/a3.out"
[ $rc -eq 1 ] && printf '%s' "$out" | grep -q "does not match its signed SHA-256" \
    && [ ! -e "$h/.local/share/aienos/releases/$TAG" ] && [ ! -e "$h/.local/share/aienos/current" ] \
    && [ ! -e "$h/.local/bin/aienos" ]; verdict tampered-bundle-refused $?
# Tampered bundle with SHA256SUMS rewritten to match it: the signature no longer matches.
cp "$S/www/tamper"/* "$S/www/resign/"
(cd "$S/www/resign" && sha256sum "$BUNDLE" install.sh aienos.om release.pub release.pub.pem > SHA256SUMS)
h=$(newhome a4)
out=$(boot "$h" "$S/root-gb10" "http://127.0.0.1:$PORT/resign" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/a4.out"
[ $rc -eq 1 ] && printf '%s' "$out" | grep -q "signature on SHA256SUMS does not match" \
    && [ ! -e "$h/.local/share/aienos/current" ]; verdict rewritten-sums-refused $?
cp "$DIST"/* "$S/www/nosig/"; rm "$S/www/nosig/SHA256SUMS.sig"
h=$(newhome a5)
out=$(boot "$h" "$S/root-gb10" "http://127.0.0.1:$PORT/nosig" 2>&1); rc=$?
[ $rc -eq 2 ] && [ ! -e "$h/.local/share/aienos/current" ]; verdict missing-signature-refused $?

# Uninstall of the real install: no file or link of AienOS is left in the home folder.
h=$S/home-a2
out=$(env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" uninstall --yes 2>&1); rc=$?
printf '%s\n' "$out" > "$S/a6.out"
[ $rc -eq 0 ] && [ -z "$(files "$h")" ] && [ ! -e "$h/.local/share/aienos" ]; verdict uninstall-leaves-no-files $?

# ---- B: the wizard, with a test release (fake engine, small model, test key) ----
"$OMC" < "$here/fake-engine.om" > "$S/fake-engine" 2> "$S/fake-engine.err" || { cat "$S/fake-engine.err"; exit 2; }
chmod +x "$S/fake-engine"
head -c 5000000 /dev/urandom > "$S/www/model/weights.bin"
printf '{"model_type":"test"}\n' > "$S/www/model/config.json"
tb=$S/tstage
rm -rf "$tb"; cp -a "$STAGE" "$tb"
install -m 755 "$S/fake-engine" "$tb/bin/aien-serve-http"
{
    printf 'name test-model\nurl http://127.0.0.1:%s/model/\n' "$PORT"
    printf 'bytes %s\nfiles 2\n' "$(cat "$S/www/model/weights.bin" "$S/www/model/config.json" | wc -c | tr -d ' ')"
    for f in config.json weights.bin; do
        printf '%s %s %s\n' "$(sha256sum "$S/www/model/$f" | cut -d' ' -f1)" "$(wc -c < "$S/www/model/$f" | tr -d ' ')" "$f"
    done
} > "$tb/share/aienos/model.manifest"
(cd "$tb" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)
(cd "$tb" && tar -czf "$S/www/test/$BUNDLE" .)
openssl genpkey -algorithm ed25519 -out "$S/test.key" 2>/dev/null
openssl pkey -in "$S/test.key" -pubout -out "$S/test.pub.pem"
awk -v pem="$S/test.pub.pem" '
    /^RELEASE_PUB_PEM=/ { while ((getline l < pem) > 0) { out = out (out == "" ? "" : "\n") l }
                          print "RELEASE_PUB_PEM='"'"'" out "'"'"'"; skip = 1; next }
    skip && /^-----END PUBLIC KEY-----/ { skip = 0; next }
    skip { next }
    { print }' "$DIST/install.sh" > "$S/www/test/install.sh"
(cd "$S/www/test" && sha256sum "$BUNDLE" install.sh > SHA256SUMS \
    && openssl pkeyutl -sign -inkey "$S/test.key" -rawin -in SHA256SUMS -out SHA256SUMS.sig)
tboot() { env HOME="$1" AIENOS_PROBE_ROOT="$2" AIENOS_BASE_URL="http://127.0.0.1:$PORT/test" \
    AIENOS_NO_WIZARD=1 sh "$S/www/test/install.sh"; }
wiz() { # home probe-root input
    printf '%b' "$3" | env HOME="$1" AIENOS_PROBE_ROOT="$2" \
        timeout 300 "$1/.local/share/aienos/current/bin/aienos" wizard --plain
}
ALL='\n\n\nyes\n\n\n\n\n\n\n'

h=$(newhome b1)
tboot "$h" "$S/root-gb10" > "$S/b1-boot.out" 2>&1
out=$(wiz "$h" "$S/root-gb10" "$ALL" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/b1.out"
m=$h/.local/share/aienos/models/test-model
[ $rc -eq 0 ] && grep -q "Every model file is downloaded and matches its SHA-256" "$S/b1.out" \
    && cmp -s "$m/weights.bin" "$S/www/model/weights.bin" && [ -f "$m/.aienos-verified" ]; verdict wizard-happy-path $?
grep -q 'Hello from the fake engine, café "ok"' "$S/b1.out"; verdict wizard-first-chat $?
grep -q "CUDA libraries in the engine's memory map (/proc/[0-9]*/maps): 0" "$S/b1.out"; verdict wizard-zero-cuda-maps $?
out=$(env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" stop 2>&1); rc=$?
[ $rc -eq 0 ] && [ ! -e "$h/.local/share/aienos/engine.pid" ]; verdict engine-stops $?
out=$(printf 'second question\n/bye\n' | env HOME="$h" AIENOS_PROBE_ROOT="$S/root-gb10" \
    "$h/.local/share/aienos/current/bin/aienos" chat 2>&1); rc=$?
[ $rc -eq 0 ] && printf '%s' "$out" | grep -q "model> Hello from the fake engine"; verdict chat-command $?
env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" stop > /dev/null 2>&1
printf 'x' >> "$h/.local/share/aienos/current/share/aienos/wizard/hole.om"
out=$(env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" verify 2>&1); rc=$?
[ $rc -eq 1 ] && printf '%s' "$out" | grep -q "does not match"; verdict omega-verify-detects-change $?

# A model file served with different bytes: the hash check refuses it and nothing is kept.
h=$(newhome b2)
tboot "$h" "$S/root-gb10" > /dev/null 2>&1
cp "$S/www/model/weights.bin" "$S/weights.good"
printf 'X' | dd of="$S/www/model/weights.bin" bs=1 seek=1000 conv=notrunc 2>/dev/null
out=$(wiz "$h" "$S/root-gb10" "$ALL" 2>&1); rc=$?
cp "$S/weights.good" "$S/www/model/weights.bin"
printf '%s\n' "$out" > "$S/b2.out"
m=$h/.local/share/aienos/models/test-model
[ $rc -eq 1 ] && grep -q "hash check failed" "$S/b2.out" \
    && [ ! -e "$m/weights.bin" ] && [ ! -e "$m/weights.bin.part" ] && [ ! -e "$m/.aienos-verified" ]; verdict tampered-model-refused $?

h=$(newhome b3)
tboot "$h" "$S/root-nogpu" > "$S/b3-boot.out" 2>&1
[ -z "$(files "$h")" ]; verdict bootstrap-nogpu-installs-nothing $?
# The wizard's own doctor on a machine without a GB10 (bundle installed by hand from the test stage).
mkdir -p "$h/.local/share/aienos/releases"; cp -a "$tb" "$h/.local/share/aienos/releases/$TAG"
ln -s "releases/$TAG" "$h/.local/share/aienos/current"
for k in nogpu othergpu olddrv; do
    out=$(wiz "$h" "$S/root-$k" "$ALL" 2>&1); rc=$?
    printf '%s\n' "$out" > "$S/b3-$k.out"
    [ $rc -eq 0 ] && grep -q "This alpha runs on Linux arm64 with an NVIDIA GB10 (DGX Spark) only." "$S/b3-$k.out" \
        && [ ! -e "$h/.local/share/aienos/models" ]; verdict "wizard-refuses-$k" $?
    out=$(env HOME="$h" AIENOS_PROBE_ROOT="$S/root-$k" "$h/.local/share/aienos/current/bin/aienos" doctor 2>&1); rc=$?
    [ $rc -eq 1 ] && printf '%s' "$out" | grep -q '\[  no  \]'; verdict "doctor-says-no-$k" $?
done

h=$(newhome b4)
tboot "$h" "$S/root-gb10-busy" > /dev/null 2>&1
out=$(wiz "$h" "$S/root-gb10-busy" "$ALL" 2>&1); rc=$?
printf '%s\n' "$out" > "$S/b4.out"
[ $rc -eq 0 ] && grep -q "I am not starting the engine now" "$S/b4.out" \
    && [ ! -e "$h/.local/share/aienos/engine.pid" ]; verdict busy-gpu-starts-no-engine $?

# Rollback to an older release folder, then uninstall keeping the model, then everything.
h=$S/home-b1
cp -a "$h/.local/share/aienos/releases/$TAG" "$h/.local/share/aienos/releases/alpha-20261025.9"
out=$(env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" rollback 2>&1); rc=$?
[ $rc -eq 0 ] && [ "$(readlink "$h/.local/share/aienos/current")" = "releases/alpha-20261025.9" ]; verdict rollback $?
out=$(env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" uninstall --keep-model --yes 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$h/.local/share/aienos/models/test-model/weights.bin" ] \
    && [ "$(files "$h" | grep -cv '/models/')" = 0 ]; verdict uninstall-keep-model $?
out=$(printf 'no\n' | env HOME="$h" "$tb/bin/aienos" uninstall 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$h/.local/share/aienos/models/test-model/weights.bin" ]; verdict uninstall-asks-first $?
out=$(env HOME="$h" "$tb/bin/aienos" uninstall --yes 2>&1); rc=$?
[ $rc -eq 0 ] && [ -z "$(files "$h")" ] && [ ! -e "$h/.local/share/aienos" ]; verdict uninstall-everything $?

printf 'AIENOS-TESTS pass=%s fail=%s scratch=%s\n' "$pass" "$fail" "$S"
[ "$fail" -eq 0 ]
