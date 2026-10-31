# Your first Omega program: hello, compile, run, exit status

Evidence level: EXERCISED. I compiled and ran this example with the pinned seeded compiler on a Linux AArch64 host; nothing here is hardware qualification.

## Goal

Write a complete Omega program, compile it with the pinned `omc`, run the result, and read its exit status the way every later lesson does.

## Explanation

Omega source lives in `.om` files. The compiler I use is `seed/out/omc` in [omega-mv](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/README.md). It is written in Omega itself and grown from a 408-byte hand-written seed (lesson 5 shows that). It reads one unit on standard input and writes a static AArch64 Linux program on standard output. There is no linker, no libc and no runtime library underneath: the file it writes is the whole program.

The shape of a unit is simple. One statement per line. Words are separated by spaces. Blocks close with `end`. There are no braces, commas or semicolons, and the only comment is a line that starts with `note`.

Three things make the hello program work:

- `text msg "..."` declares a read-only array of bytes with a known length. Only `\n`, `\t`, `\\` and `\"` are escapes; anything else is refused with error 22.
- `fn main to int` makes this a program. A unit with `fn main` is a runnable program; a unit without it compiles to bare function words for other callers (OMEGESE section 9.1).
- `write 1 msg 0 len msg` is the host word for Linux `write`: file descriptor, array, offset, count. It returns a `long`: the number of bytes written, or minus the Linux error number. Because it returns a value, I bind it to a name (`w = ...`) and check it.

The program's exit status is `main`'s value modulo 256. A runtime trap (an overflow, a bad index, a loop past its bound) exits with 100 plus the trap code, so I keep my own exit codes below 100. Then a status alone tells me whether the program chose to stop or the language stopped it.

My rule for every run: check the compiler's sha256 first, compile, print the compile status and whatever the compiler wrote to stderr, and run the output only when the compile returned 0. A refused compile can still leave bytes on stdout; those bytes are never a program.

## Example

`hello.om`:

```
note hello.om: the smallest useful Omega program
text msg "hello from seeded Omega\n"
fn main to int
w = write 1 msg 0 len msg
if ne w long len msg
ret 1
end
ret 0
end
```

`status.om` returns 300 on purpose, and `unbound.om` is the negative control: it calls `write` without binding its result.

```
note status.om: the exit status is main's value modulo 256
fn main to int
ret 300
end
```

```
note unbound.om: negative control. write gives a long; it cannot stand alone as a statement
text msg "hello\n"
fn main to int
write 1 msg 0 len msg
ret 0
end
```

Command (from the learn tree; `SRC` points at the pinned clones, `OMC` defaults to `$SRC/omega-mv/seed/out/omc`):

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. hello: compile, then run only if the compile returned 0
compile hello.om rc=0
hello from seeded Omega
run rc=0
== 2. the exit status is main's value modulo 256
compile status.om rc=0
run rc=44
== 3. negative control: a result that is not bound to a name
compile unbound.om rc=16
omc: line 4: error 16
RESULT PASS
```

The hello program prints its line and exits 0. `status.om` exits 44, because 300 modulo 256 is what Linux keeps. `unbound.om` is refused with error 16 on line 4, and the script never runs its output.

## Common mistake

Treating the compiler's silence as success. Always read the compile status first. Error numbers are the exit status of `omc` itself, and the message is always `omc: line N: error K`. The other mistake is calling a word that returns a value as if it returned nothing: `write` gives you a count or a negative error, so bind it and check it. For a value-returning function of your own the same mistake is error 7; for the `write` host word at this pin it is error 16.

## Where to go deeper

- [OMEGESE section 3, the language](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L49) and [section 9.1, program and function mode](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L400)
- [Section 9.5, read, write and exit](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L476)
- [seed/README.md, the compiler chain](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/README.md)
- [The omega-encoding guide, compile and run](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-encoding/SKILL.md)
