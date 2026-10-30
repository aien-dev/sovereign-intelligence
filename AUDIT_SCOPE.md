# Audit scope

Written for an outside, independent security audit. Revision described: the head of
`audit/readiness` that contains this file, on top of `main`
`9a08cec0475e9b9d67ce108fa042d40fde2efaaf`, 2026-10-30. Everything below is taken from the
repository's own files at that head; items marked NOT_RUN were not executed while writing this
document.

## What this repository is

Mostly documentation plus one installer (Apache 2.0 with LLVM Exceptions):

- `installer/`: the alpha installer. `install.sh` installs tag `alpha-20261029.1` from
  `aien-dev/sovereign-intelligence`. `KEYS` is the alpha key (`ff949504...f54a`). The wizard is
  eight Omega units. aien-dev/AienOS-nv has no installer; its root is LICENSE, NOTICE, README.md
  and .gitignore.
- `index/`: `index/gen/index.om` (1,573 lines of Omega) with `index/curated.yml`,
  `index/gen/repos.graphql` and the generated `index/repos.json`.
- `docs/learn/teach/` (294 files) and `docs/academy/` (208 files): lessons with examples and
  recorded outputs, and an exam with a selftest. `docs/STACK.md` and `NAMING.md` are prose.
- `evidence/alpha-20261029.1/`: receipts for the current release. `evidence/alpha-20261026.1/` and
  `evidence/alpha-20261026.2/`: receipts for the previous releases. `evidence/wizard-hole-redraw/`:
  terminal captures of the redrawn wizard screens.

## What an auditor can and cannot check here

- Can check: the installer's verification order, the archive checks, signature use, the wizard
  source, the index generator, and that the tracked workflows match what the README says.
- Can rebuild: the wizard and the index generator with the pinned omc, without any secret.
- Cannot check here: the engine source (aien-sovereign-core-mv), the private signing seed, the
  claims about other repositories in the README index (they come from `index/curated.yml`), and any
  GPU result.

## What to review, in priority order

1. `installer/install.sh` lines 75 to 120: fetch, signature and checksum order; check whether
   `curl --proto '=https,http'` and the `AIENOS_BASE_URL` and `AIENOS_PROBE_ROOT` overrides matter
   once the signature check is in place; the `tar -tzf` name check refuses absolute paths and `..`,
   so check symlink and hard link entries.
2. `installer/wizard/steps.om`, `sha256.om`, `engine.om`, `lib.om`, `net.om`, `hole.om`,
   `doctor.om`, `main.om`: install check, model download and check, child processes (`curl`,
   `stty`, `df` per HOST-DEPENDENCIES.md), the loopback HTTP client, uninstall and rollback, the
   welcome screen and the hardware check.
3. `index/gen/index.om` and `.github/workflows/index-sync.yml`: hourly, on dispatch and on
   `repository_dispatch`, the job runs with `contents: write`, `pull-requests: write` and
   `actions: write`, force-pushes `bot/index-sync`, and enables auto-merge after `index-check`.
   Check how text from the GitHub API is escaped into README markdown and JSON.
4. `installer/tools/sign.sh`: the seed passes through an environment variable of `sh -c` on its way
   to `openssl`; check its exposure.
5. `docs/learn/teach/check.sh` and `docs/academy/exam/selftest.sh`: clone the repositories in
   `docs/learn/teach/PINS` and run lesson examples; check what they execute.

## Trust boundaries

- Trust root: the alpha Ed25519 key in `KEYS`, `keys/release.pub.pem` and embedded in
  `install.sh`.
- Untrusted until checked: release assets and model files; GitHub API responses fed to the index
  generator.
