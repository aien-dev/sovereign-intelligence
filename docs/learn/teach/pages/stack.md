# Building a sovereign stack

I build my own AI on hardware I own, with every layer open to read, rebuild and change. This track is how I keep that honest: what owning a layer means, how I label how far something has got, and the receipts, gates, crumbs, signatures and tags that let anyone check my claims without taking my word for them.

## Who it is for

- Builders who want their own stack, top to bottom, and want to know which parts they really own.
- Anyone working with coding agents who wants claims they can check: what ran, on what, with what result.
- Readers of my repositories who want to know what PROPOSED, EXERCISED, NOT_RUN or an Alpha tag means there.

## Lessons

1. [Why sovereign: owning every layer](stack-01-why-sovereign.md): the ten layers of Sovereign Intelligence (SI), built on AienOS, where my ownership stops, and an Omega program that shows a binary needs nothing but the kernel.
2. [Evidence levels and verdict words](stack-02-evidence-levels.md): PROPOSED to DEPLOYED, PASS to MISSING_IMPLEMENTATION, and a fail-closed summarizer that never turns NOT_RUN into PASS.
3. [Receipts: what a run leaves behind](stack-03-receipts.md): the fields of a receipt, and verifying a kept one by recomputing every field.
4. [Gates that must fail their negative control](stack-04-gates.md): a gate on the real SI installer, and a weak gate that is caught by its own mutants.
5. [Crumbs: a directory that explains itself](stack-05-crumbs.md): the `.crumb` file, its fields, locks and whispers, read from real public crumbs.
6. [Honest status: writing what is true](stack-06-honest-status.md): a status rewritten from overclaim to evidence, and a check for overclaim words.
7. [Signed releases: owning distribution](stack-07-signed-releases.md): the Ed25519 alpha key, the signed SHA256SUMS and a pinned installer, verified offline.
8. [Alpha tags versus merge gates](stack-08-alpha-tags.md): why a commit with every host check green is not an Alpha without a GPU receipt.

Every lesson has a runnable example under `examples/<lesson id>/`. Each `run.sh` checks the compiler's sha256 first, prints every exit status, and its recorded `output.txt` reproduces byte for byte.

## Prerequisites

- A Linux arm64 (AArch64) machine. The examples need no GPU and never open a GPU device.
- POSIX `sh`, coreutils, `git`, `grep` and `sed`; `node` for the signature check in lesson 7.
- Clones of the pinned repositories: [omega-mv](https://github.com/aien-dev/omega-mv) for the pinned compiler `seed/out/omc` (sha256 `befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d`), [sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence), [aien-sovereign-core-mv](https://github.com/aien-dev/aien-sovereign-core-mv) and [omega-harness](https://github.com/aien-dev/omega-harness). Set `SRC` to the folder holding them.
- Reading Omega helps but is not required; the omega track teaches the language. Every example program here is Omega compiled by that pinned compiler, with a small shared helper file, `lib.om`, concatenated in front.

What this track does not claim: nothing in my stack is hardware QUALIFIED yet, and every example here is a host run.
