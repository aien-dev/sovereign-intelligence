# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Shared fixtures for the failure-path scripts (sourced, not run). Host only: nothing here opens
# a GPU device, uses sudo, touches a system service or writes outside the scratch folder $S.
#
# A test release is built the way tests/run.sh section B builds one: the wizard compiled from
# wizard/*.om (build.sh ORDER) with the pinned omc, tests/fake-engine.om as bin/aien-serve-http,
# a 5 MB test model, a throwaway Ed25519 key, and install.sh with only RELEASE_PUB_PEM replaced
# by that key. It is served by python3 -m http.server on a free high 127.0.0.1 port.
#
# Needs: OMC (omc whose sha256 is build.sh's OMC_PIN; anything else is NOT_RUN, exit 3),
#        python3, openssl, curl, tar, sha256sum. S (scratch folder) is set by the caller.
# Script exit codes: 0 PASS, 1 FAIL, 3 NOT_RUN.

FP_HERE=$(cd "$(dirname "$0")" && pwd)
FP_TESTS=$(cd "$FP_HERE/.." && pwd)
FP_TOP=$(cd "$FP_TESTS/.." && pwd)
TAG=$(sed -n 's/^TAG=//p' "$FP_TOP/install.sh")
BUNDLE=aienos-$TAG-linux-arm64.tar.gz
ORDER=$(sed -n 's/^ORDER="\(.*\)"$/\1/p' "$FP_TOP/build.sh")
OMC_PIN=$(sed -n 's/^OMC_PIN=//p' "$FP_TOP/build.sh")

fp_notrun() { printf 'RESULT %s NOT_RUN %s\n' "$FP_NAME" "$*"; exit 3; }
fp_log() { printf '  %s\n' "$*"; }
# check NAME COND-EXIT: one observed condition; FP_BAD counts the false ones.
FP_BAD=0
check() {
    if [ "$2" -eq 0 ]; then fp_log "ok   $1"; else fp_log "BAD  $1"; FP_BAD=$((FP_BAD + 1)); fi
}

fp_require() {
    for t in python3 openssl curl tar sha256sum gzip; do
        command -v "$t" >/dev/null 2>&1 || fp_notrun "host tool $t missing"
    done
    [ -n "${OMC:-}" ] && [ -x "$OMC" ] || fp_notrun "OMC not set to the pinned omc"
    have=$(sha256sum "$OMC" | cut -d' ' -f1)
    [ "$have" = "$OMC_PIN" ] || fp_notrun "omc sha256 $have, want $OMC_PIN"
    mkdir -p "$S"
    S=$(cd "$S" && pwd)
}

# A free TCP port on 127.0.0.1, at least 20000, never one of the Spark's live services.
fp_port() {
    while :; do
        p=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1])')
        case $p in 18091|18100|18300) continue ;; esac
        [ "$p" -ge 20000 ] && { printf '%s' "$p"; return; }
    done
}

# Compile the wizard (optionally with PORT replaced, test builds only) and the fake engine.
# fp_compile OUTDIR [ENGINE-PORT]
fp_compile() {
    mkdir -p "$1"
    : > "$1/aienos.om"
    for f in $ORDER; do cat "$FP_TOP/wizard/$f" >> "$1/aienos.om"; done
    cp "$FP_TESTS/fake-engine.om" "$1/fake-engine.om"
    if [ -n "${2:-}" ]; then
        sed -i "s/^const PORT ulong 18100\$/const PORT ulong $2/" "$1/aienos.om"
        grep -q "^const PORT ulong $2\$" "$1/aienos.om" || return 1
        sed -i -e "s/^put addr 2 70\$/put addr 2 $(($2 / 256))/" \
            -e "s/^put addr 3 180\$/put addr 3 $(($2 % 256))/" "$1/fake-engine.om"
        grep -q "^put addr 3 $(($2 % 256))\$" "$1/fake-engine.om" || return 1
    fi
    "$OMC" < "$1/aienos.om" > "$1/aienos" 2> "$1/omc.err" && [ ! -s "$1/omc.err" ] || return 1
    "$OMC" < "$1/fake-engine.om" > "$1/aien-serve-http" 2>> "$1/omc.err" || return 1
    chmod +x "$1/aienos" "$1/aien-serve-http"
}

# The test signing key and the test model, once per scratch folder.
fp_key() {
    [ -f "$S/test.key" ] && return
    openssl genpkey -algorithm ed25519 -out "$S/test.key" 2>/dev/null
    openssl pkey -in "$S/test.key" -pubout -out "$S/test.pub.pem"
    mkdir -p "$S/www/model"
    head -c 5000000 /dev/urandom > "$S/www/model/weights.bin"
    printf '{"model_type":"test"}\n' > "$S/www/model/config.json"
}

