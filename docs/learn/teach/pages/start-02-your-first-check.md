# Your first check: expected vs observed

Evidence level: EXERCISED. Both word counters compiled and ran on a Linux ARM64 computer against four inputs, and the recorded output shows the real check failing the wrong one; it is a teaching example, not a test suite for any product.

## Goal

Write a check that compares what you expected with what you observed, and make sure it is a check that can actually fail.

## Explanation

Most people test an agent's work the same way: try it once, see something reasonable, move on. That catches the obvious breakage and misses almost everything else, because the one input you tried is usually the easiest one.

A real check has three parts:

1. **Expected**: the right answer, written down *before* you run anything. If you look at the output first, you will talk yourself into believing it.
2. **Observed**: what the program actually printed.
3. **Compare**: same, or not. MATCH or MISMATCH. No "close enough".

And one more rule, the one that separates a check from a ritual: **the check must be able to fail.** If a check passes no matter what the program does, it tells you nothing. The usual way to prove a check can fail is a **negative control**: something you know is wrong, which the check must reject. If it accepts the wrong thing, the check is broken, not the program.

Pick inputs that could trip the program up, not just the friendly one. For a word counter: two spaces between words, an empty input, words on several lines. You do not need to read the program to think of these. You need to think about what real input looks like.

## Example

Say you asked an agent for a word counter and it gave you two tries. The first counts the spaces and adds one, which sounds right:

```
fn main to int
r = rdall
if lt r 0
ret 2
end
n = ulong r
c = ulong 1
for i ulong n
if eq get inb i 32
c = add c 1
end
end
emitu c
say 0
ret 0
end
```

The second counts the places where a word starts (a letter right after a gap):

```
fn isgap c uchar to bool
if eq c 32
ret true
end
if eq c 10
ret true
end
ret eq c 9
end
fn main to int
r = rdall
if lt r 0
ret 2
end
n = ulong r
c = ulong 0
prev = true
for i ulong n
g = isgap get inb i
if not g
if prev
c = add c 1
end
end
prev = g
end
emitu c
say 0
ret 0
end
```

`run.sh` compiles both, runs each on four inputs with the answer written down in advance, then runs a weak check that only asks "did it finish without an error?".

```sh
sh examples/start-02-your-first-check/run.sh
```

Recorded output:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile wc1.om rc=0 (expected 0)
compile wc2.om rc=0 (expected 0)

inputs (_ is a space, | is the end of a line):
one-space.txt    hello_world|
two-spaces.txt   hello__world|
empty.txt        (empty file)
three-lines.txt  one_two|three|four_five|

== wc1: real check, expected vs observed
one-space.txt    expected=2 observed=2 MATCH
two-spaces.txt   expected=2 observed=3 MISMATCH
empty.txt        expected=0 observed=1 MISMATCH
three-lines.txt  expected=5 observed=3 MISMATCH
wc1: CHECK FAIL mismatches=3

== wc2: real check, expected vs observed
one-space.txt    expected=2 observed=2 MATCH
two-spaces.txt   expected=2 observed=2 MATCH
empty.txt        expected=0 observed=0 MATCH
three-lines.txt  expected=5 observed=5 MATCH
wc2: CHECK PASS

== weak check: did it exit 0?
wc1: exit 0, weak check says PASS (it cannot tell the two apart)
wc2: exit 0, weak check says PASS (it cannot tell the two apart)

ALL EXIT STATUSES AS EXPECTED
```

On `hello world` both say 2, and if that was your one try, you would ship either. The real check finds three wrong answers in the first version: two spaces count as two words' worth of gap, an empty input has "1 word", and line breaks are not counted as gaps. The second version matches all four.

Now look at the weak check at the end. Both versions exit 0, so "it ran without errors" passes both. That check could never fail on a wrong count, which means it was never checking the count at all. Here the first word counter is the negative control: a version we know is wrong. The real check rejected it; the weak check did not. That is how you tell the two kinds of check apart.

## Common mistake

Checking "did it run?" instead of "did it give the right answer?". A program that runs without crashing can still be wrong on every input that matters. The fix is to write down the expected answer for a few tricky inputs before you look, compare exactly, and keep one known-wrong case around to prove your check can say no. When an agent tells you "all tests pass", ask what the tests compare, and whether they ever failed.

## Where to go deeper

- Previous: [You already program](start-01-you-already-program.md). Next: [Reading what your agent changed](start-03-reading-the-diff.md)
- How agents fake a green test run, and how to catch it: [agents-07-failure-patterns.md](agents-07-failure-patterns.md)
- Gates, the checks a whole project depends on: [stack-04-gates.md](stack-04-gates.md)
- Loops in Omega, like the one in these word counters: [omega-03-loops.md](omega-03-loops.md)
- Run, then challenge with a negative control (section 3): https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-harness/SKILL.md
