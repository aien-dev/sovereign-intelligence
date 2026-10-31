# GPU objects: the resource-manager tree, handles and classes

Evidence level: EXERCISED. A host model in Omega replays CUDApp's allocation order with class numbers from the headers; it is a model of the order, not the RM, and no device was opened.

## Goal

Picture the tree of objects a GPU program creates before it can launch anything, know what a handle and a class are, and know why the order is not negotiable.

## Explanation

The resource manager keeps every GPU resource as an object in a tree. You create one with `NV_ESC_RM_ALLOC`, passing an `NVOS21_PARAMETERS`: the root client handle, the **parent** handle, the **new** handle and the **class**. The class says what kind of object it is (lesson 2). The handle is a 32-bit name for it that you use in later calls. In CUDApp the client picks handles itself: `rm_alloc` in `nvrm/nvrm.c` sets `hObjectNew` from a counter, except for the root client, where it passes 0 and the driver returns the new client handle.

The order CUDApp uses, from `docs/DRIVER.md` and the `rm_alloc` call sites:

1. `NV01_ROOT_CLIENT`: the root. Everything hangs off it and is freed with it.
2. `NV01_DEVICE_0` under the root, then `NV20_SUBDEVICE_0` and `NV01_MEMORY_VIRTUAL` (the GPU address range) under the device.
3. `HOPPER_USERMODE_A` under the subdevice: the page that holds the doorbell.
4. `FERMI_VASPACE_A` under the device: the address space, handed to the unified-memory driver.
5. One `NV01_MEMORY_SYSTEM` object under the device per buffer. On the GB10 the CPU and GPU share one memory, so each buffer is mapped at the same address on both sides.
6. For a channel: `KEPLER_CHANNEL_GROUP_A` under the device, `FERMI_CONTEXT_SHARE_A` under the group, two buffers (the command ring with its USERD control page, and an error notifier), then `BLACKWELL_CHANNEL_GPFIFO_A` under the group and finally `BLACKWELL_COMPUTE_B` under the channel.

Three rules matter in practice. A child needs a live parent of the right class. Freeing an object frees its whole subtree, so a stale handle to a child of a freed parent is no longer an object. And some allocations need host resources you do not see: creating the compute object needs one free, physically contiguous 2 MiB block for its context buffer, which is why CUDApp retries exactly that one `NV_ERR_NO_MEMORY`, 50 times at 100 ms, and treats every other error as final.

The C client also refuses stale and duplicate handles itself before calling the driver, and quarantines an allocation that failed half way, because the driver's state is then unknown. The native Omega continuation `native/nvrm/context.om` keeps the same discipline with fixed tables of objects and mappings.

## Example

`objtree.om` is a small model: it takes the allowed (child class, parent class) pairs and an allocation script on stdin, refuses a step whose parent is not live or not of an allowed class, frees subtrees, and prints the live tree. The past host run took every class number from the headers and the order from `nvrm.c`. The allocation check (the full file is in the example folder):

```om
fn alloc c ulong p ulong to bool
n = add get ocnt 0 1
puts sal
putdec n
puts scl
puthex c 8
puts sun
putdec p
if ge n 64
puts sfu
ret false
end
if eq p 0
note Only the very first object may be parentless, and it must be the root client.
if or ne n 1 not allowed c 0
puts snr
ret false
end
else
if gt p get ocnt 0
puts snp
ret false
end
if eq get olive p 0
puts snp
ret false
end
if not allowed c get ocls p
puts snr
ret false
end
end
put ocls n c
put opar n p
put olive n 1
put ocnt 0 n
puts sok
ret true
end
```

Command: the retired runner; see `examples/cuda-04-rm-object-tree/POINTER.md`

Recorded output:

