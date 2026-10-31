#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Build the AienOS alpha bundle from pinned inputs. Linux arm64 only (omc writes arm64 ELF).
#
#   OMEGA_SRC=/path/to/omega-mv@bf54b19fa ENGINE=/path/to/aien-serve-http sh build.sh OUT
#
# OMEGA_SRC  a clone of aien-dev/omega-mv at OMEGA_REV: its seed/out/omc compiles the wizard
#            and its om/sha256/sha256-om2.om is the source wizard/sha256.om is derived from.
# ENGINE     aien-serve-http built from aien-dev/aien-sovereign-core-mv main at CORE_REV with Core's
#            path-independent container recipe (DRA-43, core#859):
#              CORE_REV=<CORE_REV> scripts/repro-container-build.sh /abs/new/dir
#            which links libomega_gpu.a from omega-mv a647b6a9 (Core's omega.lock at CORE_REV),
#            sha256 036b7491. Its bytes are pinned as ENGINE_SHA256; its --help usage line and its
#            --version build identity go into VERSION.
# OUT        output folder: OUT/stage (the bundle tree) and OUT/dist (the release assets).
#
# Optional, the Open Humanity lending program (aienos lend):
# OH_VOLUNTEER        oh-infer-volunteer built from aien-dev/open-humanity at OH_REV
#                     (cargo build --release -p oh-infer). Unset: the bundle has no lending program
#                     and the wizard's lending step says so.
# OH_SRC              the clean open-humanity clone at OH_REV it was built from; required when
#                     OH_VOLUNTEER is set.
# OH_COORDINATOR_KEY  the coordinator's 64-hex public key; required when OH_VOLUNTEER is set.
# OH_REV is open-humanity main c0484649, the squash merge of open-humanity#51 (volunteer inference).
#
# Exit: 2 missing input, 3 wrong pin, 4 derived source differs, 5 nondeterministic compile,
#       6 compile refused, 7 engine or lending program identity or linkage wrong. Signing is tools/sign.sh.
set -eu
cd "$(dirname "$0")"
TAG=alpha-20261029.1
OMEGA_REV=bf54b19fa590e8ae925c0e80815516dbf41e7326
OMC_PIN=62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b
CORE_REV=d3dec0eb18818808212bdf99db5c8612bcfcb9ef
ENGINE_SHA256=6fb04197c272aa1d0235e7644b6e91953ff9b90f5145b250d674ff9fe41806e9
OH_REV=c048464950ed40baf0d98c7bcb9e1e860aa69b87
OH_COORDINATOR=https://www.aienos.com/oh/v1/volunteer
ORDER="sha256.om lib.om hole.om doctor.om net.om steps.om engine.om lend.om main.om report.om"
out=${1:?usage: build.sh OUT}
src=${OMEGA_SRC:?set OMEGA_SRC to an omega-mv clone at $OMEGA_REV}
engine=${ENGINE:?set ENGINE to aien-serve-http built from Core $CORE_REV}

fail() { code=$1; shift; printf 'build.sh: %s\n' "$*" >&2; exit "$code"; }

[ -d "$src/.git" ] || fail 2 "$src is not a git clone"
rev=$(git -C "$src" rev-parse HEAD)
[ "$rev" = "$OMEGA_REV" ] || fail 3 "omega-mv is at $rev, want $OMEGA_REV"
omc=$src/seed/out/omc
have=$(sha256sum "$omc" | cut -d' ' -f1)
[ "$have" = "$OMC_PIN" ] || fail 3 "omc sha256 $have, want $OMC_PIN"

vol=${OH_VOLUNTEER:-}
if [ -n "$vol" ]; then
    [ -x "$vol" ] || fail 2 "OH_VOLUNTEER $vol is not executable"
    ohsrc=${OH_SRC:?OH_VOLUNTEER is set: set OH_SRC to the open-humanity clone at $OH_REV}
    [ -d "$ohsrc/.git" ] || fail 2 "$ohsrc is not a git clone"
    ohrev=$(git -C "$ohsrc" rev-parse HEAD)
    [ "$ohrev" = "$OH_REV" ] || fail 3 "open-humanity is at $ohrev, want $OH_REV"
    git -C "$ohsrc" diff --quiet HEAD -- || fail 3 "open-humanity clone $ohsrc has local changes"
    printf '%s' "${OH_COORDINATOR_KEY:-}" | grep -Eqx '[0-9a-f]{64}' \
        || fail 2 "OH_VOLUNTEER is set: OH_COORDINATOR_KEY must be 64 lowercase hex"
    "$vol" > /dev/null 2>&1 && fail 7 "$vol does not behave like oh-infer-volunteer"
    [ $? -eq 2 ] || fail 7 "$vol does not behave like oh-infer-volunteer (want usage exit 2)"
