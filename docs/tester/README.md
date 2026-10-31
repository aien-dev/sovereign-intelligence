# Alpha tester kit

For anyone other than the author who installs the Sovereign Intelligence alpha on an NVIDIA DGX
Spark and reports what happened. It covers what to install, what is not ours, how to install,
uninstall and roll back, the known issues, and how to file a report.

## How to read the citations

Every claim names the file and line it comes from, at a fixed commit:

| Short form | Commit | What it is |
|---|---|---|
| `@9335a4b` | `9335a4be7eb6940391d7951a5bf0b6e5ff882590` | tag `alpha-20261026.2`, the release a tester installs today |
| `@dcae5bd` | `dcae5bd49f4c4903525b42ff401f52a2393e9348` | `main` when this kit was written |
| `@7d5cfc0` | `7d5cfc01b174743f163d060935c0427679f4d7db` | head of draft PR #54 (`aienos doctor --report`), **not merged** |

`installer/install.sh:21@9335a4b` means line 21 of that file at that commit. To check one, run
`git show 9335a4b:installer/install.sh | sed -n 21p`. Anything not backed by a citation is marked
**NOT_RUN** or **[INFERENCE]**.

Evidence words follow the README: PROPOSED, IMPLEMENTED, EXERCISED, QUALIFIED. Nothing here is
QUALIFIED. No step in this kit has been run on a GB10 by the kit's author; host tests are not
hardware results.

## Which release to install

Install **`alpha-20261026.2`**. It is the only release whose assets are published:

- `README.md:32@dcae5bd` tells you to clone at `alpha-20261026.2`, and that tag's installer downloads
  `alpha-20261026.2` (`installer/install.sh:21@9335a4b`).
- `main` has moved its installer to `TAG=alpha-20261029.1` (`installer/install.sh:21@dcae5bd`), and
  `notes/alpha-20261029.1.md` describes that release. On 2026-10-31 there was no git tag
  `alpha-20261029.1` and no GitHub release of that name (`git tag` lists only `alpha-20261026.1`
  and `alpha-20261026.2`, and `gh release list` shows the same two). Fetching
  `https://github.com/aien-dev/sovereign-intelligence/releases/download/alpha-20261029.1/SHA256SUMS`
  returned HTTP 404, while the same path for `alpha-20261026.2` returned 200. If you run
  `installer/install.sh` from `main`, it fails at the download with exit status 2
  (`installer/install.sh:75-78@dcae5bd`). Known issue K1 below.

Between the two commits, `installer/install.sh` differs only on line 21 (`git diff 9335a4b dcae5bd
-- installer/install.sh`). The line numbers below therefore hold for both.

## What is third-party

AienOS installs none of the items below. It uses what DGX OS already has, or downloads it into
your home folder.

| Item | Who owns it | How the alpha uses it | Source |
|---|---|---|---|
| NVIDIA kernel driver | NVIDIA (open kernel module) | Required, at exactly version `580.173.02`. Any other version gets "not supported here" and nothing is changed. | `installer/install.sh:27@9335a4b`, `:52-63@9335a4b` |
| GB10 silicon and signed firmware | NVIDIA | Required: PCI `10de:2e12` | `installer/install.sh:55-61@9335a4b`; `README.md:63@dcae5bd` |
| CUDA toolkit, `libcuda`, cuBLAS, `nvidia-smi` | NVIDIA | Not used. The doctor only checks whether they exist and reports that they stay installed and unused. After start, the wizard counts `libcuda`/`libcublas`/`libcudart`/`libnvidia-*` in the engine's `/proc/PID/maps`. | `installer/wizard/doctor.om:32-34@9335a4b`, `:76@9335a4b`; `installer/wizard/engine.om:27-30@9335a4b`, `:186@9335a4b` |
| Model weights `Qwen/Qwen3.6-35B-A3B-FP8`, revision `95a723d08a9490559dae23d0cff1d9466213d989` | Qwen (Alibaba Cloud), from Hugging Face | The wizard downloads 56 files (37,493,015,668 bytes) into `~/.local/share/aienos/models/` and checks each file's SHA-256 against the manifest | `installer/share/model.manifest:1-4@9335a4b`; `installer/wizard/steps.om:44@9335a4b` |
| Model licence | Qwen | The repo records it as Apache-2.0, with the `LICENSE` file inside the model folder. The manifest pins that file's SHA-256 (`50cbab8a…6b32`, 11,343 bytes). This kit did **not** download or read the licence text itself: NOT_RUN. | `NOTICE:20-22@9335a4b`; `installer/share/model.manifest:6@9335a4b` |
| Container runtime (Docker, Podman) | n/a | **None.** Neither the installer nor the wizard starts a container: `grep -n -i 'docker\|podman'` over `installer/install.sh` and `installer/wizard/*.om` at `@dcae5bd` returns 0 lines. Docker appears only in the maintainers' test `installer/tests/container.sh`. | `installer/tests/container.sh:57@dcae5bd` |
| Bootstrap host programs: `sh` (dash), `uname`, `curl`, `openssl`, `sha256sum`, `tar`/`gzip`, `mktemp`/`ln`/`mv`/`cp`/`sed`/`awk`/`cat`, optionally `xdg-user-dir`/`gio` | Ubuntu / DGX OS | `install.sh` needs them, and the versions seen on the build machine are listed. `install.sh` itself refuses to run without `curl sha256sum tar openssl mktemp`. | `installer/HOST-DEPENDENCIES.md:13-22@9335a4b`; `installer/install.sh:66-68@9335a4b` |
| Wizard host programs: `curl` (model download), `stty size`, `df` | Ubuntu / DGX OS | The Omega wizard calls them through `fork`/`execprog` | `installer/HOST-DEPENDENCIES.md:34-38@9335a4b` |
| `oh-infer-volunteer` (Rust, optional lending) | aien-dev/open-humanity | Only on `main`, and only in a bundle built with `OH_VOLUNTEER`. `alpha-20261026.2` does not include it. | `installer/HOST-DEPENDENCIES.md:49-62@dcae5bd` |

