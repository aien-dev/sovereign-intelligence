#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Build the AienOS alpha bundle from pinned inputs. Linux arm64 only (omc writes arm64 ELF).
#
#   OMEGA_SRC=/path/to/omega-mv@3364a1dfd ENGINE=/path/to/aien-serve-http \
#   ENGINE27=/path/to/aien-serve-http-27b sh build.sh OUT
#
# OMEGA_SRC  a clone of aien-dev/omega-mv at OMEGA_REV: its seed/out/omc compiles the wizard
#            and its om/sha256/sha256-om2.om is the source wizard/sha256.om is derived from.
# ENGINE     aien-serve-http built from aien-dev/aien-sovereign-core-mv at CORE_REV (branch
#            ship/motor-l387) linking omega ship/motor-l387 libomega_gpu.a sha256 110295ef: the
#            live 35B server's build. Its bytes are pinned as ENGINE_SHA256 (this build has no
#            --version; its usage line from --help goes into VERSION).
# ENGINE27   the 27B's aien-serve-http from aien-dev/aien-sovereign-core-mv tag alpha/20261025.1
#            (CORE27_REV), the bytes of release alpha-20261025.1's bin/aien-serve-http, pinned as
#            ENGINE27_SHA256. It is installed as bin/aien-serve-http-27b (experimental, see
#            share/models.registry).
# OUT        output folder: OUT/stage (the bundle tree) and OUT/dist (the release assets).
#
# Exit: 2 missing input, 3 wrong pin, 4 derived source differs, 5 nondeterministic compile,
#       6 compile refused, 7 engine identity or linkage wrong. Signing is tools/sign.sh.
set -eu
cd "$(dirname "$0")"
TAG=alpha-20261026.3
OMEGA_REV=3364a1dfd0ca50c1b82bf19ba34932d8bc10a7a9
OMC_PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
CORE_REV=59b05a71a33e4a2f1324db2f2b6407ee82b8c2c3
ENGINE_SHA256=19173f9ec3b609fe79af644f84741d8808b92ea8eb3ecec4bc945af6f22b3aeb
CORE27_REV=cf239078d05a47d84353c1508a08663273f00c3e
ENGINE27_SHA256=80f04b676037272d6fee3809121d265d645414ec18f4e62b247b60b15628f70e
ORDER="sha256.om lib.om hole.om doctor.om net.om steps.om models.om engine.om detect.om main.om"
out=${1:?usage: build.sh OUT}
src=${OMEGA_SRC:?set OMEGA_SRC to an omega-mv clone at $OMEGA_REV}
engine27=${ENGINE27:?set ENGINE27 to the 27B aien-serve-http from Core $CORE27_REV}
engine=${ENGINE:?set ENGINE to aien-serve-http built from Core $CORE_REV}

fail() { code=$1; shift; printf 'build.sh: %s\n' "$*" >&2; exit "$code"; }

[ -d "$src/.git" ] || fail 2 "$src is not a git clone"
rev=$(git -C "$src" rev-parse HEAD)
[ "$rev" = "$OMEGA_REV" ] || fail 3 "omega-mv is at $rev, want $OMEGA_REV"
omc=$src/seed/out/omc
have=$(sha256sum "$omc" | cut -d' ' -f1)
[ "$have" = "$OMC_PIN" ] || fail 3 "omc sha256 $have, want $OMC_PIN"

