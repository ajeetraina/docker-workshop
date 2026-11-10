# Your First Cloud Sandbox

Time to run an agent on Docker's infrastructure. In this module you'll start a cloud sandbox, talk to the agent, detach while it keeps working, and reconnect.

**Prerequisite:** You've completed [Getting Started](getting-started.md) - `sbx --cloud diagnose` passes and your Anthropic key is stored with `sbx --cloud secret set anthropic`.

---

## Step 1 - Run an agent in the cloud

`run` creates a sandbox *and* attaches you to the agent in one step. If a sandbox with the given `--name` already exists, `run` reuses it.

```bash
sbx --cloud run claude --name cloud-project
```

You're now in an interactive Claude Code session - except the microVM is in Docker's cloud, not on your laptop. Ask it to do something small to confirm it's alive, e.g. *"create a file hello.txt containing the current date."*

### Useful variations

```bash
# Always start fresh, even if the name exists
sbx --cloud run claude --name cloud-project --new

# Create without opening an agent session
sbx --cloud create --name cloud-project claude

# Run detached (for scripts / CI) - returns immediately
sbx --cloud run --detach claude --name cloud-task

# Throwaway: auto-remove the sandbox when the agent exits
sbx --cloud run --rm claude
```

---

## Step 2 - Detach without killing the agent

The whole point of the cloud is that work survives your laptop. Press:

```
Ctrl+\
```

This **detaches** from the interactive session and leaves the agent running in the cloud. Close your laptop, get coffee, come back later - the sandbox is still there.

Prefer a different gesture? Set it when you start:

```bash
sbx --cloud run --detach-keys ctrl-x,ctrl-d claude --name cloud-project
```

---

## Step 3 - See it in the fleet

```bash
sbx --cloud ls
```

`cloud-project` should be listed as running. Inspect it for details - status, size, ports, TTL:

```bash
sbx --cloud inspect cloud-project
```

---

## Step 4 - Reconnect

Jump back into the agent session any time:

```bash
sbx --cloud attach cloud-project
```

If the sandbox had stopped (e.g. it hit its TTL), `attach` resumes it. `run` with the same name does the same thing.

---

## Step 5 - Run a one-off command

You don't always need an interactive session. `exec` runs a single command inside the sandbox and returns:

```bash
sbx --cloud exec cloud-project pwd
sbx --cloud exec cloud-project cat hello.txt
```

---

## Step 6 - Clean up

Billing is for running compute, so tear it down when you're done:

```bash
sbx --cloud rm cloud-project          # prompts for confirmation
sbx --cloud rm cloud-project --force  # skip the prompt
```

---

## ✅ Checkpoint

- [ ] `sbx --cloud run claude --name cloud-project` opened an agent session in the cloud
- [ ] You detached with `Ctrl+\` and the sandbox stayed running in `sbx --cloud ls`
- [ ] `sbx --cloud attach cloud-project` reconnected you
- [ ] `sbx --cloud exec` ran a one-off command
- [ ] `sbx --cloud rm` cleaned up

Next: [Lifecycle & Expiration](lifecycle.md).

> **Source:** [Use cloud sandboxes](https://docs.docker.com/ai/sandboxes/cloud/usage/).
