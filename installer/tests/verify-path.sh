#!/bin/bash
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# The installer's verification path as a gate: installer/install.sh steps 3 and 4 (the Ed25519
# signature over SHA256SUMS, the bundle's SHA-256 in that signed list, the unsafe-path refusal and
# the per-file sha256sum -c inside the bundle), run against a throwaway test release.
#
#   bash installer/tests/verify-path.sh [SCRATCH]
#
# The release under test is built here: a tiny bundle (a stub bin/aienos, the icon and the menu
# template) signed with an Ed25519 key generated for this run inside SCRATCH. It is a test-only
# key: it is never written into the repository and it signs nothing but this run's fixtures.
#
# The installer under test is installer/install.sh itself. The only change is its release key
# constant (RELEASE_PUB_HEX and RELEASE_PUB_PEM), replaced with the test key by an awk rewrite
# like the one tests/run.sh uses; case key-swap-only checks that nothing else changed. The
# release is served over http://127.0.0.1 (python3 -m http.server) and the installer runs once
# per case with a fake GB10 tree (tests/fake-root.sh) as AIENOS_PROBE_ROOT.
#
# Every refusal case checks the exit status, the installer's exact reason, and that nothing was
# installed. The self-check cases run refusal cases against copies of install.sh with one check
# removed and require this script to notice, so a gate that cannot fail is itself a failure.
# Prints "PASS name" or "FAIL name: why" per case, then "VERIFY-PATH pass=N fail=N expected=N";
# exit 0 only when every expected case ran and passed. A crash exits 2.
# Nothing here uses sudo, a GPU, the network beyond 127.0.0.1, or a path outside SCRATCH.
set -Eeuo pipefail
trap 'echo "VERIFY-PATH crashed: line $LINENO exit $?"; exit 2' ERR

here=$(cd "$(dirname "$0")" && pwd)
top=$(cd "$here/.." && pwd)
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-verify-path.XXXXXX")}
mkdir -p "$S"
S=$(cd "$S" && pwd)
rm -rf "$S/www" "$S/home" "$S/out" "$S/tmp" "$S/stage" "$S/shim"
mkdir -p "$S/www" "$S/home" "$S/out" "$S/tmp" "$S/shim"
EXPECTED=14
TAG=$(sed -n 's/^TAG=//p' "$top/install.sh")
BUNDLE=aienos-$TAG-linux-arm64.tar.gz
[ -n "$TAG" ] || { echo "VERIFY-PATH crashed: no TAG= in install.sh"; exit 2; }

pass=0
fail=0
ok() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail + 1)); printf 'FAIL %s: %s\n' "$1" "$2"; }
verdict() { if [ -z "$why" ]; then ok "$1"; else no "$1" "$why"; fi; }

# ---- the test key and the installer under test ----
openssl genpkey -algorithm ed25519 -out "$S/test.key" 2>/dev/null
openssl pkey -in "$S/test.key" -pubout -out "$S/test.pub.pem"
openssl genpkey -algorithm ed25519 -out "$S/other.key" 2>/dev/null
testhex=$(openssl pkey -pubin -in "$S/test.pub.pem" -outform DER | tail -c 32 | od -An -tx1 | tr -d ' \n')
awk -v pem="$S/test.pub.pem" -v hex="$testhex" '
    /^RELEASE_PUB_HEX=/ { print "RELEASE_PUB_HEX=" hex; next }
    /^RELEASE_PUB_PEM=/ { while ((getline l < pem) > 0) { out = out (out == "" ? "" : "\n") l }
                          print "RELEASE_PUB_PEM='"'"'" out "'"'"'"; skip = 1; next }
    skip && /^-----END PUBLIC KEY-----/ { skip = 0; next }
    skip { next }
    { print }' "$top/install.sh" > "$S/install.sh"
# Both copies with the key constant cut out; they must be byte-identical.
nokey() {
    awk '/^RELEASE_PUB_HEX=/ { next }
         /^RELEASE_PUB_PEM=/ { skip = 1; next }
         skip && /^-----END PUBLIC KEY-----/ { skip = 0; next }
         skip { next }
         { print }' "$1"
}

