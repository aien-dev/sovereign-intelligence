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
