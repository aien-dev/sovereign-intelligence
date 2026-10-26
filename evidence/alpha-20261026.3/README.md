# alpha-20261026.3 candidate: evidence

Status: candidate, NOT released and NOT signed with the release key. Built on the DGX Spark
(arm64) on 2026-10-26 with omc from omega 3364a1df. Host and container evidence only; no GPU was
used and the live model server on this machine was not touched.

| Check | Command | Result | Evidence level |
|---|---|---|---|
| Two builds give byte-identical outputs | `build.sh` twice into separate folders, `cmp` of `SHA256SUMS` | identical; see `SHA256SUMS.candidate` | EXERCISED (host) |
| Installer and wizard suite | `tests/run.sh` (DIST unsigned: section A uses a test key, the release-key signature check is NOT_RUN) | `pass=33 fail=0`, `run-sh.log` | EXERCISED (host, fake hardware tree) |
| Onboarding: detection, swap, restore, tokens, downloads | `tests/onboarding.sh` in one docker container (default bridge network, own pid namespace, user `tester`) | `pass=15 fail=0 not_run=0`, `onboarding/` | EXERCISED (container, mock servers, fake engine) |

The onboarding cases (`onboarding/run.log`, per-case output in `onboarding/files/`):

- swap-connect / restore-roundtrip: a mock vLLM on port 8000 is found, the user types yes, it is
  drained and stopped with SIGTERM, the fake engine answers the first chat on 18100 with TTFT and
  tok/s shown; `aienos restore` starts the server again with byte-identical argv and environment
  (including a value with a space, quote and `$`) in the same folder. Records are 0600, the script
  0700. Negative control: a server started with another environment compares different.
- unsupported-untouched: an unknown vLLM model, llama.cpp and Ollama are listed as not supported
  yet; all three keep running and no restore record is written.
- managed-refused: a systemd-service and a container server (fake /proc tree) are refused; the same
  server in a user session is offered (control).
- hf-bad-token / hf-tiny-download: an invalid token is refused by huggingface.co itself (HTTP 401),
  nothing stored; then the 7 files of hf-internal-testing/tiny-random-gpt2 at 71034c5d are
  downloaded from huggingface.co and match their SHA-256.
- hf-good-token: a token accepted by a local whoami mock is stored as a 0600 header file in a 0700
  folder, never printed, and used for the download.
- partial-resume: half a file left as `.part` is resumed with `Range: bytes=N-`.
- tampered-local: a local copy with one byte changed is linked, refused by its hash, the good file
  is downloaded instead, and the user's copy is unchanged.
- occupied-port: another listener on 18100 stops the swap before anything is stopped.
- swap-fail-restores: an engine that exits at once makes the wizard put the server back by itself.
- wrong-arch: an x86_64 machine is refused by the doctor and nothing is created.
- models-command: `aienos models` lists the registry.

NOT_RUN (needs the GB10 and an authorized window): install and first token of the 35B and of the
27B (engine 80f04b67) from this installer; swap and restore of a real vLLM on the GB10; TTFT and
tok/s on hardware; 3x physical qualification; the release-key signature of this candidate.
