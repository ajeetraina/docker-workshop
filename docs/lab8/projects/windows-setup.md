# Running `sbx` on Windows

Every other module in this lab assumes a macOS or Linux host, where `sbx` talks to a native hypervisor directly. Windows is different enough to deserve its own walkthrough. The isolation guarantees, the credential proxy, and the network policy all behave identically once a sandbox is running - but **how you get there** changes, and a handful of host-side details will bite you if you don't set them up first.

This module takes a clean Windows 11 machine and gets you to the same place `Getting Started` leaves a Mac user: `sbx login` done, a provider secret stored, the lab repo cloned, and a sandbox running. Along the way you'll learn the three things that trip up every Windows newcomer - where the virtual machine actually lives, how PowerShell changes the commands, and why your files belong on the Linux side of the fence.

!!! warning "Platform support"
    `sbx` on Windows requires **Windows 11 x86_64** with WSL2. Windows 10, ARM-based Windows, and bare Command Prompt (without WSL2) are not supported. A few exercises in later modules behave slightly differently on Windows - each flags the difference where it matters.

---

## How `sbx` runs on Windows

On macOS and Linux, `sbx` launches each agent inside a microVM using the platform's native virtualization. Windows has no equivalent user-space hypervisor that `sbx` drives directly, so it leans on the one that ships with the OS: **WSL2**.

The chain looks like this:

```
Your PowerShell / Windows Terminal
        │  sbx command
        ▼
WSL2 (a real Linux kernel, Hyper-V backed)
        │  sandboxd daemon
        ▼
microVM  ──►  your agent (Claude / Codex / Gemini)
```

Two consequences fall out of this that shape the rest of the module:

- **The virtualization is nested.** WSL2 is itself a lightweight VM, and your sandbox runs on top of it. That's why virtualization has to be enabled all the way down in firmware - if the CPU can't nest, nothing above it starts.
- **There are two filesystems.** Your `C:\Users\you` Windows drive and the WSL2 Linux home are *different* filesystems bridged by a translation layer. Where you put the lab repo determines whether file edits are instant or painfully slow. We'll come back to this in Step 5.

---

## Step 1 - Turn on virtualization and WSL2

