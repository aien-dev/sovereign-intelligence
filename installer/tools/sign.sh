#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Sign DIST/SHA256SUMS with the alpha release key and check the signature.
#   sh tools/sign.sh DIST
# The Ed25519 seed (64 hex digits) is read from the build machine's TPM-bound vault under
# AIENOS_RELEASE_ED25519_SEED and goes to openssl only through a pipe: it is never written to a
# file or printed. The result is checked against keys/release.pub.pem before this script succeeds.
set -eu
cd "$(dirname "$0")/../.."
dist=${1:?usage: tools/sign.sh DIST}
[ -f "$dist/SHA256SUMS" ] || { echo "sign.sh: no $dist/SHA256SUMS" >&2; exit 2; }
vault=${ATLAS_VAULT:-atlas-vault}
rm -f "$dist/SHA256SUMS.sig"
# PKCS#8 DER prefix for an Ed25519 private key (RFC 8410), then the 32-byte seed.
SIGN_DIST=$(cd "$dist" && pwd)
export SIGN_DIST
"$vault" run AIENOS_RELEASE_ED25519_SEED -- sh -c '
    printf "302e020100300506032b657004220420%s" "$AIENOS_RELEASE_ED25519_SEED" | xxd -r -p |
        openssl pkeyutl -sign -keyform DER -inkey /dev/stdin -rawin \
            -in "$SIGN_DIST/SHA256SUMS" -out "$SIGN_DIST/SHA256SUMS.sig"'
openssl pkeyutl -verify -pubin -inkey keys/release.pub.pem -rawin \
    -in "$dist/SHA256SUMS" -sigfile "$dist/SHA256SUMS.sig"
