#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# End-to-end harness for the SI Alpha test Spark (DRA-55): install -> verify -> chat -> uninstall,
# one evidence record per step in OUT (JSONL, schema si-rig-e2e/1, checked by evcheck.om).
#   sh installer/rig/e2e.sh --tag TAG --out OUT          REAL: installs into $HOME on this machine
#   sh installer/rig/e2e.sh --fake --tag TAG --out OUT   FAKE: every step is a stub; records say FAKE
# Sequencing only: the steps are the commands of installer/tests/run.sh, and every judgment about
# the evidence is made by evcheck.om. REAL needs a stock DGX Spark with no AienOS install, network,
# and the release TAG published; it starts the engine on the GPU. Every step runs and is recorded
# even after an earlier step failed, so uninstall always runs. Exit 0 when every step exited 0.
set -eu
mode=REAL tag= out=
while [ $# -gt 0 ]; do
	case $1 in
	--fake) mode=FAKE ;;
	--tag) tag=${2:?--tag needs a value}; shift ;;
	--out) out=${2:?--out needs a value}; shift ;;
	*) echo "usage: e2e.sh [--fake] --tag TAG --out OUT" >&2; exit 2 ;;
	esac
	shift
done
[ -n "$tag" ] && [ -n "$out" ] || { echo "usage: e2e.sh [--fake] --tag TAG --out OUT" >&2; exit 2; }
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/si-e2e.XXXXXX")
trap 'rm -rf "$work"' EXIT
mkdir -p "$(dirname "$out")"
: > "$out"
logs=${out%.jsonl}.logs
mkdir -p "$logs"
base=$HOME/.local/share/aienos
aienos=$base/current/bin/aienos
zero=0000000000000000000000000000000000000000000000000000000000000000
sha=$zero repo= commit=
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# The model revision as the release declares it: the url line of its model.manifest.
revision() {
	u=$(sed -n 's|^url https://huggingface.co/||p' "$1")
	repo=${u%%/resolve/*}
	commit=${u#*/resolve/}
	commit=${commit%/}
}

if [ "$mode" = FAKE ]; then
	# FAKE: no install happens. The engine hash is the sha256 of a fixed FAKE label, and the model
	# revision is read from this checkout's manifest.
	sha=$(printf 'FAKE engine for si-rig-e2e/1\n' | sha256sum | cut -d' ' -f1)
	revision "$here/../share/model.manifest"
	s_install() { echo "FAKE install $tag"; }
	s_verify() { echo "FAKE verify"; }
	s_chat() { echo "FAKE chat"; echo "model> FAKE"; }
	s_uninstall() { echo "FAKE uninstall"; }
else
	s_install() {
		git clone --quiet --depth 1 --branch "$tag" \
			https://github.com/aien-dev/sovereign-intelligence.git "$work/si" || return
		AIENOS_NO_WIZARD=1 sh "$work/si/installer/install.sh" || return
		printf '\n\n\nyes\n\n\n\n\n\n\n' | timeout 7200 "$aienos" wizard --plain
	}
	s_verify() { "$aienos" verify; }
	# chat exits 0 even after an engine error, so the step also needs a non-empty model> line.
	s_chat() {
		rc=0
		printf 'Reply with one short sentence.\n/bye\n' | timeout 900 "$aienos" chat > "$work/chat" 2>&1 || rc=$?
		cat "$work/chat"
		"$aienos" stop || true
		[ "$rc" = 0 ] || return "$rc"
		grep -Eq '^model> .*[^[:space:]]' "$work/chat" || { echo "e2e: no model> reply"; return 1; }
	}
	s_uninstall() {
		[ -x "$aienos" ] || { echo "e2e: $aienos missing"; return 1; }
		"$aienos" uninstall --yes || return
		[ ! -e "$base" ] || { echo "e2e: $base still present"; return 1; }
	}
fi

all=0
for step in install verify chat uninstall; do
	start=$(now)
	rc=0
	"s_$step" > "$logs/$step.log" 2>&1 || rc=$?
	end=$(now)
	if [ "$mode" = REAL ] && [ "$step" = install ]; then
		[ -x "$base/current/bin/aien-serve-http" ] \
			&& sha=$(sha256sum "$base/current/bin/aien-serve-http" | cut -d' ' -f1)
		[ -f "$base/current/share/aienos/model.manifest" ] \
			&& revision "$base/current/share/aienos/model.manifest"
	fi
	[ "$rc" = 0 ] || all=1
	printf '{"schema":"si-rig-e2e/1","step":"%s","mode":"%s","release_tag":"%s","engine_sha256":"%s","model_repo":"%s","model_commit":"%s","start_utc":"%s","end_utc":"%s","exit_code":%d}\n' \
		"$step" "$mode" "$tag" "$sha" "$repo" "$commit" "$start" "$end" "$rc" >> "$out"
	echo "e2e: $mode $step exit $rc"
done
exit "$all"
