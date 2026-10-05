# Moving from Local to Cloud Sandboxes

AI coding agents now run for a long time. A single task can take hours: a refactor, a full test run, a migration. You don't want your laptop pinned - fans spinning, battery draining, the lid stuck open - while an agent grinds through a job you could have handed off.

The Docker Agentic Platform fixes that with one move. You develop interactively in a **local** sandbox, then **promote the exact same sandbox to the cloud** with a single command. The isolation model, the agent, the network policy - all identical. Only the hardware changes.

The mantra for this module: **Start on your laptop. Finish in the cloud.**

---

## Prerequisites

- `sbx` CLI **0.45.0 or later**
- A Docker Agentic Platform subscription (new accounts receive complimentary credits)
- An Anthropic API key for the Claude Code agent

Check your version first:

```bash
sbx version
```

If you're below `0.45.0`, upgrade:

```bash
brew install docker/tap/sbx        # macOS
# winget install -h Docker.sbx     # Windows
```

---

## Part 1 - Build and test locally

### Sign in and pick a policy

```bash
sbx login
```

Choose a default network policy when prompted - **Open**, **Balanced**, or **Locked Down**. This same policy follows the sandbox to the cloud.

### Store the agent credential

Keep the API key in `sbx`'s secret store so it's injected through the proxy and never written inside the VM:

```bash
sbx secret set -g anthropic     # paste the key when prompted
sbx secret ls                   # confirm it's stored
```

### Create a local sandbox

```bash
sbx create claude ~/laptop-to-cloud-demo --name laptop-to-cloud-demo
sbx ls
```

`sbx ls` should show `laptop-to-cloud-demo` running locally.

### Run a quick job inside the microVM

Iterate interactively the way you normally would - edit, run, repeat:

```bash
sbx exec laptop-to-cloud-demo bash -lc 'python3 worker.py'
```

---

## Part 2 - Stage the work so it travels

Here's the one thing that trips people up.

!!! warning "Bind mounts don't travel"

    Your mounted workspace (`~/laptop-to-cloud-demo`) is a **host bind mount**. When the sandbox moves to the cloud, that directory stays on your laptop - the cloud VM can't see it.

    Anything the cloud run needs must live on the **image filesystem**, not the bind mount.

Copy the files the cloud job depends on into the image filesystem (under `/home/agent`):

```bash
sbx exec laptop-to-cloud-demo bash -lc 'cp worker.py /home/agent/worker.py'
```

Now the work is self-contained and ready to move.

---

## Part 3 - Move to the cloud

### Understand the cost first

Cloud sandboxes bill per-second by size. Pick the smallest that fits the job:

| Size | vCPUs | Memory | Hourly cost |
|---|---|---|---|
| Micro | 1 | 2 GiB | $0.07 |
| Small (default) | 2 | 4 GiB | $0.14 |
| Medium | 4 | 8 GiB | $0.28 |

### Promote the sandbox

A single command snapshots the local sandbox into a container image and launches a fresh cloud sandbox from it:

```bash
sbx move laptop-to-cloud-demo --to cloud --name laptop-to-cloud-demo --ttl 30m --force
```

- `--to cloud` - the destination.
- `--ttl 30m` - after 30 minutes of inactivity the sandbox **hibernates** rather than being deleted, so you can reconnect.
- `--force` - skip the interactive confirmation.

### Run the long job in the cloud

Now kick off the real work - the full run that you didn't want to tie up your laptop:

```bash
sbx --cloud exec laptop-to-cloud-demo bash -lc 'python3 /home/agent/worker.py --full'
```

The `--cloud` flag targets the cloud fleet. Everything else behaves exactly like the local sandbox.

### Watch the cloud fleet

```bash
sbx --cloud ls
```

### Pull results back

When the job finishes, copy artifacts back to your machine:

```bash
sbx cp laptop-to-cloud-demo:/home/agent/result.txt .
```

---

## Part 4 - Clean up

Billing is per-second, so tear down cloud resources the moment you're done:

```bash
sbx --cloud rm laptop-to-cloud-demo -f
sbx --cloud template rm tmpl_001m3zsqt39yxnwtwr8ksx3qxka --force
```

(Replace the template ID with the one `sbx --cloud ls` / the move output reports.)

---

## Programmatic access - fan-out at scale

The move command is the interactive path. For scale, the **Sandboxes API and SDK** give you programmatic control to:

- Create sandboxes and execute commands
- Transfer files in both directions
- Manage images, snapshots, volumes, and secrets

That unlocks **fan-out** workflows: spin up many sandboxes at once, dispatch an independent task to each, collect the results, and tear everything down automatically - no laptop in the loop at all.

---

## Why the environment stays identical

The reason "start local, finish in the cloud" works without surprises is that the isolation model is the same in both places:

| Layer | What it does | Local | Cloud |
|---|---|---|---|
| **Hypervisor** | Separate Linux kernel per sandbox | ✓ | ✓ |
| **Network proxy** | All traffic routed through a managed proxy; credentials injected per request | ✓ | ✓ |
| **Docker Engine** | Isolated daemon per sandbox | ✓ | ✓ |
| **Credentials** | API keys never enter the VM | ✓ | ✓ |

Same boundary, same policy, same proxy. The only variable you change is where the CPUs live.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] `sbx version` reports `0.45.0` or later
- [ ] A local `laptop-to-cloud-demo` sandbox ran a test job with `sbx exec`
- [ ] You copied the job's files onto the image filesystem (`/home/agent`), not the bind mount
- [ ] `sbx move ... --to cloud` promoted the sandbox and `sbx --cloud ls` shows it
- [ ] `sbx --cloud exec` ran the full job in the cloud
- [ ] `sbx cp` pulled results back and `sbx --cloud rm` cleaned up
- [ ] You understand why bind mounts don't travel and why the isolation model is identical in both places

**Start on your laptop. Finish in the cloud.**
