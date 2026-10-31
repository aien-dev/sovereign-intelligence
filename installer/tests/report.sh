#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# aienos doctor --report: archive contents, privacy and no network (host test, fake prefix).
#
#   AIENOS=path/to/compiled/aienos sh tests/report.sh SCRATCH
#
# Builds a fake install under SCRATCH/home (bin/aienos copied into a release folder with its own
# SHA256SUMS), plants canary secrets and chat content where a careless report would pick them up,
# then runs "aienos doctor --report" inside bubblewrap with no network namespace access, under
# strace. Checks: exact member list, gzip integrity, no CANARY byte anywhere in the archive, the
# allowed engine line and the ~ redaction kept, zero socket/connect calls, a second run to the same
# path refused. Negative controls: a plain tar of the prefix does contain the canaries, and the same
# strace filter does count the socket call of a curl run in the same sandbox.
set -u
: "${AIENOS:?set AIENOS to a compiled aienos}"
S=${1:?usage: report.sh SCRATCH}
here=$(cd "$(dirname "$0")" && pwd)
rm -rf "$S"
mkdir -p "$S"
S=$(cd "$S" && pwd)
pass=0
fail=0
ok() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1"; }

# socket/connect calls made after the program under test was exec'd (bwrap's own setup, an AF_UNIX
# and an AF_NETLINK socket to bring up lo in the new network namespace, comes before that execve).
socks() { awk -v prog="$2" 'index($0, "execve(\"") && index($0, prog "\"") { on = 1 } on && /(socket|connect)\(/ { n++ } END { print n + 0 }' "$1"; }

h=$S/home
b=$h/.local/share/aienos
r=$b/releases/alpha-test
mkdir -p "$r/bin" "$b/lend" "$h/.cache/huggingface" "$S/out"
cp "$AIENOS" "$r/bin/aienos"
printf 'AienOS alpha-test\n' > "$r/VERSION"
(cd "$r" && sha256sum bin/aienos VERSION > SHA256SUMS)
ln -s "releases/alpha-test" "$b/current"
sh "$here/fake-root.sh" "$S/root" gb10 > /dev/null

printf '=== install.sh alpha-test 2026-10-31T00:00:00Z\ninstalled into %s\nexport HF_TOKEN=CANARY1\n' "$r" > "$b/install.log"
printf 'curl: (6) Could not resolve host\nhttps://example.invalid/x?token=CANARY2\n' > "$b/download.log"
{
    printf 'aien-serve-http: serving at http://127.0.0.1:18100/v1\n'
    printf 'aien-serve-http: tokenizer from %s/models/x\n' "$h"
    printf 'aien-serve-http: chatcmpl-CANARY3: prompt 12 tok\n'
    printf 'aien-serve-http: header Authorization: Bearer CANARY4\n'
    printf '{"messages":[{"role":"user","content":"CANARY5"}]}\n'
} > "$b/engine.log"
printf '{"q":"CANARY6"}\n' > "$b/chat-history.jsonl"
printf 'CANARY7\n' > "$b/token"
printf 'CANARY8\n' > "$b/lend/key"
printf 'CANARY9\n' > "$h/.cache/huggingface/token"

out=$S/out/report.tar.gz
strace -f -qq -o "$S/strace.log" -e trace=socket,connect,execve \
    bwrap --dev-bind / / --unshare-net \
    env HOME="$h" AIENOS_PROBE_ROOT="$S/root" "$r/bin/aienos" doctor --report "$out" > "$S/run.txt" 2>&1
rc=$?
[ "$rc" -eq 0 ] && [ -s "$out" ] && ok "report written (rc=$rc)" || no "report written (rc=$rc)"
gzip -t "$out" 2> /dev/null && ok "gzip integrity" || no "gzip integrity"
want='aienos-report/README.txt
aienos-report/versions.txt
aienos-report/system.txt
aienos-report/doctor.txt
aienos-report/checksums.txt
aienos-report/service.txt
aienos-report/logs.txt'
have=$(tar -tzf "$out")
[ "$have" = "$want" ] && ok "member list" || no "member list: $(printf '%s' "$have" | tr '\n' ' ')"
mkdir -p "$S/x"
tar -xzf "$out" -C "$S/x"
n=$(gzip -dc "$out" | grep -ac CANARY)
[ "$n" -eq 0 ] && ok "no canary in archive" || no "canary lines in archive: $n"
gzip -dc "$out" | grep -aq "$h" && no "home path in archive" || ok "home path redacted"
grep -q 'serving at http://127.0.0.1:18100/v1' "$S/x/aienos-report/logs.txt" && ok "allowed engine line kept" || no "allowed engine line kept"
grep -q 'tokenizer from ~/models/x' "$S/x/aienos-report/logs.txt" && ok "home written as ~" || no "home written as ~"
grep -q '^files: 2 ok, 0 changed, 0 missing$' "$S/x/aienos-report/checksums.txt" && ok "checksums" || no "checksums"
grep -q '580.173.02' "$S/x/aienos-report/system.txt" && ok "driver string" || no "driver string"
s=$(socks "$S/strace.log" /bin/aienos)
[ "$s" -eq 0 ] && ok "no socket or connect call" || no "socket/connect calls: $s"
env HOME="$h" AIENOS_PROBE_ROOT="$S/root" "$r/bin/aienos" doctor --report "$out" > /dev/null 2>&1
[ $? -eq 1 ] && ok "existing file refused" || no "existing file refused"

# Negative controls: the canaries are where a plain copy finds them, and the strace filter sees sockets.
c=$(tar -czf - -C "$h" . | gzip -dc | grep -ac CANARY)
[ "$c" -ge 9 ] && ok "control: plain tar of the prefix holds the canaries ($c)" || no "control: canaries ($c)"
strace -f -qq -o "$S/strace-ctl.log" -e trace=socket,connect,execve \
    bwrap --dev-bind / / --unshare-net curl -s -m 2 http://127.0.0.1:1/ > /dev/null 2>&1
s=$(socks "$S/strace-ctl.log" /curl)
[ "$s" -gt 0 ] && ok "control: strace counts curl's socket calls ($s)" || no "control: strace saw no socket"
printf 'REPORT-TESTS pass=%s fail=%s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
