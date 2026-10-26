# You already program: what engineering adds

Evidence level: EXERCISED. The example compiled and ran on a Linux ARM64 computer, and the loosely written version was refused by the compiler with its real exit code; nothing here measures how people learn.

## Goal

See that describing what you want precisely is already programming, and learn the one thing engineering adds on top: a way to know you got it.

## Explanation

When you ask an agent "go through my notes and show me every line that starts with TODO, then tell me how many there were", you have written a program. You named the input (my notes), the rule (lines that start with TODO), and the output (those lines, then a count). The agent translates that into a language a computer can run. The translating is coding. Deciding what should happen, exactly, is programming.

Here is the thing nobody tells vibe coders: the computer never guesses. It does exactly what the program says, every time, including when the program says something you did not mean. "Starts with TODO" and "mentions TODO somewhere" are different programs. If you meant one and the agent wrote the other, the computer will happily run the wrong one, and it will look like it works on most of your notes.

So the skill that matters most is not typing code. It is two things you can practise without ever writing a line by hand:

1. **Say exactly what you want.** Input, rule, output. Where there are two ways to read your sentence, pick one out loud.
2. **Say how you will know you got it.** Before the agent runs anything, write down what the right answer looks like for an input you chose. Lesson 2 is all about this.

That second habit is the line between vibe coding and engineering. Engineering is not a club with a secret handshake. It is the habit of checking, so that you can trust what you built and so can the people who use it.

A few words you will see in every lesson, each in one line:

- **Program**: a list of exact instructions a computer follows.
- **Compiler**: a tool that turns a program written in a language (here, Omega) into something the computer can run. If the program is unclear, the compiler refuses.
- **Exit code** (shown as `rc=`): a number every program hands back when it ends. 0 usually means "fine"; anything else says what went wrong. It is the computer's way of telling you, without words, how it went.

## Example

I wrote the TODO request above as an Omega program, `todo.om`. The part that does the work:

```
fn main to int
r = rdall
if lt r 0
ret 2
end
n = ulong r
s = ulong 0
c = ulong 0
while lt s n bound 65536
e = eol s n
if pmat s e 0
c = add c 1
emiti s sub e s
say 3
end
s = add e 1
end
word 1
emitu c
say 2
ret 0
end
```

Read it as English: read all the input; go line by line; if a line starts with entry 0 of the word list (`TODO`), count it and print it; at the end print "found", the count, "TODO line(s)". Then I wrote the start of it loosely, the way people often talk: "the count starts at 0", without saying what kind of number. The compiler refuses to guess.

```sh
sh examples/start-01-you-already-program/run.sh
```

Recorded output:

```
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d (matches pin)
compile todo.om rc=0 (expected 0)

--- input notes.txt
buy milk
TODO call the plumber
TODO: back up the photos
this line mentions TODO but does not start with it
water the plants
--- output
TODO call the plumber
TODO: back up the photos
found 2 TODO line(s)
run rc=0 (expected 0)

--- the same idea written loosely
note the same start, written loosely: the count begins as a bare 0
note is that 0 a byte, an int or a 64-bit number? omc refuses to guess
fn main to int
c = 0
ret int c
end
compile vague.om rc=11 (expected 11)
omc: line 4: error 11

ALL EXIT STATUSES AS EXPECTED
```

Two things to notice. The line "this line mentions TODO but does not start with it" was not counted, because the rule says *starts with*. If you wanted "mentions", that is a different program, and only you know which one you meant. And the loose version stopped with `rc=11` and `error 11`, which in this compiler means "a bare number with no type": it could not tell whether 0 was meant to be a small byte or a big counter. A refusal like that is a gift. It is the computer asking you to be precise before anything runs, instead of quietly picking for you.

## Common mistake

Thinking that because you do not write code, you are not responsible for what the program does. You are the one who knows what it is for. If the agent's version counts "mentions" when you meant "starts with", nobody else will catch it. The fix is cheap: state the rule in one sentence with no wiggle room, and pick one input where you already know the answer. You just did both.

## Where to go deeper

- Next lesson: [Your first check: expected vs observed](start-02-your-first-check.md)
- Your first Omega program, line by line: [omega-01-hello-world.md](omega-01-hello-world.md)
- Why I build on things I own and understand: [stack-01-why-sovereign.md](stack-01-why-sovereign.md)
- What each Omega compiler error number means: https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md
- A gentle tour of the language: https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OM2-TUTORIAL.md
- The full program: [todo.om](../examples/start-01-you-already-program/todo.om)
