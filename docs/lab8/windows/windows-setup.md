# Windows Setup & Admin Requirements

Your team runs Windows 11 laptops, shares a single on-prem Linux server hosting Postgres, and each developer wants to run their own Compose stack in an isolated Linux microVM. This page gets every Windows machine ready to launch local sandboxes with `sbx`, and tells you exactly which steps need admin rights and which do not.

The headline you need to carry into conversations with IT: on Windows, `sbx` runs local microVMs on the **Windows Hypervisor Platform**. It does **not** require WSL2. Enabling the runtime is a **one-time elevated action** per laptop. After that, day-to-day work needs no admin at all.

---

## Prerequisites for local sandboxes

Confirm each machine meets these before you try to run a sandbox locally.

| Requirement | Detail |
| --- | --- |
| Operating system | Windows 11 |
| Processor | 64-bit Intel or AMD. Windows on ARM is **not** supported for local sandboxes |
| Virtualization runtime | Windows Hypervisor Platform optional feature enabled |
| Firmware | CPU virtualization (VT-x / AMD-V) enabled in BIOS/UEFI |

!!! note "ARM laptops"
    If a developer is on a Windows on ARM device, local sandboxes are off the table for them. Point those users at the cloud or server-hosted options described near the end of this page.

---

## Does it need admin?

This is the question everyone asks first. Here is the precise breakdown, step by step.

| Step | Admin required? |
| --- | --- |
| Install `sbx` per-user (`winget install -h Docker.sbx`) | No — installs to `%LOCALAPPDATA%`, no elevation |
| Install the all-users MSI | Yes (elevated) — prefer the per-user install |
| Enable Windows Hypervisor Platform | Yes, one-time, elevated, plus likely a reboot |
| Enable CPU virtualization in BIOS/UEFI (if off) | Physical/firmware access to the machine |
| Day-to-day `sbx run` | No admin |

The pattern to internalize: the **only** step that truly needs elevation during normal setup is enabling the hypervisor feature, and that happens once. Everything a developer does afterward runs under their own standard account.

---

## The one-time elevated command

Open an **elevated** PowerShell (Run as administrator) and enable the optional feature.

```powershell
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All
```

!!! warning "Enable the right feature"
    This enables the **Windows Hypervisor Platform** optional feature. It is **not** the Hyper-V management role, and it is **not** WSL2. Do not install or rely on WSL2 for local sandboxes.

A reboot is usually required after enabling the feature. Once the machine is back up, the runtime is live and no further elevation is needed.

---

## The ask for IT (word it carefully)

When you raise this with IT or security, be precise so the request is not mistaken for something it isn't.

- You are **not** asking for WSL2.
- You **are** asking to enable the **Windows Hypervisor Platform** optional feature and to ensure **hardware virtualization** is enabled in firmware.
- IT enables this **once per laptop** — manually, or at scale via Intune / MDM / Group Policy.
- Afterward, developers install `sbx` per-user and work **without admin**.

Framing it this way keeps the conversation focused on a single, well-scoped, one-time change rather than a broad entitlement.

---

## Intune / MDM rollout

For fleet deployment, ops can enable the feature per machine and let developers finish the per-user install themselves.

```powershell
# One-time, elevated, per machine
Enable-WindowsOptionalFeature -Online -FeatureName HypervisorPlatform -All -NoRestart
# Then, as the developer (no admin):
winget install -h Docker.sbx
```

The `-NoRestart` flag lets your deployment tooling schedule the reboot on its own terms rather than forcing one mid-rollout.

!!! warning "Windows 11 Home"
    On Windows 11 Home, verify that the Windows Hypervisor Platform is actually available before you commit to a local-sandbox plan for that machine. Check feature availability first so you are not surprised later.

---

## Install and sign in (developer)

Once the hypervisor feature is enabled and the machine has rebooted, each developer sets up their own tooling. None of this needs admin.

Install the CLI per-user:

```powershell
winget install -h Docker.sbx
```

Sign in with your own Docker account — each developer authenticates individually:

```powershell
sbx login
```

Store the credential for your model provider. The command prompts for the value and keeps the raw key out of the sandbox:

```powershell
sbx secret set anthropic
```

You can store credentials for other providers the same way — for example `openai`, `openrouter`, `google`, or `xai`.

!!! tip "PowerShell and keys"
    If you need a transient key for piping, you can set it inline for the current session:

    ```powershell
    $env:ANTHROPIC_API_KEY = "..."
    ```

    Prefer `sbx secret set`, though. It prompts for the value and stores it securely instead of leaving the raw key in your shell history or environment.

---

## First-run network preset

On your first run, `sbx` asks you to pick a network policy. Choose **Balanced**: it denies traffic by default and allows the common developer sites you need. You can tighten or loosen it later.

```powershell
sbx policy
```

Start with Balanced, then adjust per workspace as your team settles on which endpoints the shared Postgres host and your build tools actually require.

---

## If zero admin is non-negotiable

Some environments cannot grant even a one-time elevated step. In that case local sandboxes are not possible on the laptop, and you have two paths.

1. **Cloud sandboxes** (`sbx --cloud`): no local hypervisor and no admin on the laptop. The trade-off is that there is no host workspace mount, and it is pay-as-you-go.
2. **`sbx` on the Linux server**: all elevated work is done once by ops using KVM on the server, and developers SSH in to use it.

See [Runbook & Examples](runbook.md) for the concrete commands behind both paths.

---

## Linux server prerequisites

If you are running the shared Postgres host or hosting `sbx` on the server, make sure the box is ready.

| Requirement | Detail |
| --- | --- |
| OS | Ubuntu 24.04+, 64-bit |
| Virtualization | KVM available and enabled |
| Permissions | Your user is in the `kvm` group |
| Nested virt | Required if the server is itself a VM |

Add your user to the `kvm` group and refresh the session:

```bash
sudo usermod -aG kvm $USER
newgrp kvm
```

If the server is itself a virtual machine, confirm that nested virtualization is enabled by the underlying hypervisor, or KVM inside it will not start.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] The laptop is Windows 11 on a 64-bit Intel or AMD processor (not ARM).
- [ ] CPU virtualization is enabled in BIOS/UEFI.
- [ ] The Windows Hypervisor Platform optional feature is enabled (one-time, elevated) and the machine has rebooted.
- [ ] You understand this is **not** WSL2 and **not** the Hyper-V role.
- [ ] `sbx` is installed per-user with `winget install -h Docker.sbx`.
- [ ] You ran `sbx login` with your own Docker account.
- [ ] Your model-provider credential is stored with `sbx secret set`.
- [ ] You selected the **Balanced** network preset on first run.

Next: [Workspaces & Naming](workspaces.md).
