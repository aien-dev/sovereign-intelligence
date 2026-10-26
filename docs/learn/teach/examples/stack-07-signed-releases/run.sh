#!/bin/sh
# stack-07-signed-releases: check the SI alpha-20261026.1 trust chain offline from the pinned
# sovereign-intelligence clone plus one release asset (SHA256SUMS.sig, see PROVENANCE.txt):
#   1. pemkey.om (Omega): the PEM key and the raw hex key in the repo are the same Ed25519 key
#   2. node crypto (oracle): the Ed25519 signature over SHA256SUMS verifies, and fails after one byte changes
#   3. sha256sum (oracle): the repo's install.sh and key files match the signed list
#   4. install.sh pins the tag and the key it checks against
set -u
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" | cut -d' ' -f1)
if [ "$got" != "$PIN" ]; then
    echo "omc sha256 is not the pin $PIN"
    exit 90
fi
echo "omc sha256 $PIN"
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT
si=$SRC/sovereign-intelligence
status=0
want() { [ "$1" -eq "$2" ] || status=1; }

sig_pin=274321c4b9959159a36b3fdb4a4a1cef29663ae96add4c1990844941101debe9
echo "SHA256SUMS.sig sha256 matches PROVENANCE.txt: $([ "$(sha256sum "$here/SHA256SUMS.sig" | cut -d' ' -f1)" = "$sig_pin" ] && echo yes || echo no)"

cat "$here/lib.om" "$here/pemkey.om" > "$tmp/unit.om"
"$OMC" < "$tmp/unit.om" > "$tmp/pemkey" 2> "$tmp/err"
rc=$?
echo "compile lib.om+pemkey.om rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/pemkey"

echo "== 1. keys/release.pub.pem against keys/release.pub"
cat "$si/keys/release.pub.pem" "$si/keys/release.pub" | "$tmp/pemkey"
rc=$?
echo "run rc=$rc"
want "$rc" 0
echo "== 1. negative control: one base64 character of the PEM changed (/5S -> /6S)"
sed 's|EA/5SVB|EA/6SVB|' "$si/keys/release.pub.pem" > "$tmp/bad.pem"
cat "$tmp/bad.pem" "$si/keys/release.pub" | "$tmp/pemkey"
rc=$?
echo "run rc=$rc"
want "$rc" 1

echo "== 2. Ed25519 signature over evidence/alpha-20261026.1/SHA256SUMS.tested"
cp "$si/evidence/alpha-20261026.1/SHA256SUMS.tested" "$tmp/SHA256SUMS"
node "$here/verify.mjs" "$si/keys/release.pub.pem" "$tmp/SHA256SUMS" "$here/SHA256SUMS.sig"
rc=$?
echo "node rc=$rc"
want "$rc" 0
echo "== 2. negative control: one hex digit of the bundle hash changed (3c53 -> 3c54)"
sed 's/^3c53/3c54/' "$tmp/SHA256SUMS" > "$tmp/SHA256SUMS.bad"
node "$here/verify.mjs" "$si/keys/release.pub.pem" "$tmp/SHA256SUMS.bad" "$here/SHA256SUMS.sig"
rc=$?
echo "node rc=$rc"
want "$rc" 1
echo "sha256 of the signed SHA256SUMS: $(sha256sum "$tmp/SHA256SUMS" | cut -d' ' -f1)"
echo "the container receipt tested against: $(sed -n 's/^dist SHA256SUMS sha256 //p' "$si/evidence/alpha-20261026.1/container/receipt.txt")"
[ "$(sha256sum "$tmp/SHA256SUMS" | cut -d' ' -f1)" = "$(sed -n 's/^dist SHA256SUMS sha256 //p' "$si/evidence/alpha-20261026.1/container/receipt.txt")" ] || status=1

echo "== 3. repo files against the signed list"
mkdir "$tmp/files"
cp "$tmp/SHA256SUMS" "$si/installer/install.sh" "$si/keys/release.pub" "$si/keys/release.pub.pem" "$tmp/files/"
(cd "$tmp/files" && sha256sum -c --ignore-missing SHA256SUMS)
rc=$?
echo "sha256sum rc=$rc"
want "$rc" 0
for f in $(cut -d' ' -f3 "$tmp/SHA256SUMS"); do
    [ -f "$tmp/files/$f" ] || echo "$f: NOT_RUN (a release asset, not in the repository)"
done

echo "== 4. what install.sh pins"
grep '^TAG=' "$si/installer/install.sh"
hex=$(sed -n 's/^RELEASE_PUB_HEX=//p' "$si/installer/install.sh")
echo "RELEASE_PUB_HEX equals keys/release.pub: $([ "$hex" = "$(cat "$si/keys/release.pub")" ] && echo yes || echo no)"
[ "$hex" = "$(cat "$si/keys/release.pub")" ] || status=1

echo "every verdict as expected: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