# fp_release NAME BINDIR [PAD-BYTES]: www/NAME holds a signed test release whose bundle carries
# BINDIR's wizard and fake engine. PAD-BYTES adds share/aienos/test-padding.bin (zeros): a file
# much larger than the compressed bundle, for the disk-full path.
fp_release() {
    fp_key
    st=$S/stage-$1
    rm -rf "$st" "$S/www/$1"
    mkdir -p "$st/bin" "$st/share/aienos/wizard" "$S/www/$1"
    install -m 755 "$2/aienos" "$st/bin/aienos"
    install -m 755 "$2/aien-serve-http" "$st/bin/aien-serve-http"
    for f in $ORDER; do install -m 644 "$FP_TOP/wizard/$f" "$st/share/aienos/wizard/$f"; done
    install -m 644 "$2/aienos.om" "$st/share/aienos/aienos.om"
    install -m 644 "$FP_TOP/share/aienos.desktop.in" "$FP_TOP/share/aienos.svg" "$st/share/aienos/"
    {
        printf 'name test-model\nurl http://127.0.0.1:%s/model/\n' "$FP_HTTP"
        printf 'bytes %s\nfiles 2\n' "$(cat "$S/www/model/weights.bin" "$S/www/model/config.json" | wc -c | tr -d ' ')"
        for f in config.json weights.bin; do
            printf '%s %s %s\n' "$(sha256sum "$S/www/model/$f" | cut -d' ' -f1)" \
                "$(wc -c < "$S/www/model/$f" | tr -d ' ')" "$f"
        done
    } > "$st/share/aienos/model.manifest"
    [ -z "${3:-}" ] || head -c "$3" /dev/zero > "$st/share/aienos/test-padding.bin"
    (cd "$st" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)
    (cd "$st" && tar -czf "$S/www/$1/$BUNDLE" .)
    awk -v pem="$S/test.pub.pem" '
        /^RELEASE_PUB_PEM=/ { while ((getline l < pem) > 0) { out = out (out == "" ? "" : "\n") l }
                              print "RELEASE_PUB_PEM='"'"'" out "'"'"'"; skip = 1; next }
        skip && /^-----END PUBLIC KEY-----/ { skip = 0; next }
        skip { next }
        { print }' "$FP_TOP/install.sh" > "$S/www/$1/install.sh"
    (cd "$S/www/$1" && sha256sum "$BUNDLE" install.sh > SHA256SUMS \
        && openssl pkeyutl -sign -inkey "$S/test.key" -rawin -in SHA256SUMS -out SHA256SUMS.sig)
}

# The local release server on a free high port; stopped when the script exits.
fp_serve() {
    FP_HTTP=$(fp_port)
    mkdir -p "$S/www"
    python3 -m http.server "$FP_HTTP" --bind 127.0.0.1 --directory "$S/www" > "$S/http.log" 2>&1 &
    FP_SRV=$!
    i=0
    while ! curl -fs "http://127.0.0.1:$FP_HTTP/" >/dev/null 2>&1; do
        i=$((i + 1)); [ $i -lt 50 ] || fp_notrun "local http server did not start"; sleep 0.1
    done
}
fp_cleanup() {
    [ -z "${FP_SRV:-}" ] || kill "$FP_SRV" 2>/dev/null
    pkill -f "$S/home-" 2>/dev/null
    return 0
}
trap 'fp_cleanup' EXIT INT TERM

# A fake DGX Spark (tests/fake-root.sh) and an empty home folder with a Desktop.
fp_root() { [ -d "$S/root-$1" ] || sh "$FP_TESTS/fake-root.sh" "$S/root-$1" "$1"; printf '%s' "$S/root-$1"; }
fp_home() { rm -rf "$S/home-$1"; mkdir -p "$S/home-$1/Desktop"; printf '%s' "$S/home-$1"; }
# Every file and link under a home folder (gvfs metadata is GNOME's, not AienOS's).
fp_files() { (cd "$1" && find . \( -type f -o -type l \) ! -path './.local/share/gvfs-metadata/*' | LC_ALL=C sort); }

# A complete, verified install: what every failure path must either reach or leave untouched.
# fp_installed HOME -> 0 when current/bin/aienos verifies, the links exist and installed-files
# lists exactly the four paths install.sh writes outside its own folder.
fp_installed() {
    b=$1/.local/share/aienos
    [ -x "$b/current/bin/aienos" ] && [ -L "$1/.local/bin/aienos" ] \
        && [ -f "$1/.local/share/applications/aienos.desktop" ] && [ -f "$1/Desktop/aienos.desktop" ] \
        && [ -f "$b/installed-files" ] && [ "$(wc -l < "$b/installed-files")" -eq 4 ] \
        && [ ! -e "$b/installed-files.new" ] \
        && [ ! -e "$b/releases/.$TAG.new" ] \
        && env HOME="$1" "$b/current/bin/aienos" verify > "$S/verify.out" 2>&1 \
        && grep -q "files match SHA256SUMS" "$S/verify.out"
}

# fp_boot HOME RELEASE [ROOT]: the release's install.sh, as "curl ... | sh" runs it. With FP_KILL
# set, shim.sh (as curl, tar, mv, ln) interrupts it at that point with FP_SIG.
fp_boot() {
    sp=$PATH
    if [ -n "${FP_KILL:-}" ]; then
        mkdir -p "$S/shim"
        for t in curl tar mv ln; do ln -sf "$FP_HERE/shim.sh" "$S/shim/$t"; done
        sp=$S/shim:$PATH
    fi
    env HOME="$1" AIENOS_PROBE_ROOT="${3:-$(fp_root gb10)}" PATH="$sp" FP_REALPATH="$PATH" \
        AIENOS_BASE_URL="http://127.0.0.1:$FP_HTTP/$2" AIENOS_NO_WIZARD=1 TMPDIR="$S/tmp" \
        sh "$S/www/$2/install.sh"
}
# Nothing of AienOS in the home folder (the Desktop folder itself was there before).
fp_untouched() { [ -z "$(fp_files "$1")" ] && [ ! -e "$1/.local" ]; }

# fp_result: the closing line. LEVEL is EXERCISED(host...) text, CONTROL the negative control's
# observed verdict ("opposite" when it came out the other way, as it must).
fp_result() {
    if [ "$FP_BAD" -eq 0 ]; then
        printf 'RESULT %s PASS %s\n' "$FP_NAME" "$*"; exit 0
    fi
    printf 'RESULT %s FAIL %s bad=%s scratch=%s\n' "$FP_NAME" "$*" "$FP_BAD" "$S"; exit 1
}
mkdir -p "${S:?}/tmp" 2>/dev/null || true
