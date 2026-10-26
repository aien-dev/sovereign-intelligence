#!/bin/sh
HERE=$(cd "$(dirname "$0")" && pwd)
. "$HERE/../../lib.sh"
init "$1"
same "$HERE/fixture/test.sh" "$WS/test.sh" || fail "test.sh was changed"
mktmp T
cp -R "$WS/." "$T/"
cat > "$T/hidden.sh" << 'EOF'
cd "$(dirname "$0")" || exit 1
. ./words.sh
t() { got=$(count_words "$1"); [ "$got" -eq "$2" ] || exit 1; }
t "one two three" 3
t "two  spaces" 2
t "" 0
t "  leading and trailing  " 3
t "tab	separated" 2
t "word" 1
exit 0
EOF
limited 20 sh "$T/hidden.sh" > "$T/grader.out" 2>&1 && pass "bug fixed"
[ -f "$WS/ISSUE.md" ] && fail "only filed an issue; the bug is still there"
fail "count_words is still wrong for repeated, leading or trailing blanks"
