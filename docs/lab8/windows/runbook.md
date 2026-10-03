# Runbook & Examples

This is the operational playbook for rolling out Docker Sandboxes to a Windows 11 development team. Each developer runs their own Compose stack inside a Linux microVM started by `sbx`, while a single shared Postgres lives on an on-prem Linux server managed by ops. Copy, paste, and adapt the blocks below.

!!! note "Verify flags against your installed version"
    `sbx` evolves quickly. Before you trust any flag shown here, run `sbx <cmd> --help` on the actual machine. If a flag or subcommand differs, the installed CLI is authoritative.

---

## A. Developer laptop onboarding (Windows 11)

Work through this checklist on each new laptop. The first step is a one-time IT action; the rest are per-developer.

- [ ] IT enables the Windows Hypervisor Platform once per machine (elevated PowerShell, requires a reboot) — see [Windows Setup & Admin](windows-setup.md).
- [ ] Developer installs `sbx` per-user: `winget install -h Docker.sbx`.
- [ ] Developer signs in with their own Docker account: `sbx login`.
- [ ] On the first run, choose the **Balanced** network preset when prompted.
- [ ] Store the model-provider credential as a secret: `sbx secret set anthropic` (or `openai` / `openrouter` / `google` / `xai`).
- [ ] Clone the project repository onto the laptop.
- [ ] Apply the network policy and launch the agent: `sh allowlist.sh 10.0.0.5` then `sbx run opencode`.

!!! tip "Own account per developer"
    Every developer authenticates with their own Docker identity. Do not share a single login across the team — secrets and policy are scoped per user.

---

## B. Shared Postgres on the Linux server

Ops brings the database up once on the host Docker Engine:

```bash
POSTGRES_PASSWORD=<strong-secret> docker compose -f shared-db.compose.yaml up -d
```

!!! warning "Keep the database out of a sandbox"
    Run this container on the **host Docker Engine**, managed by ops. Do **not** place it in a sandbox: sandboxes are isolated microVMs and cannot reach one another, so a database inside one sandbox is invisible to every other developer.

Create one role and one database per developer. Run this once per person:

```sql
CREATE ROLE alice LOGIN PASSWORD 'alice-strong-password' CONNECTION LIMIT 20;
CREATE DATABASE alice_app OWNER alice;
```

Each developer connects their app to their own `alice_app` on `<db-host>:5432` and never receives superuser rights. See [Docker Compose & the Shared DB](compose-and-db.md) for the full Compose file and tuning notes.

---

## C. Per-project environment files

Drive each project with an environment file. Copy a per-project `sbxenv.yaml` into a folder **beside** the project — not inside a mounted workspace — then edit the name, database URL, and ports.

```yaml
schemaVersion: "1"
name: my-app
agent: opencode
workspace: ./app
env:
  NODE_ENV: development
  DATABASE_URL: postgres://alice:alice-strong-password@10.0.0.5:5432/alice_app
sandboxOptions:
  cpus: 4
  memory: 8g
  skills: readonly
ports:
  - sandbox: 3000
    host: 3000
```

Preview and create:

```sh
sbx env plan   # preview what will be created
sbx env run    # create the sandbox and attach
```

Day-to-day operations:

| Command | What it does |
| --- | --- |
| `sbx env run` | Reattach to, or restart, the environment |
| `sbx exec -it <sandbox> bash` | Open a shell inside the running sandbox |
| `sbx ports <sandbox> --publish 8080:3000` | Publish a sandbox port to the host |
| `sbx env rm` | Destroy the environment |

See [Environments, Kits & Templates](environments.md) for schema details and reusable templates.

---

## D. Network policy

Allow the shared database host, then confirm what is permitted:

```sh
sh allowlist.sh 10.0.0.5
sbx policy ls
```

The sandbox denies outbound traffic by default. `allowlist.sh` opens exactly the destinations your agent needs — in this case the Postgres server. See [Networking & Policy](networking.md) for how the allowlist is built and audited.

