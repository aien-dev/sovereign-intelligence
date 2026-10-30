# Compiler error codes and how to fix them

Evidence level: EXERCISED. Every refusal and fix below, and the repository's own refusal gate, ran with the pinned omc on a Linux AArch64 host.

## Goal

Read an `omc: line N: error K` refusal, know what each code means, and fix the ones people hit most: 12 (registers), 9 (word in the wrong place), 13 (name too long) and 16 (syntax).

## Explanation

omc refuses a program with one line on stderr, `omc: line N: error K`, and exits with K. There are no warnings and no "probably fine". The codes, as `seed/omc/gate15.sh` pins them with one minimal program each:

| Code | Meaning | Code | Meaning |
|---|---|---|---|
| 1, 2 | compiler I/O | 13 | non-function name over 8 characters |
| 3 | unknown name or word | 14 | a capacity (names, functions, blocks, input size) |
| 4 | line ends too early | 15 | missing `end` |
| 5 | extra words on the line | 16 | syntax or unknown word in that place |
| 6 | malformed number | 17 | a line after `ret`, `break`, `continue`, `trap` or `exit` |
| 7 | type mismatch | 18 | missing `ret` |
| 8 | number out of range | 19 | a global passed, or one array twice in a call |
| 9 | word in a disallowed place | 20 | write to a view or text |
| 10 | duplicate name | 21 | constant index out of range |
| 11 | ambiguous bare number | 22 | bad text literal |
| 12 | register pool exhausted | 23 | size capacity |

OM-2 adds 27, 28 and 29 (lesson 7).

**Error 12** is the one that surprises people. Each function gets 16 registers. Parameters, every live name, the hidden counter of each open loop and the temporaries of the current statement all come from that pool, and the compiler says error 12 when it needs one more. `blend.om` has six parameters, eleven named results all still needed on the last line, and that line's temporaries. The fix is the one I use everywhere: split the work into helpers, each with few live names. A rule of thumb is about 10 live names per function. To be sure the split computes the same value, `split.om` also keeps a reference (`blendref`) that computes the refused body one sum at a time, and `main` compares them; a deliberately wrong split fails that comparison.

**Error 9** means a word is valid but not here: `new` inside a loop or `if` (local arrays live only in a function's outermost block), `break` outside a loop, a seventh parameter, `free`, host words in function mode. Move the line, usually up to the top of the function.

**Error 13**: names other than functions are at most 8 characters. `totalsize` has 9.

**Error 16**: the parser met a word it cannot use there. Common causes are C habits (a C parameter list written after main), an array parameter without its length (`a view uchar` instead of `a view uchar 4`), and a variable used as an array length.

## Example

The refused program:

```
note blend.om: refused with error 12. Six parameters, eleven named results and the temporaries of
note the last line all want one of the 16 registers at the same time
fn blend a ulong b ulong c ulong d ulong e ulong f ulong to ulong
ab = mul a b
cd = mul c d
ef = mul e f
ac = add a c
bd = add b d
ce = xor c e
df = xor d f
s1 = add ab cd
s2 = add ef ac
s3 = add bd ce
ret add add add s1 s2 add s3 df add add ab cd ef
end
fn main to int
x = blend 1 2 3 4 5 6
ret int and x 255
end
```

The fix, the first part of `split.om` (the file then adds `putnum`, the reference `blendref` and a `main` that compares them):

```
note split.om: the error 12 fix. Same value, two helpers, each with few live names
note blend = s1 + s2 + (s3 + df) + (ab + cd + ef) = 2 * (ab + cd + ef) + (ac + bd + ce + df)
fn prods a ulong b ulong c ulong d ulong e ulong f ulong to ulong
ret add add mul a b mul c d mul e f
end
fn mixes a ulong b ulong c ulong d ulong e ulong f ulong to ulong
ret add add add a c add b d add xor c e xor d f
end
fn blend a ulong b ulong c ulong d ulong e ulong f ulong to ulong
p = prods a b c d e f
m = mixes a b c d e f
ret add add p p m
end
```

Command:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. error 12: the 16-register pool runs out
compile blend.om rc=12
omc: line 14: error 12
== 2. the fix: split the work into helpers
compile split.om rc=0
106
123
run split rc=0
== 2b. negative control: a wrong split (xor d f made and d f in mixes) fails the reference check
compile badsplit rc=0
run badsplit rc=3
== 3. error 9: new inside a loop
compile inblock.om rc=9
omc: line 5: error 9
== 4. the fix: hoist the array to the outermost block
compile hoisted.om rc=0
run hoisted rc=16
== 5. error 13: a 9-character variable name
compile longname.om rc=13
omc: line 3: error 13
== 6. error 16: an array parameter without its length
compile nolength.om rc=16
omc: line 2: error 16
== 7. the fix: state the length
compile withlen.om rc=0
run withlen rc=20
== 8. the whole table: seed/omc/gate15.sh, one minimal refusal per code, in a disposable copy
PASS gate15 21 refusal cases (codes 3..23; 1 and 2 are compiler I/O) plus a valid control
gate15 rc=0
RESULT PASS
```

`blend.om` is refused with error 12 at its last line. The split prints two values, and both match the reference. The wrong split (one `xor` changed to `and`) compiles but exits 3 at the comparison. The other refusals and fixes follow, and the last section runs `gate15.sh` itself in a disposable copy with the pinned compiler: 21 refusal cases plus a valid control.

## Common mistake

Working around error 12 by shortening names or deleting checks. Names do not cost registers; live values do. Split the function, keep a reference or a test that shows the split computes the same thing, and run a negative control. For every code: make the smallest program that still fails, decide whether it is your program, a documented limit, or a compiler defect, and fix one thing at a time.

## Where to go deeper

- [gate15.sh, one minimal program per code](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/gate15.sh)
- [OMEGESE section 9.2, functions, names and parameters](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L409) and [9.6, capacities](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L488)
- [omc.om: the register pool (poolc)](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/omc.om#L216) and [alloc, where error 12 is raised](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/omc.om#L2369)
- [OM-2 tutorial, what to do when the compiler refuses](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OM2-TUTORIAL.md#L242)