# install.sh's own platform gate wants Linux on aarch64 (the GitHub runner is one). On any other
# host a uname shim answers for the installer only; nothing else is changed.
ipath=$PATH
if [ "$(uname -s)" != Linux ] || [ "$(uname -m)" != aarch64 ]; then
    printf '#!/bin/sh\ncase "$1" in -s) echo Linux ;; -m) echo aarch64 ;; esac\n' > "$S/shim/uname"
    chmod +x "$S/shim/uname"
    ipath=$S/shim:$PATH
    echo "note: host is $(uname -s) $(uname -m); the installer sees a uname shim (Linux aarch64)"
fi
sh "$here/fake-root.sh" "$S/root-gb10" gb10

# ---- fixtures ----
sums() { (cd "$1" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS); }
stage() { # dir: a minimal release tree with its SHA256SUMS
    rm -rf "$1"
    mkdir -p "$1/bin" "$1/share/aienos"
    printf '#!/bin/sh\necho "verify-path test stub, not AienOS"\n' > "$1/bin/aienos"
    chmod 755 "$1/bin/aienos"
    cp "$top/share/aienos.svg" "$top/share/aienos.desktop.in" "$1/share/aienos/"
    printf 'TEST-ONLY bundle from installer/tests/verify-path.sh, signed with a throwaway key\n' > "$1/VERSION"
    sums "$1"
}
outer() { # dist-dir key: the release's SHA256SUMS over the bundle and install.sh, signed
    (cd "$1" && sha256sum "$BUNDLE" install.sh > SHA256SUMS)
    sign "$1" "$2"
}
sign() { (cd "$1" && openssl pkeyutl -sign -inkey "$2" -rawin -in SHA256SUMS -out SHA256SUMS.sig); }
flip() { # file: change one byte in the middle
    python3 - "$1" <<'EOF'
import sys
p = sys.argv[1]
b = bytearray(open(p, "rb").read())
b[len(b) // 2] ^= 1
open(p, "wb").write(bytes(b))
EOF
}
dist() { # name: a release folder served at /name, starting from the good one
    rm -rf "$S/www/$1"; cp -a "$S/www/good" "$S/www/$1"
}

mkdir -p "$S/www/good"
stage "$S/stage"
(cd "$S/stage" && tar -czf "$S/www/good/$BUNDLE" .)
cp "$S/install.sh" "$S/www/good/install.sh"
outer "$S/www/good" "$S/test.key"
goodsum=$(sha256sum "$S/www/good/$BUNDLE" | cut -d' ' -f1)

# Signed by another key.
dist bad-signature-other-key; sign "$S/www/bad-signature-other-key" "$S/other.key"
# The right key's signature with one byte changed.
dist bad-signature-corrupted; flip "$S/www/bad-signature-corrupted/SHA256SUMS.sig"
# Bundle changed and SHA256SUMS rewritten to match it, signature left as it was.
dist rewritten-sums-unsigned; flip "$S/www/rewritten-sums-unsigned/$BUNDLE"
(cd "$S/www/rewritten-sums-unsigned" && sha256sum "$BUNDLE" install.sh > SHA256SUMS)
# Bundle changed, SHA256SUMS and signature left as released.
dist tampered-bundle; flip "$S/www/tampered-bundle/$BUNDLE"
badsum=$(sha256sum "$S/www/tampered-bundle/$BUNDLE" | cut -d' ' -f1)
# A correctly signed SHA256SUMS that does not list the bundle.
dist bundle-not-in-signed-list
(cd "$S/www/bundle-not-in-signed-list" && sha256sum install.sh > SHA256SUMS)
sign "$S/www/bundle-not-in-signed-list" "$S/test.key"
# A correctly signed bundle with a "../" member.
dist unsafe-path-in-bundle
python3 - "$S/stage" "$S/www/unsafe-path-in-bundle/$BUNDLE" <<'EOF'
import io, sys, tarfile
src, out = sys.argv[1], sys.argv[2]
with tarfile.open(out, "w:gz") as t:
    t.add(src, arcname=".")
    data = b"written outside the release folder\n"
    info = tarfile.TarInfo("../escape.txt")
    info.size = len(data)
    t.addfile(info, io.BytesIO(data))
EOF
outer "$S/www/unsafe-path-in-bundle" "$S/test.key"
# A file inside the bundle changed after the bundle's SHA256SUMS was written; the bundle itself
# is listed and signed correctly, so only the per-file check can refuse it.
dist tampered-file-inside-bundle
cp -a "$S/stage" "$S/stage-tampered"
printf 'echo changed after hashing\n' >> "$S/stage-tampered/bin/aienos"
(cd "$S/stage-tampered" && tar -czf "$S/www/tampered-file-inside-bundle/$BUNDLE" .)
outer "$S/www/tampered-file-inside-bundle" "$S/test.key"
# No signature file.
dist missing-signature; rm "$S/www/missing-signature/SHA256SUMS.sig"

# ---- the server ----
PORT=$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$S/www" > "$S/http.log" 2>&1 &
srv=$!
trap 'kill $srv 2>/dev/null || true' EXIT
i=0
until curl -fs "http://127.0.0.1:$PORT/good/SHA256SUMS" > /dev/null 2>&1; do
    i=$((i + 1)); [ $i -lt 100 ] || { echo "VERIFY-PATH crashed: http server did not start"; exit 2; }
    sleep 0.1
done

# ---- cases ----
n=0
run() { # served-name installer: sets rc, out, h
    n=$((n + 1))
    h=$S/home/$n-$1
    mkdir -p "$h/Desktop"
    rc=0
    out=$(env PATH="$ipath" HOME="$h" TMPDIR="$S/tmp" AIENOS_PROBE_ROOT="$S/root-gb10" \
        AIENOS_BASE_URL="http://127.0.0.1:$PORT/$1" AIENOS_NO_WIZARD=1 \
        sh "$2" < /dev/null 2>&1) || rc=$?
    printf '%s\nexit %s\n' "$out" "$rc" > "$S/out/$n-$1.txt"
}
nothing_installed() {
    [ ! -e "$h/.local/share/aienos/current" ] && [ ! -e "$h/.local/share/aienos/releases/$TAG" ] \
        && [ ! -e "$h/.local/share/aienos/releases/.$TAG.new" ] && [ ! -e "$h/.local/bin/aienos" ] \
        && [ ! -e "$h/.local/share/aienos/escape.txt" ]
}
refusal() { # served-name installer want-rc want-reason: sets why ("" when refused as expected)
    run "$1" "$2"
    why=
    [ "$rc" = "$3" ] || why="exit $rc, want $3"
    grep -qF -- "$4" <<< "$out" || why="${why:+$why; }reason missing: $4"
    nothing_installed || why="${why:+$why; }something was installed"
    return 0
}
SIG="The signature on SHA256SUMS does not match the AienOS release key."
FILE="A file inside the bundle does not match its SHA-256. Nothing was installed."
UNSAFE="The bundle contains an unsafe path. Nothing was installed."

why=
if ! cmp -s <(nokey "$top/install.sh") <(nokey "$S/install.sh"); then
    why="install.sh under test differs from installer/install.sh beyond the key constant"
elif ! grep -qx "RELEASE_PUB_HEX=$testhex" "$S/install.sh"; then
    why="the test key was not swapped in"
elif cmp -s "$top/install.sh" "$S/install.sh"; then
    why="the installer under test still carries the real release key"
fi
verdict key-swap-only

run good "$S/install.sh"
why=
[ "$rc" = 0 ] || why="exit $rc, want 0"
grep -qF "Signature and SHA-256 match (release key $testhex)." <<< "$out" || why="${why:+$why; }no signature match line for the test key"
grep -qF "Installed Sovereign Intelligence $TAG in $h/.local/share/aienos" <<< "$out" || why="${why:+$why; }no installed line"
[ "$("$h/.local/bin/aienos" 2>&1)" = "verify-path test stub, not AienOS" ] || why="${why:+$why; }installed command is not the test stub"
cmp -s "$h/.local/share/aienos/current/release.SHA256SUMS" "$S/www/good/SHA256SUMS" || why="${why:+$why; }release.SHA256SUMS not kept"
[ "$(cat "$h/.local/share/aienos/current/.bundle-sha256" 2>/dev/null)" = "$goodsum" ] || why="${why:+$why; }.bundle-sha256 is not the bundle's"
verdict good-release-installs

refusal bad-signature-other-key "$S/install.sh" 1 "$SIG"; verdict bad-signature-other-key
refusal bad-signature-corrupted "$S/install.sh" 1 "$SIG"; verdict bad-signature-corrupted
refusal rewritten-sums-unsigned "$S/install.sh" 1 "$SIG"; verdict rewritten-sums-unsigned
refusal tampered-bundle "$S/install.sh" 1 \
    "The download does not match its signed SHA-256 (expected $goodsum, got $badsum)."; verdict tampered-bundle
refusal bundle-not-in-signed-list "$S/install.sh" 1 \
    "The download does not match its signed SHA-256 (expected none, got $goodsum)."; verdict bundle-not-in-signed-list
refusal unsafe-path-in-bundle "$S/install.sh" 1 "$UNSAFE"; verdict unsafe-path-in-bundle
refusal tampered-file-inside-bundle "$S/install.sh" 1 "$FILE"; verdict tampered-file-inside-bundle
refusal missing-signature "$S/install.sh" 2 \
    "Could not download http://127.0.0.1:$PORT/missing-signature/SHA256SUMS.sig"; verdict missing-signature

# ---- self-check: with one check removed, the matching case must FAIL ----
mutant() { # name from to: a copy of the installer under test with one line's check disabled
    m=$S/install-$1.sh
    if ! grep -qF -- "$2" "$S/install.sh"; then
        why="mutation $1 did not apply: line not found in install.sh"; return 1
    fi
    F=$2 T=$3 awk 'index($0, ENVIRON["F"]) == 1 { $0 = ENVIRON["T"] } { print }' "$S/install.sh" > "$m"
    if cmp -s "$m" "$S/install.sh"; then why="mutation $1 changed nothing"; return 1; fi
    return 0
}
selfcheck() { # name case want-rc want-reason from to
    why=
    if mutant "$1" "$5" "$6"; then
        refusal "$2" "$m" "$3" "$4"
        if [ -z "$why" ]; then why="case $2 still passed with the $1 check removed"; else why=; fi
    fi
    verdict "selfcheck-$1-removed-is-caught"
}
selfcheck signature bad-signature-other-key 1 "$SIG" \
    'if ! openssl pkeyutl -verify -pubin -inkey "$tmp/release.pub.pem" -rawin \' \
    'if false && openssl pkeyutl -verify -pubin -inkey "$tmp/release.pub.pem" -rawin \'
selfcheck bundle-hash tampered-bundle 1 \
    "The download does not match its signed SHA-256 (expected $goodsum, got $badsum)." \
    'if [ -z "$want" ] || [ "$want" != "$have" ]; then' 'if false; then'
selfcheck unsafe-path unsafe-path-in-bundle 1 "$UNSAFE" \
    "if tar -tzf \"\$tmp/\$BUNDLE\" | grep -Eq '^/|(^|/)\\.\\.(/|\$)'; then" 'if false; then'
selfcheck per-file tampered-file-inside-bundle 1 "$FILE" \
    'if ! (cd "$stage" && sha256sum --quiet -c SHA256SUMS >/dev/null 2>&1); then' 'if false; then'

printf 'VERIFY-PATH pass=%s fail=%s expected=%s scratch=%s\n' "$pass" "$fail" "$EXPECTED" "$S"
[ "$fail" -eq 0 ] && [ "$pass" -eq "$EXPECTED" ]
