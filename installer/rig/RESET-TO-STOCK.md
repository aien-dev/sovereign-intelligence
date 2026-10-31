# Reset the SI test Spark to stock (DRA-44)

Before each tester runs the alpha, the test Spark goes back to what NVIDIA ships. Afterwards
`installer/rig/stock.om` checks that nothing from Sovereign Intelligence (SI) is left. This file
covers three things:

1. what stock means;
2. how to get back to it;
3. exactly what the SI installer adds and removes, so the check knows what to look for.

Line numbers refer to this branch: `installer/install.sh`, `installer/wizard/*.om` and
`README.md` at the base of DRA-44.

Status: the procedure is PROPOSED. The check is EXERCISED on FAKE roots only. Resetting a real
stock Spark and running the check on it afterwards is NOT_RUN.

## 1. What stock DGX OS contains

### What NVIDIA documents

- DGX OS is NVIDIA's Ubuntu-based operating system for the Spark, with the drivers and tools
  already installed. NVIDIA releases a new version about twice a year, in February and August
  ([DGX OS](https://docs.nvidia.com/dgx/dgx-spark/dgx-os.html)).
- The preinstalled software is:
  - DGX OS;
  - the NVIDIA GPU driver and the CUDA Toolkit;
  - NVIDIA Container Runtime for Docker;
  - DGX Dashboard, with JupyterLab;
  - NVIDIA Sync;
  - Nsight.

  NGC and NVIDIA AI Enterprise are available to it
  ([Software](https://docs.nvidia.com/dgx/dgx-spark/software.html)).
- At first boot the setup screens ask for language, time zone, keyboard, licence terms, one user
  account and Wi-Fi. They then download and install updates
  ([First Boot](https://docs.nvidia.com/dgx/dgx-spark/first-boot.html)). The driver version you
  get after a reset therefore depends on the day of first boot.

### What the alpha relies on

`install.sh` refuses any kernel driver other than `GOOD_DRIVER=580.173.02` (install.sh:27, 52-63).
It also needs `curl sha256sum tar openssl mktemp`, which "all ship with DGX OS"
(install.sh:65-67).

### The baseline `stock.om` enforces

Every row must hold, or the check prints a `DEVIATION`:

| what | stock value | deviation kind |
| --- | --- | --- |
| `/etc/dgx-release` | present | `stock-file` |
| `/etc/passwd` | has a uid 0 entry; no user name starts with `aien` | `stock-file`, `user` |
| `/var/lib/dpkg/status` | `curl openssl coreutils tar gzip sed xdg-user-dirs` all `install ok installed` (install.sh:66 tools, `gzip` for the `.tar.gz` release, `sed` for install.sh:148, `xdg-user-dir` for install.sh:155-156) | `package` |
| `/sys/module/nvidia/version` | `580.173.02` | `driver` |
| systemd unit folders | no unit or drop-in named `aien*`, `flint*` or containing `oh-infer` | `unit` |
| `/proc/net/tcp`, `/proc/net/tcp6` | nothing LISTENing on 18100 (SI engine), 18091 or 18300 (fleet servers that are never part of stock) | `port` |
| `/proc/*/comm` | no `aien-serve-http`, `oh-infer-volunt`, `aienos` process | `process` |
| every home (uid 0 and uid ≥ 1000 in `/etc/passwd`) | none of the SI files in part 3 | `si-file`, `hf-model`, `si-clone` |

If a file the check needs cannot be read, it prints `DEVIATION unchecked <path> unreadable` and
fails. A check that could not look never counts as a pass.

The project's development Spark (not stock) reports `DGX_NAME="DGX Spark"` and
`DGX_SWBUILD_VERSION="7.2.3"` in `/etc/dgx-release`. Do not use that as a stock value: the check
requires only that the file exists.

## 2. Returning to stock

There are two ways back. In both cases, run the check afterwards; it decides whether you reached
stock.

### A. Uninstall (keeps the Spark's user account and data)

Use this when SI was installed only as described in part 3.

1. Run `aienos uninstall --yes`, without `--keep-model`.
   - It stops the engine (`estop`, engine.om:174) and the lending agent (`lunin`, lend.om:476).
   - Then it unlinks every path listed in `installed-files` that lies inside the home folder
     (`ulist`, engine.om:419-440).
   - Then it removes `~/.local/share/aienos` (`rmt`, engine.om:441-470;
     `uninst`, engine.om:524-559).
2. Remove the source clone if there is one: `rm -rf ~/sovereign-intelligence`. README.md:12 and
   README.md:32 clone it to that path.
3. If the model was ever fetched with Hugging Face tools, remove its cache:
   `rm -rf ~/.cache/huggingface/hub/models--Qwen--Qwen3.6-35B-A3B-FP8`.
4. Run the check (see "Running the check" below).

### B. NVIDIA system recovery (factory state; erases the internal SSD)

Source: [System Recovery](https://docs.nvidia.com/dgx/dgx-spark/system-recovery.html). This is
for the NVIDIA Founders Edition only; OEM Sparks get their recovery image from the OEM. It
restores the OS and the firmware to factory state. You need:

- a USB drive of 16 GB or more (it will be erased);
- a wired USB keyboard and a display;
- an NVIDIA developer account.

Steps:

1. Download the recovery image from
   [DGX Spark recovery software](https://www.nvidia.com/en-us/drivers/dgx-spark-recovery-software/).
   On 2026-10-31 the page offered version 1.145.33 (2026-07-14,
   `dgx-spark-recovery-image-1.145.33.tar.gz`, 5.9 GB). Use whatever version the page lists on the
   day.
2. Unpack it. With admin rights, run the script for the computer that writes the USB drive:
   - `CreateUSBKey.sh` on Linux;
   - `CreateUSBKey.cmd` on Windows;
   - `CreateUSBKeyMacOS.sh` on macOS.
3. Unplug other external storage and plug the USB drive into the Spark. Power on while holding
   Esc or Del to enter UEFI setup.
4. In UEFI setup:
   1. Choose Save & Exit → Restore Defaults → Yes, then Save Changes and Reset.
   2. Hold Esc or Del again to re-enter UEFI setup.
   3. Choose Save & Exit → Boot Override → the USB drive.
   4. If the Spark boots its OS instead: set Security → Secure Boot to Disabled, save, and retry.
      Recovery turns Secure Boot back on.
5. On the recovery welcome screen, press Enter, then [START RECOVERY] on the warning screen. This
   erases the internal SSD. When the progress screen reports factory state, press Enter to
   restart.
6. Complete first-boot setup
   ([First Boot](https://docs.nvidia.com/dgx/dgx-spark/first-boot.html)). It installs updates,
   so check the driver afterwards: `cat /sys/module/nvidia/version`.

NVIDIA states that the Enterprise Download Center and the DGX OS ISO are not for the Spark
([DGX OS](https://docs.nvidia.com/dgx/dgx-spark/dgx-os.html)). Use only the recovery image above.

Recovery also erases this rig's self-hosted GitHub runner. Registering it again is an operator
step and is not part of this procedure. The runner and its service are not stock, and the check
does not look for them.

### Running the check

- On the Spark, from a checkout of this repository with the pinned omc:
  `omc < installer/rig/stock.om > stock && ./stock`
- In CI: start `.github/workflows/rig-stock-check.yml` by hand (Actions → Rig stock check → Run
  workflow). It runs on the `si-test-spark` runner and fails unless the result is `STOCK PASS`.

`stock` reads its root from the first argument, else `$SI_STOCK_ROOT`, else `/`. It prints:

1. `STOCK ROOT <root>`;
2. one `DEVIATION <kind> <detail>` line per finding;
3. `STOCK PASS homes=N` or `STOCK FAIL deviations=N`.

Exit codes:

| code | meaning |
| --- | --- |
| 0 | stock |
| 1 | deviations |
| 2 | usage |
| 4 | the root is not a readable folder |

It only reads: it opens files and folders read-only and calls `lstat`/`stat`. It needs no root.

Driver deviation after route B: if first boot installed a driver other than 580.173.02, the Spark
is factory-fresh but not on the driver the alpha supports, and `install.sh` would refuse it
(install.sh:63). The check reports `DEVIATION driver <version> expected 580.173.02` so the
operator sees this before a tester does.

## 3. What the SI installer adds and removes

`install.sh` never uses sudo and never writes outside the home folder (install.sh:13).
Everything below is in the installing user's home (`~`).

### Added by `install.sh` (`curl -fsSL https://aienos.com/install.sh | sh`, or the clone in README.md:12)

| path | where | removed by uninstall |
| --- | --- | --- |
| `~/.local/share/aienos/` (`base`) | install.sh:71 | yes, `rmt` engine.om:441-470 |
| `~/.local/share/aienos/releases/<TAG>/`, `releases/.<TAG>.new` while staging | install.sh:102-117 | yes, with `base` |
| `~/.local/share/aienos/current` → `releases/<TAG>` | install.sh:132-133 | yes, with `base` |
| `~/.local/share/aienos/installed-files` | install.sh:137, 167 | yes, with `base` |
| `~/.local/bin/aienos` → `base/current/bin/aienos` (symlink) | install.sh:141 | yes, listed, `ulist` engine.om:419-440 |
| `~/.local/share/icons/hicolor/scalable/apps/aienos.svg` | install.sh:143-144 | yes, listed |
| `~/.local/share/applications/aienos.desktop` | install.sh:151-153 | yes, listed |
| `<desktop>/aienos.desktop`, where `<desktop>` is `xdg-user-dir DESKTOP`, else `~/Desktop`, skipped when it is `~` or missing; mode 755, GIO `metadata::trusted` | install.sh:154-166 | yes, listed |
| `${TMPDIR:-/tmp}/aienos-install.XXXXXX` | install.sh:72 | removed by install.sh's own trap (install.sh:73, 181) |

`install.sh` does not edit shell start-up files. It only prints the command to use
(install.sh:171-173).

### Added by the wizard and engine (`aienos wizard`, `installer/wizard/*.om`)

All of these live inside `base` and go with it:

- the model at `~/.local/share/aienos/models/NAME` (steps.om:614). The model is
  `Qwen/Qwen3.6-35B-A3B-FP8`, revision `95a723d0…`, 37.5 GB (main.om:17).
- `engine.log` and `engine.pid` (engine.om:20-21).
- the lending agent's files: `lend/key`, `lend.pid`, `lend.log` and `paused` (lend.om:5).

The wizard runs two processes:

| process | `/proc/*/comm` | listens on | source |
| --- | --- | --- | --- |
| engine `aien-serve-http` | `aien-serve-http` | 127.0.0.1:18100 | engine.om:6-7, 26 |
| lending agent `oh-infer-volunteer` | `oh-infer-volunt` (the kernel cuts it to 15 characters) | no port; it connects out to the engine at 127.0.0.1:18100 (lend.om:21, 33) | lend.om:7 |

Uninstall stops both before it deletes anything (engine.om:539-547).

The wizard installs no systemd unit, cron entry or autostart file. The check still looks for
`aien*`, `flint*` and `*oh-infer*` units in the system and user unit folders, because fleet tools
use those names and must never be on a tester's Spark.

### What uninstall leaves behind

Uninstall deliberately leaves the following:

| leftover | why | does the check flag it |
| --- | --- | --- |
| `~/.local/share/aienos/models` (and therefore `base`) after `aienos uninstall --keep-model` | engine.om:56, 59 | yes: `DEVIATION si-file ~/.local/share/aienos` |
| empty `~/.local/bin`, `~/.local/share/applications`, `~/.local/share/icons/hicolor/scalable/apps` | created by `mkdir -p` (install.sh:139-140), not recorded in `installed-files` | no: these are ordinary per-user XDG folders that a stock account can also have |
| GIO trusted flag for the desktop entry, in `~/.local/share/gvfs-metadata` | install.sh:163; the entry it describes is gone | no: the metadata store is GNOME's, shared with every other file |
| the source clone `~/sovereign-intelligence` | README.md:12, 32; not installed by `install.sh` | yes: `DEVIATION si-clone` |
| a Hugging Face cache of the model | only if the tester used HF tools | yes: `DEVIATION hf-model` |

Open PR #19 (onboard/first-run: HF token, local weights, restore) would add more files. When it
merges, add them to this table and to `stock.om`.
