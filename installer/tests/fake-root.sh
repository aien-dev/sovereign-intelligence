#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Build a fake hardware tree for the doctor and the bootstrap (AIENOS_PROBE_ROOT).
# usage: fake-root.sh DIR KIND
#   gb10       a DGX Spark: aarch64, PCI 10de:2e12, driver 580.173.02, 128 GB, device nodes
#   gb10-busy  as gb10, but only 15 GB of memory free (another model is resident)
#   nogpu      aarch64 Linux with no NVIDIA device and no module
#   othergpu   aarch64 with an NVIDIA GPU that is not a GB10 (10de:2684)
#   olddrv     a GB10 with kernel driver 570.86.10
# Device nodes are symbolic links to /dev/null: a real character device, so the doctor's
# "is it a character device" check is exercised without creating device files.
set -eu
d=$1
kind=$2
rm -rf "$d"
mkdir -p "$d/proc/sys/kernel" "$d/proc/driver/nvidia" "$d/sys/module/nvidia" \
    "$d/sys/bus/pci/devices/0000:00:00.0" "$d/dev" "$d/tmp"
printf 'aarch64\n' > "$d/proc/sys/kernel/arch"
printf '0x1def\n' > "$d/sys/bus/pci/devices/0000:00:00.0/vendor"
printf '0x0001\n' > "$d/sys/bus/pci/devices/0000:00:00.0/device"
: > "$d/proc/locks"
free=120000000
case $kind in
    gb10-busy) free=15000000 ;;
esac
cat > "$d/proc/meminfo" <<EOF
MemTotal:       127598528 kB
MemFree:         1000000 kB
MemAvailable:   $free kB
Mapped:           200000 kB
EOF
gpu() {
    mkdir -p "$d/sys/bus/pci/devices/000f:01:00.0"
    printf '0x10de\n' > "$d/sys/bus/pci/devices/000f:01:00.0/vendor"
    printf '%s\n' "$1" > "$d/sys/bus/pci/devices/000f:01:00.0/device"
    printf 'NVRM version: NVIDIA UNIX Open Kernel Module for aarch64  %s\n' "$2" > "$d/proc/driver/nvidia/version"
    printf '%s\n' "$2" > "$d/sys/module/nvidia/version"
    for n in nvidiactl nvidia0 nvidia-uvm; do ln -s /dev/null "$d/dev/$n"; done
}
case $kind in
    gb10|gb10-busy) gpu 0x2e12 580.173.02 ;;
    othergpu) gpu 0x2684 580.173.02 ;;
    olddrv) gpu 0x2e12 570.86.10 ;;
    nogpu) rm -rf "$d/sys/module/nvidia" "$d/proc/driver/nvidia" ;;
    *) echo "fake-root.sh: unknown kind $kind" >&2; exit 2 ;;
esac
