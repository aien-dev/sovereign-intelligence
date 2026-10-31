#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: bad signature on the bundle.
#
# Preconditions: OMC = the pinned omc (build.sh OMC_PIN); python3, openssl, curl, tar on the host.
#   Host run: a signed test release served on a free high 127.0.0.1 port, a fake GB10 probe root
#   (tests/fake-root.sh gb10) and empty home folders under the scratch folder.
# Expected result: install.sh exits 1 and says the signature (or the signed SHA-256) does not
#   match, for (a) SHA256SUMS re-signed with another Ed25519 key, (b) a corrupted SHA256SUMS.sig,
#   (c) one byte of the bundle changed under the original SHA256SUMS and signature. The home
#   folder stays empty and install.sh leaves no temporary folder behind.
# Negative control: the untampered release installs and `aienos verify` passes (opposite verdict).
# Status: EXERCISED(host) with the test key. Stock DGX Spark with the real release key: NOT_RUN.
#
# usage: OMC=... sh bad-signature.sh [SCRATCH]
set -u
FP_NAME=bad-signature
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-sig.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve
fp_compile "$S/bin" || fp_notrun "omc refused the wizard ($S/bin/omc.err)"
fp_release good "$S/bin"

# (a) An attacker's key signs a rewritten SHA256SUMS.
mkdir -p "$S/www/otherkey"; cp "$S/www/good"/* "$S/www/otherkey/"
openssl genpkey -algorithm ed25519 -out "$S/other.key" 2>/dev/null
(cd "$S/www/otherkey" && openssl pkeyutl -sign -inkey "$S/other.key" -rawin -in SHA256SUMS -out SHA256SUMS.sig)
# (b) The right signature with one byte changed.
mkdir -p "$S/www/badsig"; cp "$S/www/good"/* "$S/www/badsig/"
python3 - "$S/www/badsig/SHA256SUMS.sig" <<'EOF'
import sys
p = sys.argv[1]; b = bytearray(open(p, 'rb').read()); b[10] ^= 0x01; open(p, 'wb').write(b)
EOF
# (c) The bundle changed after signing.
mkdir -p "$S/www/tampered"; cp "$S/www/good"/* "$S/www/tampered/"
python3 - "$S/www/tampered/$BUNDLE" <<'EOF'
import sys
p = sys.argv[1]; b = bytearray(open(p, 'rb').read()); b[len(b) // 2] ^= 0xff; open(p, 'wb').write(b)
EOF

for c in otherkey:"signature on SHA256SUMS does not match" badsig:"signature on SHA256SUMS does not match" \
         tampered:"does not match its signed SHA-256"; do
    rel=${c%%:*}; msg=${c#*:}
    h=$(fp_home "$rel")
    fp_boot "$h" "$rel" > "$S/$rel.out" 2>&1; rc=$?
    check "$rel: install.sh exit 1 (got $rc)" "$([ $rc -eq 1 ]; echo $?)"
    grep -q "$msg" "$S/$rel.out"; check "$rel: says \"$msg\"" $?
    grep -q "Nothing was installed" "$S/$rel.out"; check "$rel: says nothing was installed" $?
    fp_untouched "$h"; check "$rel: home folder untouched" $?
done
[ -z "$(ls -A "$S/tmp")" ]; check "no temporary folder left in TMPDIR" $?

# Negative control: the same checks on the untampered release give the opposite verdict.
h=$(fp_home good)
fp_boot "$h" good > "$S/good.out" 2>&1; rc=$?
ctl=same
if [ $rc -eq 0 ] && fp_installed "$h" && ! grep -q "does not match" "$S/good.out"; then ctl=opposite; fi
check "negative control (untampered release installs and verifies): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host) cases=otherkey,badsig,tampered control=$ctl spark=NOT_RUN"
