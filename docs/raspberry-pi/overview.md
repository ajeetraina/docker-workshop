# Docker Sandboxes on Raspberry Pi

Run AI coding agents inside real microVMs on a Raspberry Pi 5. The Pi's Arm cores support hardware virtualization through KVM, so `sbx` gives you the same isolation boundary here as on a laptop.

Every output marked **Real output** in this track was captured on the hardware below.

| Component | Used for this track |
|---|---|
| Board | Raspberry Pi 5 Model B Rev 1.1, 8 GB RAM, 4 cores |
| OS | Ubuntu 26.10 (arm64), kernel `7.3.0-1003-raspi` |
| Storage | 64 GB-class microSD card (58 GB usable) |
| Cooling | CPU cooler with fan |
| Docker Sandboxes | `sbx` v0.54.0 |

!!! note "Not in the main lab's platform table"
    The [sbx pre-flight checklist](../lab8/getting-started.md) lists Linux x86_64 but not Linux arm64. This track covers arm64 as tested on one Pi 5. Other Pi models and operating systems were not tested.

## You don't need Docker Engine

Docker Engine was **not** installed on the Pi used here. Each sandbox ships with its own Docker daemon inside the microVM.

## What you'll do

1. [Set up the Pi](setup.md) - check KVM, install `sbx`, sign in
2. [Create your first sandbox](first-sandbox.md) - boot a microVM
3. [Prove the isolation](isolation.md) - kernel, files, and Pi hardware
4. [Control the network](network-policy.md) - allow and deny hosts live
5. [Run Docker inside the sandbox](docker-inside.md) - containers and ports
6. [Fit it on 8 GB](resources.md) - memory, heat, and parallel sandboxes
7. [Run Claude Code and clean up](claude-code.md)