First, confirm hardware virtualization is on. Open **Task Manager → Performance → CPU** and look for **Virtualization: Enabled**. If it says *Disabled*, reboot into your BIOS/UEFI and enable **Intel VT-x** (or **AMD-V**/**SVM**) - the exact label depends on your vendor.

Then install WSL2 from an **elevated** PowerShell (right-click → *Run as administrator*):

```powershell
wsl --install
```

This enables the required Windows features, installs the WSL2 kernel, and pulls a default Ubuntu distribution. Reboot when prompted.

After the reboot, verify you're on version 2 - not the older WSL1:

```powershell
wsl --list --verbose
```

```
  NAME      STATE           VERSION
* Ubuntu    Running         2
```

!!! warning "WSL1 will not work"
    If the `VERSION` column shows `1`, `sbx` cannot start a VM. Upgrade the distro with `wsl --set-version Ubuntu 2`, then set the default for future installs with `wsl --set-default-version 2`.

---

## Step 2 - Install `sbx`

Open **Windows Terminal** (or PowerShell) and install the CLI. The Windows build ships as an MSI you can grab from the releases page, or - if you have a package manager - via `winget`:

```powershell
winget install Docker.sbx
```

Confirm it's on your `PATH`:

```powershell
sbx version
```

Expected output: a version string such as `sbx 0.21.0`.

If PowerShell reports `sbx : The term 'sbx' is not recognized...`, close and reopen the terminal so it picks up the updated `PATH`, or add the install directory (typically `C:\Program Files\sbx`) to your user `PATH` manually.

!!! tip "Rancher Desktop works, Docker Desktop is not required"
    `sbx` manages its own microVMs and does **not** depend on Docker Desktop being installed. If you already run Rancher Desktop for containers, the two coexist cleanly - `sbx` uses WSL2 directly rather than borrowing another product's engine.

---

## Step 3 - Log in and choose a network policy

```powershell
sbx login
```

The flow is identical to macOS - the CLI prints a one-time device code and a URL:

```
Your one-time device confirmation code: XXXX-XXXX
Open this URL to sign in: https://login.docker.com/activate?user_code=XXXX-XXXX

Waiting for authentication...
Signed in as <your-docker-username>.
Daemon started (sandboxd).
```

Open the URL in your browser - the CLI confirms the sign-in automatically and starts the `sandboxd` daemon inside WSL2.

You'll then pick a default network policy for every sandbox on this machine:

```
Select a default network policy for your sandboxes:

     1. Open         - All network traffic allowed, no restrictions.
  ❯  2. Balanced     - Default deny, with common dev sites allowed.
     3. Locked Down  - All network traffic blocked unless you allow it.
```

| Policy | When to use |
|--------|-------------|
| Open | Local dev, no external exposure concerns |
| **Balanced** | **Recommended - least privilege without breaking typical dev workflows** |
| Locked Down | High-security or air-gapped environments |

Choose **Balanced** for the lab. You can change it anytime with `sbx policy reset`.

---

## Step 4 - Store your provider secret (PowerShell syntax)

This is the first place Windows syntax diverges from the Mac instructions. PowerShell does not use `export` - it sets environment variables through the `$env:` drive. Set the key for whichever provider you chose, **in your own terminal**, so it never lands on a page or in a screenshot:

!!! note "If you chose Anthropic + Claude"

    ```powershell
    $env:ANTHROPIC_API_KEY = "sk-ant-..."
    echo $env:ANTHROPIC_API_KEY | sbx secret set -g anthropic
    ```

!!! note "If you chose OpenAI + Codex"

    ```powershell
    $env:OPENAI_API_KEY = "sk-proj-..."
    echo $env:OPENAI_API_KEY | sbx secret set -g openai
    ```

!!! note "If you chose Google + Gemini"

    ```powershell
    $env:GEMINI_API_KEY = "AIza..."
    echo $env:GEMINI_API_KEY | sbx secret set -g google
    ```

The key is read from your shell, piped to `sbx secret set`, and stored in the Windows credential manager. Confirm it landed:

```powershell
sbx secret ls
```

Expected output: a line for your provider with the value masked as `****...****`.

> **Why this matters:** The raw key never enters the sandbox VM. It's injected at the host-side proxy when the agent makes an outbound request - the same credential-proxy guarantee covered in *Secrets Without Exposure*, enforced identically on Windows.

!!! warning "`$env:` lasts only for the current session"
    A variable set with `$env:NAME = "..."` disappears when you close the terminal. That's fine here - once the secret is stored with `sbx secret set`, the plaintext variable has done its job and you don't need it again. Do **not** persist the key with `setx`, which writes it to the registry in clear text.

---

## Step 5 - Clone the lab repo in the right place

The exercises use **DevBoard**, a FastAPI + Next.js issue tracker pre-seeded with bugs. Where you clone it matters more on Windows than anywhere else.

!!! warning "Clone inside the WSL2 filesystem, not `C:\`"
    Files under `/home/you` in WSL2 live on the native Linux filesystem and are read and written at full speed. Files under `C:\Users\you` are reached through a cross-OS translation layer (`/mnt/c/...`), where every file-stat an agent performs is an order of magnitude slower. A large repo can turn a two-second scan into a two-minute one. Always clone into your Linux home.

Open your WSL2 shell (`wsl` from PowerShell, or launch "Ubuntu" from the Start menu) and clone there:

```bash
git clone https://github.com/dockersamples/sbx-quickstart ~/sbx-lab
cd ~/sbx-lab
```

### Fix line endings before the agent touches anything

Git on Windows defaults to `core.autocrlf=true`, which rewrites Unix `LF` line endings to Windows `CRLF` on checkout. That silently breaks shell scripts and container entrypoints the moment they run inside the Linux microVM - you'll see errors like `/usr/bin/env: 'bash\r': No such file or directory`. Set the repo to keep line endings as-is:

```bash
git config core.autocrlf input
git rm --cached -r . >/dev/null 2>&1
git reset --hard
```

The last two commands re-checkout every file with the corrected setting. From here on, scripts in the repo run cleanly inside the sandbox.

---

## Step 6 - Create and run your sandbox

From the repo directory inside WSL2:

```bash
sbx create <agent> .
```

Replace `<agent>` with `claude`, `codex`, or `gemini` to match the secret you stored. On first run the agent image pulls (1-2 minutes) and the sandbox is created with your Balanced policy.

```bash
sbx ls
```

```
SANDBOX   AGENT     STATUS    PORTS   WORKSPACE
sbxlab    <agent>   stopped           /home/you/sbx-lab
```

Start it:

```bash
sbx run sbxlab
```

On first launch the agent may auto-update itself - if you see an update message, simply re-run `sbx run sbxlab`. You'll then see the trust prompt:

```
  Do you trust the contents of this directory? Working with untrusted
  contents comes with higher risk of prompt injection.

› 1. Yes, continue
  2. No, quit
```

Select **1. Yes, continue** and the agent starts, with `~/sbx-lab` mounted into the VM at the same path. You're now exactly where the Mac walkthrough lands at the end of *Your First Sandbox*.

---

## Accessing ports the agent exposes

When an agent inside the sandbox starts a dev server - say DevBoard's frontend on port 3000 - `sbx` forwards it to your host. On Windows there's one extra hop: the port surfaces on the WSL2 network interface, and WSL2's own localhost forwarding then exposes it to Windows.

For modern WSL2 this is automatic - open `http://localhost:3000` in your Windows browser and it works. If a port stubbornly refuses to connect, enable mirrored networking by creating `C:\Users\you\.wslconfig`:

```ini
[wsl2]
networkingMode=mirrored
memory=8GB
processors=4
```

Then restart WSL from an elevated PowerShell:

```powershell
wsl --shutdown
```

The `memory` and `processors` lines are worth setting regardless - they cap how much of your machine WSL2 (and therefore your sandboxes) may consume. Without them WSL2 can balloon to half your RAM.

---

## Windows-specific gotchas

A quick reference for the issues that are unique to - or sharper on - Windows:

| Symptom | Cause | Fix |
|---|---|---|
| `sbx` won't start a VM | Virtualization disabled, or distro on WSL1 | Enable VT-x/AMD-V in BIOS; `wsl --set-version Ubuntu 2` |
| `bash\r: No such file` inside the sandbox | `CRLF` line endings from Git | `git config core.autocrlf input`, then re-checkout (Step 5) |
| Agent file operations crawl | Repo lives under `/mnt/c/...` | Clone into the WSL2 home (`~`), not the Windows drive |
| `localhost:3000` won't connect | WSL2 port forwarding | Add `networkingMode=mirrored` to `.wslconfig`, `wsl --shutdown` |
| TLS / auth errors after sleep | Clock drift inside WSL2 after hibernate | `wsl --shutdown` and relaunch to resync the VM clock |
| WSL2 eats all your RAM | No resource caps | Set `memory=` / `processors=` in `.wslconfig` |
| `sbx: command not found` in WSL | CLI installed on Windows only | Run `sbx` from PowerShell, or install the Linux build inside WSL2 |

!!! tip "When in doubt, bounce WSL"
    A surprising share of Windows-only weirdness - stuck ports, a frozen daemon, clock drift after the laptop slept - clears up with `wsl --shutdown` followed by reopening your terminal. It's the Windows equivalent of "turn the hypervisor off and on again," and it's safe: your sandboxes and stored secrets survive the restart.

---

## Why this matters

Nothing in this module weakens the governance model - the microVM boundary, the credential proxy, and the network policy are enforced by the same machinery on Windows as on macOS and Linux. What changes is the **host plumbing**: a nested hypervisor (WSL2), two filesystems bridged by a translation layer, and a shell that spells environment variables differently.

Get those three right - virtualization on, repo on the Linux side, `$env:` for secrets - and every remaining module in this lab runs for you exactly as written. The isolation proof still holds. The branch-mode diffs still land on a worktree. The network audit log still names every outbound connection. You simply arrived there by a slightly different road.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] Task Manager shows **Virtualization: Enabled** and `wsl -l -v` reports **VERSION 2**
- [ ] `sbx version` runs from PowerShell and prints a version string
- [ ] `sbx login` completed and you selected the **Balanced** network policy
- [ ] Your provider key is stored (`sbx secret ls` shows it masked) using `$env:` syntax
- [ ] The lab repo is cloned **inside the WSL2 home** with `core.autocrlf=input`
- [ ] `sbx run sbxlab` started the agent and it can read the codebase
- [ ] You know `wsl --shutdown` is your first move when something Windows-specific breaks

Next: continue with *Your First Sandbox* - from here on, every module runs the same on Windows as it does on macOS and Linux.
