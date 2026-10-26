# The command ring: GPFIFO entries, method headers and the QMD

Evidence level: EXERCISED. An Omega program builds and decodes CUDApp's semaphore-release pushbuffer and its ring entry on a Linux AArch64 host; nothing is submitted, and native submission at this pin is NOT_RUN per CUDApp's README.

## Goal

Understand how work reaches a GPU without a system call: the ring (GPFIFO), the pushbuffer of methods, the doorbell, and where the launch descriptor (QMD) fits.

## Explanation

After the object tree of lesson 4 exists, a channel owns three pieces of shared memory: a **ring** of 8-byte entries (CUDApp uses 1,024), a **USERD** control page after it, and any number of **pushbuffers**. A pushbuffer is a list of 32-bit words: a **method header** followed by its data words. A ring entry points at a pushbuffer and says how many words it has.

To submit, the CPU does only memory writes and one store (`nvrm_enqueue` and `nvrm_ring` in `nvrm/nvrm.c`):

1. write the pushbuffer;
2. write one ring entry; a full barrier (`dsb sy`);
3. write the new `GPPut` index into USERD; another barrier;
4. ring the doorbell: one 32-bit store of the channel's work-submit token into the usermode page (`HOPPER_USERMODE_A`, `NVC361_NOTIFY_CHANNEL_PENDING`).

Blackwell's USERD reports no read pointer, so the client counts entries it has seen finish and never overruns the ring.

**The ring entry.** `clc96f.h` defines it: `GP_ENTRY0_GET` (31:2) holds the low address bits, `GP_ENTRY1_GET_HI` (7:0) the high ones, `GP_ENTRY1_LENGTH` (30:10) the length in words, plus `LEVEL` (9:9) and `SYNC` (31:31).

**The method header.** CUDApp writes it as `nvrm_mthd(subc, mthd, count)` in `nvrm/nvrm.h`: 2 in the top bits (an incrementing method: each data word goes to the next method), the count from bit 16, the subchannel from bit 13, and the method offset **in dwords** in the low bits. That header format is not in the vendored NVIDIA headers; CUDApp's `THIRD_PARTY.md` credits Mesa's open NVK driver for launch sequencing and class method offsets. The method offsets of the channel class itself are in `clc96f.h`: `SEM_ADDR_LO` is 0x5c, then `SEM_ADDR_HI`, `SEM_PAYLOAD_LO`, `SEM_PAYLOAD_HI`, `SEM_EXECUTE`.

The pushbuffer in the example is CUDApp's own first proof of life (`m16_native_build_release` in `m16/m16_native.c`): bind the compute class to subchannel 1, then a semaphore release that writes a marker into memory with a wait-for-idle. The M16 receipt's marker value is 0x16c0ffee.

**The QMD.** A real kernel launch adds a launch descriptor: a 384-byte block (`OMEGA_BW_QMD_WORDS` is 96 in `src/omega_blackwell_qmd.h`) holding grid and block size, registers, shared memory, the code address and the constant buffer with the arguments. The pushbuffer hands its address to the compute class (`MTHD_SEND_PCAS_A`, the QMD address shifted right by 8, in `src/omega_gpu_cmdlist.c`) after invalidating the shader caches. CUDApp's builder marks each QMD field as documented, observed on the GB10, or reverse engineered, and its layout facts are cited to Mesa's `nak/qmd.rs`. The native Omega version is `fn gbqmd` in `native/blackwell/launch.om`.

## Example

`gpfifo.om` builds the eight-word release pushbuffer and its ring entry exactly as CUDApp's C does, then decodes every word back into fields and checks the round trip. `run.sh` takes the compute class from `clcec0.h`, the marker address and value from the M16 receipt, and names every decoded method offset from `clc96f.h`. The two encoders:

```om
note Method header as CUDApp nvrm/nvrm.h nvrm_mthd writes it: 2 in bits 28..31 (incrementing),
note count from bit 16, subchannel in bits 13..15, method offset in dwords in the low bits.
fn mth subc uint m uint cnt uint to uint
a = shr m 2
if eq get mut 0 1
a = m
end
ret or or or uint 536870912 shl cnt 16 shl subc 13 a
end
note GPFIFO entry as nvrm.c nvrm_gp_entry writes it: VA (dword aligned), length from bit 42, bit 41.
fn gpent va ulong nw ulong to ulong
ret or or and va not ulong 3 shl and nw 0x1fffff 42 shl ulong 1 41
end
```

