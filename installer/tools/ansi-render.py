#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Render a raw ANSI terminal capture of the wizard into text frames, an SVG, or a PNG.

Documentation tooling only: it is not part of the installed product and never runs on a user's
machine. It understands exactly the escapes the wizard emits: CUP (H), ED (2J), EL (K), SGR 0/1/
38;2/48;2, and the private modes ?1049 and ?25 (ignored). The wizard starts every frame with
a bare CUP (ESC [ H), which is where this tool cuts frames.

usage: ansi-render.py CAPTURE.ans COLS ROWS --txt OUT.txt [--svg OUT.svg] [--png OUT.png] [--frame N]
"""
import argparse
import html
import re
import sys

CSI = re.compile(rb"\x1b\[([?0-9;]*)([A-Za-z])")


class Screen:
    def __init__(self, cols, rows):
        self.cols, self.rows = cols, rows
        self.clear()
        self.r = self.c = 0
        self.fg = (220, 220, 220)
        self.bg = (0, 0, 0)
        self.bold = False

    def clear(self):
        self.cells = [[(" ", (220, 220, 220), (0, 0, 0)) for _ in range(self.cols)] for _ in range(self.rows)]

    def put(self, ch):
        if ch == "\n":
            self.r = min(self.r + 1, self.rows - 1)
            self.c = 0
            return
        if ch == "\r":
            self.c = 0
            return
        if 0 <= self.r < self.rows and 0 <= self.c < self.cols:
            self.cells[self.r][self.c] = (ch, self.fg, self.bg)
        self.c += 1
        if self.c >= self.cols:
            self.c = self.cols - 1

    def sgr(self, params):
        p = [int(x) if x else 0 for x in params.split(";")] if params else [0]
        i = 0
        while i < len(p):
            if p[i] == 0:
                self.fg, self.bg, self.bold = (220, 220, 220), (0, 0, 0), False
            elif p[i] == 1:
                self.bold = True
            elif p[i] in (38, 48) and i + 4 < len(p) and p[i + 1] == 2:
                col = (p[i + 2], p[i + 3], p[i + 4])
                if p[i] == 38:
                    self.fg = col
                else:
                    self.bg = col
                i += 4
            i += 1

    def text(self):
        return "\n".join("".join(ch for ch, _, _ in row).rstrip() for row in self.cells)


def frames(data, cols, rows):
    s = Screen(cols, rows)
    out = []
    pos = 0
    started = False
    for m in CSI.finditer(data):
        for ch in data[pos:m.start()].decode("utf-8", "replace"):
            s.put(ch)
        params, cmd = m.group(1).decode(), m.group(2).decode()
        if cmd == "J" and params == "2":
            # A screen that is about to be cleared is also a frame (the end of a step).
            if started and any(ch != " " for row in s.cells for ch, _, _ in row):
                out.append([row[:] for row in s.cells])
            s.clear()
        elif cmd == "H" and params == "":
            # A bare CUP is the wizard's frame marker: everything before it was one frame.
            if started:
                out.append([row[:] for row in s.cells])
            started = True
            s.r = s.c = 0
        elif cmd == "H":
            parts = params.split(";") if params else ["1", "1"]
            s.r = int(parts[0] or 1) - 1
            s.c = int(parts[1] or 1) - 1 if len(parts) > 1 else 0
        elif cmd == "K":
            for c in range(s.c, cols):
                if 0 <= s.r < rows:
                    s.cells[s.r][c] = (" ", s.fg, s.bg)
        elif cmd == "m":
            s.sgr(params)
        pos = m.end()
    for ch in data[pos:].decode("utf-8", "replace"):
        s.put(ch)
    out.append([row[:] for row in s.cells])
    return out


def as_text(cells):
    return "\n".join("".join(ch for ch, _, _ in row).rstrip() for row in cells)


def hexc(c):
    return "#%02x%02x%02x" % c


def as_svg(cells, cw=9, ch=18):
    rows, cols = len(cells), len(cells[0])
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{cols*cw}" height="{rows*ch}" '
         f'viewBox="0 0 {cols*cw} {rows*ch}" font-family="monospace" font-size="15" '
         f'shape-rendering="crispEdges">',
         f'<rect width="100%" height="100%" fill="#000"/>']
    for r, row in enumerate(cells):
        for c, (t, fg, bg) in enumerate(row):
            x, y = c * cw, r * ch
            if t == "\u2580":
                o.append(f'<rect x="{x}" y="{y}" width="{cw}" height="{ch//2}" fill="{hexc(fg)}"/>')
                o.append(f'<rect x="{x}" y="{y+ch//2}" width="{cw}" height="{ch-ch//2}" fill="{hexc(bg)}"/>')
            else:
                if bg != (0, 0, 0):
                    o.append(f'<rect x="{x}" y="{y}" width="{cw}" height="{ch}" fill="{hexc(bg)}"/>')
                if t.strip():
                    o.append(f'<text x="{x}" y="{y+ch-5}" fill="{hexc(fg)}">{html.escape(t)}</text>')
    o.append("</svg>")
    return "\n".join(o)


def as_png(cells, path, cw=8, ch=16):
    from PIL import Image, ImageDraw
    rows, cols = len(cells), len(cells[0])
    im = Image.new("RGB", (cols * cw, rows * ch))
    d = ImageDraw.Draw(im)
    for r, row in enumerate(cells):
        for c, (t, fg, bg) in enumerate(row):
            x, y = c * cw, r * ch
            if t == "\u2580":
                d.rectangle([x, y, x + cw - 1, y + ch // 2 - 1], fill=fg)
                d.rectangle([x, y + ch // 2, x + cw - 1, y + ch - 1], fill=bg)
            else:
                d.rectangle([x, y, x + cw - 1, y + ch - 1], fill=bg)
                if t.strip():
                    d.text((x, y + 2), t, fill=fg)
    im.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("capture")
    ap.add_argument("cols", type=int)
    ap.add_argument("rows", type=int)
    ap.add_argument("--txt")
    ap.add_argument("--svg")
    ap.add_argument("--png")
    ap.add_argument("--frame", type=int, default=-1)
    a = ap.parse_args()
    fr = frames(open(a.capture, "rb").read(), a.cols, a.rows)
    if a.txt:
        with open(a.txt, "w", encoding="utf-8") as f:
            for i, cells in enumerate(fr):
                f.write(f"----- frame {i+1} of {len(fr)} -----\n{as_text(cells)}\n")
    pick = fr[a.frame]
    if a.svg:
        open(a.svg, "w", encoding="utf-8").write(as_svg(pick))
    if a.png:
        as_png(pick, a.png)
    print(f"frames={len(fr)}", file=sys.stderr)


if __name__ == "__main__":
    main()
