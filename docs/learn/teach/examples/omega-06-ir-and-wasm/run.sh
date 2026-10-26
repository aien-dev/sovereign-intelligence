#!/bin/sh
# omega-06-ir-and-wasm: one .om source to AArch64 and, through OSC IR v1 and seed/wasm/irwasm.om, to WebAssembly.
# Host-only (Linux AArch64). node is used only to load and call the module. Env: SRC, OMC.
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
# compile NAME WANT: compile NAME.om into $T/NAME, print status and stderr, check the status.
compile() {
    "$OMC" < "$here/$1.om" > "$T/$1" 2> "$T/$1.err"
    crc=$?
    echo "compile $1.om rc=$crc"
    cat "$T/$1.err"
    want "$1 compile" "$crc" "$2"
}
# runit NAME WANT: run a program that compiled with 0 (never a refused one), check its status.
runit() {
    if [ "$crc" -ne 0 ]; then echo "run $1 NOT_RUN (compile refused)"; fail=1; return; fi
    chmod +x "$T/$1"
    "$T/$1"
    rrc=$?
    echo "run $1 rc=$rrc"
    want "$1 run" "$rrc" "$2"
}
want() { [ "$2" = "$3" ] || { echo "UNEXPECTED $1: got $2, wanted $3"; fail=1; }; }
finish() { [ "$fail" -eq 0 ] && echo "RESULT PASS" || echo "RESULT FAIL"; exit "$fail"; }

echo "== 1. native: fns.om + putnum.om + main.om concatenated into one program"
cat "$here/fns.om" "$here/putnum.om" "$here/main.om" > "$T/native.om"
"$OMC" < "$T/native.om" > "$T/native" 2> "$T/native.err"; crc=$?
echo "compile native rc=$crc"; cat "$T/native.err"
want "native compile" "$crc" 0
runit native 101

echo "== 2. IR: a leading 'ir' line makes omc write OSC IR v1 instead of machine code"
{ printf 'ir\n'; cat "$here/fns.om"; } | "$OMC" > "$T/fns.ir" 2> "$T/ir.err"; crc=$?
echo "compile ir rc=$crc"; cat "$T/ir.err"
want "ir compile" "$crc" 0
echo "IR magic: $(od -An -c -N 4 "$T/fns.ir" | tr -d ' ')"

echo "== 3. the WebAssembly back end is itself an Omega program: compile irwasm.om"
"$OMC" < "$SRC/omega-mv/seed/wasm/irwasm.om" > "$T/irwasm" 2> "$T/irwasm.err"; crc=$?
echo "compile irwasm.om rc=$crc"; cat "$T/irwasm.err"
want "irwasm compile" "$crc" 0
chmod +x "$T/irwasm"
"$T/irwasm" < "$T/fns.ir" > "$T/fns.wasm"; wrc=$?
"$T/irwasm" < "$T/fns.ir" > "$T/again.wasm"
echo "irwasm rc=$wrc"
want "irwasm run" "$wrc" 0
cmp -s "$T/fns.wasm" "$T/again.wasm" && echo "two translations identical: yes" || { echo "two translations identical: no"; fail=1; }
echo "fns.wasm sha256 $(sha256sum "$T/fns.wasm" | cut -d' ' -f1)"

echo "== 4. run the module (node as a read-only oracle)"
node "$here/call.js" "$T/fns.wasm"
nrc=$?
echo "node rc=$nrc"
want "node" "$nrc" 0

echo "== 5. negative control: IR mode refuses a global pool"
{ printf 'ir\n'; cat "$here/irglobal.om"; } | "$OMC" > /dev/null 2> "$T/g.err"; crc=$?
echo "compile ir irglobal rc=$crc"; cat "$T/g.err"
want "ir global" "$crc" 9

echo "== 6. negative control: irwasm refuses truncated IR and writes nothing"
size=$(wc -c < "$T/fns.ir")
dd if="$T/fns.ir" of="$T/cut.ir" bs=1 count=$((size - 1)) 2> /dev/null
"$T/irwasm" < "$T/cut.ir" > "$T/cut.wasm" 2> "$T/cut.err"; trc=$?
echo "irwasm truncated rc=$trc stdout bytes=$(wc -c < "$T/cut.wasm")"; cat "$T/cut.err"
want "irwasm truncated" "$trc" 22

echo "== 7. SPIR-V at this pin"
if [ -e "$SRC/omega-mv/seed/spirv" ]; then echo "seed/spirv: present"; else echo "seed/spirv: absent (proposed in an open pull request, not on this commit)"; fi
finish
