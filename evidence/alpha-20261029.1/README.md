# Evidence for Sovereign Intelligence alpha-20261029.1 (host and container; no GPU)

Built twice with `installer/build.sh` from this branch's sources (omega-mv bf54b19fa omc 62775d2a...,
engine 19173f9e... from Core ship/motor-l387 59b05a71, copied from the live server's
`bin-19173f9e`, whose sha256 equals `/proc/<18091 pid>/exe` on 2026-10-29): the two SHA256SUMS
were identical. Signed with `installer/tools/sign.sh` (signature verified against
`keys/release.pub.pem`). `SHA256SUMS.tested` is the signed SHA256SUMS of the assets these tests
ran against.

| Receipt | Command | Result |
|---|---|---|
| host/ | `sh installer/tests/host-untouched.sh` (runs `installer/tests/run.sh` in bubblewrap with `/` read-only, under strace) | 33/33 PASS; writes refused outside the scratch folder (EROFS): 0; NVIDIA state (162 packages) identical before and after |
| container/ | `sh installer/tests/container.sh` (stock ubuntu:24.04 arm64 + curl/openssl/ca-certificates, unprivileged user, `docker diff`) | 6/6 PASS incl. the canary negative control |

Host: Linux 7.0.0-1019-nvidia aarch64 (DGX Spark), 2026-10-29, inside SLOT omp-fleet (cpus 2-4,
nice 19, ionice idle). No GPU device was opened. Terminal captures of the wizard: NOT_RUN for this
release (the redrawn screens are in evidence/wizard-hole-redraw/). A real install with the 37.5 GB
model download and a first token on a GB10: NOT_RUN.
