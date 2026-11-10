# How Sandboxes Work

Your Windows 11 development team shares a single on-prem Linux server that hosts a common Postgres instance. Each developer needs to run their own Compose stack without stepping on anyone else's work, without touching the host's Docker daemon, and without quietly reaching services they shouldn't. A sandbox gives each developer exactly that: a private, disposable Linux world that an agent can drive freely while staying walled off from everything around it.

This page explains the model before you touch the CLI, so the commands in later modules make sense.

---

## What a sandbox is

A sandbox is a **Linux microVM** — not a container. It boots a real guest kernel through a hypervisor, so it is a far stronger boundary than namespaces and cgroups alone.

On Windows, `sbx` runs this microVM on the **Windows Hypervisor Platform**. There is no WSL2 in the loop, so you do not need a WSL distro installed or configured.

Each sandbox carries its own complete stack:

| Resource | What the sandbox gets |
|----------|------------------------|
| Kernel | Its own guest kernel, isolated from the host |
| Docker Engine | A private Docker daemon running inside the VM |
| Filesystem | Its own root filesystem plus any mounted workspace |
| Network | A private stack with deny-by-default outbound egress through a host-side proxy |

Inside that boundary, the agent has **full control**: it can use `sudo`, install packages, start and stop its own Docker daemon, pull images, and read and write both its own filesystem and the mounted workspace. Nothing it does leaks out.

!!! note "Why a VM and not a container"
    A container shares the host kernel. A microVM does not. For an autonomous agent running untrusted code and installing arbitrary packages, that extra kernel boundary is the point.

---

## Isolation layers

The protection is layered. Each layer stands on its own:

1. **Hypervisor isolation** — the guest kernel is separated from the host by the hypervisor, the hardest boundary available.
2. **Network isolation** — outbound TCP is proxied and **deny-by-default**; UDP is off unless you enable it; ICMP is blocked; DNS resolution is forced through policy.
3. **Docker Engine isolation** — the sandbox runs its **own** Docker daemon; the host's daemon is unreachable from inside.
4. **Workspace isolation** — your code enters through one of three modes: mountless, clone, or direct mount (covered later).
5. **Credential isolation** — API keys are injected into outbound HTTP **headers by the host proxy**; the raw secret values never enter the VM.

!!! tip "Credentials never land in the guest"
    Because the proxy adds auth headers on the way out, an agent can call an authenticated API without ever seeing the key. If the sandbox is compromised, there is no secret inside to steal.

---

## Blocked by default (not configurable)

Some boundaries are hard-wired. You cannot open these up:

- The host filesystem outside your mounted workspaces and the shared skills store.
- The host's Docker daemon.
- Direct network connections between one sandbox and another.
- Direct external ICMP (ping) traffic.

These are the guarantees that let your team run many sandboxes against one shared server without them interfering with each other or with the host.

---

## Default Linux images (templates)

Templates are the starting images for a sandbox. They are **Ubuntu-based** and run as a non-root user named **`agent`** (UID 1000, home `/home/agent`) that has `sudo`. Most templates ship Git, the Docker CLI, and common toolchains such as Node, Python, Go, and Java.

Pick the template that matches the agent you want to run:

| Template | Agent inside |
|----------|--------------|
| `claude-code` | Claude Code |
| `claude-code-minimal` | Claude Code, minimal (no Node, Python, Go, or Java) |
| `codex` | OpenAI Codex |
| `copilot` | GitHub Copilot CLI |
| `cursor-agent` | Cursor |
| `devin` | Devin CLI |
| `docker-agent` | Docker Agent |
| `droid` | Droid |
| `gemini` | Gemini CLI |
| `kiro` | Kiro |
| `opencode` | OpenCode |
| `shell` | No agent — manual setup |

---

## Bring your own Linux image

You can supply your own image as long as it meets the contract the runtime expects:

- `curl`, `git`, and a set of trusted CA certificates are present.
- `/bin/sh` and `/bin/bash` exist and are executable.
- A non-root `agent` account with UID 1000 and home `/home/agent` is defined in `/etc/passwd`, and the image sets `USER agent`.
- `ENTRYPOINT`/`CMD` is set to launch the agent, or to drop into a shell.

Meet those points and your custom image behaves like a built-in template.

---

## Lifecycle and persistence

Knowing what survives a restart matters when your Compose stack holds state.

| Action | Effect |
|--------|--------|
| `sbx run` | Boots the microVM and attaches you to it |
| Stop / start | Everything inside the VM persists |
| `sbx rm` | Deletes the sandbox and all of its contents |

What persists across stop and start: installed packages, pulled images, containers, Docker volumes, and files written to a mountless workspace.

!!! warning "Directly mounted workspaces are not deleted"
    A directly mounted workspace lives on the host filesystem, not inside the VM. Running `sbx rm` removes the sandbox and everything in it, but a direct mount stays put on the host. Removing a sandbox does not delete your mounted source tree.

---

## Comparison to alternatives

How sandboxes stack up against other ways teams isolate agent and tool execution:

| Approach | Isolation | Docker daemon | Best for |
|----------|-----------|---------------|----------|
| Sandboxes (microVMs) | Full hypervisor isolation | Isolated, in-VM daemon | Autonomous agents |
| Container with socket mount | Partial (namespaces) | Shared host daemon | Trusted tools |
| Docker-in-Docker | Partial (privileged) | Nested daemon | CI/CD |
| Host execution | None | Host daemon | Manual dev |

Sandboxes trade **higher resource overhead** — a full VM plus its own Docker daemon — for complete isolation. For a shared on-prem server where several developers run independent stacks against a common Postgres, that trade is usually worth it.

---

## Cost

- The `sbx` CLI and **local** sandbox compute are free to use, including commercially.
- **Cloud** sandbox compute is pay-as-you-go.
- Organization governance — central policy, audit logs, and sign-in enforcement — is a separate paid tier.

For the single shared server in this scenario, local compute means your whole team can run sandboxes at no per-sandbox cost.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You can explain why a sandbox is a microVM and not a container.
- [ ] You can name the five isolation layers.
- [ ] You know which four boundaries are blocked by default and cannot be opened.
- [ ] You can pick the right template for the agent you want to run.
- [ ] You understand what persists across stop/start and what `sbx rm` deletes.
- [ ] You know that a directly mounted workspace survives `sbx rm`.

Next: [Windows Setup & Admin](windows-setup.md).
