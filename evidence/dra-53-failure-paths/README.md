# DRA-53 failure-path run logs

One log per script in `installer/tests/failure-paths/`, from the tree of this commit series
(PR #64). Scratch paths are shown as `SCRATCH`.

Label: **EXERCISED (host / fake tree)**. Linux arm64 CPU host, fake GB10 probe roots, the fake
engine on free high ports, a 5,000,000-byte test model served from 127.0.0.1. Stock DGX Spark:
**NOT_RUN** for every case. These are not hardware results.

Sandbox for every run:

```
nice -n 19 ionice -c3 taskset -c 2-4 bwrap --ro-bind / / --dev /dev --proc /proc --tmpfs /tmp \
  --unshare-net --bind SCRATCH SCRATCH --die-with-parent \
  --setenv CUDA_VISIBLE_DEVICES '' --setenv NVIDIA_VISIBLE_DEVICES none \
  --unsetenv DBUS_SESSION_BUS_ADDRESS --setenv XDG_RUNTIME_DIR SCRATCH/xdg-run \
  --setenv OMC <pinned omc> sh installer/tests/failure-paths/run.sh SCRATCH
```

omc sha256 `62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b` (= `OMC_PIN` in
`installer/build.sh`).

The first seven logs come from one `run.sh` pass; `model-resume.log`, `model-corrupt.log` and
`rollback-clean.log` were run by the same command per script (`model-resume.log` rerun after
its INT case was fixed to deliver SIGINT with the default disposition). Every script runs its
negative control against a deliberately broken build and records `control=opposite` when the
control failed as it must.

| Linear case | Log |
|---|---|
| 1. model download interrupted mid-file, resumed | `model-resume.log` (also `no-network.log` cut, `interrupted-install.log`) |
| 2. disk fills during the download | `disk-full.log` (EFBIG file-size limit stands in for ENOSPC) |
| 3. wrong NVIDIA driver | `wrong-gpu-driver.log` |
| 4. port 18100 in use | `port-in-use.log` (test build on a free high port) |
| 5. corrupted bundle or model refused | `bad-signature.log`, `model-corrupt.log` |
| 6. uninstall / rollback leave nothing outside `~/.local/share/aienos` | `rollback-clean.log`, `uninstall-partial.log` |
| (SIGKILL temp folder) a killed install leaves `TMPDIR/aienos-install.*`; the next run removes only that | `stale-tmp.log` |

## stale-tmp guards: one mutant per guard

`stale-tmp.sh` kills install.sh with SIGKILL mid-download, plants a live run's folder, a young
pid-less folder, a folder with a non-numeric pid, an old pid-less folder, a symlink at a matching
name (target holds a dead pid file), another user's folder (`/usr/share/doc` bound in by a nested
bwrap), and three folders with dead pids outside the `aienos-install.*` prefix, then re-runs
install.sh with an `rm` shim that logs every call. Its negative control (`control=opposite`) is
install.sh with the cleanup loop emptied: the killed run's folder stays.

Each guard of the cleanup loop was also removed in a scratch copy of the tree and the same script
run against it; each mutant FAILs on the check written for that guard:

| Mutant (install.sh line removed) | Log | Checks that went BAD |
|---|---|---|
| `[ -O "$old" ]` (owner) | `stale-tmp.mutant-noO.log` | rm named another user's folder; the re-run then exited 1 (rm failed on the read-only bind) |
| `[ ! -L "$old" ]` (symlink) | `stale-tmp.mutant-noL.log` | the planted symlink was removed; rm named it |
| `kill -0 "$pid"` (live run) | `stale-tmp.mutant-nolive.log` | a live run's folder was removed; rm named it |
