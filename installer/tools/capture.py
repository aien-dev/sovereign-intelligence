#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Record a real terminal session of the wizard for the documentation.

Runs bin/aienos in a pseudo-terminal of a fixed size, types the answers with pauses so the
animation runs between them, and writes every byte the wizard printed to OUT.ans. Documentation
tooling only; it is not part of the installed product.

usage: capture.py AIENOS_BINARY OUT.ans COLS ROWS [--tour] [ENV=VALUE ...]
"""
import os
import pty
import select
import struct
import sys
import time
import fcntl
import termios

# (seconds to let the animation run, then the line to type)
SCRIPT = [
    (4.0, ""),       # welcome
    (3.0, ""),       # doctor
    (3.0, ""),       # plan
    (2.0, "yes"),    # your yes
    (4.0, ""),       # install: every file hashed in Omega
    (3.0, ""),       # model
    (3.0, ""),       # first chat
    (3.0, ""),       # done
]
# The short tour for the web page: welcome, doctor, plan, then "no" at the question.
TOUR = [(4.0, ""), (3.0, ""), (4.0, ""), (3.0, "no")]


def main():
    binary, out, cols, rows = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    env = {"PATH": "/usr/bin:/bin", "TERM": "xterm-256color"}
    steps = SCRIPT
    for kv in sys.argv[5:]:
        if kv == "--tour":
            steps = TOUR
            continue
        k, v = kv.split("=", 1)
        env[k] = v
    pid, fd = pty.fork()
    if pid == 0:
        os.execve(binary, [binary, "wizard"], env)
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, cols, 0, 0))
    data = bytearray()

    def pump(seconds):
        end = time.time() + seconds
        while time.time() < end:
            r, _, _ = select.select([fd], [], [], 0.05)
            if r:
                try:
                    chunk = os.read(fd, 65536)
                except OSError:
                    return False
                if not chunk:
                    return False
                data.extend(chunk)
        return True

    for wait, line in steps:
        if not pump(wait):
            break
        os.write(fd, (line + "\n").encode())
    pump(3.0)
    try:
        os.kill(pid, 15)
    except ProcessLookupError:
        pass
    _, status = os.waitpid(pid, 0)
    open(out, "wb").write(bytes(data))
    print(f"bytes={len(data)} status={status}", file=sys.stderr)


if __name__ == "__main__":
    main()