# wizard/sha256.om is omega-mv's unit with "export fn" made "fn" (program mode refuses export).
shasrc=$src/om/sha256/sha256-om2.om
work=$(mktemp -d "${TMPDIR:-/tmp}/aienos-build.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
sed 's/^export fn /fn /' "$shasrc" > "$work/sha.body"
tail -n +6 wizard/sha256.om > "$work/sha.vendored"
cmp -s "$work/sha.body" "$work/sha.vendored" || fail 4 "wizard/sha256.om is not the derivation of $shasrc"
grep -q "source sha256 $(sha256sum "$shasrc" | cut -d' ' -f1)" wizard/sha256.om \
    || fail 4 "wizard/sha256.om header names a different source hash"

# One unit, compiled twice: the two binaries must be identical.
: > "$work/aienos.om"
for f in $ORDER; do cat "wizard/$f" >> "$work/aienos.om"; done
for n in 1 2; do
    if ! "$omc" < "$work/aienos.om" > "$work/aienos.$n" 2> "$work/omc.$n.err"; then
        cat "$work/omc.$n.err" >&2
        fail 6 "omc refused the wizard"
    fi
    [ ! -s "$work/omc.$n.err" ] || fail 6 "omc wrote to stderr: $(cat "$work/omc.$n.err")"
done
cmp -s "$work/aienos.1" "$work/aienos.2" || fail 5 "two compiles of the wizard differ"

# The engine: the pinned bytes, Core's commit embedded in them, and no CUDA library in NEEDED.
[ -x "$engine" ] || fail 2 "$engine is not executable"
have=$(sha256sum "$engine" | cut -d' ' -f1)
[ "$have" = "$ENGINE_SHA256" ] || fail 7 "$engine sha256 $have, want $ENGINE_SHA256"
grep -aq "$CORE_REV" "$engine" || fail 7 "$engine does not embed Core commit $CORE_REV"
"$engine" --help > "$work/engine.usage" 2>&1 || true
grep -q -- "--batch-slots N" "$work/engine.usage" || fail 7 "$engine has no --batch-slots"
readelf -d "$engine" | awk '/NEEDED/ { print $NF }' | tr -d '[]' > "$work/engine.needed"
if grep -Eiq 'cuda|cublas|nvidia|nvrtc' "$work/engine.needed"; then
    fail 7 "$engine links a CUDA library: $(tr '\n' ' ' < "$work/engine.needed")"
fi
[ -x "$engine27" ] || fail 2 "$engine27 is not executable"
have=$(sha256sum "$engine27" | cut -d' ' -f1)
[ "$have" = "$ENGINE27_SHA256" ] || fail 7 "$engine27 sha256 $have, want $ENGINE27_SHA256"
grep -aq "$CORE27_REV" "$engine27" || fail 7 "$engine27 does not embed Core commit $CORE27_REV"
readelf -d "$engine27" | awk '/NEEDED/ { print $NF }' | tr -d '[]' > "$work/engine27.needed"
if grep -Eiq 'cuda|cublas|nvidia|nvrtc' "$work/engine27.needed"; then
    fail 7 "$engine27 links a CUDA library: $(tr '\n' ' ' < "$work/engine27.needed")"
fi

stage=$out/stage
dist=$out/dist
rm -rf "$stage" "$dist"
mkdir -p "$stage/bin" "$stage/share/aienos/wizard" "$dist"
install -m 755 "$work/aienos.1" "$stage/bin/aienos"
install -m 755 "$engine" "$stage/bin/aien-serve-http"
install -m 755 "$engine27" "$stage/bin/aien-serve-http-27b"
for f in $ORDER; do install -m 644 "wizard/$f" "$stage/share/aienos/wizard/$f"; done
install -m 644 "$work/aienos.om" "$stage/share/aienos/aienos.om"
install -m 644 share/models.registry share/model.manifest share/model-27b.manifest \
    share/aienos.desktop.in share/aienos.svg "$stage/share/aienos/"
install -m 755 build.sh "$stage/share/aienos/build.sh"
install -m 644 ../LICENSE ../NOTICE ../KEYS HOST-DEPENDENCIES.md "$stage/"
install -m 644 bundle/README.txt "$stage/README.txt"
{
    printf 'AienOS %s\n' "$TAG"
    printf 'wizard: bin/aienos sha256 %s, from share/aienos/aienos.om sha256 %s\n' \
        "$(sha256sum "$work/aienos.1" | cut -d' ' -f1)" "$(sha256sum "$work/aienos.om" | cut -d' ' -f1)"
    printf 'compiler: aien-dev/omega-mv %s seed/out/omc sha256 %s\n' "$OMEGA_REV" "$OMC_PIN"
    printf 'engine: bin/aien-serve-http sha256 %s\n' "$(sha256sum "$engine" | cut -d' ' -f1)"
    printf 'engine source: aien-dev/aien-sovereign-core-mv %s (branch ship/motor-l387)\n' "$CORE_REV"
    printf 'engine GPU library: omega ship/motor-l387 6de999da libomega_gpu.a sha256 110295ef23dc7561eea371636347c005835f37b82c22f92401aa8a887a3ca990\n'
    printf 'engine NEEDED: %s\n' "$(tr '\n' ' ' < "$work/engine.needed")"
    sed 's/^/engine --help: /' "$work/engine.usage"
    printf 'engine 27B: bin/aien-serve-http-27b sha256 %s\n' "$(sha256sum "$engine27" | cut -d' ' -f1)"
    printf 'engine 27B source: aien-dev/aien-sovereign-core-mv %s (tag alpha/20261025.1)\n' "$CORE27_REV"
    printf 'engine 27B NEEDED: %s\n' "$(tr '\n' ' ' < "$work/engine27.needed")"
} > "$stage/VERSION"
(cd "$stage" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | xargs sha256sum > SHA256SUMS)

bundle=aienos-$TAG-linux-arm64.tar.gz
(cd "$stage" && find . -mindepth 1 | LC_ALL=C sort | sed 's|^\./||' > "$work/files")
tar -C "$stage" --owner=0 --group=0 --numeric-owner --mtime=@0 --no-recursion \
    -cf - -T "$work/files" | gzip -9n > "$dist/$bundle"
install -m 644 install.sh "$dist/install.sh"
install -m 644 "$work/aienos.om" "$dist/aienos.om"
install -m 644 ../keys/release.pub ../keys/release.pub.pem "$dist/"
(cd "$dist" && sha256sum "$bundle" install.sh aienos.om release.pub release.pub.pem > SHA256SUMS)
printf 'built %s\n' "$dist/$bundle"
cat "$dist/SHA256SUMS"
