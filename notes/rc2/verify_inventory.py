#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
"""Confirm notes/rc2/inventory.json matches lock files at the recorded commits.

This is a read-only check. It fetches other aien-dev repositories with `gh api`
and reads sovereign-intelligence files with `git show`. It does not push, and it
does not treat a match as a release pass.

    python3 notes/rc2/verify_inventory.py
    python3 notes/rc2/verify_inventory.py --self-test

Exit 0 when every verification agrees with the file at the recorded SHA.
A tampered pin or file hash is exit 1. --self-test also tampers one pin in
memory and requires that second check to fail.
"""

import copy
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INVENTORY = Path(__file__).resolve().parent / "inventory.json"
HEX40 = re.compile(r"^[0-9a-f]{40}$")


def die(msg):
    print(f"verify_inventory: {msg}", file=sys.stderr)
    return 1


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def gh_raw(repo, rev, path):
    endpoint = f"repos/aien-dev/{repo}/contents/{path}?ref={rev}"
    proc = subprocess.run(
        ["gh", "api", "-H", "Accept: application/vnd.github.raw", endpoint],
        capture_output=True,
    )
    return proc.returncode, proc.stdout, proc.stderr


def gh_json(endpoint):
    proc = subprocess.run(["gh", "api", endpoint], capture_output=True)
    if proc.returncode != 0:
        raise RuntimeError(proc.stderr.decode()[:400])
    return json.loads(proc.stdout)


def git_show(rev, path):
    proc = subprocess.run(
        ["git", "show", f"{rev}:{path}"],
        cwd=ROOT,
        capture_output=True,
    )
    return proc.returncode, proc.stdout, proc.stderr


def first_sha(text: str) -> str:
    for line in text.splitlines():
        s = line.strip()
        if not s or s.startswith("#"):
            continue
        return s
    raise ValueError("no pin line")


def cargo_git(text: str):
    found = []
    for block in text.split("\n[[package]]\n")[1:]:
        src = re.search(r'^source = "([^"]+)"', block, re.M)
        if not src or "git+" not in src.group(1):
            continue
        name = re.search(r'^name = "([^"]+)"', block, re.M)
        ver = re.search(r'^version = "([^"]+)"', block, re.M)
        found.append(
            {
                "name": name.group(1) if name else "",
                "version": ver.group(1) if ver else "",
                "source": src.group(1),
            }
        )
    return found


def rustls_version(text: str) -> str:
    m = re.search(r'name = "rustls"\nversion = "([^"]+)"', text)
    if not m:
        raise ValueError("rustls package not in lock")
    return m.group(1)


def aienux_omega(text: str):
    lines = [ln for ln in text.splitlines() if ln.strip()]
    if len(lines) < 3 or not HEX40.match(lines[0]):
        raise ValueError("aienux omega.lock shape")
    files = []
    for ln in lines[1:]:
        parts = ln.split()
        if len(parts) != 4 or parts[0] != "sha256":
            raise ValueError(f"vendor line: {ln}")
        files.append({"sha256": parts[1], "dest": parts[2], "src": parts[3]})
    return {"commit": lines[0], "files": files}


class Fetcher:
    def __init__(self):
        self.cache = {}

    def raw(self, via, repo, rev, path):
        key = (via, repo, rev, path)
        if key not in self.cache:
            if via == "github":
                self.cache[key] = gh_raw(repo, rev, path)
            elif via == "git":
                self.cache[key] = git_show(rev, path)
            else:
                raise ValueError(via)
        return self.cache[key]

    def tree(self, repo, rev):
        key = ("tree", repo, rev)
        if key not in self.cache:
            self.cache[key] = gh_json(
                f"repos/aien-dev/{repo}/git/trees/{rev}?recursive=1"
            )
        return self.cache[key]


