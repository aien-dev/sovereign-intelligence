#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: no network during install.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar. Host run with a signed test
#   release on a free high 127.0.0.1 port and a fake GB10 probe root. The host cannot take its
#   own network away without root (no unprivileged user namespaces here), so "no network" is
#   simulated per request: (a) nothing listens on the release port (connection refused), (b) the
#   bundle is missing on the server (HTTP 404 after SHA256SUMS and the signature came down),
#   (c) the connection drops halfway through the bundle (short body under a full Content-Length),
#   (d) bootstrap done, then the model server goes away before the wizard downloads the model.
# Expected result: (a)-(c) install.sh exits 2 with "Could not download", the home folder stays
#   empty and no temporary folder is left. (d) the wizard exits non-zero, keeps no model file and
#   no ".aienos-verified" marker, and starts no engine.
# Negative control: with the server up, the same bootstrap installs and the wizard verifies the
#   model (opposite verdict).
# Status: EXERCISED(host). Stock DGX Spark with its network cable out or DNS failing: NOT_RUN.
#
# usage: OMC=... sh no-network.sh [SCRATCH]
set -u
FP_NAME=no-network
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-net.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve
fp_compile "$S/bin" "$(fp_port)" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
fp_release good "$S/bin"
mkdir -p "$S/www/nobundle"; cp "$S/www/good"/* "$S/www/nobundle/"; rm "$S/www/nobundle/$BUNDLE"

# (a) connection refused: a free port with nothing on it.
dead=$(fp_port)
h=$(fp_home refused)
env HOME="$h" AIENOS_PROBE_ROOT="$(fp_root gb10)" AIENOS_BASE_URL="http://127.0.0.1:$dead/good" \
    AIENOS_NO_WIZARD=1 TMPDIR="$S/tmp" sh "$S/www/good/install.sh" > "$S/refused.out" 2>&1; rc=$?
check "refused: install.sh exit 2 (got $rc)" "$([ $rc -eq 2 ]; echo $?)"
grep -q "Could not download" "$S/refused.out"; check "refused: says Could not download" $?
fp_untouched "$h"; check "refused: home folder untouched" $?

# (b) the bundle is missing on the server.
h=$(fp_home nobundle)
fp_boot "$h" nobundle > "$S/nobundle.out" 2>&1; rc=$?
check "nobundle: install.sh exit 2 (got $rc)" "$([ $rc -eq 2 ]; echo $?)"
grep -q "Could not download.*$BUNDLE" "$S/nobundle.out"; check "nobundle: names the bundle" $?
fp_untouched "$h"; check "nobundle: home folder untouched" $?

# (c) the connection drops halfway through the bundle.
cut=$(fp_port)
python3 - "$cut" "$S/www/good" "$BUNDLE" > "$S/cut-server.log" 2>&1 <<'EOF' &
import http.server, os, sys
port, root, bundle = int(sys.argv[1]), sys.argv[2], sys.argv[3]
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        name = os.path.basename(self.path)
        data = open(os.path.join(root, name), 'rb').read()
        self.send_response(200)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data[: len(data) // 2] if name == bundle else data)
        self.close_connection = True
http.server.HTTPServer(('127.0.0.1', port), H).serve_forever()
EOF
cutsrv=$!
i=0; while ! curl -fs "http://127.0.0.1:$cut/SHA256SUMS" >/dev/null 2>&1; do i=$((i + 1)); [ $i -lt 50 ] || break; sleep 0.1; done
h=$(fp_home cut)
env HOME="$h" AIENOS_PROBE_ROOT="$(fp_root gb10)" AIENOS_BASE_URL="http://127.0.0.1:$cut" \
    AIENOS_NO_WIZARD=1 TMPDIR="$S/tmp" sh "$S/www/good/install.sh" > "$S/cut.out" 2>&1; rc=$?
kill $cutsrv 2>/dev/null
check "cut: install.sh exit 2 (got $rc)" "$([ $rc -eq 2 ]; echo $?)"
grep -q "Could not download.*$BUNDLE" "$S/cut.out"; check "cut: names the bundle" $?
fp_untouched "$h"; check "cut: home folder untouched" $?
[ -z "$(ls -A "$S/tmp")" ]; check "no temporary folder left in TMPDIR" $?

# Negative control for (a)-(c): the same bootstrap with the server up installs.
hg=$(fp_home good)
fp_boot "$hg" good > "$S/good.out" 2>&1; rc=$?
ctl=same
if [ $rc -eq 0 ] && fp_installed "$hg"; then ctl=opposite; fi
check "negative control (server up: installs and verifies): $ctl" "$([ $ctl = opposite ]; echo $?)"

# (d) bootstrap done, then the network goes before the wizard fetches the model.
ALL='\n\n\nyes\n\n\n\n\n\n\n'
h=$(fp_home wiznet)
fp_boot "$h" good > "$S/wiznet-boot.out" 2>&1
kill "$FP_SRV"; wait "$FP_SRV" 2>/dev/null; FP_SRV=
printf '%b' "$ALL" | env HOME="$h" AIENOS_PROBE_ROOT="$(fp_root gb10)" TMPDIR="$S/tmp" \
    timeout 300 "$h/.local/share/aienos/current/bin/aienos" wizard --plain > "$S/wiznet.out" 2>&1; rc=$?
m=$h/.local/share/aienos/models/test-model
check "wiznet: wizard exit non-zero (got $rc)" "$([ $rc -ne 0 ]; echo $?)"
[ ! -e "$m/weights.bin" ] && [ ! -e "$m/.aienos-verified" ]; check "wiznet: no model file, no verified marker" $?
grep -q "The download or a hash check failed" "$S/wiznet.out"; check "wiznet: says the download failed" $?
[ ! -e "$h/.local/share/aienos/engine.pid" ]; check "wiznet: no engine started" $?
env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" stop > /dev/null 2>&1
# Its control: the server back, the same wizard input downloads and verifies the model.
fp_serve_again() {
    python3 -m http.server "$FP_HTTP" --bind 127.0.0.1 --directory "$S/www" > "$S/http2.log" 2>&1 &
    FP_SRV=$!
    i=0; while ! curl -fs "http://127.0.0.1:$FP_HTTP/" >/dev/null 2>&1; do i=$((i + 1)); [ $i -lt 50 ] || break; sleep 0.1; done
}
fp_serve_again
printf '%b' "$ALL" | env HOME="$h" AIENOS_PROBE_ROOT="$(fp_root gb10)" TMPDIR="$S/tmp" \
    timeout 300 "$h/.local/share/aienos/current/bin/aienos" wizard --plain > "$S/wiznet-ctl.out" 2>&1; rc=$?
env HOME="$h" "$h/.local/share/aienos/current/bin/aienos" stop > /dev/null 2>&1
ctl2=same
if [ $rc -eq 0 ] && [ -f "$m/.aienos-verified" ] && cmp -s "$m/weights.bin" "$S/www/model/weights.bin"; then ctl2=opposite; fi
check "negative control (wizard with the server back verifies the model): $ctl2" "$([ $ctl2 = opposite ]; echo $?)"
fp_result "EXERCISED(host) cases=refused,nobundle,cut,wizard-model control=$ctl/$ctl2 spark=NOT_RUN"
