# Arrays, globals and host I/O: counts and negative errno

Evidence level: EXERCISED. The program below was compiled and run with the pinned omc on a Linux AArch64 host, with normal input, piped input and a closed stdin.

## Goal

Read all of standard input with a correct partial-read loop over a global buffer, tell a byte count from a Linux error, and know which slice mistakes the compiler and the runtime stop for you.

## Explanation

Omega has three kinds of array storage, and none of them is a heap:

- `global NAME T N`: a zero-filled pool in the program image, visible to every function, program mode only. A global is never passed as an argument (error 19); a function that works on it names it directly.
- `NAME = new T N v`: a local array on the stack, N elements each equal to v, allowed only in a function's outermost block. N is a literal or an integer `const`, never a variable.
- `text NAME "..."`: read-only bytes.

`get A i`, `put A i v` and `len A` are the only ways in. A constant index outside the array is a compile error (21); any other index is checked when it runs and traps 3. There is no word that turns an array into an address.

Host I/O is a set of words with fixed types: `read fd A off n` and `write fd A off n` take an `int` descriptor, a `uchar` array, and `ulong` offset and count. Before the kernel is called, the slice is checked: `n <= len A` and `off <= len A - n`, else trap 3. The result is a `long`, and it means one of three things: a positive count (which can be smaller than you asked for), 0 at end of input, or minus the Linux errno.

That third case is where most programs go wrong. A loop written as `while gt k 0` stops on an error exactly as it stops at end of input, and reports success. My rule is to handle `k < 0` and `k == 0` separately, every time.

The loop also needs a bound, so I cap the input. Every pass that reads data adds at least one byte, and passing `CAP` bytes stops the program with exit 3; so at most `CAP` passes read data and one more sees end of input. That is the `note` above the loop, and it is why `bound 999999` is a proof and not a guess.

## Example

`wc.om` (the `putnum` helper from lesson 3 prints a ulong in decimal):

```
note wc.om: count bytes and lines on stdin with a partial-read loop
note proof of the bound: every pass but the last reads at least one byte, and more than CAP
note bytes stops the program, so at most CAP passes read data and one more sees end of input
const CAP ulong 999998
global buf uchar 4096
text lb "bytes "
text ll "lines "
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
total = ulong 0
lines = ulong 0
done = false
while not done bound 999999
k = read 0 buf 0 len buf
if lt k 0
note a negative result is minus the Linux errno: report it, never treat it as end of input
ret int neg k
end
if eq k 0
done = true
else
n = ulong k
for i ulong n
if eq get buf i 10
lines = add lines 1
end
end
total = add total n
if gt total CAP
ret 3
end
end
end
w = write 1 lb 0 len lb
w = putnum total
w = write 1 ll 0 len ll
w = putnum lines
ret 0
end
```

`naive.om` is the negative control: the same count with `while gt k 0`. `slice.om` asks `read` for 4096 bytes at offset 1 of a 4096-byte array. `global.om` passes a global to a function.

Command:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. three short lines on stdin
compile wc.om rc=0
bytes 14
lines 3
run wc rc=0
== 2. 5000 lines of 'abc' through a pipe: many partial reads, one total
bytes 20000
lines 5000
run wc rc=0
== 3. stdin closed: read returns -9 (EBADF), the program exits 9
run wc rc=9
== 4. negative control: a loop that treats k <= 0 as end of input hides the error
compile naive.om rc=0
bytes 0
run naive rc=0
== 5. trap 3: the slice is checked before the kernel call (exit 103)
compile slice.om rc=0
run slice rc=103
== 6. error 19: a global passed as an argument
compile global.om rc=19
omc: line 7: error 19
RESULT PASS
```

With three lines the counts are 14 and 3. With 5000 lines through a pipe the program sees many partial reads of at most 4096 bytes and still prints one total. With stdin closed, `read` returns -9 (EBADF) and the program exits 9. The naive version, given the same closed stdin, prints `bytes 0` and exits 0: the error has vanished. The bad slice traps 3 before any system call, and the global argument is error 19.

## Common mistake

Treating any non-positive `read` result as end of input, or assuming one `read` fills the buffer. Loop until 0, add each partial count, and turn a negative result into a distinct exit status (or handle it), never into success. When you need an array in several functions, use a `global` and name it inside each function; do not try to pass it (error 19). Arrays passed between functions are local arrays or parameters, with the exact length in the parameter type.

## Where to go deeper

- [OMEGESE section 9.4, arrays](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L449)
- [OMEGESE section 9.5, read and write](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L476)
- [OMEGESE section 10, the native host words](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L757)
- [The host gate fixtures](https://github.com/aien-dev/omega-mv/tree/19f014f2178ca9cd3473728fe00a475a2398c409/seed/host/tests) and [the slice trap fixture t_rw.om](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/rung4/tests/t_rw.om)
