# You already program: from vibe coding to engineering

> "Programming and engineering are way different than coding. Nobody needs to know how to write the letters."
>
> Drake Stapleton

If you build things by describing them to an AI agent and steering it until they work, you are already programming. You decide what should exist, you break it into steps, you notice when something is wrong and you send the agent back. That is the hard part, and you are doing it. Some people call it vibe coding. I call it programming.

This track is about the next level: engineering. Not learning to type the letters. Learning to know, with evidence, that what your agent built does what you asked and nothing else. That is what turns "it seemed to work when I tried it" into something you can hand to other people and trust.

## Who it is for

People who build with AI agents and never learned to write code by hand. You do not need to read code to follow these lessons. Every example is a short script you run with one command, and every page shows the real output it printed, so you can compare yours with mine.

## Lessons

1. [You already program: what engineering adds](start-01-you-already-program.md): the computer does exactly what it is told, so the skill that matters is saying what you want and how you will know you got it.
2. [Your first check: expected vs observed](start-02-your-first-check.md): write down the answer before you look, and make sure your check can actually fail.
3. [Reading what your agent changed](start-03-reading-the-diff.md): use git diff to see every change, and catch the ones you never asked for.
4. [Asking for evidence](start-04-asking-for-evidence.md): four words that say how far a piece of work really got, and why NOT_RUN is never a pass.
5. [Steering with acceptance criteria](start-05-acceptance-criteria.md): give your agent a goal, a check you can observe, a negative control and a scope, before it starts.

## Prerequisites

- A Linux computer with an ARM64 processor (the examples use a small compiled language, Omega, whose compiler makes programs for that kind of machine), with `sh` and `git`.
- The pinned Omega compiler from [aien-dev/omega-mv](https://github.com/aien-dev/omega-mv/tree/19f014f2178ca9cd3473728fe00a475a2398c409/seed/out). Each example checks its fingerprint (a sha256 hash, a short code that changes if even one byte of the file changes) and refuses to run if it does not match.
- No GPU, no internet connection, no account. Nothing in this track touches anything outside a scratch folder it deletes when it finishes.

## How to read the evidence levels

Each lesson starts with a line like `Evidence level: EXERCISED`. That word says how far the claim on the page got. EXERCISED means the example really ran and its output is recorded next to it. Lesson 4 explains all four words. None of these lessons claims to have measured how much faster or better you get; they show the habits, and you get to try them.

## Where to go next

When you finish, pick the track that matches what you want to build:

- [Orchestrating coding agents](agents.md): run many agents at once, with reviewers and checks.
- [Building a sovereign stack](stack.md): evidence levels, receipts and gates in a real project.
- [Omega: the seeded language](omega.md): read and write the language the examples here use.
- [Reverse-engineering CUDA, the CUDA++ way](cuda.md): how I learned what a GPU driver really does.

The rules my own agents follow are public too: https://www.aienos.com/agents/RULES.md
