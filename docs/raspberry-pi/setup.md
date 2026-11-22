# Set Up the Pi

## Step 1 - Check the hardware

```bash
cat /proc/device-tree/model; echo
uname -m
ls -l /dev/kvm
```

Real output:

```
Raspberry Pi 5 Model B Rev 1.1
aarch64
crw-rw----+ 1 root kvm 10, 232 Nov 22 15:56 /dev/kvm
```

You need `aarch64` and a `/dev/kvm` device. Without `/dev/kvm`, local sandboxes can't start.

## Step 2 - Check your kvm access

```bash
groups | grep -w kvm
```

If it prints nothing, add yourself, then log out and back in:

```bash
sudo usermod -aG kvm $USER
```

## Step 3 - Install sbx

Download the arm64 package and install it:

```bash
curl -fLO https://github.com/docker/sbx-releases/releases/latest/download/DockerSandboxes-linux-arm64-ubuntu2604.deb
sudo apt-get install -y ./DockerSandboxes-linux-arm64-ubuntu2604.deb
sbx version
```

Real output:

```
sbx version v0.54.0 4bec4a5ce093466e54b034146965b143d065dc09
```

!!! note "Why the .deb?"
    At the time of testing, Docker's apt repository had no `docker-sbx` package for Ubuntu 26.10 (`stonking`). The package built for Ubuntu 26.04 (`resolute`) installed and ran on 26.10.

## Step 4 - Sign in

```bash
sbx login
```

Open the printed URL in a browser, on the Pi or on any other device. Pick the **Balanced** network policy when asked. The network module relies on it.

## Step 5 - Diagnose

```bash
sbx diagnose
```

Real output (shortened):

```
INSTALLATION
  ✓ Binary version — v0.54.0
  ✓ Daemon — healthy
PLATFORM
  ✓ Virtualization — supported
      /dev/kvm is accessible
CONNECTION
  ✓ Authentication — authenticated
  ✓ Global network policy — initialized

  16 passed · 4 skipped
```

If **Virtualization** fails, go back to Step 2.
