# Workspaces & Naming

A **workspace** is a host directory that is shared into your sandbox. Through a filesystem passthrough, the host path appears *inside* the Linux microVM at the same absolute path. There is no copy step and no background sync: an edit the agent makes inside the sandbox is instantly visible on your Windows machine, and a change you make in your editor is instantly visible to the agent.

This page shows how to attach workspaces, how to mount more than one, how clone mode isolates your working tree, and how `sbx` decides which sandbox you are talking to.

---

## Attaching a workspace

The simplest attachment is the directory you are standing in. The current folder becomes the **primary** workspace, mounted read-write, and the agent starts there.

```bash
# Current directory becomes the primary read-write workspace
sbx run opencode

# Attach an explicit path instead
sbx run opencode ~/my-project

# A mountless sandbox: no host workspace at all (scratch space inside the VM)
sbx create --name scratch opencode
```

!!! note "run vs create"
    `sbx run` builds the sandbox (if needed) and attaches you to the agent. `sbx create` only builds the sandbox — it prepares the environment without starting the agent session. Reach for `create` when you want to provision ahead of time, then `run` later.

A mountless sandbox is handy for throwaway experiments: the agent can scaffold, install, and test entirely on the VM's own disk without touching any host folder.

---

## Multiple workspaces

You can hand the agent several directories at once. The **first** path is always the primary (where the agent starts); any additional paths are also mounted and reachable at their absolute path. Append `:ro` to mount a directory read-only.

```bash
sbx run opencode ~/project-a ~/shared-libs:ro ~/docs:ro
```

Here the agent works in `~/project-a`, can read your shared libraries and docs, but cannot modify them.

The same intent is clearer in an environment file:

```yaml
workspace: ./web-app
additionalWorkspaces:
  - path: ./shared-components              # read-write
  - path: ./architecture-docs
    readOnly: true
```

!!! tip "When to add extra workspaces"
    Use `additionalWorkspaces` for related repositories, shared libraries, or reference documentation the agent must consult while it works. Mark anything the agent should not change as read-only — it narrows the blast radius and makes intent explicit.

---

## Clone mode

Clone mode keeps the agent out of your working tree entirely.

```bash
sbx run --clone opencode ~/my-project
```

With `--clone`, your host repository is mounted **read-only** at `/run/sandbox/source`. The agent then works inside a private, in-VM clone of that repo. Your host working tree is never touched; the agent's commits and edits live only in the sandbox until you explicitly fetch or push them out.

| Aspect | Normal mount | Clone mode |
| --- | --- | --- |
| Host working tree | Edited live by the agent | Left untouched |
| Where the agent writes | Directly in your folder | A private in-VM clone |
| Getting changes out | Already on the host | Fetch or push from the sandbox |
| Requirement | Any directory | Primary workspace must be a Git repo |

!!! warning "Clone mode is fixed at creation"
    You choose clone mode when the sandbox is created; you cannot flip an existing sandbox into or out of it. It also requires the primary workspace to be a Git repository.

Use clone mode when you want to run several agents against one repository in parallel, or whenever you simply don't want an agent editing your working tree directly.

---

## How sandboxes are identified: folder vs name

A sandbox has an identity so that `sbx` knows whether to create a new one or reconnect you to an existing one.

- **Named sandboxes.** Passing `--name` gives the sandbox an explicit identity. You can reattach from anywhere, regardless of your current directory:

    ```bash
    sbx run --name my-sandbox
    ```

- **Unnamed sandboxes.** Without a name, the **workspace path becomes the key**. Running `sbx run` against the same workspace path again reconnects you to the existing sandbox rather than creating a new one.

- **Several sandboxes on one folder.** If you want more than one sandbox over the same directory, give each a distinct name:

    ```bash
    sbx run opencode --name feature ~/my-project
    sbx run opencode --name spike   ~/my-project
    ```

- **Environment files.** The name defaults to `<agent>-<workspace-basename>`. Override it with the `name:` field in the file or with `--name` on the command line.

!!! note "The rule in one line"
    A sandbox is not rigidly tied to a folder. But if you don't name it, its identity is derived from the mounted workspace path.

---

## Best practices

- **Mount source, not build output.** Keep heavy-I/O generated directories — `node_modules`, `.venv`, `target/`, `dist/` — *off* the bind mount and on the sandbox's own disk (via a mountless sandbox or named Docker volumes). This is the single biggest performance win. See [Performance](performance.md).
- **Never mount network shares.** SMB, NFS, or cloud-synced folders (OneDrive, Dropbox) make a terrible workspace: every file operation crosses the network, and agent performance collapses. Keep workspaces on local disk.
- **Keep the environment file outside mounted workspaces.** The file is mounted read-only, but if it sits inside a writable mount the agent could still alter it. Store it alongside, not within.
- **One sandbox per project** for a clean, predictable environment. Reach for `--name` only when you genuinely need parallel sandboxes over the same repository.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You can attach the current directory, an explicit path, and create a mountless sandbox.
- [ ] You understand the primary workspace vs `additionalWorkspaces`, and how `:ro` / `readOnly: true` work.
- [ ] You know what `--clone` does and that it is fixed at creation and needs a Git repo.
- [ ] You can explain how an unnamed sandbox is keyed by its workspace path, and how `--name` overrides that.
- [ ] You keep build output and network shares off the bind mount, and the environment file outside writable workspaces.

Next: [Environments, Kits & Templates](environments.md).
