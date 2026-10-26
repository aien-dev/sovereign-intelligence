# Machine code: reading 16-byte GB10 instructions and their scheduling bits

Evidence level: EXERCISED. An Omega decoder ran on a Linux AArch64 host over the seed-built vector add; the bytes were read as a file, not run on a GPU here.

## Goal

See what GPU machine code (SASS) actually is on the GB10, how I learned its encoding without documentation, and read one instruction field by field, scheduling bits included.

## Explanation

NVIDIA documents PTX, a virtual instruction set, but not the real machine code its GPUs execute. To skip `nvcc` and `ptxas` I had to write that machine code myself, so I had to learn it. `docs/HOW_I_DID_IT.md` describes the three sources, and every result was checked against the chip:

1. **NVIDIA's tools as an offline oracle on my own kernels.** I wrote small probe kernels, compiled them once with `nvcc -arch=sm_121 -cubin`, printed the result with `cuobjdump -sass`, and compared kernels that differ in one detail (a register, an immediate, a predicate) to see which bits change.
2. **Mesa's open NAK compiler**, whose source records many opcodes, bit positions and latencies. Cited, not copied.
3. **The chip.** An encoding is believed only once the GPU runs it and gives the right answer. Tensor-core arithmetic was fitted on 2,048 chosen cases until one model matched every output bit.

What came out is CUDA++'s own encoder (`src/omega_blackwell_encoder.c`, `src/omega_blackwell_codegen*.c`): 59 instruction kinds, a register allocator, golden words in the tests.

**The shape of an instruction.** Every GB10 instruction is 128 bits, stored as four little-endian 32-bit words. Word 0 holds the opcode (bits 0..11), the guard predicate (12..15, where 7 means "always"), the destination register (16..23) and the first source (24..31). Words 1 and 2 hold more operands and modifiers; register 255 is `RZ`, the zero register. Word 3 is the **control word** that a normal compiler hides from you: a stall count (bits 9..12), a yield bit (13), a write scoreboard (14..16), a read scoreboard (17..19) and a wait mask (20..25), where 7 in a scoreboard field means none. Slow instructions such as memory loads set a scoreboard; a later instruction that needs the result waits on it. Get one of these bits wrong and nothing crashes: the GPU reads a register before the load lands and returns a wrong number. That is why every encoding has golden words.

**The same knowledge, written in Omega's seed.** In omega-mv, `seed/sm121/sm121.tbl` teaches the seed assembler `asm2` the GB10's instructions as plain text, read line by line from CUDApp's C encoder. `vecadd.s2` is the vector add written by hand with those names, and `vecadd.bin` is what `asm2` makes of it: 32 instructions, 512 bytes. Its gate compares the table's output with every program the C generators make. omega-mv's README for that rung records a chip run of these exact bytes on 2026-10-20 (1,048,576 additions, 0 wrong, with a one-word mutant that failed), and notes the run record is marked `dirty=3`; I did not re-run it for this lesson.

## Example

`sass.om` reads `vecadd.bin` from stdin, decodes every instruction's word 0 and control word, and spells out the add. `run.sh` names each opcode from the base words in `sm121.tbl` and compares the decoded add with the listing's own comment. The field extraction:

```om
fn word i ulong k ulong to ulong
b = add mul i 16 mul k 4
lo = or ulong get inb b shl ulong get inb add b 1 8
hi = or shl ulong get inb add b 2 16 shl ulong get inb add b 3 24
ret or lo hi
end
fn main to int
if not slurp
ret 3
end
if ne get inn 0 512
ret 3
end
for i ulong 32
line i
end
for i ulong 32
if eq and word i 0 0xfff 0x210
puts sia
reg and shr word i 0 16 0xff
puts spt
reg shr word i 0 24
puts scm
reg and word i 1 0xff
puts scm
reg and word i 2 0xff
putc 10
end
end
flush
ret 0
end
```

Command: `sh examples/cuda-08-sass-words/run.sh`

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
vecadd.bin sha256 39f3dfdfc529a75a8274a27900acf4e7382b7f280a211e0412c51609f44b62a1, 512 bytes
compile rc=0
 0 op=0xb82 pred=7 rd=1 ra=255 | stall=1 yield=1 sets=- rsets=- waits=-
 1 op=0x919 pred=7 rd=9 ra=0 | stall=1 yield=1 sets=SB0 rsets=- waits=-
 2 op=0x7ac pred=7 rd=4 ra=255 | stall=1 yield=1 sets=SB0 rsets=- waits=-
 3 op=0x919 pred=7 rd=0 ra=0 | stall=1 yield=1 sets=SB0 rsets=- waits=-
 4 op=0x7ac pred=7 rd=5 ra=255 | stall=1 yield=1 sets=SB1 rsets=- waits=-
 5 op=0xc24 pred=7 rd=9 ra=9 | stall=5 yield=0 sets=- rsets=- waits=SB0 
 6 op=0xc0c pred=7 rd=0 ra=9 | stall=13 yield=0 sets=- rsets=- waits=SB1 
 7 op=0x94d pred=0 rd=0 ra=0 | stall=5 yield=1 sets=- rsets=- waits=-
 8 op=0xb82 pred=7 rd=2 ra=255 | stall=1 yield=1 sets=SB0 rsets=- waits=-
 9 op=0x7ac pred=7 rd=4 ra=255 | stall=7 yield=1 sets=SB1 rsets=- waits=-
