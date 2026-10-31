#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Host arms of the test-rig checkers. Sequencing only: every judgment is made by the .om tools.
#   sh installer/rig/test.sh OMC   (OMC = the pinned omega-mv seed/out/omc; its sha256 is checked)
# wfcheck (DRA-45): the repository's workflows must pass; every good fixture must pass; every bad
# fixture is a negative control that must exit 1 and print the PROBLEM text named in bad/EXPECT.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
omc=${1:?usage: test.sh OMC}
pin=62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b
echo "$pin  $omc" | sha256sum -c - >/dev/null || { echo "test.sh: $omc is not the pinned omc $pin"; exit 3; }
out=$(mktemp -d)
trap 'rm -rf "$out"' EXIT
"$omc" < "$here/wfcheck.om" > "$out/wfcheck"
chmod +x "$out/wfcheck"
fail=0
"$out/wfcheck" "$repo/.github/workflows" || { echo "ARM repo-workflows: want 0"; fail=1; }
"$out/wfcheck" "$here/fixtures/workflows/good" || { echo "ARM good-fixtures: want 0"; fail=1; }
n=0
while IFS="$(printf '\t')" read -r f want; do
	case $f in '#'*|'') continue ;; esac
	n=$((n + 1))
	rc=0
	"$out/wfcheck" "$here/fixtures/workflows/bad/$f" > "$out/o" || rc=$?
	if [ "$rc" != 1 ] || ! grep -qF -- "$want" "$out/o"; then
		echo "NEGATIVE-CONTROL $f: rc=$rc (want 1), wanted text: $want"
		cat "$out/o"
		fail=1
	else
		echo "NEGATIVE-CONTROL $f: rejected as expected"
	fi
done < "$here/fixtures/workflows/bad/EXPECT"
k=$(find "$here/fixtures/workflows/bad" -name '*.yml' | wc -l)
[ "$n" = "$k" ] || { echo "EXPECT lists $n fixtures, bad/ holds $k"; fail=1; }
[ "$fail" = 0 ] && echo "RIG TEST PASS negative-controls=$n" || { echo "RIG TEST FAIL"; exit 1; }
