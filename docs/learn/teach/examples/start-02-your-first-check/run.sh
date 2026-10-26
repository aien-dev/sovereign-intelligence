#!/bin/sh
# start-02-your-first-check: two word counters an agent might write, a real check (expected vs observed) and a weak check that cannot fail.
# Host-only (Linux AArch64): no GPU, no network, no live service.
# Env: SRC = directory of the pinned clones, OMC = pinned omc (sha256 checked, exit 90 on mismatch).
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" 2>/dev/null | cut -d ' ' -f 1)
if [ "$got" != "$PIN" ]; then
    printf 'omc sha256 does not match the pin, refusing to run\n'
    exit 90
fi
printf 'omc sha256 %s (matches pin)\n' "$PIN"
work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT
bad=0
build() {
    "$OMC" < "$here/$1.om" > "$work/$1" 2> "$work/err"
    rc=$?
    printf 'compile %s.om rc=%s (expected %s)\n' "$1" "$rc" "$2"
    cat "$work/err"
    if [ "$rc" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
    chmod +x "$work/$1" || exit 2
}
run() {
    printf '\n--- input %s\n' "$2"
    cat "$here/$2"
    printf -- '--- output\n'
    "$work/$1" < "$here/$2"
    rc=$?
    printf 'run rc=%s (expected %s)\n' "$rc" "$3"
    if [ "$rc" -ne "$3" ]; then
        bad=$((bad + 1))
    fi
}
build wc1 0
build wc2 0
check() {
    printf '\n== %s: real check, expected vs observed\n' "$1"
    miss=0
    for t in one-space:2 two-spaces:2 empty:0 three-lines:5; do
        f=${t%%:*}
        want=${t#*:}
        got=$("$work/$1" < "$here/$f.txt")
        if [ "$got" = "$want" ]; then
            v=MATCH
        else
            v=MISMATCH
            miss=$((miss + 1))
        fi
        printf '%-16s expected=%s observed=%s %s\n' "$f.txt" "$want" "$got" "$v"
    done
    if [ "$miss" -eq 0 ]; then
        printf '%s: CHECK PASS\n' "$1"
    else
        printf '%s: CHECK FAIL mismatches=%s\n' "$1" "$miss"
    fi
    if [ "$miss" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
}
printf '\ninputs (_ is a space, | is the end of a line):\n'
for f in one-space two-spaces empty three-lines; do
    v=$(tr ' \n' '_|' < "$here/$f.txt")
    if [ -z "$v" ]; then
        v='(empty file)'
    fi
    printf '%-16s %s\n' "$f.txt" "$v"
done
check wc1 3
check wc2 0
printf '\n== weak check: did it exit 0?\n'
for p in wc1 wc2; do
    "$work/$p" < "$here/two-spaces.txt" > /dev/null
    rc=$?
    if [ "$rc" -eq 0 ]; then
        printf '%s: exit 0, weak check says PASS (it cannot tell the two apart)\n' "$p"
    else
        printf '%s: exit %s\n' "$p" "$rc"
        bad=$((bad + 1))
    fi
done

printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
