# Declarative Environments with `sbx env`

Every module so far has stood up sandboxes with `sbx run` and a fistful of flags - the agent, the workspace, memory, CPUs, secrets, ports. That works, but it lives in your shell history. The next person on your team can't see it, can't review it, and can't reproduce it.

`sbx env` fixes that. You describe the whole environment **once** in a `.sbxenv.yaml` file that lives in the repo - the agent, the workspace mounts, environment variables, resource limits, secrets, MCP servers, and ports - and commit it. Anyone who clones the repo runs one command and gets the identical governed sandbox.

If you've used Docker Compose, the mental model is exact: **`.sbxenv.yaml` is to a sandbox what `compose.yaml` is to a container.** Same declarative shape, same multi-file override semantics, same lifecycle verbs.

---

## The `.sbxenv.yaml` file

Create a file named `.sbxenv.yaml` in the root of your workspace. Here's a minimal one:

```yaml
schemaVersion: "1"       # required - selects the parsing/validation rules
name: sbxenv-demo        # optional - the sandbox name and secret scope
agent: shell             # required - claude, codex, gemini, shell, ...
workspace: .             # the primary read/write mount (defaults to this dir)

env:                     # environment variables set inside the sandbox
  APP_ENV: workshop
  GREETING: "hello from sbxenv"

sandboxOptions:          # create-time knobs, mapping to `sbx create` flags
  memory: 2g
  cpus: 2
```

That's the whole contract. When `name` is omitted, `sbx` derives `<agent>-<workspace-basename>`, exactly like `sbx run`.

---

## The lifecycle: four verbs

`sbx env` mirrors the create/attach/remove flow you already know, driven entirely from the file:

| Command | What it does |
|---|---|
| `sbx env create` | Provisions declared secrets and creates the sandbox. Does **not** attach. |
| `sbx env run` | Creates the sandbox if needed, then drops you into its shell. Re-attaches an existing one without re-provisioning. |
| `sbx env exec -- CMD` | Runs a command in the sandbox (starting it first if stopped). |
| `sbx env rm` | Removes the sandbox **and** the secrets scoped to it. |

Each verb takes optional `PATH` arguments - either a directory (it reads `<dir>/.sbxenv.yaml`) or the path to a file itself. With no path, it reads `.sbxenv.yaml` from the current directory.

---

## Hands-on: stand it up

From the directory containing your `.sbxenv.yaml`:

```bash
sbx env create
```

`sbx` loads the file, resolves the configuration, prepares the image, and creates the sandbox:

```
── LOAD ENVIRONMENT
   reading environment file…
     ./.sbxenv.yaml
   ✓ environment loaded
── RESOLVE SETUP
   resolving configuration…
     sandbox    sbxenv-demo
     agent      shell
     workspace  /Users/you/work/sbxenv-demo (rw)
     image      docker/sandbox-templates:shell-docker
     cpu        2
     memory     2g
   ✓ configuration resolved
── PREPARE IMAGE
   ✓ image ready
── CREATE SANDBOX
   ✓ Created sandbox sbxenv-demo
```

Confirm it's running with the same `sbx ls` you've used all lab - the environment sandbox is an ordinary sandbox, just declared instead of typed:

```bash
sbx ls
```

```
SANDBOX       AGENT    STATUS    PORTS   WORKSPACE
sbxenv-demo   shell    running           /Users/you/work/sbxenv-demo
```

---

## Verify the file drives everything

Nothing here is magic - every value in the file lands where it should. Prove it with `sbx env exec`:

```bash
# Environment variables come straight from the `env:` block
sbx env exec -- sh -c 'echo "APP_ENV=$APP_ENV"; echo "GREETING=$GREETING"'
```

```
APP_ENV=workshop
GREETING=hello from sbxenv
```

```bash
# The workspace mount is your directory, at the same absolute path
sbx env exec -- sh -c 'pwd; ls -la'
```

```bash
# Resource limits match sandboxOptions (cpus: 2, memory: 2g)
sbx env exec -- sh -c 'nproc; free -h | head -2'
```

```
2
               total        used        free      shared  buff/cache   available
Mem:           2.0Gi       128Mi       1.5Gi       256Ki       340Mi       1.8Gi
```

Two CPUs, two gigs of RAM, your env vars, your workspace - exactly what the file declared. No flags, no shell history.

---

## Layering files: compose `-f` semantics

Here's where the Compose analogy pays off. Pass **more than one** path and `sbx env` deep-merges them in order - later files win. This is the standard base + personal-override pattern.

Keep the base `.sbxenv.yaml` in Git, then add a personal `.sbxenv.local.yaml` (gitignored) with your overrides:

```yaml
# .sbxenv.local.yaml
schemaVersion: "1"
agent: shell
env:
  APP_ENV: production-override
  EXTRA: added-by-override
```

Create the sandbox from both files:

```bash
sbx env create .sbxenv.yaml .sbxenv.local.yaml
sbx env exec .sbxenv.yaml .sbxenv.local.yaml -- \
  sh -c 'echo "APP_ENV=$APP_ENV"; echo "EXTRA=$EXTRA"; echo "GREETING=$GREETING"'
```

