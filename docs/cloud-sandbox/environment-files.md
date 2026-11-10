# Environment Files

Typing `--cpus`, `--memory`, `--ttl`, and a pile of flags every time is fine for one-off runs. For a sandbox you want to **reproduce or share with teammates**, describe it once in an environment file and run that.

An environment file is a `.sbxenv.yaml` describing the agent, tools, env vars, and resource limits for a sandbox. The cloud variant has a few rules of its own.

**Prerequisite:** [Files, Ports & SSH](files-ports-ssh.md).

---

## What goes in a cloud environment file

Because a cloud sandbox has no host workspace and its own secret store, a cloud `.sbxenv.yaml` **omits** the fields that only make sense locally.

```yaml
schemaVersion: "1"
name: cloud-web-app
agent: claude

env:
  NODE_ENV: test

sandboxOptions:
  cpus: 2
  memory: 4g
```

**Supported fields**

- `agent` - which agent to run (e.g. `claude`)
- `env` - environment variables injected into the sandbox
- `sandboxOptions` - `cpus`, `memory`, and other resource limits
- `kits` - project tools to install
- credentials for supported providers
- `lifecycle` commands (`postCreate`, `preRemove`)

**Remove these local-only fields for cloud** - they're unsupported and will be rejected:

`workspace`, `additionalWorkspaces`, clone options, `ports`, `registries`, `mcp.servers`, `template`, `profile`, `gpu`, `usb`, `skills`, `display`.

Since there's no `workspace`, you copy the project in (or clone it) and retrieve results before deleting the sandbox - same as every other cloud exercise.

---

## Set credentials first

```bash
sbx --cloud secret set anthropic
sbx --cloud secret set github --sandbox cloud-web-app
```

---

## The workflow

```bash
# 1. Preview what the file will create - no resources spent
sbx --cloud env plan ./cloud.sbxenv.yaml

# 2. Create the sandbox from the file
sbx --cloud env create --ttl 2h --on-timeout delete ./cloud.sbxenv.yaml

# 3. Upload your project (no host workspace, remember)
sbx --cloud cp . cloud-web-app:/home/agent/workspace/web-app

# 4. Attach to the agent (Ctrl+\ to detach, agent keeps running)
sbx --cloud env run ./cloud.sbxenv.yaml

# 5. Or run a one-off command without attaching
sbx --cloud env exec ./cloud.sbxenv.yaml -- \
    git -C /home/agent/workspace/web-app diff --stat

# 6. Retrieve results
sbx --cloud cp cloud-web-app:/home/agent/workspace/web-app ../web-app-result

# 7. Clean up
sbx --cloud env rm ./cloud.sbxenv.yaml
```

---

## Automate the upload with `postCreate`

Add a lifecycle command so the project is uploaded automatically whenever the sandbox is created - then `env run` creates, uploads, and attaches in a single step:

```yaml
lifecycle:
  postCreate:
    - name: Upload project
      command: sbx --cloud cp . "$SBX_SANDBOX_NAME:/home/agent/workspace/web-app"
```

```bash
sbx --cloud env run ./cloud.sbxenv.yaml   # create + upload + attach
```

`$SBX_SANDBOX_NAME` is provided to lifecycle commands so the file stays portable.

---

## ✅ Checkpoint

- [ ] Wrote a `cloud.sbxenv.yaml` with `schemaVersion: "1"`, an `agent`, and `sandboxOptions`
- [ ] Removed local-only fields (`workspace`, `ports`, `mcp.servers`, …)
- [ ] Previewed with `sbx --cloud env plan`
- [ ] Created and attached with `sbx --cloud env create` / `env run`
- [ ] Added a `postCreate` command to auto-upload the project
- [ ] Cleaned up with `sbx --cloud env rm`

> **Source:** [Use environment files in the cloud](https://docs.docker.com/ai/sandboxes/cloud/environment-files/).
