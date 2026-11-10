# Prerequisites & Setup

Before you can drive the sandbox lifecycle, you need to be on the **sandbox-based** version of Docker Offload and have a working `docker-cloud` context.

---

## Prerequisites

- **Docker Desktop 4.97 or later.** The persistent-sandbox lifecycle (`docker offload create` / `stop` / `rm`) landed in this release.
- A **Docker Agentic Platform** subscription (new accounts include complimentary credits).
- An active Docker login - run `docker login` if you're not signed in.
- **Unrestricted internet connectivity** to Docker Cloud (corporate proxies/firewalls can block the encrypted tunnel).

!!! warning "Disable the old 'Enable Docker Offload' toggle"
    The current sandbox-based Offload is **not** the legacy v1 feature. In **Docker Desktop → Settings**, make sure the old **"Enable Docker Offload"** beta toggle is **off**. If it's on, you're on v1 and the `docker offload create` lifecycle commands won't behave as described here.

---

## Confirm the CLI

```bash
docker offload --help
```

You should see the lifecycle subcommands:

```text
Usage:  docker offload COMMAND

Commands:
  create     Create (or connect to) a cloud sandbox
  status     Show the status of the cloud sandbox
  stop       Pause the cloud sandbox
  rm         Delete the cloud sandbox
  ...
```

---

## Create your sandbox for the workshop

Create a sandbox with sensible defaults. This also switches your active Docker context to `docker-cloud`:

```bash
docker offload create
```

Verify the context switched:

```bash
docker context ls
```

```text
NAME             DESCRIPTION                               DOCKER ENDPOINT
default          Current DOCKER_HOST based configuration   unix:///var/run/docker.sock
desktop-linux    Docker Desktop                            unix:///...docker.sock
docker-cloud *   docker cloud context                      unix:///...docker-cloud.sock
```

The `*` on `docker-cloud` means subsequent `docker` commands run **in the cloud sandbox**.

Confirm you're really on cloud hardware:

```bash
docker info | grep -E "(Server Version|Operating System)"
```

```text
 Server Version: 28.0.2
 Operating System: Ubuntu 22.04.5 LTS
```

---

## ✅ Checkpoint

- [ ] Docker Desktop is **4.97+** and the legacy Offload toggle is **off**
- [ ] `docker offload --help` lists `create`, `status`, `stop`, `rm`
- [ ] `docker offload create` succeeded and `docker-cloud` is the active context
- [ ] `docker info` reports a cloud server (Ubuntu), not your local OS

Next: [Creating & Sizing a Sandbox](create-and-size.md).

> **Sources:** [Docker Offload quickstart](https://docs.docker.com/offload/quickstart/) and [Lifecycle, Idle Timeout & TTL](https://collabnix.com/docker-offload-cloud-sandboxes-lifecycle-idle-timeout-ttl/).