- README and `notes/alpha-20261029.1.md` tell a person to clone this repository and run
  `installer/install.sh`. The script header still names
  `curl -fsSL https://aienos.com/install.sh | sh`. Release assets then come from GitHub
  (`AIENOS_BASE_URL` defaults to that tag's release URL). Either fetch of the script is HTTPS,
  before the signature check.
- Workflows use only the built-in `GITHUB_TOKEN` (index-sync header; `sbom.yml` is
  `contents: read`).

## Threat model summary

- Assets: the user's home folder and account; the NVIDIA driver and CUDA install, which must stay
  unchanged; the integrity of `main` given an auto-merging bot.
- Attackers considered: a tampered release, a malicious archive, a network attacker, a wrong
  machine; a public repository whose name or description carries hostile text.
- Defended: signature before unpack, two SHA-256 passes, archive name checks, exact tag, refusal on
  other platforms; the index generator exits 1 on any repository missing from `curated.yml`.
- Not defended / explicitly out of scope: a compromised build machine or vault; a tampered
  `install.sh` delivered over HTTPS; engine-side flaws.

## Build from source at a pin

Pins in `installer/build.sh` and in `verify.yml`, `index.yml`, `index-sync.yml` and
`release-verify.yml`: omega-mv `bf54b19fa590e8ae925c0e80815516dbf41e7326`, omc sha256
`62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b`. Those four workflows and
`build.sh` agree. `learn.yml` does not: it clones omega-mv at the `PINS` commit below and checks
omc sha256 `befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d`. `sbom.yml` pins
neither. `installer/build.sh` also pins the engine to aien-sovereign-core-mv
`59b05a71a33e4a2f1324db2f2b6407ee82b8c2c3` (re-read at this head). Linux arm64 only.

```sh
git clone https://github.com/aien-dev/omega-mv && git -C omega-mv checkout bf54b19fa590e8ae925c0e80815516dbf41e7326
echo "62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b  omega-mv/seed/out/omc" | sha256sum -c -
omega-mv/seed/out/omc < index/gen/index.om > index-gen
OMEGA_SRC=$PWD/omega-mv ENGINE=/path/to/aien-serve-http sh installer/build.sh OUT
```

## Run every test

NOT_RUN while writing this document. From the script headers and workflows:

```sh
for f in install.sh build.sh tests/run.sh tests/fake-root.sh tests/container.sh tests/host-untouched.sh tools/sign.sh tools/release.sh; do sh -n "installer/$f"; done
OMC=/path/to/omc DIST=OUT/dist STAGE=OUT/stage sh installer/tests/run.sh
sh installer/tests/host-untouched.sh
DIST=OUT/dist sh installer/tests/container.sh RECEIPT_DIR    # needs docker
./index-gen check                                            # offline index check
sh docs/learn/teach/check.sh clone SRC && SRC=SRC sh docs/learn/teach/check.sh
OMC=SRC/omega-mv/seed/out/omc sh docs/academy/exam/selftest.sh
```

`installer/tests/run.sh` needs the signed build output, so it needs the release seed.

## Known limitations and NOT_RUN

- README: the engine is byte-identical to a live build and rebuilt from Core `59b05a71` (branch
  `ship/motor-l387`) to the same hash, EXERCISED, not QUALIFIED. A fresh GB10 install and first
  token, and the 3x physical qualification, are NOT_RUN.
- README install examples still name tag `alpha-20261026.2`. `installer/install.sh` and
  `notes/alpha-20261029.1.md` name `alpha-20261029.1`.
- The engine branch named above is not `main` of aien-sovereign-core-mv.
- `installer/tools/capture.py` and `ansi-render.py` are Python, used to record documentation
  screens, not in the install path.
- The Learn check reads omega-mv at `19f014f2178ca9cd3473728fe00a475a2398c409` from `PINS` and
  checks omc digest `befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d`, not the
  installer pin `62775d2a...`.

## Dependencies and provenance

- omega-mv and omc pins above, checked by digest in the workflows that set them; engine pin in
  `installer/build.sh`.
- Model: Qwen3.6-35B-A3B-FP8 (README), hashes in `installer/share/model.manifest`.
- Host tools for `install.sh` and the wizard, with versions seen: `installer/HOST-DEPENDENCIES.md`.
- `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683` (v4.2.2) in `verify.yml`, `index.yml`,
  `index-sync.yml`, `release-verify.yml` and `learn.yml`. Those jobs run on `ubuntu-24.04-arm`.
- `sbom.yml` runs on `ubuntu-latest` and pins `actions/checkout@11d5960a326750d5838078e36cf38b85af677262`
  (v4.4.0) and `anchore/sbom-action@66cbf4bc1f1c0d2edc94016e65bc221b6bb0ad6c` (v0.24.3).

## Evidence

- `evidence/alpha-20261029.1/README.md`: built twice with identical `SHA256SUMS` (omega-mv
  bf54b19fa, omc 62775d2a..., engine 19173f9e... from Core 59b05a71); host suite 33/33 PASS under
  bubblewrap with `/` read-only; container suite 6/6 PASS with a canary negative control;
  `SHA256SUMS.tested`. Wizard terminal captures for this release: NOT_RUN.
- `evidence/alpha-20261026.2/README.md`: the previous release, same host and container shape
  (33/33 and 6/6).
- `evidence/alpha-20261026.1/`: the same receipts for the release before that.
- `notes/alpha-20261029.1.md`, `notes/alpha-20261026.2.md`, `notes/alpha-20261026.1.md`: release
  notes.
