# ioctl request numbers: four fields, one 32-bit word

Evidence level: EXERCISED. Computed by an Omega program on a Linux AArch64 host and checked against the headers, CUDApp's own literals and the pinned compiler's rule; the only ioctl issued goes to /dev/null.

## Goal

Compute an NVIDIA ioctl request number yourself from the header, understand each of its four fields, and catch the classic layout mistake before it reaches a driver.

## Explanation

On Linux, `ioctl(fd, request, arg)` carries a 32-bit request number. For NVIDIA's control device that number is built with the kernel's `_IOC` macro, which packs four fields:

| bits | field | NVIDIA value |
|---|---|---|
| 31..30 | direction | 3 = read and write (`_IOC_READ | _IOC_WRITE`) |
| 29..16 | size of the argument struct | `sizeof` the parameter struct, at most 16383 |
| 15..8 | type ("magic") | `NV_IOCTL_MAGIC`, the character `'F'` |
| 7..0 | number | the escape code |

CUDApp's C client writes exactly that: `#define NV_IOWR(nr, sz) _IOC(_IOC_READ | _IOC_WRITE, NV_IOCTL_MAGIC, (nr), (sz))` in `nvrm/nvrm.c`. Note two details that are easy to get wrong.

First, the number. The RM escapes (`NV_ESC_RM_ALLOC` is 0x2B) are used directly, while the device escapes are counted from `NV_IOCTL_BASE`, 200 (`NV_ESC_CARD_INFO` is `NV_IOCTL_BASE + 0`). Both fit the 8-bit field.

Second, the size. It is `sizeof` the C structure as the compiler lays it out, padding included. `NVOS21_PARAMETERS` has four 32-bit fields, then a 64-bit pointer marked `NV_ALIGN_BYTES(8)`, then two more 32-bit fields: 32 bytes. `nv_ioctl_card_info_t` is where padding bites: a one-byte `valid` flag followed by a 4-byte-aligned PCI struct leaves a hole, and the four 64-bit fields need 8-byte alignment. CUDApp asks for 64 cards at once, so the size is 64 times the padded struct. The size field has 14 bits; a struct too big for it has to go through `NV_ESC_IOCTL_XFER_CMD`, which the header describes for exactly that case.

In Omega you do not write `_IOC`. The pinned compiler has checked device words (ids 166 to 177, `devctl` through `mapbind`), and `devctl` takes the request as a literal. At compile time `omc` checks the literal's shape: read/write direction, type `'F'`, a non-zero size (or the one `FIONREAD` literal). At run time it checks that the byte span you pass is exactly the encoded size. That is the rule in `fn hdevctl` of `seed/omc/omc.om`, and the example below uses it as a third oracle.

## Example

`ioctl.om` reads the header values (extracted by `run.sh` with `sed`), computes C struct sizes with natural alignment, and builds each request. The core:

```om
fn up x ulong a ulong to ulong
ret mul div add x sub a 1 a a
end
note C layout of fields a..b-1 (size, alignment): natural alignment, end padded.
fn csize a ulong b ulong to ulong
off = ulong 0
mx = ulong 1
for k ulong sub b a
i = add a k
off = add up off get fal i get fsz i
if gt get fal i mx
mx = get fal i
end
end
ret up off mx
end
fn ioc dir ulong ty ulong nr ulong size ulong to ulong
ret or or or shl dir 30 shl size 16 shl ty 8 nr
end
note omc's devctl rule (seed/omc/omc.om fn hdevctl): read/write, type F, nonzero size.
fn devok q ulong to bool
if ne and q 0xc000ff00 0xc0004600
ret false
end
ret ne and shr q 16 16383 0
end
text sacc " devctl-rule=accept\n"
```

Then `run.sh` checks every result three ways: the header lines themselves, whether CUDApp's own native client `native/nvrm/context.om` uses the identical literal, and what the pinned `omc` says when the number is compiled into a `devctl`.

