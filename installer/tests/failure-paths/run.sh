#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure-path runner (DRA-53): runs the eleven failure-path scripts and prints one line per path:
#   PASS|FAIL|NOT_RUN  <path>  <evidence level and cases, negative control, stock-Spark status>
# then one summary line. Exit 0 when nothing failed, 1 otherwise. Not wired into CI: it builds
# test releases, serves them on 127.0.0.1 and starts the fake engine on a free high port, so run
# it by hand on a CPU-only host:
#   OMC=/path/to/pinned/omc sh installer/tests/failure-paths/run.sh [SCRATCH]
# Each script's own log is SCRATCH/<path>.log. A run on a stock DGX Spark is NOT_RUN for every
# path; these are host results, never hardware results.
set -u
here=$(cd "$(dirname "$0")" && pwd)
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-failure-paths.XXXXXX")}
mkdir -p "$S"
pass=0 fail=0 notrun=0
for p in disk-full no-network wrong-gpu-driver interrupted-install bad-signature port-in-use uninstall-partial \
        model-resume model-corrupt rollback-clean stale-tmp; do
    sh "$here/$p.sh" "$S/$p" > "$S/$p.log" 2>&1; rc=$?
    line=$(sed -n "s/^RESULT $p [A-Z_]* //p" "$S/$p.log" | tail -n 1)
    case $rc in
        0) v=PASS; pass=$((pass + 1)) ;;
        3) v=NOT_RUN; notrun=$((notrun + 1)) ;;
        *) v=FAIL; fail=$((fail + 1)); [ -n "$line" ] || line="exit $rc, see $S/$p.log" ;;
    esac
    printf '%-8s %-20s %s\n' "$v" "$p" "$line"
done
printf 'SUMMARY pass=%s fail=%s not_run=%s stock-spark=NOT_RUN logs=%s\n' "$pass" "$fail" "$notrun" "$S"
[ $fail -eq 0 ]
