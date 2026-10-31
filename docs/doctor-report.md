# aienos doctor --report

`aienos doctor --report FILE` writes a gzip tar archive of install diagnostics for an alpha tester
issue. It opens no network connection and sends nothing; you read the file and decide whether to
attach it. It refuses to overwrite an existing FILE (exit 1).

```sh
aienos doctor --report report.tar.gz
tar -tzf report.tar.gz          # member list
tar -xzOf report.tar.gz         # read every member before you share it
```

## Example

This example was **not made on a DGX Spark**. It comes from the fake install tree of
[installer/tests/report.sh](../installer/tests/report.sh): a release folder `alpha-test` holding
only `bin/aienos` and `VERSION`, a fake GB10 hardware tree (`installer/tests/fake-root.sh … gb10`,
read through `AIENOS_PROBE_ROOT`), and logs seeded with canary secrets that must not reach the
archive. The command ran inside `bwrap --dev-bind / / --unshare-net` (no network namespace access)
under strace, exactly as the test runs it:

```sh
env HOME="$S/home" AIENOS_PROBE_ROOT="$S/root" "$S/home/.local/share/aienos/releases/alpha-test/bin/aienos" doctor --report report.tar.gz
```

The `free disk` and `Disk` values are the build host's real free space; every other hardware value
is from the fake tree, so `kernel` and `/etc/os-release` read `(not found)`. The report writes the
home folder as `~` itself; it contains no hostname, user name or serial number, so nothing below
was redacted by hand. `installer/tests/report.sh` checks that every member and every documented
field name (the text before `: `) on this page still appears in the real output.

Terminal output:

```text
Wrote report.tar.gz (11799 bytes).
It holds versions, checksums, system strings, the doctor's checks, service state and filtered
logs; no prompts, chats, conversation ids, keys or tokens. Read it before you share it:
  tar -xzOf report.tar.gz
Attach it to an alpha tester issue: https://github.com/aien-dev/sovereign-intelligence/issues/new/choose
```

Archive members (`tar -tzf report.tar.gz`):

```text
aienos-report/README.txt
aienos-report/versions.txt
aienos-report/system.txt
aienos-report/doctor.txt
aienos-report/checksums.txt
aienos-report/service.txt
aienos-report/logs.txt
```

### README.txt

```text aienos-report/README.txt
aienos doctor --report: install diagnostics for an AienOS alpha tester report.
Made on this computer by bin/aienos (Omega). It opened no network connection and sent nothing;
you decide whether to share this file. Your home folder is written as ~.

Members:
  versions.txt   this release and its build pins (aienos about, VERSION, the current link)
  system.txt     kernel, OS and DGX OS versions, NVIDIA driver, CUDA version, memory, free disk
  doctor.txt     the eight checks of aienos doctor
  checksums.txt  SHA-256 of every installed file against the release's SHA256SUMS, and of the
                 downloaded bundle against the signed release manifest
  release.SHA256SUMS, release.SHA256SUMS.sig  the signed release manifest and its Ed25519 signature
  service.txt    engine and lending process state (AienOS installs no system service)
  logs.txt       recent lines of install.log, download.log and engine.log, filtered

Never included: prompts, chat text, conversation ids or history, keys, tokens or other secrets.
Only the files named above are read. A log line is copied only when it names no conversation
id, credential or message content, and a download or engine log line only when it starts with
the program's own prefix; other lines are counted, not copied. The lending key and log are not read.
```

### versions.txt

