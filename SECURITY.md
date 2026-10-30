# Security policy

## Reporting a vulnerability

Report privately. Do not open a public issue, pull request or discussion about it.

Use GitHub private vulnerability reporting. Open this repository's Security tab and choose
"Report a vulnerability":

https://github.com/aien-dev/sovereign-intelligence/security/advisories/new

That creates a private advisory that only the maintainers can see.

Include the commit or release you tested, the component (path), steps to reproduce, and what an
attacker gains. If the report involves a secret, say where it was exposed and do not include the
secret itself. Do not post proof-of-concept payloads publicly.

## Response targets

This project has one maintainer; the targets below are best effort and stated honestly.

- Acknowledgement: within 3 working days.
- Triage and severity: within 7 days of acknowledgement.
- Fix or mitigation for confirmed issues: aim for 30 days for high and critical, 90 days
  otherwise, with a status update at least every 14 days until closed.
- Disclosure: coordinated. An advisory is published with credit (unless you ask otherwise)
  once the fix is on the default branch. Default embargo 90 days, negotiable.

## Scope

This repository is the Sovereign Intelligence front door and the current home of the AienOS alpha
release: the POSIX `sh` bootstrap `installer/install.sh`, the Omega wizard in `installer/wizard/`,
release signing and checking, the generated project index (`index/`), and the Learn and Agent
Academy material under `docs/`. The engine binary it ships is built in
aien-dev/aien-sovereign-core-mv; report engine flaws there.

In scope:

- Any way to make `install.sh` or `aienos` install or run bytes not covered by a valid Ed25519
  signature over `SHA256SUMS` from the key in `KEYS`.
- Archive extraction escaping the staging folder, or writes outside `$HOME/.local/share/aienos`
  and the menu and desktop entries the installer names.
- The model download and per-file SHA-256 check against `installer/share/model.manifest`.
- The index generator `index/gen/index.om`, which turns GitHub API data (repository names and
  descriptions) into `index/repos.json` and README text, and the `index-sync` workflow that pushes
  and auto-merges its output.
- The Learn and Academy check scripts and the six tracked workflows: `verify.yml`, `index.yml`,
  `index-sync.yml`, `release-verify.yml`, `learn.yml` and `sbom.yml`.

Out of scope: the NVIDIA driver, the engine internals, Hugging Face, and the host programs listed
in `installer/HOST-DEPENDENCIES.md`.

## Supported versions

Only the current alpha release named in `installer/install.sh` (`alpha-20261029.1`) and the default branch `main`. Reports against older commits are welcome but fixes land on the default branch only.

## Status

Alpha. README: the installer is EXERCISED; a fresh GB10 install with a first token through the
installer, and the 3x physical qualification, are NOT_RUN; nothing is QUALIFIED. The release key
is an alpha key, replaced by a ceremony key before beta (`KEYS`). No certification, no bug
bounty. See AUDIT_SCOPE.md for what to review and how to build and test it.
