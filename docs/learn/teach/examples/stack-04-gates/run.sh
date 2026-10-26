#!/bin/sh
# stack-04-gates: two gates for "the installer installs one explicit release". Each gate runs on the
# real SI installer/install.sh (must PASS) and on two mutants of it (must FAIL). A gate that accepts
# a mutant has failed its negative control and is refused as a gate.
set -u
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
PIN=befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
got=$(sha256sum "$OMC" | cut -d' ' -f1)
if [ "$got" != "$PIN" ]; then
    echo "omc sha256 is not the pin $PIN"
    exit 90
fi
echo "omc sha256 $PIN"
tmp=$(mktemp -d) || exit 2
trap 'rm -rf "$tmp"' EXIT

for g in pingate pingate_weak; do
    cat "$here/lib.om" "$here/$g.om" > "$tmp/unit.om"
    "$OMC" < "$tmp/unit.om" > "$tmp/$g" 2> "$tmp/err"
    rc=$?
    echo "compile lib.om+$g.om rc=$rc"
    cat "$tmp/err"
    [ "$rc" -eq 0 ] || exit 1
    chmod +x "$tmp/$g"
done

real=$SRC/sovereign-intelligence/installer/install.sh
echo "input install.sh sha256 $(sha256sum "$real" | cut -d' ' -f1)"
cp "$real" "$tmp/good.sh"
sed 's/^TAG=alpha-20261026\.1$/TAG=latest/' "$real" > "$tmp/mut-tag.sh"
echo "mutant mut-tag.sh differs: $(cmp -s "$real" "$tmp/mut-tag.sh" && echo no || echo yes) (TAG=latest)"
sed 's|releases/download/\$TAG|releases/latest/download|' "$real" > "$tmp/mut-url.sh"
echo "mutant mut-url.sh differs: $(cmp -s "$real" "$tmp/mut-url.sh" && echo no || echo yes) (downloads from releases/latest)"

status=0
for g in pingate pingate_weak; do
    caught=yes
    for input in good mut-tag mut-url; do
        echo "== $g < $input.sh"
        "$tmp/$g" < "$tmp/$input.sh"
        rc=$?
        echo "run rc=$rc"
        if [ "$input" = good ]; then
            [ "$rc" -eq 0 ] || caught=no
        else
            [ "$rc" -ne 0 ] || caught=no
        fi
    done
    if [ "$caught" = yes ]; then
        echo "$g: accepts the real input and rejects every negative control: usable as a gate"
    else
        echo "$g: a negative control was accepted: REFUSED as a gate (it proves nothing)"
    fi
    case "$g:$caught" in
        pingate:yes|pingate_weak:no) ;;
        *) status=1 ;;
    esac
done
echo "every verdict as expected: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
