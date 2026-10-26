#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Publish a release from the build machine: build, sign, check, upload.
#   OMEGA_SRC=... ENGINE=... sh tools/release.sh OUT
# Uploads OUT/dist/* to the GitHub release of TAG on aien-dev/sovereign-intelligence with the notes in
# notes/TAG.md. The tests (installer/tests/run.sh, host-untouched.sh, container.sh) run on
# OUT before this script is used; their receipts go in evidence/TAG/.
set -eu
cd "$(dirname "$0")/../.."
TAG=alpha-20261026.3
out=${1:?usage: tools/release.sh OUT}
[ -f "notes/$TAG.md" ] || { echo "release.sh: no notes/$TAG.md" >&2; exit 2; }
sh installer/build.sh "$out"
sh installer/tools/sign.sh "$out/dist"
(cd "$out/dist" && sha256sum -c SHA256SUMS)
gh release create "$TAG" --repo aien-dev/sovereign-intelligence --title "Sovereign Intelligence $TAG" \
    --notes-file "notes/$TAG.md" --prerelease \
    "$out/dist/SHA256SUMS" "$out/dist/SHA256SUMS.sig" "$out/dist/aienos-$TAG-linux-arm64.tar.gz" \
    "$out/dist/install.sh" "$out/dist/aienos.om" "$out/dist/release.pub" "$out/dist/release.pub.pem"