```text
omc sha256 befb8199db8c4bca188a494dfaac2a6f0ee5c36fcea11188c75666c55fce8a1d
== oracle 1: the order and parents CUDApp nvrm/nvrm.c allocates with
304:    if (rm_alloc(rm, 0, NV01_ROOT_CLIENT, NULL, 0, &rm->root)) return -1;
336:    if (rm_alloc(rm, rm->root, NV01_DEVICE_0, &dp, sizeof dp, &rm->device)) return -1;
339:    if (rm_alloc(rm, rm->device, NV20_SUBDEVICE_0, &sp, sizeof sp, &rm->subdevice)) return -1;
343:    if (rm_alloc(rm, rm->device, NV01_MEMORY_VIRTUAL, &vp, sizeof vp, &rm->virtmem)) return -1;
362:    if (rm_alloc(rm, rm->subdevice, rm->usermode_class, NULL, 0, &rm->usermode)) return -1;
381:    if (rm_alloc(rm, rm->device, FERMI_VASPACE_A, &vap, sizeof vap, &rm->vaspace)) return -1;
587:    if (rm_alloc(rm, rm->device, NV01_MEMORY_SYSTEM, &mp, sizeof mp, &h)) {
701:    if (rm_alloc(rm, rm->device, KEPLER_CHANNEL_GROUP_A, &cg, sizeof cg, &rm->chgroup)) return -1;
706:    if (rm_alloc(rm, rm->chgroup, FERMI_CONTEXT_SHARE_A, &cs, sizeof cs, &rm->ctxshare)) return -1;
712:    if (nvrm_alloc_gpu_uncached(rm, 0x10000, &rm->fifo)) return -1;
713:    if (nvrm_alloc(rm, 0x100000, &rm->notifier)) return -1;
726:    if (rm_alloc(rm, rm->chgroup, rm->gpfifo_class, &gp, sizeof gp, &rm->gpfifo)) return -1;
735:        if (rm_alloc(rm, rm->gpfifo, rm->compute_class, NULL, 0, &rm->compute_obj) == 0) break;
== oracle 2: class numbers from the headers
NV01_ROOT_CLIENT = 0x00000041
NV01_DEVICE_0 = 0x80
NV20_SUBDEVICE_0 = 0x2080
NV01_MEMORY_VIRTUAL = 0x70
HOPPER_USERMODE_A = 0xc661
FERMI_VASPACE_A = 0x000090f1
NV01_MEMORY_SYSTEM = 0x0000003E
KEPLER_CHANNEL_GROUP_A = 0x0000A06C
FERMI_CONTEXT_SHARE_A = 0x00009067
BLACKWELL_CHANNEL_GPFIFO_A = 0x0000C96F
BLACKWELL_COMPUTE_B = 0xCEC0
compile rc=0
== run 1: open, channel, free the channel group, free the root client
alloc #1 class 0x00000041 under #0: ok
alloc #2 class 0x00000080 under #1: ok
alloc #3 class 0x00002080 under #2: ok
alloc #4 class 0x00000070 under #2: ok
alloc #5 class 0x0000c661 under #3: ok
alloc #6 class 0x000090f1 under #2: ok
alloc #7 class 0x0000003e under #2: ok
alloc #8 class 0x0000a06c under #2: ok
alloc #9 class 0x00009067 under #8: ok
alloc #10 class 0x0000003e under #2: ok
alloc #11 class 0x0000003e under #2: ok
alloc #12 class 0x0000c96f under #8: ok
alloc #13 class 0x0000cec0 under #12: ok
live tree:
  #1 0x00000041
    #2 0x00000080
      #3 0x00002080
        #5 0x0000c661
      #4 0x00000070
      #6 0x000090f1
      #7 0x0000003e
      #8 0x0000a06c
        #9 0x00009067
        #12 0x0000c96f
          #13 0x0000cec0
      #10 0x0000003e
      #11 0x0000003e
free #8: freed 4 object(s), the whole subtree
live tree:
  #1 0x00000041
    #2 0x00000080
      #3 0x00002080
        #5 0x0000c661
      #4 0x00000070
      #6 0x000090f1
      #7 0x0000003e
      #10 0x0000003e
      #11 0x0000003e
free #1: freed 9 object(s), the whole subtree
live tree:
  (empty)
run rc=0
== negative 1: compute object allocated directly under the channel group
alloc #13 class 0x0000cec0 under #8: REFUSED, this class may not be a child of that class
run rc=6
== negative 2: compute object under a channel that was already freed
alloc #13 class 0x0000cec0 under #12: REFUSED, parent is not a live object
run rc=6
```

The tree has the shape of the list above. Freeing the channel group (#8) removes four objects: the group, the context share, the channel and the compute object; the buffers stay, because they hang off the device. Freeing the root removes the remaining nine. Negative 1 tries to put the compute object directly under the channel group and is refused (exit 6). Negative 2 frees the channel group first and then tries to use the channel as a parent: refused, exit 6.

What this model does **not** do: it is not the RM. It encodes only the parent pairs CUDApp actually uses, not the driver's full rule set, it makes no ioctl, and it says nothing about whether those calls succeed on a GPU. That proof is a chip run (lesson 6), and at this pin CUDApp's own README records the native path as NOT_RUN.

## Common mistake

Allocating or freeing out of order and then retrying blindly. If an allocation fails, the objects already created are still live and must be freed in reverse order; if a free fails half way, the safe move is to stop using that handle entirely. CUDApp quarantines rather than reuses, and refuses all further GPU work in a process when it cannot tell whether the GPU finished.

## Where to go deeper

- [docs/DRIVER.md](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/DRIVER.md): open, memory, channel, submit and wait, call by call.
- [nvrm/nvrm.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/nvrm/nvrm.c) and [nvrm/lifecycle_gates.c](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/nvrm/lifecycle_gates.c) (the chip gates for free, stale and duplicate handles).
- [native/nvrm/context.om](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/native/nvrm/context.om): the same lifecycle in Omega.
- The object diagram: [docs/img/driver-objects.svg](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/docs/img/driver-objects.svg).
- [nvos.h](https://github.com/aien-dev/CUDApp/blob/780a0af1f08c1786ea53a4e8702ca8bb1396fdbb/third_party/nvidia-open-580.173.02/src/common/sdk/nvidia/inc/nvos.h) for `NVOS21_PARAMETERS`.
