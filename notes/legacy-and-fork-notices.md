# Notices for the legacy personal profile and the aien-dev forks (drafts)

These are drafts. No agent edits github.com/drakestapleton or any fork; Drake applies the profile
text himself, and the fork set needs his decision (below).

## 1. Profile notice for github.com/drakestapleton (paste into the profile README)

> **This is my old personal account.** My work now lives in the
> [aien-dev](https://github.com/aien-dev) organization. Sovereign Intelligence (SI), my own AI on a
> DGX Spark, is at [aien-dev/sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence);
> its alpha status and evidence are at the top of that README. Repositories here are not
> maintained and are not part of any release. Please open issues and security reports in aien-dev,
> not here.

## 2. Fork notice template (top of a fork's README, above the upstream text)

> **This is a fork, kept by [aien-dev](https://github.com/aien-dev) for <PURPOSE>.** It is not part
> of the Sovereign Intelligence alpha and has no status of its own. Upstream:
> [<UPSTREAM>](https://github.com/<UPSTREAM>). Report upstream bugs upstream. For SI, see
> [aien-dev/sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence).

## 3. The fork set (from `gh repo list aien-dev --fork`, 2026-10-31)

| Fork | Upstream | Archived |
|---|---|---|
| infra | compiler-explorer/infra | no |
| compiler-explorer | compiler-explorer/compiler-explorer | no |
| BabelStream | UoB-HPC/BabelStream | no |
| edk2-non-osi | tianocore/edk2-non-osi | no |
| rpi5-uefi | worproject/rpi5-uefi | no |
| t3code | pingdotgg/t3code | no |
| translate | xnx3/translate | yes (read-only) |
| arm-trusted-firmware | worproject/arm-trusted-firmware | yes (read-only) |
| edk2 | worproject/edk2 | yes (read-only) |
| odysseus | odysseus-dev/odysseus | yes (read-only) |
| edk2-platforms | worproject/edk2-platforms | yes (read-only) |

Archived forks cannot take a README commit without being unarchived, which is a repository
settings change.

**Decision needed (Drake):** which forks get the notice, and the `<PURPOSE>` text for each.
- A: all six non-archived forks.
- B: only the firmware mirrors (edk2-non-osi, rpi5-uefi), which the README index lists under the
  boot chain.
- C: none; delete or archive the unused forks instead (a settings change).
