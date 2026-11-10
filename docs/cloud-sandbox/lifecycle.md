# Lifecycle & Expiration

Cloud compute costs money while it runs, so controlling *size* and *how long a sandbox lives* is the difference between a few cents and a surprise bill. This module covers sizing, inspection, TTL, stop/resume, and deletion.

**Prerequisite:** [Your First Cloud Sandbox](first-cloud-sandbox.md).

---

## Sizing a sandbox

Pick the smallest size that fits the job. Set it at creation with `--cpus` and `--memory`:

```bash
sbx --cloud create --name cloud-project --cpus 4 --memory 8g claude
```

The platform offers these sizes:

| Size | vCPUs | Memory |
|---|---|---|
| micro | 1 | 2 GB |
| small *(default)* | 2 | 4 GB |
| medium | 4 | 8 GB |
| large | 8 | 16 GB |
| xl | 16 | 32 GB |

Need a specific architecture?

```bash
sbx --cloud create --name cloud-project --platform linux/amd64 claude
```

---

## Inspecting a sandbox

```bash
sbx --cloud ls                       # fleet overview
sbx --cloud inspect cloud-project    # full detail
```

Machine-readable output composes nicely with `jq` - for example, pull a published port URL:

```bash
sbx --cloud inspect cloud-project --format json | jq -r '.ports[]? | .url // empty'
```

---

## Expiration (TTL)

A cloud sandbox **expires after one hour by default**. On expiration, the service **stops** sandboxes that can be resumed and **deletes** the rest.

Control this per-sandbox at creation:

```bash
sbx --cloud create --name cloud-project --ttl 2h --on-timeout delete claude
```

- `--ttl 2h` - lifetime before the timeout action fires.
- `--on-timeout` - what happens then. Valid actions: `stop`, `restart`, `delete`.

Check and extend TTL on a live sandbox:

```bash
sbx --cloud ttl cloud-project        # how long is left
sbx --cloud ttl +30m cloud-project   # add 30 minutes
```

!!! warning "Choose `--on-timeout` deliberately"
    The default behavior stops resumable sandboxes and deletes the rest. If a job must survive a timeout, create it with `--on-timeout stop` (resumable). If you never want leftovers, `--on-timeout delete`.

---

## Stop and resume

Stop halts a sandbox but keeps it resumable - you stop paying for active compute while preserving state:

```bash
sbx --cloud stop cloud-project
```

Resume by attaching (or by `run` with the same name):

```bash
sbx --cloud attach cloud-project
# or
sbx --cloud run claude --name cloud-project
```

---

## Persistent volumes

A volume outlives the sandbox - useful for a dependency cache shared across runs:

```bash
sbx --cloud volume create dependency-cache

sbx --cloud create --name cloud-project \
    --volume dependency-cache:/workspace/cache claude

# fix ownership if the agent user needs write access
sbx --cloud exec cloud-project sudo chown agent:agent /workspace/cache
```

---

## Deleting

```bash
sbx --cloud rm cloud-project          # confirmation prompt
sbx --cloud rm cloud-project --force  # skip the prompt
```

---

## ✅ Checkpoint

- [ ] Created a sandbox with an explicit size (`--cpus` / `--memory`)
- [ ] Read its details with `sbx --cloud inspect`
- [ ] Set and extended a TTL with `--ttl` and `sbx --cloud ttl +30m`
- [ ] Stopped and resumed a sandbox
- [ ] Deleted the sandbox with `sbx --cloud rm`

Next: [Files, Ports & SSH](files-ports-ssh.md).

> **Source:** [Use cloud sandboxes](https://docs.docker.com/ai/sandboxes/cloud/usage/).
