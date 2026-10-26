#!/bin/sh
# omega-01-hello-world: compile hello.om with the pinned omc, run it, read its exit status.
# Host-only (Linux AArch64). Env: SRC (pinned clones), OMC (pinned compiler).
set -u
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" 2>/dev/null | cut -d' ' -f1)
[ "$got" = "$PIN" ] || { echo "omc sha256 mismatch (wanted $PIN)"; exit 90; }
echo "omc sha256 $PIN"
T=$(mktemp -d) || exit 2
trap 'rm -rf "$T"' EXIT HUP INT TERM
fail=0
# compile NAME: compile NAME.om into $T/NAME, print the status and the compiler's stderr.
compile() {
    "$OMC" < "$here/$1.om" > "$T/$1" 2> "$T/$1.err"
    crc=$?
    echo "compile $1.om rc=$crc"
    cat "$T/$1.err"
}
# want WHAT GOT EXPECTED: record a mismatch.
want() { [ "$2" = "$3" ] || { echo "UNEXPECTED $1: got $2, wanted $3"; fail=1; }; }

echo "== 1. hello: compile, then run only if the compile returned 0"
compile hello
want "hello compile" "$crc" 0
if [ "$crc" -eq 0 ]; then
    chmod +x "$T/hello"
    "$T/hello"
    rrc=$?
    echo "run rc=$rrc"
    want "hello run" "$rrc" 0
fi

echo "== 2. the exit status is main's value modulo 256"
compile status
want "status compile" "$crc" 0
chmod +x "$T/status"
"$T/status"
rrc=$?
echo "run rc=$rrc"
want "status run" "$rrc" 44

echo "== 3. negative control: a result that is not bound to a name"
compile unbound
want "unbound compile" "$crc" 16

[ "$fail" -eq 0 ] && echo "RESULT PASS" || echo "RESULT FAIL"
exit "$fail"
