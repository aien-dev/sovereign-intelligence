#!/bin/sh
# test.sh: tests for words.sh
cd "$(dirname "$0")" || exit 1
. ./words.sh
failed=0
check() {
	got=$(count_words "$1")
	if [ "$got" -eq "$2" ]; then echo "ok '$1' = $2"; else echo "FAIL '$1': got $got, want $2"; failed=$((failed + 1)); fi
}
check "one two three" 3
check "word" 1
echo "$failed failed"
[ "$failed" -eq 0 ]
