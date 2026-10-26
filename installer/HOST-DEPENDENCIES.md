# Host dependencies of the AienOS alpha

AienOS is written in Omega wherever Omega can do the job today. Everything below is a program
from the host system that AienOS still calls, what it is used for, and how it gets replaced by
Omega. Versions are the ones on the build machine (DGX OS, Ubuntu 24.04 arm64) on 2026-10-26.
Nothing here is bundled: AienOS uses what the machine already has.

## The bootstrap (`install.sh`)

`install.sh` is the only part of AienOS that is not Omega. It runs before any Omega binary is on
the machine, so it has to be something every DGX Spark can already run: POSIX `sh`.

| Program | Version seen | Used for |
|---|---|---|
| `sh` (dash) | 0.5.12 | runs the script |
| `uname` | coreutils 9.4 | platform gate: Linux and aarch64 |
| `curl` | 8.5.0 | downloads SHA256SUMS, its signature and the bundle over HTTPS |
| `openssl` | 3.0.13 | checks the Ed25519 signature of SHA256SUMS (`pkeyutl -verify -rawin`) |
| `sha256sum` | coreutils 9.4 | checks the bundle against the signed SHA256SUMS, then every file inside it |
| `tar`, `gzip` | 1.35, 1.12 | unpacks the bundle (after the checks) |
| `mktemp`, `ln`, `mv`, `cp`, `sed`, `awk`, `cat` | coreutils 9.4, sed 4.9, gawk 5.2.1 | staging, links, the launcher template |
| `xdg-user-dir`, `gio` | xdg-user-dirs, 2.80.0 | optional: finds the desktop folder and marks the icon trusted |

Omega replacement path: a static Omega program, `aienos-get`, doing the same steps with the
omega-mv `sha256` unit and the omnet `ed25519` unit, both already Omega. It needs an HTTPS
client in Omega (a TLS unit, or a host word for it) before it can replace `curl`, and it still
needs a first download, so a few lines of `sh` stay as the entry point either way.

## The wizard (`bin/aienos`, Omega)

The wizard is Omega. It calls the host programs below through `fork` and `execprog`, each recorded
here because Omega lacks a word for the job today.

| Program | Version seen | Used for | Omega replacement |
|---|---|---|---|
| `curl` | 8.5.0 | downloads the model files from Hugging Face over HTTPS (with resume, `-C -`); checks a pasted Hugging Face token (`-H @~/.local/share/aienos/keys/hf.header -w %{http_code}` against `/api/whoami-v2`), so the token is never on a command line | an HTTPS client unit in Omega; the SHA-256 check of every file is already Omega |
| `stty size`, `stty -echo`, `stty echo` | coreutils 9.4 | reads the terminal size; hides the token while it is typed | a `ttysize` host word (Linux `TIOCGWINSZ`) and a termios word; `devctl` only allows FIONREAD and NVRM requests today |
| `df -B1 --output=avail` | coreutils 9.4 | free space in the home folder | a `fsstat` host word (Linux `statfs`) |
| `/bin/sh`, `/usr/bin/env` | dash 0.5.12, coreutils 9.4 | `aienos restore` runs the recorded `restore.sh` (`cd` to the server's folder, then `exec /usr/bin/env -i` with its recorded environment and argv) | `execprog` with a recorded environment and folder (an `execve`+`chdir` word), which would make the script unnecessary |

Notes:

- `execprog` starts programs with an empty environment, so `curl` sees no proxy settings. A
  machine that needs an HTTP proxy for Hugging Face cannot download the model through the wizard
  yet. An `execprog` form that passes chosen environment entries would fix that.
- The wizard has no signal handling: Ctrl+C ends it at once, which can leave the terminal on the
  alternate screen. Typing `reset` restores it. A signal word (block SIGINT and read it as input)
  would let the wizard clean up.

## Test-only settings

- `AIENOS_PROBE_ROOT`: a folder prefixed to every hardware path the doctor and `install.sh` read
  (`/proc/...`, `/sys/...`, `/dev/...`). Tests point it at a fake tree. It changes only what is
  read, never what is written.
- `AIENOS_PROC_ROOT`: a folder put in front of `/proc` when the wizard looks for running model
  servers. `tests/run.sh` points it at an empty folder so the host's processes are never scanned;
  `tests/onboarding.sh` points it at a fake tree for the systemd and container refusals.
- `AIENOS_HF_API`: where the Hugging Face token is checked (default `https://huggingface.co`).
  `tests/onboarding.sh` points it at a local mock that answers `/api/whoami-v2`.
- `AIENOS_BASE_URL`: where `install.sh` downloads from. The signature is still checked against
  the key inside `install.sh`, so another source cannot change what gets installed.
- `AIENOS_NO_WIZARD=1`: `install.sh` does not offer to open the wizard.