fi
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
"$engine" --version > "$work/engine.version" 2>&1 || fail 7 "$engine has no --version"
grep -qx "sovereign-core commit: $CORE_REV (dirty 0)" "$work/engine.version" \
    || fail 7 "$engine --version does not name clean Core commit $CORE_REV"
grep -q -- "--batch-slots N" "$work/engine.usage" || fail 7 "$engine has no --batch-slots"
readelf -d "$engine" | awk '/NEEDED/ { print $NF }' | tr -d '[]' > "$work/engine.needed"
if grep -Eiq 'cuda|cublas|nvidia|nvrtc' "$work/engine.needed"; then
    fail 7 "$engine links a CUDA library: $(tr '\n' ' ' < "$work/engine.needed")"
fi

stage=$out/stage
dist=$out/dist
rm -rf "$stage" "$dist"
mkdir -p "$stage/bin" "$stage/share/aienos/wizard" "$dist"
install -m 755 "$work/aienos.1" "$stage/bin/aienos"
install -m 755 "$engine" "$stage/bin/aien-serve-http"
if [ -n "$vol" ]; then
    install -m 755 "$vol" "$stage/bin/oh-infer-volunteer"
    {
        printf 'coordinator %s\n' "$OH_COORDINATOR"
        printf 'coordinator-key %s\n' "$OH_COORDINATOR_KEY"
        printf 'model-digest %s\n' "$(sha256sum share/model.manifest | cut -d' ' -f1)"
    } > "$work/lend.conf"
    install -m 644 "$work/lend.conf" "$stage/share/aienos/lend.conf"
fi
for f in $ORDER; do install -m 644 "wizard/$f" "$stage/share/aienos/wizard/$f"; done
install -m 644 "$work/aienos.om" "$stage/share/aienos/aienos.om"
install -m 644 share/model.manifest share/aienos.desktop.in share/aienos.svg "$stage/share/aienos/"
install -m 755 build.sh "$stage/share/aienos/build.sh"
install -m 644 ../LICENSE ../NOTICE ../KEYS HOST-DEPENDENCIES.md "$stage/"
install -m 644 bundle/README.txt "$stage/README.txt"
{
    printf 'AienOS %s\n' "$TAG"
    printf 'wizard: bin/aienos sha256 %s, from share/aienos/aienos.om sha256 %s\n' \
        "$(sha256sum "$work/aienos.1" | cut -d' ' -f1)" "$(sha256sum "$work/aienos.om" | cut -d' ' -f1)"
    printf 'compiler: aien-dev/omega-mv %s seed/out/omc sha256 %s\n' "$OMEGA_REV" "$OMC_PIN"
    printf 'engine: bin/aien-serve-http sha256 %s\n' "$(sha256sum "$engine" | cut -d' ' -f1)"
    printf 'engine source: aien-dev/aien-sovereign-core-mv %s (main, core scripts/repro-container-build.sh)\n' "$CORE_REV"
    printf 'engine GPU library: omega-mv a647b6a9821fffcf52ba9ce813f75afa4b84be62 libomega_gpu.a sha256 036b7491d85a2d0781360c194402f345ad2f63720dab1b8f6d0cbc5c09f87d3e\n'
    printf 'engine NEEDED: %s\n' "$(tr '\n' ' ' < "$work/engine.needed")"
    sed 's/^/engine --help: /' "$work/engine.usage"
    sed 's/^/engine --version: /' "$work/engine.version"
    if [ -n "$vol" ]; then
        printf 'lending: bin/oh-infer-volunteer sha256 %s, from aien-dev/open-humanity %s (main, open-humanity#51)\n' \
            "$(sha256sum "$vol" | cut -d' ' -f1)" "$OH_REV"
    else
        printf 'lending: not included\n'
    fi
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
