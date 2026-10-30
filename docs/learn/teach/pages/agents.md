# Orchestrating coding agents

I build most of my stack with coding agents: a dozen or more working in parallel on a good day, each in its own lane, each checked by something other than itself. This track is how I run them. It is not about prompts. It is about roles, rules and checks that keep many agents honest and useful at once.

## Who it is for

Anyone who already uses a coding agent and wants to run more than one without losing track of what is true. You do not need my hardware or my repositories. Every example runs on an ordinary Linux AArch64 host with no GPU, no network and no live service.

## Lessons

1. [Roles and models: who does the work, who gets consulted](agents-01-roles-and-models.md): one default worker, consultants only on named triggers, two independent consultants for a real fork.
2. [Skills: teaching agents the checks they keep forgetting](agents-02-skills.md): what a `SKILL.md` is, how I ship skills publicly, and why I install them as symlinks.
3. [Reviewers and advisors: who checks the work, and how to weigh them](agents-03-reviewers-and-advisors.md): read-only reviewers, advisor seats with one office each, and how to decide when reviews disagree.
4. [Lanes and integration owners: many agents, one shared surface](agents-04-lanes-and-integration.md): isolated worktrees, one owner per shared surface, conflicts sent back to the lane.
5. [Memory and lessons: keep what was verified, retract what was wrong](agents-05-memory-and-lessons.md): Symptom, Root cause, Fix, Verified, and memory as navigation, not proof.
6. [Correcting and redirecting agents: how I steer](agents-06-correcting-agents.md): the corrections I make most often, and "fix it, don't file it".
7. [Failure patterns: how agents overclaim, and how to catch it](agents-07-failure-patterns.md): unbacked receipts, shrinking denominators, NOT_RUN counted as PASS, and more.
8. [The evidence-first handoff: what a receiving agent needs](agents-08-evidence-handoff.md): six parts of a brief, and evidence back instead of a summary.
9. [Keeping the guides current: part of every task](agents-09-keeping-guides-current.md): whoever changes the system updates the guide in the same piece of work.

## How to use it

Read the lessons in order the first time: each one assumes the roles and words of the ones before it. Then run each example yourself and compare your output with the recorded one byte for byte. If yours differs, that difference is the most useful thing on the page: find out why before you trust either.

## Prerequisites

- A Linux AArch64 host with `sh`, `git` and coreutils.
- The `.om` examples were compiled, in the recorded host runs, with the pinned omc from [aien-dev/omega-mv](https://github.com/aien-dev/omega-mv/tree/19f014f2178ca9cd3473728fe00a475a2398c409/seed/out), sha256 `befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d`. The runners that checked that hash were retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31).
- A clone of [aien-dev/omega-harness](https://github.com/aien-dev/omega-harness/tree/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills) for lesson 2.
- The Omega track ([omega.md](omega.md)) helps if you want to read the `.om` programs line by line, but you can run them without it.

## How to read the evidence levels

Each lesson says what its evidence rests on. Here every example is EXERCISED: it ran, and its exact output is recorded next to it, with a negative control that had to fail. None of it measures how much these practices improve agents; that is not done. A checker in this track checks the shape of a decision or a record. It does not replace the person or agent who reads the content.

The rules all of this comes from are public: https://www.aienos.com/agents/RULES.md
