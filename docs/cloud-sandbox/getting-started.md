# Getting Started with Cloud Sandboxes

This module gets you from "installed `sbx`" to "cloud access confirmed." Three steps: check the version, store a credential, and verify connectivity with `diagnose`.

---

## Prerequisites

- **`sbx` CLI 0.45.0 or later** - cloud support landed in 0.45.0.
- **An active Docker Agentic Platform subscription** with cloud access activated. New accounts receive complimentary credits.
- **An agent credential** - this lab uses Claude Code, which needs an Anthropic API key.

Check your version:

```bash
sbx version
```

If you're below `0.45.0`, upgrade:

```bash
brew install docker/tap/sbx        # macOS
# winget install -h Docker.sbx     # Windows
```

---

## Step 1 - Sign in

```bash
sbx login
```

This authenticates the CLI against your Docker account. The same login covers both local and cloud sandboxes - there is no separate "cloud login."

---

## Step 2 - Store the agent credential (in the cloud)

Cloud sandboxes keep their own secret store, separate from your local one. Set the credential with the `--cloud` flag so it lives server-side and is injected through the proxy - the raw key never lands inside the VM:

```bash
sbx --cloud secret set anthropic     # paste the key when prompted
```

You can scope a secret to a single sandbox instead of your whole cloud account:

```bash
sbx --cloud secret set github --sandbox cloud-project
```

!!! note "Local and cloud secrets are separate"
    A secret you set locally with `sbx secret set` is **not** visible to cloud sandboxes. Set cloud credentials explicitly with `sbx --cloud secret set`.

---

## Step 3 - Verify cloud access

Before spending any compute, confirm the CLI can reach the Cloud Sandboxes API and that your subscription has cloud access:

```bash
sbx --cloud diagnose
```

This checks authentication, cloud entitlement, and connectivity. Fix anything it flags before moving on - a failed `diagnose` is why most "it won't start" problems happen.

List your cloud fleet (it will be empty on a fresh account):

```bash
sbx --cloud ls
```

---

## The `--cloud` flag, once and for all

Every command in this lab is an ordinary `sbx` command with `--cloud` added:

```bash
sbx ls                 # local sandboxes
sbx --cloud ls         # cloud sandboxes

sbx run claude         # run an agent locally
sbx --cloud run claude # run the same agent in the cloud
```

`--cloud` is a **global** flag: it goes right after `sbx`, before the subcommand.

---

## ✅ Checkpoint

- [ ] `sbx version` reports `0.45.0` or later
- [ ] `sbx login` succeeded
- [ ] `sbx --cloud secret set anthropic` stored your key server-side
- [ ] `sbx --cloud diagnose` passes all checks
- [ ] `sbx --cloud ls` runs (empty list is expected)

Next: [Your First Cloud Sandbox](first-cloud-sandbox.md).

> **Sources:** [Cloud sandboxes](https://docs.docker.com/ai/sandboxes/cloud/) and [Use cloud sandboxes](https://docs.docker.com/ai/sandboxes/cloud/usage/).
