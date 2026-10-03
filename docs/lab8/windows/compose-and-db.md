# Docker Compose & the Shared DB

In this module you run your own Docker Compose stack inside your sandbox's isolated Linux microVM, then connect it to the team's shared PostgreSQL database running on an on-prem Linux server. On Windows 11 with no WSL2, every developer gets a private Docker daemon per sandbox, so your stack never collides with anyone else's.

---

## Compose Runs Fully Inside the Sandbox

Each sandbox ships with its own private Docker daemon. You, and any agent working in the sandbox, can build images, run containers, and drive multi-service stacks with Compose exactly as you would on a normal Linux box. The difference is isolation: containers you start inside the sandbox never show up in the host's `docker ps`.

That isolation has real consequences for a shared team:

| Concern | Behavior inside a sandbox |
| --- | --- |
| Ports | Private to the sandbox — two developers can both bind `3000` with no conflict |
| Image names | Private namespace — no collisions on tags like `app:dev` |
| Volumes | Private per sandbox — named volumes never leak between developers |
| Persistence | Images, containers, and volumes survive `sbx stop` / `sbx start` |
| Removal | Everything is deleted only when you run `sbx rm` |
| Build cache | Per sandbox — the first build in a brand-new sandbox is cold |

```bash
# Inside your sandbox, Compose behaves normally
docker compose up -d
docker compose ps
docker compose logs -f app
```

!!! note "Cold first build"
    A fresh sandbox has an empty build cache. Expect the first `docker compose build` to pull base images and compile from scratch. Later builds in the same sandbox reuse the cache and are fast.

---

## Give Docker Enough Disk

All Docker data — images, containers, volumes, and build cache — lives in the sandbox's Docker volume, which defaults to **10 GB**. Multi-service stacks with database images, language runtimes, and layered builds fill that quickly.

```bash
# One-off: create a sandbox with a 30 GB Docker volume
DOCKER_SANDBOXES_DOCKER_SIZE=30g sbx create opencode ~/my-project

# Persistent default for every new sandbox
sbx settings set sandbox.disk.dockerVolume 30g
```

!!! tip "Size it before you build"
    Growing the Docker volume is easiest at creation time. Set a sensible persistent default so your whole team avoids "no space left on device" halfway through a build.

---

## Reaching Services From Windows

By default, services running in your sandbox are **not** reachable from the Windows host. To open an app in your browser you must publish the port, and the service inside the container must listen on `0.0.0.0` — binding only to `127.0.0.1` makes it invisible to the forwarder.

```bash
# Publish at creation time
sbx run --publish 8080:3000 opencode ~/my-project

# Publish on an existing sandbox
sbx ports my-sandbox --publish 8080:3000

# List current published ports
sbx ports my-sandbox

# Stop publishing a port
sbx ports my-sandbox --unpublish 8080:3000
```

Once published, open `http://localhost:8080` in your Windows browser.

!!! warning "`sbx run --publish` is ignored when reattaching"
    `--publish` only takes effect when `sbx run` creates a sandbox. If the sandbox already exists, `sbx run` reattaches and silently drops the flag. For an existing sandbox, always use `sbx ports`.

---

## Reaching the Shared Database

This is the one connection in the whole design that crosses a boundary, so get it right early.

The shared PostgreSQL instance runs on an **on-prem Linux server**, not on your laptop and not in any sandbox. That single fact determines how you connect.

!!! warning "Do not use `host.docker.internal` for the shared DB"
    Inside a laptop sandbox, `host.docker.internal` resolves to **your laptop**, not the database server. Pointing your app there will fail or hit the wrong machine. Use the server's hostname or IP and port instead.

Outbound TCP from containers inside the sandbox egresses through the sandbox proxy, so you must allow the server's address in the network policy before anything can connect:

```bash
# Allow outbound to the shared DB server
sbx policy allow network 10.0.0.5:5432
```

Then point your Compose app at the server directly — by IP or by a DNS name the sandbox proxy can resolve:

```yaml
services:
  app:
    build: .
    environment:
      DATABASE_URL: postgres://alice:${DB_PASSWORD}@10.0.0.5:5432/alice_app
    ports:
      - "3000:3000"
```

Test this path first — before wiring up the rest of your stack. If the allow rule is missing, the connection is refused at the proxy, not inside the container. For deeper policy control, see [Networking & Policy](networking.md).

---

## The Shared-DB Compose File (Ops-Managed)

The database itself is **not** run in a sandbox. Operations runs it on the server's host Docker Engine. For reference, here is the stack they manage:

```yaml
services:
  postgres:
    image: postgres:16
    container_name: shared-postgres
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - shared_pgdata:/var/lib/postgresql/data
    command:
      - postgres
      - -c
      - max_connections=200
    deploy:
      resources:
        limits:
          cpus: "4"
          memory: 8g
volumes:
  shared_pgdata:
```

```bash
# On the server (not in a sandbox)
POSTGRES_PASSWORD=<strong-secret> docker compose -f shared-db.compose.yaml up -d
```

---

## Local Model Servers Are a Different Case

If a developer runs a model server such as Ollama **on their own laptop**, that laptop *is* the sandbox host — so here `host.docker.internal` is exactly right.

```bash
sbx policy allow network localhost:11434
# Then from inside the sandbox: http://host.docker.internal:11434
```

Contrast that with the shared DB: the model server is local to the host, so `host.docker.internal` works; the database lives on a remote server, so it does not.

---

## Recommended Compose Pattern

The host-mounted workspace uses a filesystem-passthrough path that is slower than native. Keep that path limited to the files you actually edit.

- Put heavy or generated directories — `node_modules`, `.venv`, build output — in **named Docker volumes** or inside the sandbox filesystem, never on the host-mounted workspace.
- Bind-mount **only the source tree** for live editing.

```yaml
services:
  app:
    build: .
    volumes:
      - ./src:/app/src          # source for live editing
      - node_modules:/app/node_modules   # heavy dir in a named volume
volumes:
  node_modules:
```

---

## Database Tenancy: One Role Per Developer

Treat the shared database like production. Give each developer their own database and role, cap their resources, and keep the superuser out of application configs.

- One database plus one login role per developer — no shared superuser.
- Connection limits per role and resource caps on the server.
- Per-developer credentials delivered with `sbx secret set` so the value never lands in a sandbox's filesystem.

```sql
CREATE ROLE alice LOGIN PASSWORD 'alice-strong-password' CONNECTION LIMIT 20;
CREATE DATABASE alice_app OWNER alice;
```

```bash
# Deliver the credential without writing it to disk in the sandbox
sbx secret set DB_PASSWORD
```

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You understand that Compose runs against a private per-sandbox Docker daemon and containers never appear in the host's `docker ps`.
- [ ] You have sized the sandbox Docker volume above the 10 GB default for multi-service stacks.
- [ ] You can publish a port with `sbx ports` and reach the app at `http://localhost:8080` on Windows.
- [ ] You allowed the shared DB with `sbx policy allow network 10.0.0.5:5432` and connect by server IP/hostname, not `host.docker.internal`.
- [ ] You tested the cross-boundary DB connection first, before building out the rest of the stack.
- [ ] Heavy/generated directories live in named volumes; only the source tree is bind-mounted.
- [ ] Each developer has a dedicated role and database with a connection limit, and credentials come from `sbx secret set`.

Next: [Networking & Policy](networking.md).
