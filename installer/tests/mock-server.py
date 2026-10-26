#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Test stand-ins for tests/onboarding.sh only (a test oracle, not part of the installer).
#
# Run through a link named vllm, llama-server or ollama, it pretends to be that model server:
#   vllm serve MODEL [--port N] [--served-model-name ID]   GET /v1/models -> {"data":[{"id":ID}]}
#   llama-server -m FILE [--port N]                          GET /v1/models, /health
#   ollama serve                                             port from OLLAMA_HOST, GET /api/tags
# It answers /health with 200, writes "ready pid N" to stdout, and exits 0 on SIGTERM after
# finishing the request in flight. It never loads a model.
#
# Run as mock-server.py files DIR PORT LOG: a static file server with byte ranges (curl -C -),
# one line per request in LOG ("GET /path range=bytes=N-").
# Run as mock-server.py whoami PORT TOKEN: GET /api/whoami-v2 answers 200 when the request
# carries "Authorization: Bearer TOKEN", else 401, like huggingface.co.
import http.server
import json
import os
import signal
import sys
import threading


def arg(argv, name, default=None):
    for i, a in enumerate(argv):
        if a == name and i + 1 < len(argv):
            return argv[i + 1]
        if a.startswith(name + "="):
            return a[len(name) + 1:]
    return default


class Quiet(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"

    def log_message(self, *a):
        pass

    def reply(self, code, body, ctype="application/json"):
        b = body.encode() if isinstance(body, str) else body
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(b)))
        self.end_headers()
        self.wfile.write(b)


def serve_model(kind, argv):
    if kind == "vllm":
        rest = argv[argv.index("serve") + 1:] if "serve" in argv else []
        model = rest[0] if rest and not rest[0].startswith("-") else arg(argv, "--model", "none")
        mid = arg(argv, "--served-model-name", model)
        port = int(arg(argv, "--port", "8000"))
    elif kind == "llama-server":
        mid = arg(argv, "-m", "none")
        port = int(arg(argv, "--port", "8080"))
    else:
        mid = "llama3:8b"
        port = int(os.environ.get("OLLAMA_HOST", "127.0.0.1:11434").rsplit(":", 1)[1])

    class H(Quiet):
        def do_GET(self):
            if self.path == "/v1/models":
                self.reply(200, json.dumps({"object": "list", "data": [{"id": mid, "object": "model"}]}))
            elif self.path == "/api/tags":
                self.reply(200, json.dumps({"models": [{"name": mid}]}))
            elif self.path == "/health":
                self.reply(200, "{}")
            else:
                self.reply(404, "{}")

    srv = http.server.HTTPServer(("127.0.0.1", port), H)
    signal.signal(signal.SIGTERM, lambda *a: threading.Thread(target=srv.shutdown).start())
    print("ready pid %d port %d id %s" % (os.getpid(), port, mid), flush=True)
    srv.serve_forever()
    srv.server_close()
    print("stopped by SIGTERM", flush=True)


def serve_files(root, port, log):
    class H(Quiet):
        def do_GET(self):
            rng = self.headers.get("Range", "")
            with open(log, "a") as f:
                f.write("GET %s range=%s\n" % (self.path, rng))
            p = os.path.join(root, self.path.lstrip("/"))
            if ".." in self.path or not os.path.isfile(p):
                return self.reply(404, "missing")
            data = open(p, "rb").read()
            if rng.startswith("bytes=") and rng.endswith("-"):
                start = int(rng[6:-1])
                if start >= len(data):
                    self.send_response(416)
                    self.send_header("Content-Range", "bytes */%d" % len(data))
                    self.send_header("Content-Length", "0")
                    self.end_headers()
                    return
                self.send_response(206)
                self.send_header("Content-Range", "bytes %d-%d/%d" % (start, len(data) - 1, len(data)))
                self.send_header("Content-Length", str(len(data) - start))
                self.end_headers()
                self.wfile.write(data[start:])
                return
            self.reply(200, data, "application/octet-stream")

    http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()


def serve_whoami(port, token):
    class H(Quiet):
        def do_GET(self):
            ok = self.path == "/api/whoami-v2" and self.headers.get("Authorization") == "Bearer " + token
            self.reply(200 if ok else 401, '{"name":"tester"}' if ok else '{"error":"Invalid credentials"}')

    http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()


def main():
    me = os.path.basename(sys.argv[0])
    if me in ("vllm", "llama-server", "ollama"):
        serve_model(me, sys.argv[1:])
    elif len(sys.argv) == 5 and sys.argv[1] == "files":
        serve_files(sys.argv[2], int(sys.argv[3]), sys.argv[4])
    elif len(sys.argv) == 4 and sys.argv[1] == "whoami":
        serve_whoami(int(sys.argv[2]), sys.argv[3])
    else:
        sys.exit("usage: see the header of mock-server.py")


if __name__ == "__main__":
    main()
