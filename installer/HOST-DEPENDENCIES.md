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

The wizard is Omega. It calls three host programs through `fork` and `execprog`, each recorded
here because Omega lacks a word for the job today.

| Program | Version seen | Used for | Omega replacement |
|---|---|---|---|
| `curl` | 8.5.0 | downloads the model files from Hugging Face over HTTPS (with resume) | an HTTPS client unit in Omega; the SHA-256 check of every file is already Omega |
| `stty size` | coreutils 9.4 | reads the terminal size | a `ttysize` host word (Linux `TIOCGWINSZ`); `devctl` only allows FIONREAD and NVRM requests today |
| `df -B1 --output=avail` | coreutils 9.4 | free space in the home folder | a `fsstat` host word (Linux `statfs`) |

Notes:

- `execprog` starts programs with an empty environment, so `curl` sees no proxy settings. A
  machine that needs an HTTP proxy for Hugging Face cannot download the model through the wizard
  yet. An `execprog` form that passes chosen environment entries would fix that.
- The wizard has no signal handling: Ctrl+C ends it at once, which can leave the terminal on the
  alternate screen. Typing `reset` restores it. A signal word (block SIGINT and read it as input)
  would let the wizard clean up.

## The lending program (`bin/oh-infer-volunteer`, Rust, optional)

`aienos lend` and the wizard's optional lending step run one program that is not Omega. It is
bundled only when `build.sh` is given `OH_VOLUNTEER`; without it the bundle has no lending program
and the step says so.

| Program | Version | Used for | Omega replacement |
|---|---|---|---|
| `oh-infer-volunteer` | aien-dev/open-humanity `crates/oh-infer` at `60a093c1` (PR #41 head, pending until it merges) | makes the Spark's volunteer key, checks the model files against the release manifest, connects out to the Open Humanity coordinator and answers through the local engine on 127.0.0.1:18100; pause and resume | `oh-infer` as one `.om` unit speaking the same `OHINF001` bytes, once the OmegaTLS words (SHA-2, X25519, ChaCha20-Poly1305, Ed25519, X.509, a TLS client) and OmegaNet sockets merge on omega-mv; tested against the Rust program as the reference (open-humanity `docs/design/volunteer-inference-v0.md`, last section) |

Its Rust dependencies (rustls 0.23.46, webpki-roots 1.0.10, sha2 0.10.9, ed25519-dalek, x25519-dalek,
chacha20poly1305, serde, serde_json, bincode) are listed with their successors in that design doc.
The wizard starts it with `fork`, `setsid` and `execprog`, like the engine; there is no systemd
unit and no autostart.

## Test-only settings

- `AIENOS_PROBE_ROOT`: a folder prefixed to every hardware path the doctor and `install.sh` read
  (`/proc/...`, `/sys/...`, `/dev/...`). Tests point it at a fake tree. It changes only what is
  read, never what is written.
- `AIENOS_BASE_URL`: where `install.sh` downloads from. The signature is still checked against
  the key inside `install.sh`, so another source cannot change what gets installed.
- `AIENOS_NO_WIZARD=1`: `install.sh` does not offer to open the wizard.
