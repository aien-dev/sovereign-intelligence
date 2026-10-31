# Omega: the seeded language

This track teaches Omega the way I write it: a small systems language whose compiler, `omc`, is itself written in Omega and grown from 408 hand-written bytes, with no C compiler in the path that builds it. Every lesson has a runnable example compiled by the pinned compiler, its real recorded output, and at least one negative control: a refused compile or a trap with its real exit code.

## Who it is for

Programmers and coding agents who want to write `.om` that the compiler actually accepts, and anyone curious why I built a language where every loop is finite, every conversion is checked, and a missing feature is something you add rather than work around. You do not need to know AArch64 or compilers to start; lessons 5 and 6 go deeper.

## Prerequisites

- The lessons are seeded Omega sources plus a recorded Linux AArch64 host run. No GPU is used anywhere in this track.
- The host runners that compiled those sources with the pinned omc were retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Lesson 6's Node WebAssembly oracle was retired with them. The recorded output stays; it is not a new run.
- A clone of [omega-mv](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/README.md) at commit `19f014f2178ca9cd3473728fe00a475a2398c409`, whose `seed/out/omc` has sha256 `befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d`, is what those past runs used.

## Lessons

1. [Your first Omega program: hello, compile, run, exit status](omega-01-hello-world.md)
2. [Values and types: prefix words and no implicit conversions](omega-02-values-and-types.md)
3. [Loops in Omega: while with a bound, for with a count](omega-03-loops.md)
4. [Arrays, globals and host I/O: counts and negative errno](omega-04-arrays-and-io.md)
5. [The seeded compiler: from 408 bytes to omc, and what a fixpoint proves](omega-05-seeded-compiler.md)
6. [IR mode and WebAssembly: one source, two targets (and where SPIR-V stands)](omega-06-ir-and-wasm.md)
7. [OM-2: letting the compiler hold the contract](omega-07-om2-contracts.md)
8. [Compiler error codes and how to fix them](omega-08-error-codes.md)
9. [Building a missing feature: how a new word gets into Omega](omega-09-adding-a-word.md)

## How to read the evidence lines

Each lesson starts with an evidence level. EXERCISED means I ran it on a host and recorded the output; it never means hardware qualification. PROPOSED means it is described or in an open pull request, not on the pinned commit (SPIR-V, in lesson 6). Calling Omega from C and Python through omega-bridge is not a lesson here: the bridge at its pinned commit bootstraps a different, older compiler (sha256 `191b776e...98e9`) from its own source pin, so I could not run it with this track's compiler.

## Where to go deeper

- [OMEGESE, the language document](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md)
- [OM-2 tutorial and guarantee matrix](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OM2-TUTORIAL.md)
- [seed/README.md, the compiler ladder](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/README.md)
- [ROADMAP-1.0, what 1.0 still needs](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/ROADMAP-1.0.md)
- [The omega-encoding guide for writers and agents](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-encoding/SKILL.md)
