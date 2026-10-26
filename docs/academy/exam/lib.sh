# lib.sh: shared helpers for the Agent Academy exam. POSIX sh, no network.
# Sourced by run.sh, selftest.sh and every tasks/*/check.sh.

OMC_PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
LC_ALL=C
export LC_ALL

# Temporary directories made with mktmp are removed when the script exits.
_TMPS=
cleanup() { for _d in $_TMPS; do rm -rf "$_d"; done; }
trap cleanup EXIT
trap 'exit 130' HUP INT TERM

# mktmp VAR: make a fresh temporary directory and store its path in VAR.
mktmp() {
	_d=$(mktemp -d "${TMPDIR:-/tmp}/academy.XXXXXX") || { echo "mktemp failed" >&2; exit 3; }
	_TMPS="$_TMPS $_d"
	eval "$1=\$_d"
}

# verdict WORD REASON: print the one grader line for task $ID and exit 0 PASS, 1 FAIL, 2 NOT_RUN.
verdict() {
	printf '%s %s %s\n' "$ID" "$1" "$2"
	case $1 in PASS) exit 0 ;; FAIL) exit 1 ;; *) exit 2 ;; esac
}
pass() { verdict PASS "$1"; }
fail() { verdict FAIL "$1"; }
notrun() { verdict NOT_RUN "$1"; }

# sha256 FILE: print the lowercase hex SHA-256 of FILE (of standard input when FILE is -).
sha256() {
	if [ "$1" = - ]; then _sha256; else _sha256 < "$1"; fi
}
_sha256() {
	if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
	elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
	elif command -v openssl >/dev/null 2>&1; then openssl dgst -sha256 | awk '{print $NF}'
	else echo "no sha256 tool (sha256sum, shasum or openssl)" >&2; return 1
	fi
}

# same A B: true when files A and B have identical bytes.
same() { [ -f "$1" ] && [ -f "$2" ] && cmp -s "$1" "$2"; }

# limited SECS CMD...: run CMD with a wall clock limit. Redirect its output to a file, never
# capture it with $(...).
limited() {
	_s=$1
	shift
	if command -v timeout >/dev/null 2>&1; then
		timeout "$_s" "$@"
		return $?
	fi
	"$@" &
	_p=$!
	(sleep "$_s"; kill -9 "$_p" 2>/dev/null) >/dev/null 2>&1 &
	_w=$!
	wait "$_p"
	_rc=$?
	kill "$_w" 2>/dev/null
	wait "$_w" 2>/dev/null
	return "$_rc"
}

# init: common start of a check.sh. Sets ID from the task folder and WS from $1.
init() {
	ID=${HERE##*/}
	WS=${1:-}
	[ -n "$WS" ] && [ -d "$WS" ] || notrun "workspace missing"
}

# git_env DIR: run git with a fixed identity and dates, no system or user config, HOME=DIR.
git_env() {
	HOME=$1
	XDG_CONFIG_HOME=$1
	GIT_CONFIG_NOSYSTEM=1
	GIT_CONFIG_GLOBAL=$1/gitconfig
	GIT_TERMINAL_PROMPT=0
	GIT_AUTHOR_NAME="Sam Rivera"
	GIT_AUTHOR_EMAIL=sam@example.invalid
	GIT_COMMITTER_NAME="Sam Rivera"
	GIT_COMMITTER_EMAIL=sam@example.invalid
	GIT_AUTHOR_DATE="2026-10-20T10:00:00+0000"
	GIT_COMMITTER_DATE="2026-10-20T10:00:00+0000"
	: > "$1/gitconfig"
	export HOME XDG_CONFIG_HOME GIT_CONFIG_NOSYSTEM GIT_CONFIG_GLOBAL GIT_TERMINAL_PROMPT \
		GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL \
		GIT_AUTHOR_DATE GIT_COMMITTER_DATE
}

# omc_ready: true when OMC is the pinned omc on Linux AArch64; otherwise sets OMC_WHY.
omc_ready() {
	[ -n "${OMC:-}" ] || { OMC_WHY="OMC not set"; return 1; }
	[ -f "$OMC" ] || { OMC_WHY="OMC is not a file"; return 1; }
	if [ "$(uname -s)" != Linux ] || [ "$(uname -m)" != aarch64 ]; then
		OMC_WHY="the pinned omc runs on Linux AArch64 only"
		return 1
	fi
	[ "$(sha256 "$OMC")" = "$OMC_PIN" ] || { OMC_WHY="OMC sha256 is not the pin"; return 1; }
}

# build_ws TASKDIR WS: copy the task fixture into WS and run the task setup.sh if present.
build_ws() {
	mkdir -p "$2" || return 1
	if [ -d "$1/fixture" ]; then cp -R "$1/fixture/." "$2/" || return 1; fi
	if [ -f "$1/setup.sh" ]; then sh "$1/setup.sh" "$2" || return 1; fi
	return 0
}

# exam_id EXAMDIR: first 12 hex of the SHA-256 over the sorted tasks/ file listing and contents.
exam_id() {
	(
		cd "$1" || exit 1
		find tasks -type f | sort | while IFS= read -r _f; do
			printf '%s  %s\n' "$(sha256 "$_f")" "$_f"
		done
	) | sha256 - | cut -c1-12
}
