---
name: omega-basics
description: Use before writing, reviewing or explaining Omega (.om) code for the seeded compiler omc.
---

# Omega basics

## When to use
Writing or reading `.om` code. Check every claim against the compiler you actually run; this note was checked with omc sha256 `befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d` (omega-mv `19f014f2`), Linux AArch64, which is the only host omc targets.

## Rules
1. One statement per line, words separated by spaces. Comments start with `note`. Blocks end with `end`.
2. Every operator is a prefix word with fixed arity: `add mul r r 4` is (r*r)+4. There are no infix operators.
3. No implicit conversions: both sides of an operation must have the same type (error 7). A bare number needs a type from context, otherwise write `uint 5` (error 11).
4. Loops always have a bound: `while COND bound N` runs at most N passes; one more traps with exit 104. Choose N from a reason, and write that reason in a `note`.
5. Names other than functions have at most 8 characters (error 13). A function has at most 6 parameters.
6. Error 12 means the 16-register pool ran out: split the function into helpers with fewer live names.
7. A runtime trap exits with 100 plus its code, so keep your own exit codes below 100.
8. Only compile status 0 permits running the output.

## Example (ran: compile rc=0, run rc=120)
```
note factorial of 5 with a bounded while; the exit status is the result
fn main to int
n = uint 5
f = uint 1
while gt n 1 bound 32
f = mul f n
n = sub n 1
end
ret int f
end
```
With `bound 3` instead of `bound 32` the same program traps: run rc=104.

## Learn more
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/omega-01-hello-world.md
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/omega-03-loops.md
- https://github.com/aien-dev/sovereign-intelligence/blob/main/docs/learn/teach/pages/omega-08-error-codes.md
- https://github.com/aien-dev/omega-harness
