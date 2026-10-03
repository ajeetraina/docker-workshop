# sbx on Windows: Overview and Architecture

This track sets up a repeatable sandbox workflow for a team of Windows 11 developers who build against an on-prem Linux server hosting a shared PostgreSQL database. Each developer runs their own isolated Docker Compose stack, yet everyone talks to the same database.

!!! note "Who this is for"
    You are on a Windows 11 laptop (Intel or AMD). Your team shares one Linux server on the LAN that runs a common Postgres container. You want each engineer to run their own stack without colliding with anyone else and without being able to break the shared machine.

---

## What you are building

You install `sbx` on each Windows laptop. Every developer then runs their coding agent plus their own `docker compose` stack inside a Linux microVM. The shared database stays put on the on-prem Linux server as an ordinary container, reached across the LAN.

On Windows, `sbx` runs on top of the Windows Hypervisor Platform. Turning that on is a one-time elevated action per laptop. You do **not** need WSL2.

---

## Recommended architecture

Put the compute where the developer sits, and keep the one shared resource — the database — on the server.

```text
  Windows 11 laptop (Dev A)              Windows 11 laptop (Dev B)
  +-------------------------+            +-------------------------+
  |  sbx microVM (Linux)    |            |  sbx microVM (Linux)    |
  |   - own Docker daemon   |            |   - own Docker daemon   |
  |   - own compose stack   |            |   - own compose stack   |
  |   - workspace (mount)   |            |   - workspace (mount)   |
  +-----------+-------------+            +-----------+-------------+
              |                                      |
              |   sbx policy allow network           |
              |   <db-host>:5432  (LAN)              |
              +-------------------+------------------+
                                  |
                                  v
                 +-------------------------------------+
                 |  On-prem Linux server (Ubuntu 24.04+)|
                 |    host Docker Engine                |
                 |    shared-postgres (published :5432) |
                 +-------------------------------------+
```

Each microVM is sealed off by default. To let a sandbox reach Postgres over the network, you add one allow rule:

```bash
sbx policy allow network <db-host>:5432
```

---

## Key properties

- **Hypervisor-level isolation** — every sandbox is a microVM with its own kernel, Docker daemon, filesystem, and network stack. It is a boundary enforced by the hypervisor, not by container flags.
- **Per-developer independence** — each engineer's compose stack and volumes live inside their own sandbox, so nobody's containers, ports, or data step on anyone else's.
- **Shared DB, per-developer access** — the database is common, but each developer gets their own database and role rather than a shared superuser.
- **Linux parity** — the sandbox is real Linux, so your builds and containers match what ships to the server.

---

## How this meets the team's goals

| Team goal | How the architecture delivers it |
|-----------|----------------------------------|
| Windows devs, on-prem Linux server | Developers only need a terminal and editor; the Linux work happens in the microVM and on the server |
| One shared DB container on the Linux box | Postgres runs under the server's host Docker Engine; sandboxes reach it over the LAN via an allow rule |
| Own Docker Compose, fully independent | Each sandbox has a private Docker daemon, so stacks never share state |
| One engineer can't break the machine | The microVM boundary blocks host filesystem access outside mounts, host Docker, and unapproved network by default |
| Linux targets without WSL2 | Sandboxes are Linux microVMs on the Windows Hypervisor Platform |

---

## Alternatives

If laptops can't take the one-time admin step, or you prefer centralized compute, two other shapes work.

- **Server-hosted sbx** — install `sbx` on the Linux server, give each developer a Linux account, and have them SSH in and run their agent there. This needs Ubuntu 24.04+, KVM enabled, and users in the `kvm` group — all one-time elevated work done by ops.
- **Cloud sandboxes** (`sbx --cloud`) — Docker-managed compute with no local hypervisor and no local admin. There is no host workspace mount, it can't reach on-prem host paths, and you pay as you go.

| Dimension | sbx on laptops | sbx on server | Cloud sandboxes |
|-----------|----------------|---------------|-----------------|
| Compute | Each laptop | Shared server | Docker-managed |
| Compose runs on | Laptop microVM | Server microVM | Cloud microVM |
| Admin needed | One-time per laptop | One-time by ops | None |
| Reaches on-prem DB | Yes (LAN) | Yes (local) | No |
| Workspace mount | Yes | Yes | No |
| Cost | Existing hardware | Existing server | Pay-as-you-go |

---

## The one shared failure domain: the database

Everything else is isolated per developer. The database is not — it lives outside the sandboxes, on the server's host Docker Engine, and everyone connects to it. Treat it with care.

!!! warning "Protect the shared database"
    - Give each developer their own database and role. Do not hand out the shared superuser.
    - Set connection limits and resource caps per role so one runaway client can't starve the others.
    - Issue per-developer credentials and inject them with `sbx secret set` rather than baking them into files.

---

## What to avoid

| Anti-pattern | Why it fails you |
|--------------|------------------|
| Everyone sharing one Docker daemon | No isolation; access is effectively root-equivalent across the team |
| Mounting the host Docker socket into a container | Containers become host-root — the boundary is gone |
| Docker-in-Docker as an isolation story | Needs privileged mode and only gives partial separation |
| Running compose directly on the server host | Defeats the isolation goal entirely |

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You understand that `sbx` runs each developer's compose stack inside its own Linux microVM.
- [ ] You know the shared Postgres stays on the on-prem server and is reached via `sbx policy allow network <db-host>:5432`.
- [ ] You can explain why the database is the one shared failure domain and how per-dev roles contain it.
- [ ] You know the Windows Hypervisor Platform needs a one-time elevated enablement and that WSL2 is not required.
- [ ] You can name the two alternatives (server-hosted and cloud) and when each applies.

Next: [How Sandboxes Work](how-sandboxes-work.md).
