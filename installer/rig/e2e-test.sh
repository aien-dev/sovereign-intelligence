#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Host arms of the end-to-end harness (DRA-55, DRA-59). FAKE mode only: nothing is installed.
#   sh installer/rig/e2e-test.sh OMC   (OMC = omega-mv bf54b19f seed/out/omc inside its checkout)
# Sequencing only; evcheck.om makes every judgment. Arms:
#   vendor/json.om is byte-identical to the pinned omega-mv seed/json/json.om;
#   a FAKE e2e.sh run passes evcheck in schema mode and in --want FAKE;
#   negative controls, each must exit 1 with the named problem: a missing member, a bad sha256,
#   a start before the previous end, and the FAKE records presented with --want REAL.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
omc=${1:?usage: e2e-test.sh OMC}
pin=62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b
echo "$pin  $omc" | sha256sum -c - >/dev/null || { echo "e2e-test.sh: $omc is not the pinned omc $pin"; exit 3; }
omega=$(cd "$(dirname "$omc")/../.." && pwd)
fail=0
cmp "$here/vendor/json.om" "$omega/seed/json/json.om" && echo "ARM vendor-json: identical" \
	|| { echo "ARM vendor-json: vendor/json.om differs from $omega/seed/json/json.om"; fail=1; }
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
{ printf 'om2\n'; cat "$here/vendor/json.om" "$here/evcheck.om"; } | "$omc" > "$out/evcheck"
chmod +x "$out/evcheck"
ev=$out/evcheck

sh "$here/e2e.sh" --fake --tag alpha-20261029.1 --out "$out/fake.jsonl" || { echo "ARM fake-run: want 0"; fail=1; }
cat "$out/fake.jsonl"
"$ev" "$out/fake.jsonl" || { echo "ARM schema: want 0"; fail=1; }
"$ev" --want FAKE "$out/fake.jsonl" || { echo "ARM certify-fake: want 0"; fail=1; }

# neg NAME TEXT EVCHECK-ARGS...: must exit 1 and print TEXT
neg() {
	name=$1 want=$2
	shift 2
	rc=0
	"$ev" "$@" > "$out/o" || rc=$?
	if [ "$rc" != 1 ] || ! grep -qF -- "$want" "$out/o"; then
		echo "NEGATIVE-CONTROL $name: rc=$rc (want 1), wanted text: $want"
		cat "$out/o"
		fail=1
	else
		echo "NEGATIVE-CONTROL $name: rejected as expected ($want)"
	fi
}
f=$out/fake.jsonl
sed '2s/,"exit_code":[-0-9]*//' "$f" > "$out/missing.jsonl"
neg missing-member "line 2: missing member exit_code" "$out/missing.jsonl"
sed '3s/"engine_sha256":"[0-9a-f]/"engine_sha256":"X/' "$f" > "$out/badsha.jsonl"
neg bad-sha "line 3: engine_sha256 is not 64 lowercase hex digits" "$out/badsha.jsonl"
sed '3s/"start_utc":"[^"]*"/"start_utc":"2000-01-01T00:00:00Z"/' "$f" > "$out/mono.jsonl"
neg non-monotonic "line 3: start_utc is before the previous record's end_utc" "$out/mono.jsonl"
neg fake-as-real "certify: mode is not the wanted mode" --want REAL "$f"
sed '1s/"mode":"FAKE"/"mode":"REAL"/' "$f" > "$out/mixed.jsonl"
neg mixed-mode "line 2: mode differs from the first record" --want REAL "$out/mixed.jsonl"
[ "$fail" = 0 ] && echo "E2E HOST TEST PASS (FAKE only; REAL NOT_RUN)" || { echo "E2E HOST TEST FAIL"; exit 1; }
