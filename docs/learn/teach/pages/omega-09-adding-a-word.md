# Building a missing feature: how a new word gets into Omega

Evidence level: EXERCISED. The `random` word, its fixture and its refusals were compiled and run with the pinned omc on a Linux AArch64 host; the workflow itself is a project rule, not a measured result.

## Goal

When Omega lacks something you need, add it the way I add words: a concrete proposal, a keyword, a lowering in the compiler, a guide row, a gate fixture, negative controls, and a compiler fixpoint, all in one reviewable change.

## Explanation

My rule is short: if `.om` does not have a feature you need, make that feature. Do not write the missing part in C, Rust, Python or shell and call the result Omega, and do not invent a word in your program and hope. A missing word is a concrete extension proposal, and then an implementation.

The proposal answers five questions before any code:

1. **The need.** Which OS or hardware operation, and which program needs it.
2. **The word and its types.** Its exact spelling, its inputs and their types, and what it returns. Host words follow one convention: `fd`, flags and modes are `int`; offsets and counts `ulong`; buffers `uchar` arrays; every result a `long` that is a count or minus the Linux errno.
3. **The refusals.** Which programs the compiler must reject and with which code (a read-only array is 20, a wrong type is 7), and which run-time checks trap (a bad slice is trap 3).
4. **The gate.** A fixture that proves the word does what it says, including a case that must fail.
5. **The guide update.** The row in OMEGESE and the language guide that tells the next writer it exists.

A real example is the `random` host word, Linux `getrandom`, added in commit [3fba1c43](https://github.com/aien-dev/omega-mv/commit/3fba1c438bfc05f4469a581a9d2f428336f41a56). That one change touched `seed/omc/omc.om` (the keyword, id 135, and a lowering function `hrand` that checks the slice and issues the system call), `seed/omc/genkw.awk` (the keyword list), `docs/one_layer/OMEGESE.md` (one table row), `seed/host/tests/random.om` plus three lines in `seed/host/gate.sh` (the fixture: exactly 8 bytes, not all zero, two calls differ, an invalid flag gives a negative result), `seed/README.md` (rung R17), and `seed/out/omc` with its hash, because the compiler rebuilt itself to a new fixpoint. The commit message also records a corpus audit: 103 benchmark files, 0 output differences after reserving the new keyword.

Inside omc, a keyword is its spelling packed into one ulong, first byte lowest. The example computes that number for `random` in Omega and finds it in `fn kw`, next to `ret 135`. Reserving a word also means nobody can use it as a name any more, so `random = ulong 1` becomes error 16. That is why the audit matters.

## Example

`kwpack.om` computes the packed spelling (the `putnum` helper is from lesson 3):

```
note kwpack.om: how omc spells a keyword inside itself. The bytes of "random", first byte lowest,
note packed into one ulong: the number fn kw in seed/omc/omc.om compares against for word id 135
text word "random"
fn putnum v ulong to long
note write v in decimal and a newline. A ulong has at most 20 digits, so bound 20 is proved
d = new uchar 21 0
o = new uchar 21 0
n = ulong 0
x = v
while true bound 20
put d n uchar add rem x 10 48
n = add n 1
x = div x 10
if eq x 0
break
end
end
for i ulong n
put o i get d sub sub n i 1
end
put o n 10
w = write 1 o 0 add n 1
ret w
end
fn main to int
v = ulong 0
for i ulong len word
v = or v shl ulong get word i mul i 8
end
w = putnum v
ret 0
end
```

The refusals the word promises, one file each: `intotext.om` (a text is read-only), `badflags.om` (flags passed as a `ulong`), `asname.om` (the word as a name) and `overrun.om` (8 bytes at offset 4 of an 8-byte array):

```
note overrun.om: negative control. 8 bytes from offset 4 do not fit 8; checked before getrandom (trap 3)
fn main to int
a = new uchar 8 0
r = random a 4 8 0
ret 0
end
```

Command:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. the guide row in docs/one_layer/OMEGESE.md
OMEGESE.md rows for random: 1
== 2. the keyword: compute its packed spelling in Omega, then find it in omc.om
compile kwpack.om rc=0
120325193752946
run kwpack rc=0
767:if eq w 120325193752946
768-ret 135
== 3. the lowering: fn hrand issues Linux syscall 278 (getrandom on arm64)
1:fn hrand dst ulong x ulong to void
10:hsys 278
== 4. the host gate fixture, compiled and run as the gate does
compile seed/host/tests/random.om rc=0
run random rc=0
== 5. negative control: the fixture with a wrong expected count must fail
compile mutant rc=0
run mutant rc=1
== 6. the refusals the word promises
compile intotext.om rc=20
omc: line 4: error 20
compile badflags.om rc=7
omc: line 4: error 7
compile asname.om rc=16
omc: line 3: error 16
compile overrun.om rc=0
run overrun rc=103
RESULT PASS
```

The guide row exists once. The packed number computed in Omega matches the line in `omc.om` that returns 135. `hrand` issues system call 278 (getrandom on arm64). The repository's own fixture compiles and passes; with its expected count changed from 8 to 9 it fails with exit 1, so the fixture can fail. The three compile refusals and the run-time trap 3 are what the word's contract says.

## Common mistake

Two opposite ones. Writing a host-language helper and calling it Omega, which hides the gap the project exists to close. And adding a word without the rest of the change: no refusal cases, no fixture that can fail, no guide row, no corpus audit of the newly reserved spelling, no fixpoint. Each of those is part of the feature. If you cannot land it yourself, the proposal (need, word, types, refusals, gate, guide row) is the useful thing to file.

## Where to go deeper

- [The random host word commit](https://github.com/aien-dev/omega-mv/commit/3fba1c438bfc05f4469a581a9d2f428336f41a56)
- [seed/README.md rung R17, getrandom](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/README.md#L464)
- [omc.om fn kw, the keyword table](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/omc.om#L745) and [fn hrand](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/omc.om#L4662)
- [The fixture random.om](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/host/tests/random.om) and [seed/host/gate.sh](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/host/gate.sh)
- [OM_COMPLETION.md, what is open and what is blocked on a decision](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OM_COMPLETION.md)
- [omega-harness: implement in the actual language](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md)
