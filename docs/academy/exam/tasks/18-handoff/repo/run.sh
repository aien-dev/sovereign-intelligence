#!/bin/sh
# tests/run.sh: tests for csvtool.sh
cd "$(dirname "$0")/.." || exit 1
. ./csvtool.sh
n=0 bad=0
t() {
	n=$((n + 1))
	if eval "$2"; then echo "ok $n $1"; else echo "not ok $n $1"; bad=$((bad + 1)); fi
}
t parse '[ "$(parse a,b,c | wc -l | tr -d " ")" = 3 ]'
t validate 'validate a,b,c 3 && ! validate a,b 3'
t export '[ "$(export_row a,b)" = "[\"a\",\"b\"]" ]'
echo "$n tests, $((n - bad)) passed, $bad failed"
[ "$bad" -eq 0 ]
