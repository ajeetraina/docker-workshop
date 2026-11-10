# Security & Guardrails

Your team runs on Windows 11 with no WSL2. Each developer spins up their own Compose stack inside a Linux microVM via `sbx`, while a single on-prem Linux box hosts the shared Postgres. The whole point of this design is simple: **no single engineer can damage the whole machine**. This page explains the isolation you get for free, what is blocked no matter what, and the guardrails you add on top.

---

## Isolation layers

The sandbox stacks several independent boundaries. Each one would have to fail for an agent or a careless script to reach the host.

1. **Hypervisor isolation.** Every sandbox runs in its own Linux microVM with its own kernel. There is no shared memory and no shared process table with your Windows host. An agent inside a sandbox sees only its own kernel, not yours.
2. **Network isolation.** Outbound TCP is proxied through the host with a deny-by-default policy; nothing leaves unless a rule allows it. UDP is disabled and ICMP is blocked, so there is no ping or raw datagram path out of the VM. See the [Networking](networking.md) module for how egress rules are authored.
3. **Docker Engine isolation.** Each sandbox carries its own Docker Engine inside the microVM. There is no route from the sandbox to the host's Docker daemon, so an agent cannot reach the engine that controls your machine.
4. **Workspace isolation.** You choose how your code enters the VM: mountless (nothing shared), clone (a copy), or direct mount (your working tree is live in the VM). Pick the weakest coupling the task allows.
5. **Credential isolation.** API keys are injected into HTTP request headers by the host-side proxy. The raw secret values never enter the VM, so an agent cannot read them from the environment or exfiltrate them.

---

## Blocked by default (not changeable by policy)

Some boundaries are structural. No configuration flag opens them:

- The host filesystem outside your mounted workspaces and the shared skills store.
- The host Docker daemon.
- Direct sandbox-to-sandbox network communication.
- Direct external ICMP.

!!! warning "These are floors, not knobs"
    You cannot relax these with policy. If a task seems to need one of them, the task is wrong, not the sandbox.

---

## Guardrails to add on top

The sandbox protects the host. You still have to protect the one thing that is genuinely shared: the Postgres server. Add these.

| Guardrail | Why |
|-----------|-----|
| Never add developers to the host `docker` group | Daemon access is root-equivalent on the host and defeats the entire design. Only ops needs host Docker. |
| Per-developer DB database + role | The shared DB is the only shared failure domain. Separate tenancy prevents one dev from damaging another's data. |
| Connection limits + resource caps on Postgres | Stops one developer exhausting connections or CPU for everyone. |
| Host resource limits (systemd slices / cgroups) and `sandboxOptions.cpus` / `memory` | Prevents a single sandbox from starving the others on a developer's machine. |
| Disk quotas + `sbx prune` | Sandboxes consume VM and Docker disk (10 GB default each) and accumulate fast. |
| `sbx secret set` for credentials | Keeps raw values out of the sandbox and out of any saved template. |
| Standard network rules shipped in a kit | Consistent, auditable egress across the whole team. |
| Review direct-mounted changes before running modified code | In direct mode the agent edits your working tree, including Git hooks, Makefiles, `package.json` scripts, and CI config. |

The per-developer database split is covered in detail in the [Docker Compose & the Shared DB](compose-and-db.md) module.

---

## Secrets

Credentials deserve their own discipline. Environment variables are convenient but visible.

- Store provider keys with `sbx secret`. The host-side proxy injects them at request time, so the sandbox never holds the raw value.
- Variables set with `-e` / `--env` are readable inside the sandbox. That is fine for non-secrets (log levels, feature flags) but never for keys.
- Saved templates capture the filesystem. If you manually wrote a key into a sandbox, it ends up baked into the template and shared with whoever uses it. Prefer managed secrets so this cannot happen.

!!! tip "Rule of thumb"
    If leaking it would be bad, it goes through `sbx secret`, not through `--env`.

---

## Shared skills caveat

Sandboxes can mount a shared agent-skills store. By default it is mounted read-only, so no sandbox can alter what the others load.

!!! warning "Read-write skills are a shared blast radius"
    If the store is mounted `readwrite`, one sandbox can modify the instructions every other sandbox reads. When that risk is unacceptable, disable the store with `--skills=off` on the command line or `skills: off` in your template.

---

## MCP caveat

Local stdio MCP servers do not run inside the sandbox. They run on your host, with your host permissions.

!!! warning "MCP servers are host integrations"
    An MCP server the agent calls executes outside every boundary above. Treat each one as a trusted integration and only wire up servers you fully control.

---

## Governance (optional, paid)

For larger teams, org admins can centrally manage network, filesystem, and MCP policies across every local sandbox, enforce sign-in, and collect audit logs.

When central governance is active, only org allow rules grant access:

- Local allow rules are ignored.
- Local deny rules still apply (a developer can tighten, never loosen).

This gives security teams one place to audit what every sandbox on every laptop is permitted to do.

---

## Threat model summary

Who can affect what, assuming you have applied the guardrails above:

| Actor | Can affect |
|-------|-----------|
| A sandboxed agent | Its own VM, its mounted workspace, and the network destinations you allowed. Nothing else. |
| A developer | Their own sandboxes, and their own DB schema if database tenancy is enforced. |
| A developer exploiting the sandbox | Only via a host kernel or hypervisor escape — a far higher bar than the shared-daemon access they would have had without microVMs. |

The takeaway: the worst-case blast radius of a mistake is a single developer's sandbox or their own slice of the database. The host, and everyone else's work, stays intact.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You can name the five isolation layers and what each one blocks.
- [ ] No developer is a member of the host `docker` group.
- [ ] Each developer has their own Postgres database and role.
- [ ] Postgres has connection limits and resource caps configured.
- [ ] Provider keys are stored with `sbx secret`, never passed via `--env`.
- [ ] The shared skills store is read-only, or disabled where read-write is unsafe.
- [ ] You understand that MCP servers run on the host with host permissions.

Next: [Runbook & Examples](runbook.md).
