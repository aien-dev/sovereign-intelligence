# Reading the open kernel module's headers: escapes, classes and controls

Evidence level: EXERCISED. The example ran on a Linux AArch64 host against the 67 headers CUDApp vendors; it reads files only and is not a GPU run.

## Goal

Find your way around NVIDIA's open-module headers: where the resource manager (RM) API lives, and what an escape code, a class number and a control command are.

## Explanation

NVIDIA's kernel driver contains a large component called the resource manager. User space talks to it through very few entry points and a very large vocabulary. Once you see the three kinds of number, the headers stop being a wall of macros.

**Escape codes say which operation.** An ioctl on `/dev/nvidiactl` carries an escape code. A handful do almost all the work: `NV_ESC_RM_ALLOC` creates an object, `NV_ESC_RM_CONTROL` asks an object to do something, `NV_ESC_RM_FREE` destroys one, and `NV_ESC_RM_MAP_MEMORY` maps memory for the CPU. These live in `src/nvidia/arch/nvalloc/unix/include/nv_escape.h`. The device-level escapes (`NV_ESC_CARD_INFO`, `NV_ESC_REGISTER_FD`) live in `kernel-open/common/inc/nv-ioctl-numbers.h`, counted from `NV_IOCTL_BASE`. Lesson 3 turns these into actual ioctl request numbers.

**Parameter structures say what you pass.** `src/common/sdk/nvidia/inc/nvos.h` defines them: `NVOS21_PARAMETERS` for an alloc (root client, parent, new handle, class, a pointer to class-specific parameters), `NVOS54_PARAMETERS` for a control, `NVOS00_PARAMETERS` for a free.

**Class numbers say what kind of object.** Every object you allocate has a class, and each class has its own header named after its number: `class/cl0080.h` defines `NV01_DEVICE_0` as 0x80, `class/cl2080.h` defines `NV20_SUBDEVICE_0`, `class/clc96f.h` defines `BLACKWELL_CHANNEL_GPFIFO_A` and the channel's methods, `class/clcec0.h` defines `BLACKWELL_COMPUTE_B`. The names carry the GPU generation that introduced the class, and old classes stay in use: CUDApp puts its Blackwell channel inside a channel group of class 0xA06C, `KEPLER_CHANNEL_GROUP_A`.

**Control commands are numbers with fields.** `ctrl/ctrlxxxx.h` says a control command is CLASS in bits 31..16, CATEGORY in bits 13..8 and INDEX in bits 7..0. So `NV2080_CTRL_CMD_GR_GET_INFO`, 0x20801201, is "subdevice class, graphics category, call 1". The command tells you which object you must send it to.

The unified-memory driver is different. Its calls in `kernel-open/nvidia-uvm/uvm_ioctl.h` are plain numbers on Linux (`UVM_IOCTL_BASE(i)` is just `i`), with no encoded size, so the header is the only place the payload size is written down. omega-mv's device words keep an explicit allowlist of those sizes for exactly that reason.

CUDApp keeps the exact files it needs, unchanged, in `third_party/nvidia-open-580.173.02/` with a `SHA256SUMS`. That is a deliberate choice: the layouts can change between module versions, so I pin one version and refuse others.

## Example

`ctrl.om` splits control-command numbers into the fields `ctrlxxxx.h` defines and refuses a number with the unused bits 14..15 set. The past host run took every number from the headers and looked the class part up in `class/cl<class>.h`. The heart of `ctrl.om`:

```om
fn main to int
if not slurp
ret 3
end
seen = ulong 0
while true bound 65
c = nextnum
if eq c 18446744073709551615
break
end
seen = add seen 1
puts scmd
puthex c 8
if ne and c 0xc000 0
puts sbad
flush
ret 7
end
puts scls
hexn shr c 16 4
puts scat
hexn and shr c 8 0x3f 2
puts sidx
hexn and c 0xff 2
putc 10
end
flush
if eq seen 0
ret 3
end
ret 0
end
```

