# OM-2: letting the compiler hold the contract

Evidence level: EXERCISED. The OM-2 units and refusals below were compiled and run with the pinned omc on a Linux AArch64 host; the guarantee matrix rows I quote are the repository's own classes, not my re-verification.

## Goal

Opt a unit into the OM-2 profile, use three checks the compiler holds for you (external byte layouts, definite writes to fresh scratch, sealed types), read OM-2 diagnostics, and know what the guarantee matrix does and does not promise.

## Explanation

OM-2 is opt-in per unit. If the first line that is not blank or a `note` is exactly `om2`, `om2 diag` or `om2 fmt`, the unit is OM-2; otherwise it stays OM-1 and keeps its exact meaning. In an OM-1 unit the OM-2 words are not words at all: `rotr` there is error 3.

What OM-2 adds, in the order I reach for it:

- **External layouts.** `layout NAME SIZE`, then `field F T [COUNT] at OFF little|big` lines, then `end`. A parameter `c edit NAME` is a `uchar` array of exactly SIZE bytes, and `get c F` / `put c F v` load and store with the field's width and byte order. Offsets and endianness are the compiler's, not a comment's. A field past SIZE or a byte shared with an earlier field is error 29 (`obligation=layout`).
- **Fresh scratch.** A parameter `s edit T N fresh` has unspecified contents. omc tracks which elements are definitely written on the path it is compiling; reading one that is not is error 27 (`obligation=init`).
- **Abstract types.** `abstract v32 ulong` with `holds v32 dup32` makes a type only its constructor can produce, through `seal`. A `seal` elsewhere is error 28. The run-time check of the invariant is erased only when the constructor's body has one exact shape the compiler can prove.
- **Compact code with limits.** `for ... unroll`, `inline`, `rotr`/`rotl`, hex literals, unsized views `view T *` and `part A o k` slices. Every expansion is bounded by contract (64 copies, 4 inline levels, 65536 words), and every index into an unsized view keeps its run-time check.
- **`om2 diag`.** Each refusal gets a machine-readable `omc-diag` record (code, line, column, byte span, the bytes found, the obligation), each run-time trap site an `omc-site` record, and each `seal` an `omc-check` record saying whether its check was kept or erased.

The guarantee matrix in the OM-2 tutorial is the honest part. It marks as SUPPORTED, among others, that every index into an unsized view is checked and that a fresh element read before a definite write is refused. It marks as NOT ESTABLISHED the behaviour of arbitrary OM-2 programs, and constant-time behaviour in general as NO CLAIM. Packed structs, imports, shared objects and a heap are UNSUPPORTED at this pin.

## Example

`header.om`, my own small OM-2 unit:

```
note header.om: an OM-2 unit. The compiler, not a comment, owns the byte layout
om2
layout hdr 8
field magic uint at 0 big
field size ushort at 4 little
field kind uchar at 6 little
field flags uchar at 7 little
end
fn mkhdr c edit hdr to void
put c magic 0x4f4d4547
put c size 512
put c kind 2
put c flags 0
end
fn main to int
c = new uchar 8 0
mkhdr c
note big-endian magic: the first four bytes spell OMEG
w = write 1 c 0 4
nl = new uchar 1 10
w = write 1 nl 0 1
note size 512 little-endian is the bytes 0 then 2
if ne get c 4 0
ret 1
end
if ne get c 5 2
ret 2
end
ret 0
end
```

The refusals, `overlap.om` and `fresh.om`, both with `om2 diag`:

```
note overlap.om: negative control. size would share byte 3 with magic (error 29, layout)
om2 diag
layout hdr 8
field magic uint at 0 big
field size ushort at 3 little
end
fn main to int
ret 0
end
```

```
note fresh.om: negative control. element 1 of fresh scratch is read before any write (error 27, init)
om2 diag
fn first s edit uint 4 fresh to uint
put s 0 1
ret get s 1
end
fn main to int
s = new uint 4 0
ret int first s
end
```

The script also compiles the repository's `examples/om2-tour.om` as is, under `om2 diag`, and with two mutations.

Command:

```sh
sh examples/omega-07-om2-contracts/run.sh
```

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. an external byte layout, written through an edit parameter
compile header.om rc=0
OMEG
run header rc=0
== 2. error 29 (layout): two fields share a byte
compile overlap.om rc=29
omc: line 5: error 29
omc-diag 1 code=29 sev=error line=5 col=24 span=160-166 expect=type found=6c6974746c65 obligation=layout profile=OM-2
== 3. error 27 (init): a fresh element is read before it is written
compile fresh.om rc=27
omc: line 5: error 27
omc-diag 1 code=27 sev=error line=5 col=11 span=168-169 expect=value found=31 obligation=init profile=OM-2
== 4. without the om2 line, rotr is an unknown word (error 3)
compile oneline.om rc=3
omc: line 3: error 3
== 5. the repository's tour: examples/om2-tour.om
compile tour rc=0
run tour rc=0
== 6. the same tour under 'om2 diag': trap sites and the erased constructor check
compile diag rc=0
omc-site records: 15
omc-check 1 erased line=11 rule=dup32
== 7. negative control: a predicate omc does not know (holds v32 dup31)
compile dup31 rc=28
omc: line 8: error 28
== 8. negative control: one changed constant in stamp is caught by main
compile stamp rc=0
run stamp rc=11
RESULT PASS
```

The layout writes `OMEG` big-endian and size 512 little-endian, and the program checks both bytes. The overlap and the unwritten read are refused with their obligation named. The tour compiles and runs; under `om2 diag` it reports its trap sites and the erased `dup32` check on line 11. An unknown predicate is error 28, and a one-digit change inside `stamp` is caught by the tour's own check (exit 11).

## Common mistake

Using OM-2 words without the `om2` line (error 3 on `rotr`, error 6 on `0x10`), or reading an erased check as "the compiler optimised away safety". Erasure happens only for the exact proven shape; change the body and the check comes back, and `om2 diag` tells you which it did. And do not quote the guarantee matrix as broader than it is: fixtures and mutants, not proofs.

## Where to go deeper

- [OM-2 tutorial and guarantee matrix](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OM2-TUTORIAL.md) ([matrix](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OM2-TUTORIAL.md#L178))
- [OMEGESE section 9.13, what omc implements of OM-2](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L624)
- [The normative contract, spec/omegese-om2.md](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/spec/omegese-om2.md)
- [examples/om2-tour.om](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/examples/om2-tour.om) and [the OM-2 fixtures](https://github.com/aien-dev/omega-mv/tree/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/om2)