Command: `sh examples/cuda-03-ioctl-numbers/run.sh`

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== oracle 1: the header lines (CUDApp third_party, NVIDIA 580.173.02, MIT)
29:#define NV_IOCTL_MAGIC      'F'
30:#define NV_IOCTL_BASE       200
31:#define NV_ESC_CARD_INFO             (NV_IOCTL_BASE + 0)
32:#define NV_ESC_REGISTER_FD           (NV_IOCTL_BASE + 1)
29:#define NV_ESC_RM_FREE                              0x29
30:#define NV_ESC_RM_CONTROL                           0x2A
31:#define NV_ESC_RM_ALLOC                             0x2B
input to ioctl.om (decimal): 70 200 41 42 43 
== compute: ioctl.om
compile rc=0
nv_pci_info_t size=12 align=4
nv_ioctl_card_info_t size=72 (packed sum would be 65)
NV_ESC_RM_ALLOC    NVOS21_PARAMETERS      nr=43 size=32 request=3223340587 (0xc020462b) devctl-rule=accept
NV_ESC_RM_CONTROL  NVOS54_PARAMETERS      nr=42 size=32 request=3223340586 (0xc020462a) devctl-rule=accept
NV_ESC_RM_FREE     NVOS00_PARAMETERS      nr=41 size=16 request=3222292009 (0xc0104629) devctl-rule=accept
NV_ESC_CARD_INFO   nv_ioctl_card_info[64] nr=200 size=4608 request=3523233480 (0xd20046c8) devctl-rule=accept
NV_ESC_REGISTER_FD nv_ioctl_register_fd   nr=201 size=4 request=3221505737 (0xc00446c9) devctl-rule=accept
MISTAKE CARD_INFO  packed, no padding     nr=200 size=4160 request=3493873352 (0xd04046c8) devctl-rule=accept
run rc=0
== oracle 2: does CUDApp native/nvrm/context.om use the same literal?
3223340587 used 1 time(s): NV_ESC_RM_ALLOC    NVOS21_PARAMETERS
3223340586 used 1 time(s): NV_ESC_RM_CONTROL  NVOS54_PARAMETERS
3222292009 used 1 time(s): NV_ESC_RM_FREE     NVOS00_PARAMETERS
3523233480 used 1 time(s): NV_ESC_CARD_INFO   nv_ioctl_card_info[64]
3221505737 used 2 time(s): NV_ESC_REGISTER_FD nv_ioctl_register_fd
3493873352 used 0 time(s): MISTAKE CARD_INFO  packed, no padding
== oracle 3: the pinned omc's devctl rule, compiled (never opens a GPU device)
RM_ALLOC read/write, 32-byte span: compile rc=0
RM_ALLOC read/write, 32-byte span: run on /dev/null rc=25
negative: same fields, write-only direction (1075856939): compile rc=9
omc: line 3: error 9
negative: RM_ALLOC with a 16-byte span: compile rc=0
negative: RM_ALLOC with a 16-byte span: run on /dev/null rc=103
```

What to read in it:

- Five computed requests are exactly the literals `context.om` uses; the padded card-info struct is 72 bytes.
- The **mistake** line forgets padding (65 bytes per card). It still has a valid shape, so the compiler's `devctl` rule would accept it; only the comparison with the real literal (used 0 times) catches it. Shape checks are not semantic checks.
- The real `RM_ALLOC` request compiles (rc 0). Run against `/dev/null`, the kernel answers `ENOTTY` (exit 25 here, the program returns minus the result). No NVIDIA device is touched.
- The same fields with direction "write only" are refused at compile time, error 9.
- The right request with a 16-byte span compiles but traps at run time with exit 103 (trap 3): the span must equal the encoded size.

## Common mistake

Adding up field sizes by hand and forgetting alignment padding. The size is part of the request number, so a wrong size is simply a different request from the one the module defines; the example shows the packed guess matching nothing CUDApp sends. What the module then does with it lives in its source (`nv.c` upstream), which is not among the vendored headers, so do not rely on any particular failure. Compute the layout with the alignment rules and check it against a known literal, never by summing fields.

## Where to go deeper

- The headers: [nv-ioctl-numbers.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/kernel-open/common/inc/nv-ioctl-numbers.h), [nv-ioctl.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/kernel-open/common/inc/nv-ioctl.h), [nv_escape.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/src/nvidia/arch/nvalloc/unix/include/nv_escape.h).
- The C client's ioctl wrapper: [nvrm/nvrm.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/nvrm/nvrm.c), and the Omega continuation: [native/nvrm/context.om](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/native/nvrm/context.om).
- The compiler's rule: [seed/omc/omc.om](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/omc/omc.om#L4973) (`fn hdevctl`) and the contract [seed/host/MAPPING.md](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/host/MAPPING.md).
- Language reference for the device words: [docs/one_layer/OMEGESE.md](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/docs/one_layer/OMEGESE.md).