Command: `sh examples/cuda-05-gpfifo-and-methods/run.sh`

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== oracle: header fields (NVIDIA 580.173.02 clc96f.h, clcec0.h; MIT)
82:#define NVC96F_SEM_EXECUTE_OPERATION                                       2:0
84:#define NVC96F_SEM_EXECUTE_OPERATION_RELEASE                        0x00000001
85:#define NVC96F_SEM_EXECUTE_RELEASE_WFI                                   20:20
95:#define NVC96F_GP_ENTRY0_GET                                        31:2
98:#define NVC96F_GP_ENTRY1_GET_HI                                      7:0
99:#define NVC96F_GP_ENTRY1_LEVEL                                       9:9
100:#define NVC96F_GP_ENTRY1_LEVEL_MAIN                           0x00000000
101:#define NVC96F_GP_ENTRY1_LEVEL_SUBROUTINE                     0x00000001
102:#define NVC96F_GP_ENTRY1_LENGTH                                    30:10
103:#define NVC96F_GP_ENTRY1_SYNC                                      31:31
27:#define BLACKWELL_COMPUTE_B    0xCEC0
from the M16 receipt: context A marker_va 0x1004111000, expected marker 0x16c0ffee
pushbuffer VA (illustrative, not from a receipt): 0x1000010000
== build and decode: gpfifo.om
compile rc=0
pb[0] = 0x20012000
  header: bits28-31=2 count=1 subch=1 method=0x00000000
pb[1] = 0x0000cec0
  data for method 0x00000000
pb[2] = 0x20050017
  header: bits28-31=2 count=5 subch=0 method=0x0000005c
pb[3] = 0x04111000
  data for method 0x0000005c
pb[4] = 0x00000010
  data for method 0x00000060
pb[5] = 0x16c0ffee
  data for method 0x00000064
pb[6] = 0x00000000
  data for method 0x00000068
pb[7] = 0x00100001
  data for method 0x0000006c
gpfifo entry = 0x0000221000010000
  ENTRY0 GET (31:2) va>>2 = 0x00004000
  ENTRY1 GET_HI (7:0) = 16
  ENTRY1 LEVEL (9:9) = 1
  ENTRY1 LENGTH (30:10) dwords = 8
  ENTRY1 SYNC (31:31) = 0
  va rebuilt from GET_HI:GET = 0x1000010000
round trip: exact
run rc=0
== oracle: name each decoded method offset from clc96f.h
0x00000000 NVC96F_SET_OBJECT
0x0000005c NVC96F_SEM_ADDR_LO
0x00000060 NVC96F_SEM_ADDR_HI
0x00000064 NVC96F_SEM_PAYLOAD_LO
0x00000068 NVC96F_SEM_PAYLOAD_HI
0x0000006c NVC96F_SEM_EXECUTE
== read the code against the header: CUDApp nvrm/nvrm.c says
808:/* GP entry per clc96f.h: ENTRY0 GET 31:2 (VA low, dword aligned), ENTRY1 GET_HI 7:0,
809: * LEVEL 9:9 = MAIN, LENGTH 30:10 in dwords, SYNC 31:31 = PROCEED. */
811:    return (va & ~3ull) | ((uint64_t)(nwords & 0x1fffff) << 42) | (1ull << 41);
== negative control: method offset written in bytes, the >> 2 forgotten
  header: bits28-31=2 count=1 subch=1 method=0x00000000
  header: bits28-31=2 count=5 subch=0 method=0x00000170
round trip: MISMATCH at pb[2]
mutant run rc=5
```

Every decoded method offset has a name in the header: `SET_OBJECT`, then the five semaphore methods. The ring entry decodes to the address it was built from and a length of 8 words.

Look at `LEVEL`: it decodes to **1**. `clc96f.h` names value 1 `GP_ENTRY1_LEVEL_SUBROUTINE` and 0 `MAIN`, but the comment in `nvrm/nvrm.c` above `nvrm_gp_entry` says "LEVEL 9:9 = MAIN" while its code sets bit 41, which is that LEVEL bit. Decoding against the header caught a comment that disagrees with the code. The code is what the historical chip runs used; whether MAIN would behave differently has not been run.

The negative control writes the method offset in bytes instead of dwords (the `>> 2` forgotten). The header now says method 0x170 instead of 0x5c, the round-trip check fails, and the program exits 5.

## Common mistake

Writing method offsets in bytes. Header files give method offsets in bytes (0x5c), but the method header stores them in dwords. Forget the shift and the GPU executes a different method, usually silently. Always decode what you emit against the header, as the example does.

## Where to go deeper

- [nvrm/nvrm.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/nvrm/nvrm.c) (`nvrm_gp_entry`, `nvrm_enqueue`, `nvrm_ring`) and [nvrm/nvrm.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/nvrm/nvrm.h) (`nvrm_mthd`).
- [m16/m16_native.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/m16/m16_native.c): the release pushbuffer.
- [clc96f.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/src/common/sdk/nvidia/inc/class/clc96f.h): ring entry and channel methods.
- The launch: [src/omega_gpu_cmdlist.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/src/omega_gpu_cmdlist.c), [src/omega_blackwell_qmd.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/src/omega_blackwell_qmd.c), and in Omega [native/blackwell/launch.om](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/native/blackwell/launch.om).
- [docs/DRIVER.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/DRIVER.md), section 4, and [THIRD_PARTY.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/THIRD_PARTY.md) for the Mesa sources.