```
APP_ENV=production-override    # overridden by the local file
EXTRA=added-by-override        # added by the local file
GREETING=hello from sbxenv     # preserved from the base file
```

The merge is **key-by-key**, exactly like Compose: mappings (`env`, `secrets`, `sandboxOptions`) merge per key, sequences (`kits`, `ports`, `mcp.servers`) concatenate, and scalars are replaced by the last file to set them. Relative paths and the derived sandbox name anchor to the **first** file's directory.

!!! note "`env` is applied at create time"
    Environment variables are baked in when the sandbox is **created**. Changing `env:` and re-running `sbx env exec` won't retroactively change a running sandbox - `sbx env rm` and re-create (or `sbx env run` a fresh one) to pick up the new values.

---

## Interpolation: keep secrets out of the file

Values can reference the environment `sbx` itself runs in, with the same syntax as Compose:

| Syntax | Meaning |
|---|---|
| `$VAR` / `${VAR}` | the value, or `""` when unset |
| `${VAR:-default}` | the value if set and non-empty, else `default` |
| `${VAR:?message}` | error out if unset or empty |
| `$$` | a literal `$` |

```yaml
env:
  API_HOST: ${API_HOST:-api.staging.internal}
sandboxOptions:
  memory: ${SBX_MEM:-4g}
```

For actual secrets, don't interpolate them into `env:` - use the `secrets:` block, which provisions them into the credential store at the sandbox's scope so `sbx env rm` can clean them up:

```yaml
secrets:
  anthropic:
    ref: op://Private/Anthropic/api-key   # a 1Password / vault reference
    refresh: 55m
  github:
    command: gh auth token                # stdout of a command becomes the value
```

Each secret names **exactly one** source - `value` (a literal), `ref` (a vault reference resolved at use time), or `command` (stdout of a shell command). This is the declarative equivalent of the `sbx secret` flow from the *Secrets Without Exposure* module.

---

## Tear it down

Because everything provisioned is scoped to the environment's sandbox name, one command removes the sandbox and its scoped secrets together:

```bash
sbx env rm            # add -f to skip the confirmation prompt
```

```
Deleting sandbox sbxenv-demo...
Sandbox 'sbxenv-demo' removed
Removed secrets scoped to "sbxenv-demo"
```

Global credential **bindings** are left in place by default (they're user-wide and may be shared). Pass `--prune-bindings` to also remove the bindings this environment declared.

---

## The full schema at a glance

Every top-level key you can declare in `.sbxenv.yaml`:

| Key | Purpose |
|---|---|
| `schemaVersion` | **Required.** Currently `"1"`. |
| `agent` | **Required.** Built-in agent (`claude`, `codex`, `gemini`, `shell`, …) or an agent kit name. |
| `name` | Sandbox name and secret scope. Derived when omitted. |
| `kits` | Extra kit references (directory, ZIP, or OCI) composed on top of the agent. |
| `workspace` | Primary read/write mount. A bare path, or `{path, clone}` to run on a private in-container clone. |
| `additionalWorkspaces` | Extra directories to mount, each with an optional `readOnly: true`. |
| `env` | Environment variables set inside the sandbox. |
| `sandboxOptions` | Create-time knobs: `template`, `memory`, `cpus`, `pullPolicy`, `profile`. |
| `secrets` | Secrets provisioned at the sandbox scope (`value` / `ref` / `command`). |
| `registries` | Container-registry pull credentials, injected into the registry token handshake. |
| `mcp.servers` | MCP servers registered and wired into the sandbox's static MCP set. |
| `ports` | Host-port bindings for ports the sandbox exposes. |
| `bindings` | Per-service credential bindings (apiKey/oauth domains) - your consent to injection. |

---

## Why this matters

`sbx env` turns a governed sandbox from a command you remember into an artifact you commit. That single change unlocks the things that make agent governance real at a team scale:

- **Reproducible** - clone the repo, run `sbx env run`, get the identical governed sandbox. No "works on my laptop."
- **Reviewable** - the environment is a file in a pull request. Network policy, mounted directories, and secret sources are visible in code review, not buried in someone's shell history.
- **Layerable** - a committed base plus a gitignored `.sbxenv.local.yaml` gives every developer personal overrides without forking the shared config.

It's the same leap Compose gave containers: from imperative flags to a declarative, versioned, shareable description of the whole environment.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You wrote a `.sbxenv.yaml` with `agent`, `workspace`, `env`, and `sandboxOptions`
- [ ] `sbx env create` stood up the sandbox and `sbx ls` shows it running
- [ ] `sbx env exec` proved the `env:` vars and resource limits match the file
- [ ] A second file merged over the base with `sbx env create base.yaml override.yaml` (later wins)
- [ ] `sbx env rm` removed the sandbox **and** its scoped secrets
- [ ] You understand `.sbxenv.yaml` is the `compose.yaml` of Docker Sandboxes

Next: the governance summary - the full architecture pulled together.
