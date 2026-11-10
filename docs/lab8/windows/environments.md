# Environments, Kits & Templates

Every sandbox starts from *something*: a base operating system, a set of tools, maybe an agent, perhaps a few secrets and open ports. `sbx` gives you four layers to shape that contents. They stack from lightweight and disposable up to fully reproducible, and the golden rule is simple — reach for the lightest layer that does the job.

For your Windows 11 team sharing an on-prem Linux server, this matters: you want every developer spinning up a sandbox that already knows how to talk to the shared Postgres, run Compose, and reach only the domains you allow — without anyone hand-configuring their microVM each morning.

| Layer | Purpose | Mechanism |
|-------|---------|-----------|
| Agent / template | Base OS + agent + tools | `sbx run <agent>` → `docker/sandbox-templates:<variant>` |
| Kits | Package tools, config, network, credentials, agent instructions | `--kit`, kit sets |
| Environment file | Repeatable full environment per project | `sbxenv.yaml` + `sbx env ...` |
| Template image | Snapshot a hand-configured sandbox | `sbx template save` / `-t` |

---

## 1. Pick the agent / template

The fastest way to get a sandbox is to name an agent. Each agent maps to a base template variant that ships with the OS, the agent binary, and a sensible toolchain.

```bash
sbx run opencode   # start with the opencode agent
sbx run claude      # start with Claude Code
sbx run shell       # no agent at all — a bare Linux shell you drive manually
```

Use `shell` when you want to configure things by hand before deciding what to bake in. The full list of template variants and what each one includes lives in [How Sandboxes Work](how-sandboxes-work.md).

---

## 2. Kits

A kit packages software *and* its configuration into a reusable, publishable unit. Kits play one of two roles:

- **Workload** — supplies the base environment plus a launch command. You pass a workload to `sbx run` or `sbx create` as the thing you're starting.
- **Mixin** — layers extra tools or behavior onto a workload. You add mixins with `--kit`.

```bash
sbx run me/my-agent-kit:latest --kit me/my-mixin:latest
```

A **kit set** bundles a workload plus one or more mixins behind a single publishable reference, so the team pulls one name instead of assembling pieces by hand.

!!! warning "Version compatibility"
    Kits come in two generations and they do not mix inside one sandbox.

    - v3 kits require `sbx` version 0.45 or newer.
    - The built-in agent names (`opencode`, `claude`, and friends) are v2 kits.
    - You cannot combine v2 and v3 kits in the same sandbox.
    - To use a v3 mixin, start from a v3 workload selected by its image, path, or Git reference — not by a built-in v2 agent name.

Kits can also declare their **network access and credentials**. This is the team-wide lever: encode which domains a sandbox may reach into a shared kit, and every developer who uses it inherits the same policy for free.

---

## 3. Environment files (`sbxenv.yaml`)

This is the layer you'll use most. An environment file captures a sandbox's full setup — agent, tools, resources, secrets, ports — so everyone on the team reproduces the same environment from one checked-in file.

!!! note "Experimental"
    `sbx env` is experimental. Its interface may still change between releases, so pin your `sbx` version if you depend on it in CI.

```yaml
schemaVersion: "1"
name: web-app
agent: opencode
workspace: ./web-app
additionalWorkspaces:
  - path: ./shared-components
    readOnly: true          # mount read-only
kits:
  - docker.io/sbx/playwright-kit:latest
env:
  NODE_ENV: development
sandboxOptions:
  cpus: 4
  memory: 8g
  skills: off
secrets:
  anthropic:
    command: cat ~/.anthropic-key   # resolved on the host
ports:
  - sandbox: 3000
    host: 3000
lifecycle:
  postCreate:
    - command: ./scripts/seed-fixtures.sh
      workdir: web-app
```

### Commands

| Command | Description |
|---------|-------------|
| `sbx env plan` | Preview the changes without applying them |
| `sbx env run` | Apply the plan, create the sandbox if needed, then attach |
| `sbx env create` | Apply the plan without attaching |
| `sbx env exec -- <cmd>` | Run a command inside an existing environment |
| `sbx env rm` | Destroy the environment and its resources |

### How files are found and merged

- Keep the file **outside** any mounted workspace, so the sandbox can't rewrite its own definition.
- Put a per-project `sbxenv.yaml` in each repo, and keep a `~/.sbxenv.yaml` for personal defaults. The personal file cannot set `name`.
- Multiple files merge: later values override earlier ones, and lists concatenate.
- Parameterize with an `args:` block, then supply values via `--env-arg NAME=VALUE` or `--env-args-file`.
- Reference paths with `${{ env.projectDir }}` and `${{ env.fileDir }}`.

!!! warning "What changes take effect when"
    Edits to `workspace`, `kits`, `ports`, `secrets`, or `sandboxOptions` apply only on the **next creation**. To pick them up, run `sbx env rm` and recreate the environment.

### Top-level fields

`schemaVersion`, `name`, `agent`, `args`, `kits`, `workspace`, `additionalWorkspaces`, `env`, `sandboxOptions`, `secrets`, `bindings`, `registries`, `mcp`, `ports`, `lifecycle`.

### Resource limits

| Option | Meaning | Default |
|--------|---------|---------|
| `sandboxOptions.cpus` | Number of CPUs; `0` = all host CPUs (also `--cpus` on run/create) | `0` |
| `sandboxOptions.memory` | Memory limit, e.g. `8g`, `512m` | host default |
| `sandbox.disk.dockerVolume` | Docker storage inside the sandbox | `10g` |

!!! tip "Per-sandbox disk override"
    Need more room for images and Compose volumes? Bump the sandbox's Docker store at creation:

    ```bash
    DOCKER_SANDBOXES_DOCKER_SIZE=30g sbx create ...
    ```

---

## 4. Templates — snapshot a configured sandbox

When you've hand-tuned a running sandbox and want to reuse that exact state, save it as a template image.

```bash
sbx template save my-sandbox my-template:v1   # snapshot a running sandbox
sbx run -t my-template:v1 opencode             # start a new sandbox from it
sbx template ls                                 # list saved templates
sbx template rm my-template:v1                  # delete one
```

!!! warning "What a template does and does not capture"
    - Templates capture the **container filesystem only**. They do *not* include mounted host workspaces, and they do *not* include `/var/lib/docker` (the sandbox's own Docker store).
    - Agent user-level config files are recreated fresh on each creation.
    - A template *can* embed secrets if you wrote them into the filesystem. Prefer `sbx secret set`, which keeps credentials out of the image.

---

## Choosing a layer

| You want to... | Use |
|----------------|-----|
| Run a quick one-off experiment | Agent / template variant |
| Standardize a toolchain and rules across the whole team | Kit or kit set |
| Reproduce a per-project environment | `sbxenv.yaml` (recommended default) |
| Reuse a sandbox you configured by hand | Saved template |

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You can name the four layers and which is the lightest for a throwaway task.
- [ ] You know the difference between a kit **workload** and a kit **mixin**, and why v2 and v3 kits can't share a sandbox.
- [ ] You can write a minimal `sbxenv.yaml` with an agent, a workspace, resource limits, and a port mapping.
- [ ] You understand that workspace, kits, ports, secrets, and sandboxOptions changes need `sbx env rm` and a recreate.
- [ ] You know a saved template excludes host workspaces and the sandbox's Docker store, and that secrets belong in `sbx secret set`.

Next: [Docker Compose & the Shared DB](compose-and-db.md).
