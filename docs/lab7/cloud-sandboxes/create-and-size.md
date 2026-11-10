# Creating & Sizing a Sandbox

`docker offload create` is the single entry point to the sandbox. It **creates** one if none exists, or **connects** you to the existing one. This module covers sizing it correctly and inspecting its state.

**Prerequisite:** [Prerequisites & Setup](getting-started.md).

---

## Create with a size

Pick the smallest size that fits the job - you pay for running compute.

```bash
docker offload create --cpus 8 --memory 16g --ttl 4h
```

| Flag | Meaning | Values |
|---|---|---|
| `--cpus` | vCPUs for the sandbox | `1`, `2`, `4`, `8`, or `16` |
| `--memory` | RAM | size notation, e.g. `16g` |
| `--ttl` | Lifetime while **disconnected** | duration, **max 24h** (e.g. `4h`) |
| `--timeout` | How long to wait for provisioning | default `15m0s` |

!!! info "Sizing flags apply only at creation"
    `--cpus` and `--memory` are honored when the sandbox is **first created**. Running `create` again with new sizes on an existing sandbox has **no effect** unless you also pass `--recreate`.

---

## Inspect the sandbox

```bash
docker offload status
```

The output shows the sandbox ID and state (running/paused), creation timestamp, connection state, session age, the idle settings, and either a **time-until-idle** countdown or the reasons it's being kept awake.

!!! warning "`status` never wakes a paused sandbox"
    `docker offload status` is a *query*. It will report `paused` without resuming the sandbox. The same is true of `docker ps` and `docker images` - read-only commands never trigger a resume. Only **operational** commands do (covered in [Stop, Resume & Delete](stop-resume-delete.md)).

---

## Resizing an existing sandbox

Because sizing is fixed at creation, resizing means **recreating**:

```bash
docker offload create --cpus 16 --memory 32g --recreate
```

!!! danger "`--recreate` deletes everything"
    `--recreate` tears down the current sandbox - **all containers, images, and volumes are lost** - and provisions a fresh one at the new size. **Push any valuable images to a registry first**, and recreate volumes from backups as needed.

A safe resize workflow:

```bash
# 1. Save what you need out of the current sandbox
docker push myorg/myapp:cloud-wip

# 2. Recreate at the new size
docker offload create --cpus 16 --memory 32g --recreate

# 3. Pull back what you saved
docker pull myorg/myapp:cloud-wip
```

---

## ✅ Checkpoint

- [ ] Created a sandbox with explicit `--cpus` and `--memory`
- [ ] Read its state with `docker offload status` (and noticed it didn't wake a paused one)
- [ ] Understand that resizing requires `--recreate` and **destroys data**
- [ ] Backed up images to a registry before any `--recreate`

Next: [Idle Timeout & Keep-Alive](idle-timeout.md).

> **Sources:** [Manage Docker Offload sandboxes](https://docs.docker.com/offload/usage/) and [Lifecycle, Idle Timeout & TTL](https://collabnix.com/docker-offload-cloud-sandboxes-lifecycle-idle-timeout-ttl/).