First-party, for completeness: `bin/aienos` (the Omega wizard) and `bin/aien-serve-http` (the
engine, sha256 `19173f9e…3aeb`, Core commit `59b05a71`, linked only to glibc libraries)
(`notes/alpha-20261026.2.md:19-20@9335a4b`, `:30-33@9335a4b`).

## Install

On the Spark, as your own user (no sudo):

```sh
git clone --branch alpha-20261026.2 https://github.com/aien-dev/sovereign-intelligence
cd sovereign-intelligence
sh installer/install.sh
```

What `install.sh` does, in order (`@9335a4b`):

1. **Platform gate, before any download.** Linux, `aarch64`, a loaded NVIDIA kernel driver, a GB10
   PCI device, and driver `580.173.02`. Anything else prints a note and exits 0 without changing
   anything (`installer/install.sh:39-45`, `:47-63`).
2. **Tools.** It checks for `curl sha256sum tar openssl mktemp` and a usable `HOME`. If one is
   missing it exits 2 (`:65-69`).
3. **Download and verify.** It fetches `SHA256SUMS`, `SHA256SUMS.sig` and the bundle by exact tag
   (`:21-25`, `:80-84`). It checks the Ed25519 signature against the key built into the script
   (`:33-36`, `:85-91`), then the bundle's SHA-256 (`:92-99`). A failure exits 1 with "Nothing was
   installed".
4. **Unpack safely.** It refuses absolute or `..` paths (`:103-106`), unpacks into
   `releases/.TAG.new`, rechecks every file against `SHA256SUMS` (`:107-115`), then moves the folder
   into `~/.local/share/aienos/releases/TAG`. An intact copy already in place is kept as it is
   (`:116-129`). It then points `~/.local/share/aienos/current` at the release with an atomic link
   swap (`:132-133`).
5. **Command, menu entry, desktop icon.** It creates `~/.local/bin/aienos`, the icon, the menu entry
   and, when a desktop folder exists, a desktop launcher. Every path it writes goes into
   `~/.local/share/aienos/installed-files` (`:135-167`).
6. **Wizard offer.** On a terminal it asks "Open the setup wizard now? [Y/n]". Setting
   `AIENOS_NO_WIZARD=1` skips the question (`:176-185`).

Exit status: 0 for installed or not supported here, 1 for a signature or checksum mismatch, 2 for
a missing tool or download (`installer/install.sh:16-18`).

The wizard (`aienos`) runs doctor, plan, your `yes`, install, model download and first chat. Before
your `yes` it lists what it will change: only paths under your home folder, nothing in `/usr` or
`/etc`, and no sudo (`installer/wizard/main.om:39-47@9335a4b`). The engine listens on
`127.0.0.1:18100` (`installer/wizard/engine.om:6@9335a4b`, `:45@9335a4b`). The engine log is
`~/.local/share/aienos/engine.log` (`engine.om:20@9335a4b`), and the download log is
`~/.local/share/aienos/download.log` (`installer/wizard/steps.om:71@9335a4b`).

Other commands: `aienos doctor | chat | start | stop | verify | source | about | uninstall
[--keep-model] [--yes] | rollback` (`installer/wizard/main.om:70@9335a4b`).

Evidence: the installer, wizard and uninstaller are EXERCISED on a fake GB10 tree with a read-only
`/` (33/33 PASS) and in a stock `ubuntu:24.04` container (6/6 PASS, canary control included). The
first chat is EXERCISED **only against a fake engine**. A real GB10 install with the 37.5 GB
download and a first token is **NOT_RUN** (`notes/alpha-20261026.2.md:48-53@9335a4b`).

