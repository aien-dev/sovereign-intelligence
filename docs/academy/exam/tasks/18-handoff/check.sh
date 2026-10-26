#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
command -v git > /dev/null 2>&1 || notrun "git is not installed"
H=$WS/HANDOFF.md
[ -f "$H" ] || fail "no HANDOFF.md"
mktmp G
git_env "$G"
cd "$WS" || fail "cannot enter workspace"
base=$(git log --format='%H %s' 2>/dev/null | awk '$2 == "step" && $3 == "2:" {print $1; exit}')
head=$(git rev-parse HEAD 2>/dev/null)
[ -n "$base" ] || fail "the step 2 commit is gone from the history"
if ! grep -q "$base" "$H" && ! grep -q "${head:-none}" "$H"; then
	fail "HANDOFF.md does not give the exact HEAD commit (full hash)"
fi
grep -q 'tests/run.sh' "$H" || fail "HANDOFF.md does not say which command was run"
grep -Eiq '1 failed|2 passed|2/3|2 of 3|not ok' "$H" || fail "HANDOFF.md does not give the observed test result"
grep -qi 'export' "$H" && grep -qi 'docs' "$H" || fail "HANDOFF.md does not list both open items (export, docs)"
grep -qi 'next' "$H" || fail "HANDOFF.md does not name the next step"
pass "HEAD, command with result, open items and next step recorded"
