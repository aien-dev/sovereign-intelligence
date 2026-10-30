# Values and types: prefix words and no implicit conversions

Evidence level: EXERCISED. Every claim below is a compile or run status I recorded with the pinned omc on a Linux AArch64 host.

## Goal

Read and write Omega values: prefix words with a fixed number of inputs, numbers that always have a type, and conversions that are checked instead of silently truncated.

## Explanation

Omega has no infix operators. Every operation is a word written before its inputs, and every word takes a fixed number of values: `add`, `sub`, `mul`, `div`, `rem`, `and`, `or`, `xor`, `shl` and `shr` take two; `neg` and `not` take one; comparisons `eq ne lt le gt ge` take two and give a `bool`. Because the count is fixed, nesting needs no brackets: `add mul a a 4` is (a times a) plus 4, read innermost first, left to right. I designed it that way so a model writing code has exactly one spelling for each meaning, and so the compiler never guesses precedence.

The types are `bool uchar ushort uint ulong byte short int long` (bool, u8, u16, u32, u64, i8, i16, i32, i64), plus `f32` and `f64`. `uchar` is an 8-bit number, never a character.

Three rules do most of the work:

1. **No implicit conversions.** Both inputs of an operation, a value and the name it is written to, an argument and its parameter: all must have the same type, or the line is refused with error 7. A `uint` plus a `long` does not quietly become anything.
2. **A bare number needs a place that gives it a type.** In `add a 4` the 4 takes `a`'s type. In `x = 5` for a new `x` nothing says what 5 is, so it is error 11. Write `x = uint 5`. Two bare numbers in one operation (`add 2 3`) are error 11 for the same reason.
3. **A conversion is checked.** `uchar big` converts; if the value does not fit, the program traps 5 and exits 105. If I want the low byte, I say so with a mask first: `uchar and big 255`.

Arithmetic follows the type, too. Unsigned words wrap modulo 2 to the width (`uchar 255` plus 1 is 0). Signed words trap 1 on overflow instead of wrapping. Division by zero traps 2. These are not optional checks: they are the meaning of the words (OMEGESE section 9.3).

## Example

`values.om`:

```
note values.om: prefix words, typed numbers, unsigned wrap, a checked conversion
fn main to int
a = uint 7
b = add mul a a 4
note b = (7 * 7) + 4, a uint because a is a uint
c = uchar 255
d = add c 1
note uchar arithmetic wraps modulo 256, so d is 0
if ne d 0
ret 1
end
big = uint 300
low = uchar and big 255
note mask first, then convert: the value fits, so the conversion does not trap
if ne low 44
ret 2
end
ret int b
end
```

The negative controls are one line each. `narrow.om` converts 300 to `uchar` without a mask; `mixed.om` adds a `long` to a `uint`; `bare.om` writes `x = 5`. `fixed.om` repairs both refusals by naming every type:

```
note fixed.om: the two refusals above, fixed by naming every type
fn main to int
x = uint 7
y = add ulong x 1
z = uint 5
ret int add y ulong z
end
```

Command:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. values: exit status is the computed value b = 53
compile values.om rc=0
run values rc=53
== 2. trap 5: a conversion whose value does not fit (exit 100 + 5)
compile narrow.om rc=0
run narrow rc=105
== 3. error 7: no implicit conversion between uint and long
compile mixed.om rc=7
omc: line 4: error 7
== 4. error 11: a bare number with no type
compile bare.om rc=11
omc: line 3: error 11
== 5. the fix: say every type; 8 + 5 = 13
compile fixed.om rc=0
run fixed rc=13
RESULT PASS
```

`values.om` exits 53, which is `add mul a a 4` with `a` = 7. The wrap and the masked conversion pass their own checks inside the program (exits 1 and 2 would say otherwise). The unmasked conversion traps 5. The two type errors are refused at compile time with the line number, and the fixed version exits 13.

## Common mistake

Expecting the compiler to widen or narrow for you, as C does. When omc says error 7, find the operation whose two inputs differ and write the conversion yourself (`ulong x`), on purpose, where you mean it. When it says error 11, give the number a type (`uint 5`). And never convert to a narrower type without thinking about the values that do not fit: either mask first, or let the trap 5 tell you your assumption was wrong.

## Where to go deeper

- [OMEGESE section 3, values and typing](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L73)
- [OMEGESE section 9.3, numbers: wrap, traps, no implicit conversions](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L429)
- [The conversion trap fixture t_conv.om](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/rung4/tests/t_conv.om)
- [gate15.sh, one minimal case per refusal code](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/gate15.sh)
