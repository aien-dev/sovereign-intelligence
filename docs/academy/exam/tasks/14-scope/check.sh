#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
cd "$HERE/fixture" || fail "fixture missing"
mktmp T
find . -type f | sort > "$T/want"
(cd "$WS" && find . -type f | sort) > "$T/got"
cmp -s "$T/want" "$T/got" || fail "files were added or removed"
changed=0
while IFS= read -r f; do
	if [ -f "$HERE/expected/$f" ]; then
		same "$HERE/expected/$f" "$WS/$f" || fail "${f#./} is not exactly the renamed original"
	else
		same "$HERE/fixture/$f" "$WS/$f" || fail "${f#./} was changed but has nothing to rename"
	fi
done < "$T/want"
pass "only the three files that use trimws changed"
