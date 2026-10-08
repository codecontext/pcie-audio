# Real-Time PCIe Audio Streaming POC

**Target Architecture:** ARM64 (`qemu_cortex_a53`)
**Operating System:** Zephyr RTOS (v4.5.0-rc1)
**Host Environment:** Linux (Ubuntu 24.04 LTS)

---

## Executive Overview

This project establishes a software-defined prototyping environment to validate end-to-end PCI Express (PCIe) bus operations, Direct Memory Access (DMA) engines, and real-time streaming data pipelines on an emulated ARM64 target (`qemu_cortex_a53`).

By leveraging standard QEMU-emulated PCIe peripherals (`pci-edu` and `ivshmem-plain`), the system models a **Real-Time Audio Signal Processing Engine**. Synthetic 16-bit PCM audio frames are generated within guest software, pushed across the virtual PCIe bus via DMA from an audio source endpoint (`pci-edu`), mapped into host-accessible memory via an inter-VM shared memory endpoint (`ivshmem`), and monitored under strict real-time execution constraints.

This approach provides 100% hardware-independent API validation using standard Zephyr RTOS PCIe drivers (`pcie.h`), ensuring seamless code portability to future physical silicon and memory controllers.

---

## Technical Specifications

| Parameter | Specification |
| :--- | :--- |
| **Target Architecture** | ARM64 (`arch/arm64`) on `qemu_cortex_a53` |
| **Guest OS** | Zephyr RTOS (v4.5.0-rc1) |
| **PCIe Host Controller** | Generic PCI Express Host Controller (`gpex`) |
| **ECAM Memory Base** | `0x4010000000` |
| **Bus Topology** | Virtual PCIe Bus 0 (`00:00.0` Root Complex) |
| **Endpoint 1 (Source/DMA)** | `pci-edu` (QEMU Educational Device) @ BDF `00:01.0` |
| **Endpoint 2 (Shared RAM)** | `ivshmem-plain` (Inter-VM Shared Memory) @ BDF `00:02.0` |
| **Audio Format** | Signed 16-bit PCM Mono Stream (`int16_t`) |
| **Sampling Rate** | 48 kHz |
| **Frame Size** | 1024 samples per frame (2048 bytes payload) |
| **Processing Deadline** | **21.33 ms** per frame window |

---

## System Architecture

The architecture is divided into three distinct layers: the **Guest Firmware Layer** (Zephyr RTOS), the **Emulated Hardware Layer** (QEMU `gpex` Root Complex), and the **Host Layer** (Linux RAM & Visualizer).

### End-to-End System Dataflow

```text
+-------------------------------------------------------------------------------------------------+
|                                        GUEST SOFTWARE LAYER                                     |
|                                                                                                 |
|   +--------------------------+        +--------------------------+     +--------------------+   |
|   |   Audio Generator Thread |        |  Zephyr PCIe Subsystem   |     | Audio Buffer Pool  |   |
|   |  (48kHz / 1024 Samples)  |        |  (pcie.h / pcie_ecam.c)  |     |   (SRAM Payload)   |   |
|   +------------+-------------+        +------------+-------------+     +---------+----------+   |
|                |                                   |                             |              |
|                +-----------------------------------+-----------------------------+              |
|                                                    |                                            |
+----------------------------------------------------|--------------------------------------------+
                                                     | MMIO Writes & DMA Commands
                                                     v
+-------------------------------------------------------------------------------------------------+
|                                    EMULATED HARDWARE LAYER                                      |
|                                                                                                 |
|   +-----------------------------------------------------------------------------------------+   |
|   |                           QEMU GPEX PCIe Root Complex (Bus 0)                           |   |
|   +--------------------------------------------+--------------------------------------------+   |
|                                                |                                                |
|                   +----------------------------+----------------------------+                   |
|                   |                                                         |                   |
|                   v                                                         v                   |
|     +---------------------------+                             +---------------------------+     |
|     |   Endpoint 1: pci-edu     |                             |   Endpoint 2: ivshmem     |     |
|     |        (BDF 00:01.0)      |                             |        (BDF 00:02.0)      |     |
|     +-------------+-------------+                             +-------------+-------------+     |
|                   |                                                         |                   |
|                   | Triggers DMA Transfer                                   | Maps BAR2 Memory  |
+-------------------|---------------------------------------------------------|-------------------+
                    |                                                         |
                    v                                                         v
+-------------------------------------------------------------------------------------------------+
|                                          HOST SYSTEM                                            |
|                                                                                                 |
|   +-----------------------------------------------------------------------------------------+   |
|   |                      Shared Host Memory Buffer (/dev/shm/ivshmem_buffer)               |   |
|   +--------------------------------------------+--------------------------------------------+   |
|                                                |                                                |
|                                                v Reads Payload                                  |
|   +-----------------------------------------------------------------------------------------+   |
|   |                           Python Host Visualizer (Waveform Plot)                        |   |
|   +-----------------------------------------------------------------------------------------+   |
+-------------------------------------------------------------------------------------------------+