## Uninstall

```sh
aienos uninstall               # asks; type yes
aienos uninstall --keep-model  # keeps ~/.local/share/aienos/models
aienos uninstall --yes         # no question
```

What it does, step by step (`installer/wizard/engine.om@9335a4b`, parsed by
`installer/wizard/main.om:723-735@9335a4b`):

1. Without `--yes` it asks "Type yes to remove it". Any other answer prints "Nothing was removed."
   and exits 0 (`engine.om:516-529`, `:55`).
2. It stops the engine. If the engine does not stop, it removes nothing and exits 1
   (`engine.om:530-535`).
3. It unlinks every path listed in `installed-files`, but only paths inside your home folder that
   contain no `..` (`engine.om:385-433`, `:536`).
4. It removes the whole `~/.local/share/aienos` tree, skipping `models/` with `--keep-model`
   (`engine.om:434-476`, `:537-538`).
5. It prints "AienOS is removed. NVIDIA's driver and CUDA were never touched." (`engine.om:58`,
   `:539-546`).

On `main` the uninstaller also stops the optional lending agent first (`installer/wizard/engine.om:545-547@dcae5bd`).

What remains, read from the code: the folders `~/.local/bin`, `~/.local/share/applications` and
`~/.local/share/icons/hicolor/scalable/apps`. `install.sh` creates them with `mkdir -p`
(`installer/install.sh:139-140@9335a4b`) but writes only files into `installed-files`, so they are
not removed. [INFERENCE: they are often present already and are harmless.] Also left in place: the
cloned `sovereign-intelligence` folder, which is yours to delete.

Evidence: `uninstall-leaves-no-files`, `uninstall-keep-model`, `uninstall-asks-first` and
`uninstall-everything` PASS on the host suite (`installer/tests/run.sh:122-124@9335a4b`,
`:219-225@9335a4b`; `evidence/alpha-20261026.2/host/suite.log:14@9335a4b`, `:31-33@9335a4b`).
Uninstall on a real GB10: NOT_RUN.

## Rollback

Rollback **is implemented**, with limits listed below.

```sh
aienos rollback
```

What it does (`installer/wizard/engine.om@9335a4b`):

1. It reads where `~/.local/share/aienos/current` points (`engine.om:552-560`).
2. It picks the **alphabetically greatest** folder in `releases/` that is not the current one,
   skipping names that start with `.`, such as the staging folder (`engine.om:572-631`, `:604`).
3. If there is none, it prints "There is no other release to roll back to." and exits 1
   (`engine.om:68`, `:561-567`).
4. Otherwise it creates `current.new` pointing at that release and renames it over `current`
   (`engine.om:633-668`). `~/.local/bin/aienos` points through `current`
   (`installer/install.sh:141@9335a4b`), so the command switches with it.

Evidence: `rollback` PASS on the host suite with a fake older release folder
(`installer/tests/run.sh:214-218@9335a4b`; `evidence/alpha-20261026.2/host/suite.log:30@9335a4b`).
Rollback on a real GB10: NOT_RUN.

**Open gaps in rollback**, read from the code above:

- **G1. No previous release to roll back to on a fresh machine.** `install.sh` installs one tag
  (`installer/install.sh:21@9335a4b`). Only one release, `alpha-20261026.2`, is downloadable
  (see K1). A tester who installed only that release gets "There is no other release to roll back
  to." Rollback has something to switch to only when an older tag's installer was run earlier on
  the same account.
- **G2. It is "greatest other name", not "previous".** If you have already rolled back, running
  `aienos rollback` again goes forward to the newest release (`engine.om:599-631@9335a4b`).
- **G3. It does not stop or restart the engine.** `rollbk` never calls `estop`
  (`engine.om:552-569@9335a4b`), so a running engine keeps the old binary until you run
  `aienos stop` and then `aienos start`.
- **G4. It does not re-verify the target release.** `rswap` only swaps the link
  (`engine.om:633-668@9335a4b`). Run `aienos verify` yourself after a rollback.

## Collecting diagnostics: `aienos doctor --report`

