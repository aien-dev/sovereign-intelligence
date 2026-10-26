---
name: evidence-and-receipts
description: Use before reporting any result, status, measurement or completion. Labels evidence levels and attaches a receipt to every claim.
---

# Evidence and receipts

## When to use
Before you write "done", "passed", "works", "faster", "merged" or any status line.

## Rules
1. Every claim names its artifact: the exact command, its exit status, and the output (or the log file path inside the repo).
2. Use one evidence word per claim:
   - PROPOSED: written down, no code.
   - IMPLEMENTED: code exists, not run on the changed path.
   - EXERCISED: ran, output kept, compared with an expected value.
   - QUALIFIED: passed the real target's own gate (real hardware, real service). A host, container or emulator run is never QUALIFIED.
   Merged and deployed are separate states again: a merged pull request is not running anywhere until it is deployed.
3. A receipt records: source commit, sha256 of the inputs and of the binary that ran, the exact command, the platform, expected versus observed, and what it does not prove.
4. Never edit an old receipt or log to fit a new claim. Write a new one.
5. If something was not run, write NOT_RUN and the reason. NOT_RUN is never PASS.

## Example status line
`parser: EXERCISED. tests/parse.sh ran 41/41 PASS at commit 1a2b3c4 on Linux x86-64; not run on Windows.`

## Learn more
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/stack-02-evidence-levels.md
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/stack-03-receipts.md
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/stack-06-honest-status.md
