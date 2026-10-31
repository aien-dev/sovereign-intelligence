#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: the engine's port is already in use.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar. The shipped wizard and engine
#   use 127.0.0.1:18100. This host run never binds 18100 (nor 18091 or 18300): it builds a test
#   wizard and tests/fake-engine.om with PORT replaced by a free high port EP (the only source
#   change), installs that test release into a scratch home on a fake GB10 probe root, and puts
#   another program on EP first:
#   (a) a program that accepts connections but does not answer /health (not HTTP);
#   (b) an HTTP server that answers GET /health with 200, i.e. it looks like an engine.
# Expected result: in both cases `aienos start` exits 1 and says the port is used by another
#   program; it does not report "engine ready", leaves no engine.pid and no engine process, and the
#   other program keeps running untouched. `aienos chat` on (b) sends no question to the other
#   program (its request log shows only connection probes, no POST).
# Negative control: with EP free, `aienos start` starts the fake engine and says "engine ready"
#   (opposite verdict); `aienos stop` stops it.
# Status: EXERCISED(host, test build on a high port, fake engine). The real aien-serve-http on a
#   stock DGX Spark with 18100 taken: NOT_RUN.
#
# usage: OMC=... sh port-in-use.sh [SCRATCH]
set -u
FP_NAME=port-in-use
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-port.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve
EP=$(fp_port)
fp_compile "$S/bin" "$EP" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
fp_release good "$S/bin"
h=$(fp_home port)
fp_boot "$h" good > "$S/boot.out" 2>&1
a=$h/.local/share/aienos/current/bin/aienos
R=$(fp_root gb10)
enginepids() { pgrep -f "^$h/.local/share/aienos/.*aien-serve-http" 2>/dev/null; }

# occupy KIND: another program on EP. tcp = accept and say nothing; http = 200 on every GET.
occupy() {
    python3 - "$EP" "$1" "$S/occupier-$1.log" <<'EOF' &
import http.server, socket, sys
port, kind, log = int(sys.argv[1]), sys.argv[2], sys.argv[3]
out = open(log, 'a', buffering=1)
if kind == 'tcp':
    s = socket.socket(); s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind(('127.0.0.1', port)); s.listen(16)
    while True:
        c, _ = s.accept(); out.write('connect\n'); c.close()
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        out.write('GET %s\n' % self.path)
        b = b'{"status":"ok"}'
        self.send_response(200); self.send_header('Content-Length', str(len(b))); self.end_headers()
        self.wfile.write(b)
    def do_POST(self):
        out.write('POST %s\n' % self.path)
        self.send_response(500); self.send_header('Content-Length', '0'); self.end_headers()
    def log_message(self, *a): pass
http.server.HTTPServer(('127.0.0.1', port), H).serve_forever()
EOF
    OCC=$!
    i=0
    while ! python3 -c 'import socket,sys; s=socket.socket(); sys.exit(s.connect_ex(("127.0.0.1",int(sys.argv[1]))))' "$EP"; do
        i=$((i + 1)); [ $i -lt 50 ] || break; sleep 0.1
    done
}

for kind in tcp http; do
    occupy "$kind"
    env HOME="$h" AIENOS_PROBE_ROOT="$R" timeout 120 "$a" start > "$S/start-$kind.out" 2>&1; rc=$?
    check "$kind: aienos start exit 1 (got $rc)" "$([ $rc -eq 1 ]; echo $?)"
    grep -q "used by another program" "$S/start-$kind.out"; check "$kind: says the port is used by another program" $?
    ! grep -q "engine ready" "$S/start-$kind.out"; check "$kind: does not say engine ready" $?
    [ ! -e "$h/.local/share/aienos/engine.pid" ] && [ -z "$(enginepids)" ]; check "$kind: no engine.pid, no engine process" $?
    if [ "$kind" = http ]; then
        printf 'secret question\n/bye\n' | env HOME="$h" AIENOS_PROBE_ROOT="$R" timeout 120 "$a" chat > "$S/chat-http.out" 2>&1
        ! grep -q '^POST' "$S/occupier-http.log"; check "http: aienos chat sent no question to the other program" $?
    fi
    kill -0 "$OCC" 2>/dev/null; check "$kind: the other program still runs" $?
    kill "$OCC" 2>/dev/null; wait "$OCC" 2>/dev/null
    env HOME="$h" "$a" stop > /dev/null 2>&1
done

# Negative control: the port is free.
env HOME="$h" AIENOS_PROBE_ROOT="$R" timeout 120 "$a" start > "$S/start-free.out" 2>&1; rc=$?
ctl=same
if [ $rc -eq 0 ] && grep -q "engine ready" "$S/start-free.out" && [ -n "$(enginepids)" ]; then ctl=opposite; fi
env HOME="$h" "$a" stop > "$S/stop-free.out" 2>&1
[ -z "$(enginepids)" ]; check "control: aienos stop stops the engine" $?
check "negative control (port free: engine starts): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host, test build on port $EP) cases=tcp,http control=$ctl spark=NOT_RUN"