**Not merged and not in any release.** `aienos doctor --report [FILE]` is in draft PR
[#54](https://github.com/aien-dev/sovereign-intelligence/pull/54) (tracking issue #51). The release
you install (`alpha-20261026.2`) does not have it: its usage line has a plain `doctor`
(`installer/wizard/main.om:70@9335a4b`).

Until #54 is merged and released, attach the output of these commands instead. They read your
machine and print to the terminal:

```sh
aienos about    > aienos-about.txt
aienos doctor   > aienos-doctor.txt 2>&1
aienos verify   > aienos-verify.txt 2>&1
```

Read each file before you attach it.

When a release includes #54, the behaviour at `@7d5cfc0` is:

- The usage line is `doctor [--report [FILE]]` (`installer/wizard/main.om:72@7d5cfc0`).
- With no FILE it writes `aienos-report-<tag>-<n>.tar.gz` in the current folder. With FILE it writes
  there, or inside FILE when FILE is a folder. The file is created new with mode 0600
  (`installer/wizard/report.om:190-207@7d5cfc0`, `:240-246@7d5cfc0`).
- It contains `README.txt`, `versions.txt`, `system.txt`, `doctor.txt`, `checksums.txt`,
  `release.SHA256SUMS`, `release.SHA256SUMS.sig`, `service.txt` and `logs.txt`
  (`report.om:17-25@7d5cfc0`, `:81-88@7d5cfc0`).
- It opens no network connection. It never includes prompts, chat text, conversation ids, keys or
  tokens. Log lines are filtered, and the lending key and log are never read. Your home folder is
  written as `~` (`report.om:2-6@7d5cfc0`, `:78-79@7d5cfc0`, `:89-92@7d5cfc0`).
- It prints how to read the archive before you share it: `tar -xzOf <file>` (`report.om:157-159@7d5cfc0`).

The privacy claims above are what the code says. This kit did not test them; see PR #54 for its
tests (`installer/tests/report.sh@7d5cfc0`).

## Known issues

From the release notes and the open GitHub issues on 2026-10-31.

| # | Issue | Source |
|---|---|---|
| K1 | `main` installs `alpha-20261029.1`, which has no tag or release yet (download 404, exit 2). Use the `alpha-20261026.2` tag. | `installer/install.sh:21@dcae5bd`; `README.md:32@dcae5bd`; this kit's check on 2026-10-31 |
| K2 | A real install on a GB10 with the 37.5 GB download and a first token has never been run through this installer. The first chat is tested only against a fake engine. | `notes/alpha-20261026.2.md:51-53@9335a4b` |
| K3 | Only kernel driver `580.173.02` is accepted. Other versions are refused with nothing changed. | `installer/install.sh:27@9335a4b`, `:63@9335a4b` |
| K4 | No HTTP proxy support for the model download: the wizard's `curl` gets an empty environment. | `installer/HOST-DEPENDENCIES.md:42-44@9335a4b` |
| K5 | Ctrl+C in the wizard can leave the terminal on the alternate screen. Type `reset`. | `installer/HOST-DEPENDENCIES.md:45-47@9335a4b` |
| K6 | The engine will not start while another model holds the GB10's memory. The doctor flags a busy GPU below 62,780,416 kB free and refuses machines with less than 64 GiB of memory. | `installer/wizard/doctor.om:338@9335a4b`; `notes/alpha-20261026.2.md:38@9335a4b` |
| K7 | The installer's engine port (18100) differs from the author's live Spark server (18091). | issue [#34](https://github.com/aien-dev/sovereign-intelligence/issues/34); `installer/wizard/engine.om:6@9335a4b` |
| K8 | No per-install bearer token yet between the wizard and the local engine. On loopback, any local user can reach `127.0.0.1:18100`. The wizard sends no `Authorization` header: `grep -n -i 'authoriz\|bearer' installer/wizard/*.om` at `@dcae5bd` returns nothing. | issue [#56](https://github.com/aien-dev/sovereign-intelligence/issues/56); `installer/wizard/net.om:2-3@9335a4b` |
| K9 | The engine is a development build from Core `ship/motor-l387` `59b05a71`, not a Core release. Its pins lag Core main and Core's GPU lock. | `notes/alpha-20261026.2.md:30-31@9335a4b`; issues [#37](https://github.com/aien-dev/sovereign-intelligence/issues/37), [#38](https://github.com/aien-dev/sovereign-intelligence/issues/38) |
| K10 | Rollback limits G1–G4 above. | this file |
| K11 | `aienos doctor --report` is not available yet (draft PR #54). | [#51](https://github.com/aien-dev/sovereign-intelligence/issues/51), [#54](https://github.com/aien-dev/sovereign-intelligence/pull/54) |

Other open issues (#31, #39, #41, #43–#47, #55) cover docs, governance, CI and release pins. They
do not change what a tester runs.

## Filing a report

Open a new issue with the **Alpha tester report** form
([.github/ISSUE_TEMPLATE/alpha-tester.yml](../../.github/ISSUE_TEMPLATE/alpha-tester.yml)). It asks
for the release, how you installed it, the doctor output or archive, and your environment.

**Never paste chat content, prompts, model replies, API keys, Hugging Face tokens or any other
token.** If a log line you want to share contains any of those, leave it out.