```text aienos-report/versions.txt
Sovereign Intelligence alpha-20261029.1: the installer and the aienos command
written in Omega (.om), compiled by omc sha256 62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b
  (aien-dev/omega-mv bf54b19fa590e8ae925c0e80815516dbf41e7326, seed/out/omc)
engine: aien-serve-http sha256 19173f9ec3b609fe79af644f84741d8808b92ea8eb3ecec4bc945af6f22b3aeb,
  the build that serves the Spark's 35B: aien-dev/aien-sovereign-core-mv branch ship/motor-l387
  commit 59b05a71a33e4a2f1324db2f2b6407ee82b8c2c3 (a development build, not a Core release tag)
  evidence: Core evidence/l387-motor-ship (merge train 20261022T0244Z-bfc41659, timing runs)
GPU path: the engine's statically linked libomega_gpu.a (omega ship/motor-l387 6de999da) talks to
  /dev/nvidiactl, /dev/nvidia0 and /dev/nvidia-uvm. There is no separate CUDA++ runtime.
model: Qwen/Qwen3.6-35B-A3B-FP8 revision 95a723d08a9490559dae23d0cff1d9466213d989 (37.5 GB)
  This is the only model offered. A 27B is to come; it is not offered in this release.
evidence: this engine binary serving the 35B on a GB10 EXERCISED (it is the live server's build);
  this installer's GB10 install and first token, and the 3x physical qualification: NOT_RUN.
signature: Ed25519 alpha release key ff949504b427680039d53c33c85c448546b57d590eb1ecee3bb2ed6c2eaaf54a
  (an alpha key; it is rotated to a ceremony key before beta)

release folder: ~/.local/share/aienos/releases/alpha-test
~/.local/share/aienos/current -> releases/alpha-test
releases in ~/.local/share/aienos/releases:
  alpha-test
--- VERSION (this release)
AienOS alpha-test
```

### system.txt

```text aienos-report/system.txt
kernel: (not found)
kernel release: (not found)
/etc/os-release: PRETTY_NAME= (not found)
/etc/os-release: VERSION_ID= (not found)
/etc/dgx-release: DGX_PRETTY_NAME= (not found)
/etc/dgx-release: DGX_SWBUILD_VERSION= (not found)
/etc/dgx-release: DGX_OTA_VERSION= (not found)
NVIDIA kernel module (/sys/module/nvidia/version): 580.173.02
NVIDIA driver (/proc/driver/nvidia/version): NVRM version: NVIDIA UNIX Open Kernel Module for aarch64  580.173.02
CUDA toolkit (/usr/local/cuda/version.json; not part of AienOS): (not found)
/proc/meminfo: MemTotal:       127598528 kB
/proc/meminfo: MemFree:         1000000 kB
/proc/meminfo: MemAvailable:   120000000 kB
/proc/meminfo: Mapped:           200000 kB
/proc/meminfo: SwapTotal: (not found)
/proc/meminfo: SwapFree: (not found)
free disk in the home folder (df -B1 --output=avail): 395270426624 bytes
```

### doctor.txt

```text aienos-report/doctor.txt
[  ok  ] CPU      arm64 (aarch64), Linux
[  ok  ] GPU      NVIDIA GB10 found (PCI 10de:2e12), device nodes present
[  ok  ] Driver   kernel driver 580.173.02 (the version this alpha was built and tested against)
[  ok  ] Memory   130 GB memory, 122 GB free for a model
[  ok  ] Disk     395.3 GB free in your home
[ info ] AienOS   installed: alpha-test, model not downloaded yet
[  ok  ] GPU lock the GB10 lock (/tmp/aien-gb10.lock) is not held right now
[ info ] NVIDIA   no NVIDIA user-space libraries found; AienOS does not need them
verdict: this machine can take this alpha (no check failed)
```

### checksums.txt

```text aienos-report/checksums.txt
SHA-256 computed now for every file of this release, against the release's own SHA256SUMS.
release folder: ~/.local/share/aienos/releases/alpha-test
bundle sha256 recorded by install.sh (.bundle-sha256): (not present)
ok      bin/aienos
ok      VERSION
files: 2 ok, 0 changed, 0 missing
model manifest (share/aienos/model.manifest): not present
```

### service.txt

```text aienos-report/service.txt
autostart: none. AienOS installs no systemd unit, service or login item; the engine runs only
  after aienos chat, aienos start or the wizard starts it, and aienos stop ends it.
engine: not running
engine address: http://127.0.0.1:18100/v1 (not probed: this report opens no connection)
lending program: not in this release
lending key: present (not copied)
lending: not running
lending paused: no
lending log ~/.local/share/aienos/lend/lend.log: (not present)
```

### logs.txt

```text aienos-report/logs.txt
Recent lines of AienOS's own logs, filtered as README.txt says.
--- ~/.local/share/aienos/install.log
=== install.sh alpha-test 2026-10-31T00:00:00Z
installed into ~/.local/share/aienos/releases/alpha-test
--- ~/.local/share/aienos/download.log
curl: (6) Could not resolve host
--- ~/.local/share/aienos/engine.log
aien-serve-http: serving at http://127.0.0.1:18100/v1
aien-serve-http: tokenizer from ~/models/x
lines copied: 5
lines left out: 5
```