Command: the retired runner; see `examples/cuda-02-reading-the-headers/POINTER.md`

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== 1. a class header is named after its class number
class/cl0080.h:36:#define NV01_DEVICE_0      (0x80U) /* finn: Evaluated from "NV0080_ALLOC
class/cl2080.h:36:#define NV20_SUBDEVICE_0      (0x2080U) /* finn: Evaluated from "NV2080_
class/clc96f.h:27:#define  BLACKWELL_CHANNEL_GPFIFO_A                           (0x0000C96
class/clcec0.h:27:#define BLACKWELL_COMPUTE_B    0xCEC0
== 2. the control-command layout (ctrl/ctrlxxxx.h)
47:#define NVXXXX_CTRL_CMD_CLASS                                             31:16
49:#define NVXXXX_CTRL_CMD_CATEGORY                                           13:8
50:#define NVXXXX_CTRL_CMD_INDEX                                               7:0
== 3. the control commands CUDApp nvrm.c sends, as the headers define them
NV0000_CTRL_CMD_GPU_GET_ID_INFO_V2 = 0x205 (named 1 time(s) in nvrm.c)
NV0080_CTRL_CMD_GPU_GET_CLASSLIST = 0x800201 (named 2 time(s) in nvrm.c)
NV2080_CTRL_CMD_GR_GET_INFO = 0x20801201 (named 1 time(s) in nvrm.c)
NV2080_CTRL_CMD_GPU_GET_GID_INFO = 0x2080014a (named 1 time(s) in nvrm.c)
NVC36F_CTRL_CMD_GPFIFO_GET_WORK_SUBMIT_TOKEN = 0xc36f0108 (named 2 time(s) in nvrm.c)
NVA06C_CTRL_CMD_GPFIFO_SCHEDULE = 0xa06c0101 (named 1 time(s) in nvrm.c)
compile rc=0
== 4. ctrl.om splits them
cmd 0x00000205 class=0x0000 category=0x02 index=0x05
cmd 0x00800201 class=0x0080 category=0x02 index=0x01
cmd 0x20801201 class=0x2080 category=0x12 index=0x01
cmd 0x2080014a class=0x2080 category=0x01 index=0x4a
cmd 0xc36f0108 class=0xc36f category=0x01 index=0x08
cmd 0xa06c0101 class=0xa06c category=0x01 index=0x01
run rc=0
== 5. which object class does each command talk to? (class/cl<class>.h, if vendored)
0x0000: class/cl0000.h defines NV01_NULL_OBJECT NV01_ROOT 
0x0080: class/cl0080.h defines NV01_DEVICE_0 
0x2080: class/cl2080.h defines NV20_SUBDEVICE_0 
0xa06c: class/cla06c.h defines KEPLER_CHANNEL_GROUP_A 
0xc36f: class/clc36f.h is not among the 67 vendored headers
== 6. negative control: a number with bit 14 set
cmd 0x20805201 REFUSED: bits 14..15 are set
run rc=7
```

Notice two things. The class part of each command is an object class you already met (root 0x0000, device 0x0080, subdevice 0x2080, channel group 0xA06C). And `clc36f.h` is not vendored: the work-submit-token control belongs to the Volta GPFIFO class family, and CUDApp only needed its control header `ctrl/ctrlc36f.h`, not the class header. The negative control exits 7.

## Common mistake

Treating the numbers as magic constants copied from a trace. Copy the header instead, and read the struct and field definitions with it. A number with no header behind it cannot be checked when the module version changes; a header-pinned number can be re-derived, as the next lesson does.

## Where to go deeper

- The vendored headers: [third_party/nvidia-open-580.173.02](https://github.com/aien-dev/CUDApp/tree/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02), with [SHA256SUMS](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/SHA256SUMS).
- [nvos.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/src/common/sdk/nvidia/inc/nvos.h) and [ctrlxxxx.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/src/common/sdk/nvidia/inc/ctrl/ctrlxxxx.h).
- [docs/DRIVER.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/DRIVER.md): which control goes to which object, in order.
- omega-mv's device word contract, including the UVM size allowlist: [seed/host/MAPPING.md](https://github.com/aien-dev/omega-mv/blob/19f014f2178ca9cd3473728fe00a475a2398c409/seed/host/MAPPING.md).
- Upstream source of the headers: [NVIDIA/open-gpu-kernel-modules](https://github.com/NVIDIA/open-gpu-kernel-modules).
