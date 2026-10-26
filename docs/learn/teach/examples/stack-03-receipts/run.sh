#!/bin/sh
# stack-03-receipts: verify the kept receipt.txt for hello.om by recomputing every field, then show two
# negative controls: a one-byte change to the source (FAIL) and a receipt with its limits line cut
# (REFUSED). The checker, rcptchk.om, is compiled with the pinned omc; sha256sum is the hash oracle.
# "sh run.sh record" rewrites receipt.txt from a fresh run (done once, when the receipt was kept).
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
h() { sha256sum "$1" | cut -d' ' -f1; }

# mkreceipt SOURCE OUT: compile SOURCE, run it once, write the 13-line receipt to OUT.
mkreceipt() {
    "$OMC" < "$1" > "$tmp/hello" 2> "$tmp/hello.err"
    crc=$?
    if [ "$crc" -ne 0 ]; then
        echo "compile hello rc=$crc"
        cat "$tmp/hello.err"
        return 1
    fi
    chmod +x "$tmp/hello"
    (cd "$tmp" && ./hello < /dev/null > "$tmp/stdout")
    orc=$?
    {
        echo "receipt 1"
        echo "program hello.om"
        echo "omega_mv 19f014f2178ca9cd3473728fe00a475a2398c409"
        echo "omc_sha256 $(h "$OMC")"
        echo "source_sha256 $(h "$1")"
        echo "binary_sha256 $(h "$tmp/hello")"
        echo "command ./hello < /dev/null"
        echo "platform linux-aarch64 host, no GPU device opened"
        echo "expect_exit 0"
        echo "observed_exit $orc"
        echo "expect_stdout_sha256 $(h "$here/expected.txt")"
        echo "observed_stdout_sha256 $(h "$tmp/stdout")"
        echo "limits host only; one run; not hardware qualification"
    } > "$2"
}

if [ "${1:-}" = record ]; then
    mkreceipt "$here/hello.om" "$here/receipt.txt" || exit 1
    echo "recorded receipt.txt"
    exit 0
fi

cat "$here/lib.om" "$here/rcptchk.om" > "$tmp/unit.om"
"$OMC" < "$tmp/unit.om" > "$tmp/rcptchk" 2> "$tmp/err"
rc=$?
echo "compile lib.om+rcptchk.om rc=$rc"
cat "$tmp/err"
[ "$rc" -eq 0 ] || exit 1
chmod +x "$tmp/rcptchk"

echo "== the kept receipt"
cat "$here/receipt.txt"

status=0
check() {
    # check KEPT FRESH WANT_RC
    { cat "$1"; echo "--"; cat "$2"; } | "$tmp/rcptchk" > "$tmp/out"
    rc=$?
    cat "$tmp/out"
    echo "run rc=$rc"
    [ "$rc" -eq "$3" ] || status=1
}

echo "== verify: recompute every field from hello.om and compare"
mkreceipt "$here/hello.om" "$tmp/fresh.txt" || exit 1
check "$here/receipt.txt" "$tmp/fresh.txt" 0

echo "== negative control: hello.om with one byte changed (mine -> Mine)"
sed 's/mine/Mine/' "$here/hello.om" > "$tmp/mutant.om"
mkreceipt "$tmp/mutant.om" "$tmp/fresh2.txt" || exit 1
check "$here/receipt.txt" "$tmp/fresh2.txt" 1

echo "== negative control: the kept receipt with its limits line removed"
grep -v '^limits ' "$here/receipt.txt" > "$tmp/cut.txt"
check "$tmp/cut.txt" "$tmp/fresh.txt" 4

echo "every verdict as expected: $([ "$status" -eq 0 ] && echo yes || echo no)"
exit "$status"