def check_one(fetcher, v):
    ident = v["id"]
    kind = v["parse"]
    if kind == "absent":
        code, out, err = fetcher.raw("github", v["repo"], v["sha"], v["path"])
        blob = out + err
        if code == 0:
            return f"{ident}: {v['path']} exists at {v['sha']}, expected absent"
        if b"404" not in blob and b"Not Found" not in blob:
            return f"{ident}: expected 404, got {blob[:180]!r}"
        return None

    if kind == "gitlinks":
        tree = fetcher.tree(v["repo"], v["sha"])
        got = {
            t["path"]: t["sha"]
            for t in tree["tree"]
            if t.get("mode") == "160000"
        }
        if got != v["pin"]:
            missing = sorted(set(v["pin"]) ^ set(got))
            return f"{ident}: gitlinks differ ({missing[:8]})"
        return None

    if kind == "tree-entry":
        tree = fetcher.tree(v["repo"], v["sha"])
        # Non-recursive would be enough, but the cached tree may be recursive.
        # A recursive listing does not repeat the directory entry itself.
        # Ask the contents-less root tree when the cached one is recursive.
        if tree.get("truncated"):
            return f"{ident}: tree truncated"
        root = gh_json(f"repos/aien-dev/{v['repo']}/git/trees/{v['sha']}")
        hit = [t for t in root["tree"] if t["path"] == v["path"]]
        if len(hit) != 1:
            return f"{ident}: {v['path']} not in root tree"
        if hit[0]["sha"] != v["pin"] or hit[0]["mode"] != v["mode"]:
            return (
                f"{ident}: tree {hit[0]['mode']} {hit[0]['sha']}, "
                f"want {v['mode']} {v['pin']}"
            )
        return None

    code, out, err = fetcher.raw(v["via"], v.get("repo", ""), v["sha"], v["path"])
    if code != 0:
        return f"{ident}: read failed: {(err or out)[:200]!r}"
    digest = sha256(out)
    if "sha256" in v and digest != v["sha256"]:
        return f"{ident}: file sha256 {digest}, inventory has {v['sha256']}"
    text = out.decode("utf-8", "surrogateescape")

    if kind == "file-sha256":
        if digest != v["pin"]:
            return f"{ident}: pin {v['pin']}, file sha256 {digest}"
        return None
    if kind == "first-sha":
        got = first_sha(text)
        if got != v["pin"]:
            return f"{ident}: lock pins {got}, inventory has {v['pin']}"
        return None
    if kind == "contains":
        for needle in v["pin"]:
            if needle not in text:
                return f"{ident}: missing {needle}"
        return None
    if kind == "cargo-git":
        got = cargo_git(text)
        if got != v["pin"]:
            return f"{ident}: cargo git pins differ ({len(got)} vs {len(v['pin'])})"
        return None
    if kind == "rustls":
        got = rustls_version(text)
        if got != v["pin"]:
            return f"{ident}: rustls {got}, inventory has {v['pin']}"
        return None
    if kind == "aienux-omega":
        got = aienux_omega(text)
        if got != v["pin"]:
            return f"{ident}: omega.lock parse {got} != {v['pin']}"
        return None
    if kind == "json-fields":
        doc = json.loads(text)
        for key, want in v["pin"].items():
            cur = doc
            for part in key.split("."):
                if part.isdigit():
                    cur = cur[int(part)]
                else:
                    cur = cur[part]
            if cur != want:
                return f"{ident}: {key} is {cur}, inventory has {want}"
        return None
    return f"{ident}: unknown parse {kind}"


def check(data, fetcher=None):
    fetcher = fetcher or Fetcher()
    errors = []
    for v in data["verifications"]:
        try:
            err = check_one(fetcher, v)
        except Exception as exc:
            err = f"{v.get('id','?')}: {type(exc).__name__}: {exc}"
        if err:
            errors.append(err)
    return errors


def tamper(data):
    mutant = copy.deepcopy(data)
    for v in mutant["verifications"]:
        pin = v.get("pin")
        if isinstance(pin, str) and HEX40.match(pin):
            v["pin"] = "0" * 40 if pin != "0" * 40 else "1" * 40
            return mutant, v["id"]
        if isinstance(pin, str) and re.fullmatch(r"[0-9a-f]{64}", pin):
            v["pin"] = "0" * 64
            return mutant, v["id"]
    raise SystemExit("no pin available to tamper")


def main(argv):
    path = INVENTORY
    self_test = False
    args = argv[1:]
    if args and args[0] == "--self-test":
        self_test = True
        args = args[1:]
    if args:
        path = Path(args[0])
    data = json.loads(path.read_text())
    if data.get("schema") != "si-rc2-dependency-inventory/1":
        return die(f"unexpected schema {data.get('schema')}")
    fetcher = Fetcher()
    errors = check(data, fetcher)
    if errors:
        print(f"FAIL {len(errors)}")
        for err in errors:
            print(err)
        return 1
    print(f"OK {len(data['verifications'])} verifications match the locks at the recorded SHAs")
    if self_test:
        mutant, ident = tamper(data)
        merrors = check(mutant, fetcher)
        if not merrors:
            return die(f"mutant of {ident} was not caught")
        print(f"MUTANT CAUGHT {ident}: {merrors[0]}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
