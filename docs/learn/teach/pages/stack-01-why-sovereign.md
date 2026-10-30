# Why sovereign: owning every layer

Evidence level: EXERCISED. The example ran on a Linux arm64 host with the pinned compiler; nothing in the stack is hardware QUALIFIED yet.

## Goal

Understand what I mean by a sovereign stack, where Sovereign Intelligence (SI) sits in it, and how to check for yourself that a program built with my compiler depends on nothing but the kernel below it.

## Explanation

I build my own AI on hardware I own, and I want every layer of it open to read, rebuild and change. The stack runs from the GB10 silicon at the bottom, through the kernel, the GPU driver, the CUDA++ runtime, the Omega language and compiler, the Sovereign Core engine, memory and Aien, up to the apps you touch. The full walk is in [docs/STACK.md](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/docs/STACK.md), ten layers, each with its license and its evidence level.

The package you download is called Sovereign Intelligence (SI), built on AienOS. Three repositories carry the names, and they are not the same thing:

- [aien-dev/sovereign-intelligence](https://github.com/aien-dev/sovereign-intelligence) is the front door: the installer, the signed releases, the stack map and the index of every repository.
- [aien-dev/aienux](https://github.com/aien-dev/aienux) is Aienux, the kernel: boot, scheduling, IPC and capabilities.
- [aien-dev/AienOS-nv](https://github.com/aien-dev/AienOS-nv) is AienOS's own home. SI is built on AienOS; it never replaces the name.

Owning a layer means three things to me: the source is public under a license that lets you change it, you can build it yourself, and I can show what the layer needs from the layer below. The last one is where honesty starts. Layer 1, the GB10 silicon and the firmware NVIDIA signs, is not mine and I cannot change it. Layer 2 today is NVIDIA's open kernel module; my own driver is PROPOSED. And SI alpha runs on the Spark's own Linux, not on Aienux, because Aienux has not booted on the Spark yet. I say all of that up front, because a stack map that hides its boundary is marketing.

So how do you check what a program needs below it? A Linux program is an ELF file. If it carries a `PT_INTERP` segment, the kernel first starts a dynamic loader, which then pulls in shared libraries such as libc before your code runs. If it carries neither `PT_INTERP` nor `PT_DYNAMIC`, the only thing below it is the kernel's system call interface. Omega's compiler, `omc`, is written in Omega, grows from a 408-byte seed, and emits static AArch64 ELF files directly. No assembler, no linker, no libc. The example below proves that for `omc` itself and for a program it builds, with a negative control.

The checker is itself Omega: `elfinfo.om` reads the ELF header and program header table from stdin and counts segment types. It is compiled together with a small shared helper file, `lib.om`, by plain concatenation, because Omega units compose that way; there is no import.

## Example

`elfinfo.om` (the shared helpers are in [lib.om](../examples/stack-01-why-sovereign/lib.om)):

```om
note elfinfo: read a 64-bit little-endian ELF file on stdin and say whether it needs a loader
note PT_INTERP (3) names a dynamic loader and PT_DYNAMIC (2) lists shared libraries; a file with neither
note runs on the kernel alone. exit 0 static, 1 needs a loader or libraries, 3 not an ELF64 LE file, 4 too big
text telf "elf64 little-endian\n"
text ttype "type "
text tmach "machine "
text tph "program headers "
text tload "PT_LOAD "
text tdyn "PT_DYNAMIC "
text tint "PT_INTERP "
text vstat "verdict STATIC: no loader, no shared libraries, only kernel system calls below it\n"
text vdyn "verdict DYNAMIC: needs a loader and shared libraries before its first instruction\n"
text vnot "verdict NOT_ELF64\n"
text vbig "verdict REFUSED input too big\n"
text nl "\n"
global ph ulong 4
fn rd16 o ulong to ulong
ret or ulong get inb o shl ulong get inb add o 1 8
end
fn rd32 o ulong to ulong
ret or rd16 o shl rd16 add o 2 16
end
fn rd64 o ulong to ulong
ret or rd32 o shl rd32 add o 4 32
end
fn kv t view uchar * v ulong to void
ot t
on v
ot nl
end
fn isel n ulong to bool
note magic 127 E L F, class 2 (64-bit), data 1 (little-endian)
if lt n 64
ret false
end
if ne get inb 0 127
ret false
end
if ne get inb 1 69
ret false
end
if ne get inb 2 76
ret false
end
if ne get inb 3 70
ret false
end
if ne get inb 4 2
ret false
end
if ne get inb 5 1
ret false
end
ret true
end
fn scan n ulong to bool
note count segment types; false when the header table is not inside the file
off = rd64 32
esz = rd16 54
cnt = rd16 56
if gt off n
ret false
end
if gt mul esz cnt sub n off
ret false
end
if lt esz 4
ret false
end
for i ulong cnt
t = rd32 add off mul i esz
if lt t 4
put ph t add get ph t 1
end
end
ret true
end
fn main to int
r = rdall
if lt r 0
ret 4
end
if eq get st 2 1
ot vbig
f = flush
ret 4
end
n = ulong r
ok = isel n
if ok
ok = scan n
end
if not ok
ot vnot
f = flush
ret 3
end
ot telf
kv ttype rd16 16
kv tmach rd16 18
kv tph rd16 56
kv tload get ph 1
kv tdyn get ph 2
kv tint get ph 3
v = int 0
if gt add get ph 2 get ph 3 0
v = 1
ot vdyn
else
ot vstat
end
f = flush
ret v
end
```

Run it:

The host runner for this lesson was retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read the example's POINTER.md and the native Omega sources beside it. The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
compile lib.om+elfinfo.om rc=0
== the pinned compiler, omc
elf64 little-endian
type 2
machine 183
program headers 2
PT_LOAD 2
PT_DYNAMIC 0
PT_INTERP 0
verdict STATIC: no loader, no shared libraries, only kernel system calls below it
run rc=0
== elfinfo itself, as omc built it
elf64 little-endian
type 2
machine 183
program headers 2
PT_LOAD 2
PT_DYNAMIC 0
PT_INTERP 0
verdict STATIC: no loader, no shared libraries, only kernel system calls below it
run rc=0
== negative control: the host's /bin/sh (verdict line only; its sizes differ between hosts)
verdict DYNAMIC: needs a loader and shared libraries before its first instruction
run rc=1
== negative control: elfinfo.om, a text file
verdict NOT_ELF64
run rc=3
every verdict as expected: yes
```

Both `omc` and `elfinfo` have two loadable segments and nothing else: no loader, no shared library. The host's `/bin/sh` needs a loader (exit 1), and a text file is refused as not an ELF (exit 3). I print only the verdict line for `/bin/sh`, because its header counts differ between Linux distributions and the recorded output must be the same on every machine.

What this does not show: a static binary still trusts the Linux kernel under it, and the GPU path still goes through NVIDIA's kernel module. Those are layers 3 and 2, and their status is in the stack map.

## Common mistake

Calling something "independent" because one dependency was removed. Dropping a user-space library is not the same as owning the layers under it. Check what is actually loaded (`PT_INTERP`, `PT_DYNAMIC`, and at run time `/proc/PID/maps`), name the layers you still rely on, and give each one its own evidence level. Another frequent slip is mixing the names: SI is the package, AienOS is the operating system it is built on, Aienux is the kernel.

## Where to go deeper

- [The SI README: the stack table and every repository](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/README.md)
- [The stack walked from the top down](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/docs/STACK.md)
- [What I am building: an audit of every repository](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/docs/WHAT-I-AM-BUILDING.md)
- [How to write the names](https://github.com/aien-dev/sovereign-intelligence/blob/5279659888301816d1f41e1715056560a4781608/NAMING.md)
- [Omega's README: the seeded compiler](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/README.md)
- [OMEGESE, the language reference](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md)
