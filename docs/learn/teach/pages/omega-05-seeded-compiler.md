# The seeded compiler: from 408 bytes to omc, and what a fixpoint proves

Evidence level: EXERCISED. I rebuilt the compiler from the seed in a disposable copy on a Linux AArch64 host and compared it with the committed one; this is a same-lineage rebuild check, not diverse double compilation.

## Goal

Understand the chain `seed0 -> hex1 -> asm2 -> om4 -> omc`, rebuild the compiler yourself in under a second, and be precise about what the matching hash does and does not prove.

## Explanation

My question was simple: C was built from B, B from something older. If every old tool added mistakes or waste, we inherit all of it. So the `seed/` folder grows a toolchain from a few hundred hand-written bytes, and the existing C compiler and GNU tools are used only as referees that check answers, never as builders.

The ladder:

- **seed0** (`seed/rung0/seed0.hex`): 408 bytes of AArch64 written by hand as hex words, each instruction named with its section of the Arm Architecture Reference Manual. It turns hex text into bytes. The one outside step is `load0.sh`, a short POSIX shell script that uses only `printf` to make the first `seed0.bin`; after that seed0 rebuilds itself.
- **hex1** adds labels; **asm2** names instructions; **om4** is a translator for Omegese written in asm2.
- **omc** (`seed/omc/omc.om`) is the Omega compiler written in Omega. om4 compiles it (stage 1), stage 1 compiles it again (stage 2), and stage 2 compiles it a third time (stage 3). Stage 2 must equal stage 3, and the om4-built and omc-built compilers must be the same bytes. Then the result goes to `seed/out/omc` with its hash beside it.

What that fixpoint proves: omc reads its own source the same way om4 does, and the committed binary is exactly what this seed and this source produce. Nobody slipped in a binary that the source does not explain.

What it does not prove: that the compiler is correct. A self-rebuild is consistency, not truth. My negative control shows it: I append one unused function to a copy of `omc.om`, and the changed source reaches a fixpoint of its own, just with a different hash. A wrong word that omc itself never uses would also survive a self-rebuild. That is why the repository also runs om4 as a referee on the corpus, planted-mistake checks, refusal-code gates and the C path as an outside referee, and why the README says plainly that this is a same-lineage check, not diverse double compilation.

The rebuild script rewrites tracked files (`om4.s`, `om4.bin`, `seed/out/omc`), so I never run it in a clone I care about. The example copies `seed/` into a temporary directory first.

## Example

The program part is `hello.om` from lesson 1, compiled by both compilers. `extra.om` is the function appended for the negative control:

```
note extra.om: appended to a copy of omc.om as a negative control. omc never calls it
fn zzextra to int
ret 7
end
```

The past host run copied the seed tree and rebuilt omc. The shell that did that is retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read [POINTER.md](../examples/omega-05-seeded-compiler/POINTER.md). The recorded output below is that host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. the committed compiler and the hash recorded beside it
seed/out/omc.sha256: befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
seed0.bin bytes: 408
omc bytes: 297836
omc.om lines: 11118
== 2. birth: seed0 -> hex1 -> asm2 -> om4 -> omc -> omc -> omc, in a disposable copy
PASS seed0 408 bytes, rebuilds itself
PASS hex1 776 bytes, born from seed0
PASS asm2 2464 bytes, born from hex1
PASS om4 om4.bin 14224 bytes
PASS omc fixpoint befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
PASS fwd exit 0
PASS fwd runs, exit 7
PASS mut exit 0
PASS mut runs, exit 0
PASS cycle exit 9
PASS assign exit 7
RC=0
omega-from-seed.sh rc=0
rebuilt omc equals the pin: yes
== 3. the rebuilt compiler and the committed one make the same program bytes
compile rc=0 and rc=0
hello binaries identical: yes
== 4. negative control: a changed compiler source reaches a fixpoint of its own
om4-built equals omc-built: yes
stage2 equals stage3 (a fixpoint): yes
mutant fixpoint equals the pin: no
RESULT PASS
```

Every rung passes, the rebuilt compiler has exactly the pinned hash, and it writes byte-identical programs. The mutated source still reaches a fixpoint (stage 2 equals stage 3) whose hash is not the pin.

## Common mistake

Reading "the compiler reproduces itself" as "the compiler is correct", or as independent verification. It is neither. A fixpoint pins provenance and consistency; correctness comes from the referees, fixtures and gates around it, and independence would need a second compiler from a different lineage. The practical mistake is running `omega-from-seed.sh` in a shared working tree: it rewrites tracked files, so use a disposable copy and compare the hash yourself.

## Where to go deeper

- [seed/README.md, the whole ladder](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/README.md) and [rung R5, omc](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/README.md#L209)
- [omega-from-seed.sh](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omega-from-seed.sh) and [seed0.hex](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/rung0/seed0.hex)
- [omc.om, the compiler source](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/omc.om)
- [README, current state and what the fixpoint does not prove](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/README.md)
- [OM-2 guarantee matrix: fixpoint is SUPPORTED, not diverse compilation](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OM2-TUTORIAL.md#L178)
