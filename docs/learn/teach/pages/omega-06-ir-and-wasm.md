# IR mode and WebAssembly: one source, two targets (and where SPIR-V stands)

Evidence level: EXERCISED. Native and WebAssembly results were recorded on a Linux AArch64 host, with Node used only to load and call the module. SPIR-V is PROPOSED: it is an open pull request, not on the pinned commit.

## Goal

Compile the same scalar Omega functions to an AArch64 program and, through OSC IR v1 and the Omega-written `irwasm` back end, to an import-free WebAssembly module; then know exactly what exists for SPIR-V.

## Explanation

**IR mode.** A first line `ir` tells omc to write OSC IR version 1 (a compact binary intermediate form, magic `OSC1`) instead of machine words. IR mode is deliberately the scalar subset: at most 32 functions and 6 parameters, calls only to *earlier* functions, integer constants folded, `break` allowed. It refuses what it cannot lower, by name: a `struct`, `global` or `text` declaration is error 9, and a float word, a host word, `continue`, `sizeof` or `offsetof` is error 3. It never skips a declaration silently.

**WebAssembly.** `seed/wasm/irwasm.om` is itself an Omega program. It reads OSC IR v1 on stdin and writes a deterministic WebAssembly MVP module: no memory, no imports, no WASI, every IR function exported under its own name. Small unsigned and signed types travel as `i32`, `u64`/`i64` as `i64`, and inside the module the checks stay: signed overflow, bad shifts, division by zero, failed conversions and loop guards become wasm traps (`WebAssembly.RuntimeError`). Wasm cannot carry Omega's numeric trap code, so a native trap 1 (exit 101) is just "a trap" in wasm. Refusals are named exits with empty stdout, for example 22 `TRUNCATED`.

Node appears only as a read-only oracle that loads and calls the module. It never generates IR or wasm. Any conforming wasm engine could replace it.

Composition note: Omega has no imports. Units compose by concatenation, so the native program is `fns.om` + `putnum.om` + `main.om` piped into omc together.

**SPIR-V.** At the pinned commit there is no SPIR-V emitter (`seed/spirv` is absent, which the script checks). An open pull request, [omega-mv #804](https://github.com/aien-dev/omega-mv/pull/804), adds `seed/spirv/irspirv.om`, which emits SPIR-V 1.0 OpenCL Kernel modules from the same OSC IR v1 subset. Its authors report CPU-only parity through PoCL and `spirv-val` acceptance; it is not merged, I did not run it, and `spirv-val` is not installed on the host that recorded this lesson. So for this track SPIR-V is PROPOSED, and GPU execution of either back end is not claimed.

## Example

`fns.om`, compiled both ways:

```
note fns.om: plain scalar functions. One source, two targets: AArch64 and WebAssembly
fn gcd a uint b uint to uint
while ne b 0 bound 64
t = rem a b
a = b
b = t
end
ret a
end
fn lcm a uint b uint to uint
ret mul div a gcd a b b
end
fn tri n uint to uint
note 0 + 1 + ... + (n - 1)
s = uint 0
for i uint n
s = add s i
end
ret s
end
fn addi a int b int to int
note signed add: overflow traps, it never wraps
ret add a b
end
```

`main.om` is the native driver. The Node oracle that used to load the wasm module was retired; see [POINTER.md](../examples/omega-06-ir-and-wasm/POINTER.md).

```
note main.om: the native driver. Units compose by concatenation: fns.om, putnum.om, main.om
fn main to int
w = putnum ulong gcd 1071 462
w = putnum ulong lcm 21 6
w = putnum ulong tri 10
w = putnum ulong addi 2 3
x = addi 2147483647 1
ret 0
end
```

The host runner and the Node wasm oracle were retired (Part of https://github.com/aien-dev/sovereign-intelligence/issues/31). Read [POINTER.md](../examples/omega-06-ir-and-wasm/POINTER.md). The recorded output below is a past Linux AArch64 host run, not a new run and not a hardware result. The wasm lines in that output are from the past Node oracle, not a new validation.


Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. native: fns.om + putnum.om + main.om concatenated into one program
compile native rc=0
21
42
45
5
run native rc=101
== 2. IR: a leading 'ir' line makes omc write OSC IR v1 instead of machine code
compile ir rc=0
IR magic: OSC1
== 3. the WebAssembly back end is itself an Omega program: compile irwasm.om
compile irwasm.om rc=0
irwasm rc=0
two translations identical: yes
fns.wasm sha256 3028744939f987532d7b69b272eae804761a2bae0644a83e214dbcf8961935b7
== 4. run the module (node as a read-only oracle)
valid wasm: true
imports: 0
exports: gcd lcm tri addi
21
42
45
5
addi(2147483647, 1) trapped: true
node rc=0
== 5. negative control: IR mode refuses a global pool
compile ir irglobal rc=9
omc: line 3: error 9
== 6. negative control: irwasm refuses truncated IR and writes nothing
irwasm truncated rc=22 stdout bytes=0
irwasm: TRUNCATED
== 7. SPIR-V at this pin
seed/spirv: absent (proposed in an open pull request, not on this commit)
RESULT PASS
```

Both targets give the same four answers. The native program then traps 1 on the signed overflow (exit 101); the wasm module traps with a `RuntimeError`. Two translations are byte-identical, so the module hash is reproducible. IR mode refuses the global with error 9, and irwasm refuses one-byte-short IR with exit 22 and writes nothing.

## Common mistake

Expecting IR mode to take a whole program. Keep IR units to scalar functions that call earlier functions; put arrays, text, globals and host I/O in the native driver. The second mistake is reading a wasm trap as a specific Omega trap code: it is not preserved, so if you need the code, compare against the native run as this example does. The third is calling SPIR-V "supported" because a PR exists: until it merges and you run its gate, it is PROPOSED.

## Where to go deeper

- [OMEGESE section 11, OSC IR output](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L888) and [11.1, WebAssembly](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md#L914)
- [irwasm.om, the back end in Omega](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/wasm/irwasm.om) and [gate-irwasm.sh, its parity gate](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/wasm/gate-irwasm.sh)
- [ROADMAP-1.0 RM9, targets](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/ROADMAP-1.0.md#L284)
- [The omega-encoding guide, merged IR/wasm backend section](https://github.com/aien-dev/omega-harness/blob/9ab649cd97c7a09d769f97569d62bde847af3ef4/skills/omega-encoding/SKILL.md)