10 op=0xb82 pred=7 rd=4 ra=255 | stall=8 yield=1 sets=SB2 rsets=- waits=-
11 op=0xb82 pred=7 rd=6 ra=255 | stall=1 yield=1 sets=SB3 rsets=- waits=-
12 op=0x825 pred=7 rd=2 ra=9 | stall=6 yield=0 sets=- rsets=- waits=SB0 
13 op=0x981 pred=7 rd=2 ra=2 | stall=1 yield=1 sets=SB4 rsets=- waits=SB1 
14 op=0x825 pred=7 rd=4 ra=9 | stall=6 yield=0 sets=- rsets=- waits=SB2 
15 op=0x981 pred=7 rd=5 ra=4 | stall=1 yield=1 sets=SB4 rsets=- waits=-
16 op=0x825 pred=7 rd=6 ra=9 | stall=1 yield=1 sets=- rsets=- waits=SB3 
17 op=0x210 pred=7 rd=9 ra=2 | stall=5 yield=0 sets=- rsets=- waits=SB4 
18 op=0x986 pred=7 rd=0 ra=6 | stall=1 yield=1 sets=- rsets=- waits=-
19 op=0x94d pred=7 rd=0 ra=0 | stall=5 yield=1 sets=- rsets=- waits=-
20 op=0x947 pred=7 rd=252 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
21 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
22 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
23 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
24 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
25 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
26 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
27 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
28 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
29 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
30 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
31 op=0x918 pred=7 rd=0 ra=0 | stall=0 yield=0 sets=- rsets=- waits=-
IADD3 decoded: IADD3 R9, PT, PT, R2, R5, RZ
run rc=0
== names for each opcode, from the base words in sm121.tbl (word 0, bits 0..11)
0x210: iadd3 
0x7ac: ldcu ldcu.64 
0x825: imad.wide 
0x918: nop 
0x919: s2r 
0x947: bra 
0x94d: exit exit.p0 
0x981: ldg 
0x986: stg stg.strong.sys 
0xb82: ldc ldc.64 
0xc0c: isetp.ge.u 
0xc24: imad.u 
== oracle: the listing's own comment for this instruction (vecadd.s2)
listing: IADD3 R9, PT, PT, R2, R5, RZ
decoded add: MATCH
== negative control: one bit changed in the add's destination register (byte 274)
IADD3 decoded: IADD3 R8, PT, PT, R2, R5, RZ
decoded add: DIFFERS
mutant run rc=0
```

Read the scoreboards down the listing: the two loads at instructions 13 and 15 (`ldg`) set SB4, and instruction 17, the add, waits on SB4 with a 5-cycle stall. That is the dependency "add only after both loads have landed", written in bits. Instructions 21 to 31 are `nop` padding. The decoded add equals the listing's comment, `IADD3 R9, PT, PT, R2, R5, RZ`. The negative control flips one bit of the destination byte: the decoder now says `R8`, the comparison says DIFFERS. The decoder itself exits 0 in both cases, because a flipped bit is still a valid instruction; only a check against an independent expectation catches it, which is the whole argument for golden words.

## Common mistake

Treating the control word as optional, or copying it from another instruction. A wrong stall or a missing wait does not fault; it produces wrong numbers some of the time. Decode the control bits of every instruction you emit, and keep golden words per instruction kind with a chip run behind them.

What is not done: CUDA++'s own disassembler (roadmap bar C6) is BUILDING on an Omega branch; some host tests still call NVIDIA's `nvdisasm` as an optional cross-check when it is installed.

## Where to go deeper

- [docs/HOW_I_DID_IT.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/HOW_I_DID_IT.md), step 2.
- The encoder: [src/omega_blackwell_encoder.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/src/omega_blackwell_encoder.c) and [src/omega_blackwell_codegen.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/src/omega_blackwell_codegen.c) (the "Control words" note).
- The seed rung: [seed/sm121/README.md](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/sm121/README.md), [sm121.tbl](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/sm121/sm121.tbl), [vecadd.s2](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/sm121/vecadd.s2), and the chip receipt folder [evidence/SEED-0/sm121/chip](https://github.com/aien-dev/omega-mv/tree/19f014f2178ca9cd3473728fe00a475a2398c409/evidence/SEED-0/sm121/chip).
- [ROADMAP.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/ROADMAP.md): bar C6, the disassembler.
