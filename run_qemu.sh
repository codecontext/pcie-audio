#!/usr/bin/env bash
set -e

if [ -z "${ZEPHYR_BIN:-}" ]; then
    echo "Error: ZEPHYR_BIN is not set." >&2
    echo "Set it to the Zephyr ELF path, for example: export ZEPHYR_BIN=/path/to/zephyr.elf" >&2
    exit 1
fi

if [ ! -f "$ZEPHYR_BIN" ]; then
    echo "Error: Zephyr executable binary not found: $ZEPHYR_BIN" >&2
    echo "Set ZEPHYR_BIN to the path of the built Zephyr ELF." >&2
    exit 1
fi

if [ -z "${QEMU_BIN:-}" ]; then
    echo "Error: QEMU_BIN is not set." >&2
    echo "Set it to the qemu-system-aarch64 executable path, for example: export QEMU_BIN=/path/to/qemu-system-aarch64" >&2
    exit 1
fi

if [ ! -x "$QEMU_BIN" ]; then
    echo "Error: QEMU executable not found or not executable: $QEMU_BIN" >&2
    echo "Set QEMU_BIN to the path of the qemu-system-aarch64 executable." >&2
    exit 1
fi

SHM_FILE="/dev/shm/ivshmem_audio_buffer"
touch "$SHM_FILE"

echo "========================================================="
echo " Launching Dual-Endpoint PCIe Audio Target (qemu_cortex_a53)"
echo " QEMU Binary : $QEMU_BIN"
echo " Root Complex: GPEX ECAM @ 0x4010000000"
echo " Endpoint 1  : edu (BDF 00:01.0)"
echo " Endpoint 2  : ivshmem-plain (BDF 00:02.0)"
echo "========================================================="

QEMU_ARGS=(
    # Use the ARM virt machine with a GICv3 interrupt controller.
    -M virt,gic-version=3
    # Emulate a Cortex-A53 CPU.
    -cpu cortex-a53
    # Allocate 1 GiB of guest RAM.
    -m 1024
    # Route serial output to this terminal and disable graphical output.
    -nographic
    # Disable the default NIC so it does not occupy PCI slot 01.0.
    -nic none
    # Boot the Zephyr firmware image.
    -kernel "$ZEPHYR_BIN"
    # Attach the QEMU educational PCI device at bus 0, device 1, function 0.
    -device edu,bus=pcie.0,addr=01.0
    # Attach the shared-memory PCI device at bus 0, device 2, function 0.
    -device ivshmem-plain,bus=pcie.0,addr=02.0,memdev=hostmem
    # Back the ivshmem device with a 2 MiB host shared-memory file.
    -object memory-backend-file,id=hostmem,share=on,mem-path="$SHM_FILE",size=2M
)

"$QEMU_BIN" "${QEMU_ARGS[@]}"
