# Multi-Machine & Hybrid Workflows

Because there's **one sandbox per account**, any machine that logs in and runs `docker offload create` connects to the *same* environment. This module covers working across machines and mixing cloud + local Docker in one workflow.

**Prerequisite:** [Stop, Resume & Delete](stop-resume-delete.md).

---

## Connecting a second machine

Run this on a different laptop (same Docker account):

```bash
docker offload create
```

It does **not** create a new sandbox - it connects to your existing one. Both machines:

- report the **same** account ID and sandbox ID, but
- keep **separate** session tracking and idle-detection state.

So a build you kick off on machine A is visible from machine B, and both sessions independently keep the sandbox awake while they're active.

!!! warning "`stop` and `rm` hit everyone"
    Since the sandbox is shared, `docker offload stop` or `docker offload rm` from **any** machine pauses or deletes it for **all** connected machines. Coordinate before tearing down a shared sandbox.

---

## Switching between cloud and local

While `docker-cloud` is the active context, `docker` talks to the sandbox. To run something **locally** without switching your default context, target `desktop-linux` per command:

```bash
docker --context desktop-linux ps -a
docker --context desktop-linux compose up
```

!!! info "Containers and images don't cross the boundary"
    While the `docker-cloud` context is active, `docker ps -a` shows **only cloud** containers. Images you built locally don't exist in the sandbox, and images built in the sandbox don't appear locally. Use a registry (`docker push` / `docker pull`) to move images between them.

---

## The global `--cloud` flag

You can offload a single command without switching contexts at all - but **the flag must come *before* the subcommand**:

```bash
docker --cloud build .      # ✅ runs this build in the cloud
docker build --cloud .      # ❌ "unknown flag: --cloud"
```

This is handy for keeping `desktop-linux` as your default while occasionally pushing a heavy build to the cloud.

---

## Compose: `stop` vs. `down`

The usual Compose semantics apply inside the sandbox - mind the difference:

| Command | Effect in the sandbox |
|---|---|
| `docker compose stop` | Stops containers but **preserves** them and their data |
| `docker compose down` | **Removes** containers (and networks) |

These are *Compose-level* operations on your services - distinct from `docker offload stop`, which pauses the **entire sandbox**.

---

## ✅ Checkpoint

- [ ] Connected a second machine and saw it join the **same** sandbox
- [ ] Ran a local command with `docker --context desktop-linux …` while cloud was active
- [ ] Offloaded one command with `docker --cloud build .` (flag **before** the subcommand)
- [ ] Understand images/containers don't cross the cloud/local boundary without a registry

Next: [Troubleshooting & Cost Control](troubleshooting.md).

> **Sources:** [Docker Offload usage](https://docs.docker.com/offload/usage/) and [Lifecycle, Idle Timeout & TTL](https://collabnix.com/docker-offload-cloud-sandboxes-lifecycle-idle-timeout-ttl/).