---

## E. Common commands cheat sheet

```sh
# Lifecycle
sbx run opencode ~/my-project
sbx run --name feature opencode ~/proj
sbx run --name feature
sbx create --name scratch opencode
sbx ls
sbx stop my-sandbox
sbx rm my-sandbox
sbx prune --dry-run

# Shell inside a sandbox
sbx exec -it my-sandbox bash

# Ports
sbx ports my-sandbox --publish 8080:3000
sbx ports my-sandbox

# Files
sbx cp ./config.json my-sandbox:/home/agent/workspace/
sbx cp my-sandbox:/home/agent/workspace/out.log ./

# Environments
sbx env plan | run | create | exec | rm

# Templates
sbx template save my-sandbox my-template:v1
sbx run -t my-template:v1 opencode

# Settings
sbx settings list
sbx settings set sandbox.disk.dockerVolume 30g
sbx daemon restart
```

---

## F. Server-hosted sbx (alternative)

If laptops are underpowered, run `sbx` centrally on the Linux server instead of on each laptop.

**Ops setup, once:** on Ubuntu 24.04 or newer, confirm KVM is present, install Docker Engine and `sbx`, then add each developer to the `kvm` group.

```sh
lsmod | grep kvm
sudo usermod -aG kvm alice
```

**Developer over SSH:**

```sh
ssh alice@dev-server
sbx login
cd ~/projects/my-app
sbx policy allow network localhost:5432   # DB lives on this same host
sbx run opencode
```

Because the database runs on the same host, allow `localhost:5432` rather than the laptop-side IP.

!!! tip "Editing with VS Code Remote-SSH"
    Connect VS Code Remote-SSH to the server and open the project directory — the same directory the sandbox mounts read-write. Run the agent in a terminal. Because the mount is direct, your edits are live inside the sandbox with no sync step.

---

## G. Cleanup and disk management

Stop and remove sandboxes, then reclaim disk:

```sh
sbx stop my-sandbox
sbx rm my-sandbox
sbx prune --dry-run    # show what would be removed
sbx prune              # actually remove it
sbx template ls && sbx template rm <name>
```

Always run `sbx prune --dry-run` first so you can see what will be deleted before committing.

---

## Appendix: local model servers (Ollama)

If a developer runs a model server on the **same machine** as `sbx` — for example Ollama on the laptop — then that machine *is* the sandbox host, so `host.docker.internal` resolves correctly from inside the sandbox.

Start the server bound to all interfaces, then allow the port:

```sh
OLLAMA_HOST=0.0.0.0 ollama serve
sbx policy allow network localhost:11434
```

Point your agent config at the host model through its base URL:

```json
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama Local",
      "options": { "baseURL": "http://host.docker.internal:11434/v1" },
      "models": { "qwen2.5-coder:7b-instruct-q4_K_M": { "name": "qwen2.5-coder:7b-instruct-q4_K_M" } }
    }
  }
}
```

!!! warning "Local host only"
    `host.docker.internal` works **only** for a model server on the same machine as `sbx`. The team's shared database is remote — allow `<server>:5432`, not `host.docker.internal`.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] A laptop is onboarded end to end: Hypervisor Platform enabled, `sbx` installed, logged in, Balanced preset chosen, provider secret stored.
- [ ] The shared Postgres runs on the host Docker Engine, with a per-developer role and database created.
- [ ] A project runs from an `sbxenv.yaml` placed beside the workspace, using `sbx env plan` then `sbx env run`.
- [ ] The network policy allows the correct destination (`<db-host>:5432` for remote; `localhost` only on the same host).
- [ ] You can list, shell into, publish ports from, and prune sandboxes using the cheat sheet.

That completes the Windows rollout track — you now have everything needed to onboard a team, run the shared database, and manage per-developer sandboxes. Return to the [Overview](overview.md) to revisit any module.
