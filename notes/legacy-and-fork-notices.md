# Notices for the legacy personal profile, the legacy Core fork, archived repositories and the aien-dev forks (drafts)

These are drafts. No agent edits github.com/drakestapleton or any fork; Drake applies the profile
text himself, and the fork set needs his decision (below).

DRA-35 asks that each notice point to SI and list what has been withdrawn. The withdrawn claims,
used in every notice below:

- Modular MAX and Mojo: dropped; nothing in SI uses them.
- The SRCL-1.0 licence: withdrawn; each repository's LICENSE file is the licence that applies.
- `curl | sh` and `curl | bash` installers: withdrawn; install SI only as its README describes.
- Performance figures published before 2026-09-23: withdrawn; only figures with a receipt linked
  from SI count.

## 1. Profile notice for drakestapleton/aien-dev (aien-dev/aien-dev redirects there; paste at the top of its README)

> **This is my old personal account.** My work now lives in the
> [aien-dev](https://github.com/aien-dev) organization. Sovereign Intelligence (SI), my own AI on a
> DGX Spark, is at [aien-dev/sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence);
> its alpha status and evidence are at the top of that README. Repositories here are not
> maintained and are not part of any release. Please open issues and security reports in aien-dev,
> not here.
>
> **Withdrawn:** Modular MAX and Mojo, the SRCL-1.0 licence, `curl | sh` and `curl | bash`
> installers, and every performance figure published before 2026-09-23. Anything here that says
> otherwise is out of date.

## 1b. Legacy Core fork: drakestapleton/aien-sovereign-core (formerly dhgmonkey/aien-sovereign-core)

Its README (read 2026-10-31 with `gh api repos/dhgmonkey/aien-sovereign-core/readme`, which now
resolves to drakestapleton/aien-sovereign-core) still shows
`curl -fsSL https://raw.githubusercontent.com/aien-dev/aien-sovereign-core/main/install.sh | bash`,
Modular MAX, Mojo, SRCL-1.0 and tokens/s figures, and does not mention SI. Notice for the top of
that README:

> **Historical checkout, not maintained.** Current engine work is in
> [aien-dev/aien-sovereign-core-mv](https://github.com/aien-dev/aien-sovereign-core-mv); the product
> is [Sovereign Intelligence](https://github.com/aien-dev/sovereign-intelligence).
> **Withdrawn:** Modular MAX and Mojo, the SRCL-1.0 licence, the `curl | bash` installer below, and
> every performance figure in this README (all published before 2026-09-23).

## 1c. Archived aien-dev repositories whose README still reads as current

All 20 archived repositories with a README were read on 2026-10-31
(`gh api repos/aien-dev/<repo>/readme`). None points to SI. Those whose body still advertises a
withdrawn claim, or reads as current (cortex-rs: "the canonical memory engine powering Atlas"):

| Repository | Still shows |
|---|---|
| cortex-rs | current-tense "canonical memory engine" text; its banner points to aien-dev/aien-sovereign-core, not SI |
| spark-inquisitor | `curl -fsSL …/install.sh \| sh` |
| spark-adapters, spark-debugger, harvester | Modular MAX |
| rad-id-sync, aien-yardsticks | Modular MAX, Mojo |
| MojoLlama | Mojo, tok/s figures |
| spark-hive | tok/s figures |

Notice for the top of each (archived repositories must be unarchived to take it, a settings
change for Drake):

> **Archived, not part of Sovereign Intelligence.** Read-only history. The product is
> [aien-dev/sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence).
> **Withdrawn:** Modular MAX and Mojo, the SRCL-1.0 licence, `curl | sh` and `curl | bash`
> installers, and every performance figure published before 2026-09-23, including any below.

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
