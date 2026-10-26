# Evidence for Sovereign Intelligence alpha-20261026.1 (host and container; no GPU)

Built with `installer/build.sh` from this commit's sources (omega-mv 3364a1dfd omc befb8199..., engine
80f04b67... from Core cf239078), signed with `installer/tools/sign.sh`. `SHA256SUMS.tested` is the
signed SHA256SUMS of the assets these tests ran against, identical to the release's.

| Receipt | Command | Result |
|---|---|---|
| host/ | `sh installer/tests/host-untouched.sh` (runs `installer/tests/run.sh` in bubblewrap with `/` read-only, under strace) | 33/33 PASS; writes refused outside the scratch folder (EROFS): 0; NVIDIA state (162 packages, dpkg --verify, file listing, CUDA tree) identical before and after |
| container/ | `sh installer/tests/container.sh` (stock ubuntu:24.04 arm64 + curl/openssl/ca-certificates, unprivileged user, `docker diff`) | 6/6 PASS incl. the canary negative control |
| capture/ | `installer/tools/capture.py --tour` then `installer/tools/ansi-render.py` | real terminal screens of bin/aienos (100x34) on a fake GB10 tree |

Host: Linux 7.0.0-1019-nvidia aarch64 (DGX Spark), 2026-10-26. No GPU device was opened. A real
install with a model download and a first token on a GB10: NOT_RUN.
