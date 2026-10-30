# Loops in Omega: while with a bound, for with a count

Evidence level: EXERCISED. The loops, the trap 4 and the error 8 below were compiled and run with the pinned omc on a Linux AArch64 host.

## Goal

Write every loop shape Omega has (a bounded `while`, a counted `for`, `break`, `continue`) and know exactly what happens when a loop runs longer than you promised.

## Explanation

Here is the direct answer. A loop in Omega is one of two lines, closed by `end`:

```
while <condition> bound <N>
...
end

for <name> <type> <count>
...
end
```

`while` recomputes its condition before every pass. `bound N` is a promise that the body runs at most N times, with N from 1 to 999999. One pass more and the program stops with trap 4 (exit 104). If you leave `bound` off, the limit is 1000000 passes. A bound outside 1..999999 is refused at compile time with error 8.

`for i T K` runs `i` = 0, 1, ..., K minus 1, with `i` of type T. If K is a literal number the loop needs no hidden guard; if K is a name or an expression, the compiler adds the same 1000000-pass guard a `while` gets.

`break` leaves the innermost loop and `continue` jumps to its next pass (in a `while`, the condition and the bound count run again). Both outside a loop are error 9. A do-while is `while true bound N` with a `break` at the bottom.

Why did I make every loop finite? Because a program that cannot run forever is one I can reason about, and so can a model writing it. The bound is not a guess: it is a small proof you write in a `note`. Euclid's algorithm on 32-bit numbers needs far fewer than 64 passes. A ulong has at most 20 decimal digits, so a digit loop needs at most 20. A read loop where every pass consumes at least one byte of a capped input needs at most the cap plus one. If the proof is wrong, the trap tells you at the first input that breaks it, instead of a hang.

The compiler lowers `while c bound N` to a hidden counter: test the condition, then `ge counter N` goes to a trap block, otherwise the body runs and the counter grows (OMEGESE section 4). That hidden counter takes one of the 16 registers, which matters in lesson 8.

## Example

`loops.om` has all three shapes: `gcd` uses `while ... bound`, `putnum` uses the do-while shape and a `for` to reverse digits, and `main` sums 0..9 with `for` and uses `break` to find the first i with i times i above 3000.

```
note loops.om: while with a bound, for with a count, break, and a do-while shape
fn gcd a uint b uint to uint
note Euclid: b falls every pass; 64 passes is far more than 32-bit inputs need
while ne b 0 bound 64
t = rem a b
a = b
b = t
end
ret a
end
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
g = gcd 1071 462
w = putnum ulong g
s = ulong 0
for i ulong 10
s = add s i
end
w = putnum s
f = ulong 0
for i ulong 100
if gt mul i i 3000
f = i
break
end
end
w = putnum f
ret 0
end
```

The negative control `runaway.om` needs 10 passes but promises 5; `bounded.om` is the same loop with the right bound; `toobig.om` asks for a bound of 1000000.

```
note runaway.om: negative control. the loop needs 10 passes but promises at most 5
fn main to int
n = uint 0
while lt n 10 bound 5
n = add n 1
end
ret int n
end
```

Command:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. gcd(1071, 462) with while+bound, sum of 0..9 with for, first i with i*i > 3000 with break
compile loops.om rc=0
21
45
55
run loops rc=0
== 2. trap 4: one pass more than the bound allows (exit 100 + 4)
compile runaway.om rc=0
run runaway rc=104
== 3. the fix: a bound that matches the proof
compile bounded.om rc=0
run bounded rc=10
== 4. error 8: a written bound outside 1..999999
compile toobig.om rc=8
omc: line 4: error 8
RESULT PASS
```

The program prints gcd(1071, 462), the sum of 0..9 and the first i with i times i above 3000. The runaway loop exits 104 (trap 4), the corrected one exits 10, and the oversized bound is error 8.

## Common mistake

Picking a bound by feel ("1000 should be enough"), or making it huge so the trap never fires. Either hides the reasoning the bound is there to hold. Write the proof in a `note` above the loop and choose N from it. The other mistake is relying on `and` to protect a load: `and lt i len a eq get a i 0` evaluates both sides, so the `get` still runs and traps 3 when `i` is out of range. Test the index in an outer `if` and load inside it.

## Where to go deeper

- [OMEGESE section 3, while, for, break, continue](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L49)
- [OMEGESE section 4, how loops are lowered](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L126)
- [OMEGESE section 9.8, break, continue and trap](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L518)
- [The trap 4 fixture t_loop.om](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/rung4/tests/t_loop.om) and its [expected status](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/rung4/tests/t_loop.want)
