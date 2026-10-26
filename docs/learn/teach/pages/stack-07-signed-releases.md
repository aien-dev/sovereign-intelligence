# Signed releases: owning distribution

Evidence level: EXERCISED. The alpha release key, the signature over SHA256SUMS and the repository files were checked offline on a Linux arm64 host, with negative controls; a real install on a GB10 is NOT_RUN.

## Goal

Understand how an SI release proves which bytes it contains, and verify the alpha-20261026.1 signature and hashes yourself, offline, from the public repository.

## Explanation

Owning a stack includes owning how it reaches you: if the download can be swapped on the way, nothing else matters. An SI release is a short chain of checks, all public in [aien-dev/sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence):

1. `SHA256SUMS` lists the sha256 of every asset: the bundle, `install.sh`, `aienos.om` and the two key files.
2. `SHA256SUMS.sig` is an Ed25519 signature over its raw bytes, no prehash.
3. The alpha release key is in [KEYS](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/KEYS) and [keys/release.pub.pem](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/keys/release.pub.pem); its raw public key starts `ff949504` and ends `f54a`.
4. [install.sh](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/installer/install.sh#L21) names the tag `alpha-20261026.1` (never "latest"), carries the key's hex, checks the signature, then the bundle hash, unpacks into a staging folder and checks every file again before anything moves into place.

About the key, plainly: it is an alpha key, made on 2026-10-26 on my build machine, its private seed held in a TPM-bound vault there and passed to `openssl` only through a pipe in [sign.sh](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/installer/tools/sign.sh). Before beta it is replaced by a key made at a witnessed offline ceremony. Until then, trusting a release means trusting that one machine.

The lesson checks, offline:

- **Key forms agree.** `pemkey.om` decodes the PEM's base64 in Omega, checks the 12-byte Ed25519 SubjectPublicKeyInfo prefix and compares the 32 key bytes with `keys/release.pub`.
- **Signature verifies.** The signed file is in the repository as `evidence/alpha-20261026.1/SHA256SUMS.tested`. The 64-byte signature is a release asset, copied into the example with its source and hash in `PROVENANCE.txt`. Node's built-in crypto ([verify.mjs](../examples/stack-07-signed-releases/verify.mjs)) is the Ed25519 oracle, doing what the `openssl` line in KEYS does.
- **Repository files match.** `install.sh` and both key files hash to the signed values. The bundle and `aienos.om` are not repository files, so they are reported NOT_RUN, not skipped.

Each check has a one-byte negative control.

## Example

`pemkey.om` (shared helpers in [lib.om](../examples/stack-07-signed-releases/lib.om)):

```om
note pemkey: stdin is an Ed25519 public key in PEM (SubjectPublicKeyInfo) followed by the same key as one
note line of hex. Decode the base64, check the 12-byte Ed25519 prefix (RFC 8410, OID 1.3.101.112), print the
note 32 key bytes as hex and compare them with the hex line.
note exit 0 the two forms agree, 1 they differ, 2 malformed
text tbeg "-----BEGIN"
text tend "-----END"
text tder "DER bytes "
text tpfx "Ed25519 SubjectPublicKeyInfo prefix: ok\n"
text tkey "key from PEM  "
text thex "key from hex  "
text tsame "the two forms agree: "
text yes "yes\n"
text no "no\n"
text vbad "verdict MALFORMED\n"
text nl "\n"
global der uchar 64
global pfx uchar 12
note b: 0 state (0 before BEGIN, 1 body, 2 after END), 1 bits, 2 nbits, 3 der count, 4 bad, 5 hex start, 6 hex end
global b ulong 7
fn setpfx to void
put pfx 0 48
put pfx 1 42
put pfx 2 48
put pfx 3 5
put pfx 4 6
put pfx 5 3
put pfx 6 43
put pfx 7 101
put pfx 8 112
put pfx 9 3
put pfx 10 33
put pfx 11 0
end
fn b64 c uchar to ulong
note value of a base64 character, 64 for padding, 65 for anything else
if and ge c 65 le c 90
ret ulong sub c 65
end
if and ge c 97 le c 122
ret add ulong sub c 97 26
end
if and ge c 48 le c 57
ret add ulong sub c 48 52
end
if eq c 43
ret 62
end
if eq c 47
ret 63
end
if eq c 61
ret 64
end
ret 65
end
fn push v ulong to void
acc = or shl get b 1 6 v
nb = add get b 2 6
if ge nb 8
nb = sub nb 8
n = get b 3
if lt n len der
put der n uchar and shr acc nb 255
put b 3 add n 1
else
put b 4 1
end
end
put b 1 and acc 255
put b 2 nb
end
fn body a ulong e ulong to void
for i ulong sub e a
v = b64 get inb add a i
if eq v 65
put b 4 1
end
if lt v 64
push v
end
end
end
fn oneline a ulong e ulong to void
s = get b 0
if sameb tbeg 0 a len tbeg
put b 0 1
else
if sameb tend 0 a len tend
put b 0 2
else
if eq s 1
body a e
end
if eq s 2
if lt a e
if eq get b 6 0
put b 5 a
put b 6 e
end
end
end
end
end
end
fn hexc v uchar to uchar
if lt v 10
ret add v 48
end
ret add v 87
end
fn cmpkey to bool
note print the key bytes as hex and compare with the hex line
h = get b 5
same = eq sub get b 6 h 64
ot tkey
for i ulong 32
x = get der add i 12
c1 = hexc shr x 4
c2 = hexc and x 15
oc c1
oc c2
if same
if ne c1 get inb add h mul i 2
same = false
end
if ne c2 get inb add h add mul i 2 1
same = false
end
end
end
ot nl
ot thex
oi h get b 6
ot nl
ret same
end
fn prefixok to bool
for i ulong 12
if ne get der i get pfx i
ret false
end
end
ret true
end
fn main to int
setpfx
r = rdall
if lt r 0
ret 2
end
n = ulong r
a = ulong 0
for i ulong n
if eq get inb i 10
oneline a i
a = add i 1
end
end
if lt a n
oneline a n
end
ot tder
on get b 3
ot nl
ok = eq get b 4 0
if ne get b 3 44
ok = false
end
if ok
ok = prefixok
end
if not ok
ot vbad
f = flush
ret 2
end
ot tpfx
same = cmpkey
ot tsame
v = int 1
if same
v = 0
ot yes
else
ot no
end
f = flush
ret v
end
```

Run it:

```sh
sh examples/stack-07-signed-releases/run.sh
```

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
SHA256SUMS.sig sha256 matches PROVENANCE.txt: yes
compile lib.om+pemkey.om rc=0
== 1. keys/release.pub.pem against keys/release.pub
DER bytes 44
Ed25519 SubjectPublicKeyInfo prefix: ok
key from PEM  ff949504b427680039d53c33c85c448546b57d590eb1ecee3bb2ed6c2eaaf54a
key from hex  ff949504b427680039d53c33c85c448546b57d590eb1ecee3bb2ed6c2eaaf54a
the two forms agree: yes
run rc=0
== 1. negative control: one base64 character of the PEM changed (/5S -> /6S)
DER bytes 44
Ed25519 SubjectPublicKeyInfo prefix: ok
key from PEM  ffa49504b427680039d53c33c85c448546b57d590eb1ecee3bb2ed6c2eaaf54a
key from hex  ff949504b427680039d53c33c85c448546b57d590eb1ecee3bb2ed6c2eaaf54a
the two forms agree: no
run rc=1
== 2. Ed25519 signature over evidence/alpha-20261026.1/SHA256SUMS.tested
signature VALID (ed25519)
node rc=0
== 2. negative control: one hex digit of the bundle hash changed (3c53 -> 3c54)
signature INVALID (ed25519)
node rc=1
sha256 of the signed SHA256SUMS: d442d2ac1b434fff31cb1104c3c71d0e7df2b845a4c672e91a14cb10f3cd3c84
the container receipt tested against: d442d2ac1b434fff31cb1104c3c71d0e7df2b845a4c672e91a14cb10f3cd3c84
== 3. repo files against the signed list
install.sh: OK
release.pub: OK
release.pub.pem: OK
sha256sum rc=0
aienos-alpha-20261026.1-linux-arm64.tar.gz: NOT_RUN (a release asset, not in the repository)
aienos.om: NOT_RUN (a release asset, not in the repository)
== 4. what install.sh pins
TAG=alpha-20261026.1
RELEASE_PUB_HEX equals keys/release.pub: yes
every verdict as expected: yes
```

To check a downloaded release the way the release notes say, with OpenSSL 3.0 or newer, in the folder holding the assets:

```sh
openssl pkeyutl -verify -pubin -inkey release.pub.pem -rawin -in SHA256SUMS -sigfile SHA256SUMS.sig
sha256sum -c SHA256SUMS
```

Take the key from the repository's KEYS, not from the same download: a key that ships next to the files it vouches for proves only that the files and key came together.

## Common mistake

Checking the hash without checking the signature. Anyone who can replace the bundle can replace `SHA256SUMS` next to it, so `sha256sum -c` alone proves only that the download is self-consistent. The signature, checked against a key you got from somewhere else, is what ties the hashes to me. The second mistake is installing from "latest": the signature then covers whatever was newest, and no receipt can say which release a user actually ran.

## Where to go deeper

- [KEYS: the alpha key, its status and how to check a release](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/KEYS)
- [install.sh: tag, key and every check in order](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/installer/install.sh)
- [sign.sh: how SHA256SUMS is signed](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/installer/tools/sign.sh)
- [Release notes for alpha-20261026.1](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/notes/alpha-20261026.1.md)
- [The evidence for this release](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/evidence/alpha-20261026.1/README.md)
- [The signed list, as tested](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/evidence/alpha-20261026.1/SHA256SUMS.tested)
