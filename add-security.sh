#!/usr/bin/env bash
#
# apply-security-update.sh
#
# Adds the Container Security, Docker Scout (Reactive), and DHI (Pro-active)
# sections to the docker-workshop site (https://dockerworkshop.vercel.app).
#
# Usage:
#   1. cd into the root of your docker-workshop repo (where mkdocs.yml lives)
#   2. ./apply-security-update.sh
#   3. git add docs/security mkdocs.yml && git commit -m "Add container security workshop sections" && git push
#
# Safe to run multiple times — it overwrites the target files.

set -euo pipefail

# Sanity check: must be at the repo root
if [ ! -f "mkdocs.yml" ]; then
  echo "Error: mkdocs.yml not found in the current directory." >&2
  echo "Run this script from the root of the docker-workshop repo." >&2
  exit 1
fi

# Back up the existing mkdocs.yml
cp mkdocs.yml mkdocs.yml.bak
echo "Backed up existing mkdocs.yml to mkdocs.yml.bak"

# Create directories
mkdir -p docs/security/container-security
mkdir -p docs/security/scout-reactive
mkdir -p docs/security/dhi-proactive

echo "Writing files..."


echo "  -> docs/security/container-security/overview.md"
cat > 'docs/security/container-security/overview.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Container Security

Welcome to **Creating a More Secure Production with Containers** — a hands-on workshop covering **8 container security best practices** plus a full **Docker Hardened Images (DHI) migration**, using the `catalog-service-node` app as the running example.

This workshop is split into two complementary tracks:

| Track | Approach | What it covers |
|-------|----------|----------------|
| **Docker Scout** | 🔄 **Reactive** — Scan and Fix | Surface CVEs in existing images, gate them in CI, fix them as they appear |
| **Docker Hardened Images** | 🛡️ **Pro-active** — Start Secure | Build on minimal, distroless, attested images with near-zero CVEs from day one |

Both approaches matter. Scout helps you understand and remediate what you already run; DHI helps you stop creating the problem in the first place.

---

## The four attack vectors that keep production teams up at night

1. **Image vulnerabilities** — known CVEs in OS packages and language dependencies
2. **Supply chain integrity** — compromised dependencies, post-install scripts, untrusted base images
3. **Runtime attack surface** — shells, package managers, dev tools, and OS utilities that aid attackers
4. **Compliance** — FIPS, STIG, license obligations, audit-ready provenance

The 8 best practices below directly address vectors 1, 3, and 4. Scout addresses vector 1 reactively. DHI addresses all four pro-actively.

---

## The 8 Container Security Best Practices

| # | Best Practice | What it addresses |
|---|---------------|-------------------|
| 1 | [Start with minimal base images](minimal-base-images.md) | Less OS surface = fewer CVEs |
| 2 | [Use multi-stage builds](multi-stage-builds.md) | Keep dev tools out of production |
| 3 | [Run as non-root user](non-root-user.md) | Limit blast radius of code execution |
| 4 | [Read-only filesystem + drop capabilities](readonly-capabilities.md) | Stop attackers from writing payloads |
| 5 | [Scan continuously, not just at build](../scout-reactive/continuous-scanning.md) | Catch new CVEs as they emerge |
| 6 | [Manage secrets properly](secrets-and-tools.md) | Never bake credentials into images |
| 7 | [No dev tools in production](secrets-and-tools.md) | Smaller attack surface |
| 8 | [No OS tools in production](secrets-and-tools.md) | No `curl`, no `wget`, no payload delivery |

---

## Key numbers from the field

| Image | Critical CVEs | High CVEs | Packages | Size |
|-------|---------------|-----------|----------|------|
| `node:18` (where most teams start) | 2 | 26 | 693 | 1.62 GB |
| `node:25-slim` (BP#1 applied) | 0 | 2 | 272 | 368 MB |
| `dhi.io/node:24-debian13` (DHI) | 0 | 0 | ~12 | ~50 MB |

> **One `FROM` line change** from `node:18` to `node:25-slim` eliminates **2 critical and 25 high** CVEs immediately. Migrating to DHI eliminates **all of them**, removes 595 packages, and shrinks the image 10x.

---

## The sample application

Throughout this workshop we use [`catalog-service-node`](https://github.com/dockersamples/catalog-service-node) — a real-world Node.js service with PostgreSQL, Kafka, and S3 dependencies. It ships with a setup script that deliberately introduces a vulnerable state (old base image, downgraded dependencies) so you can experience the full security journey from the bottom up.

Ready to start? Head over to [Setup](setup.md) to clone the project and configure your environment.
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/container-security/setup.md"
cat > 'docs/security/container-security/setup.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Setup

Before you begin, you'll need a Docker Hub account, Docker Desktop installed (4.40+ recommended), and access to a Docker organization. Throughout this workshop, replace `<YOUR_ORG>` with your actual Docker Hub organization name.

## Step 1. Choose your DHI tier

Docker Hardened Images are available in two tiers:

| Tier | Registry | Requirements |
|------|----------|--------------|
| **Free** | `dhi.io/node:...` | No Docker Hub subscription needed |
| **Paid** | `<YOUR_ORG>/dhi-node:...` | Paid plan with images mirrored into your org |

> **How to choose?** Use the free tier (`dhi.io`) unless you have a paid plan with `dhi-node` already mirrored. Throughout the DHI sections, replace `<DHI_PREFIX>` with either `dhi.io/` (free) or `<YOUR_ORG>/dhi-` (paid).

## Step 2. Docker login

```bash
docker login
```

If you're using the free DHI tier, also log in to the `dhi.io` registry:

```bash
docker login dhi.io
```

You should see `Login Succeeded` after each.

## Step 3. Configure Docker Scout organization

```bash
docker scout config organization <YOUR_ORG>
```

This makes Scout output policy results aligned to your organization's configuration. To learn more, see the [Docker Scout Policy guides](https://docs.docker.com/scout/policy/).

## Step 4. Clone and bootstrap the project

The setup script applies a patch that **deliberately introduces a vulnerable state** — old base image and downgraded dependencies — so you can demonstrate the full security journey from the bottom up.

```bash
git clone https://github.com/dockersamples/catalog-service-node
cd catalog-service-node
./demo/sdlc-e2e/setup.sh
```

Clean up any leftover containers from previous runs:

```bash
docker rm $(docker ps -a -q) -f
```

Install Node dependencies:

```bash
npm install
```

## Step 5. Pre-build the initial image

Build the (deliberately vulnerable) starting image so Scout has something to analyse:

```bash
docker build -t catalog-service --sbom=true --provenance=mode=max .
```

The `--sbom=true` and `--provenance=mode=max` flags tell BuildKit to attach a Software Bill of Materials and SLSA provenance attestations to the image. We'll use these in later sections.

You're all set! Continue to [Surface the Problem](surface-the-problem.md) to see what's wrong with the starting image — or jump directly to any of the [8 best practices](overview.md#the-8-container-security-best-practices).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/container-security/surface-the-problem.md"
cat > 'docs/security/container-security/surface-the-problem.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Surface the Problem

Before we fix anything, let's measure exactly what's wrong with the starting image. After the setup patch, our `Dockerfile` starts with:

```dockerfile
FROM node:18 AS base
```

`node:18` is a full, unoptimised image — and it's where most teams start by default. Let's see what that costs us.

## Quick vulnerability overview

```bash
docker scout quickview catalog-service --org <YOUR_ORG>
```

You'll see something like this:

```text
  Target             │  catalog-service:latest  │    2C    26H    25M   122L     4?
    digest           │  360db4f00cbd            │
  Base image         │  node:18                 │    2C    26H    25M   122L     4?
  Updated base image │  node:25-slim            │    0C     1H     2M    24L
                     │                          │    -2    -25    -23    -98     -4
```

Scout is already pointing at the answer: **one `FROM` line change** from `node:18` to `node:25-slim` would eliminate **2 critical and 25 high** CVEs immediately.

## Policy evaluation

Scout doesn't just count CVEs — it evaluates your image against a set of organisational policies:

```bash
docker scout policy catalog-service --org <YOUR_ORG>
```

```text
Policy status  FAILED  (4/7 policies met)

  Status │                     Policy                     │           Results
─────────┼────────────────────────────────────────────────┼──────────────────────────────
  ✓      │ Default non-root user                          │
  !      │ AGPL v3 licenses found                         │    3 packages
  !      │ Fixable critical or high vulnerabilities found │    2C    26H     0M     0L
  ✓      │ No high-profile vulnerabilities                │
  ✓      │ No outdated base images                        │
  !      │ Unapproved base images found                   │    1 deviation
  ✓      │ Supply chain attestations                      │    0 deviations
```

**4/7 policies failing.** This is the **reactive "scan and fix"** cycle most teams know all too well:

1. Developers pull a base image, build, ship
2. CI scanner finds 2 critical and 26 high CVEs
3. Developers spend 3 days researching fixes
4. Rebuild — 189 vulnerabilities still remain
5. Cycle repeats; security blocks deployment

The next 8 sections walk through fixing this **proactively, one best practice at a time** — and then [migrating to DHI](../dhi-proactive/overview.md) to eliminate the cycle altogether.
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/container-security/minimal-base-images.md"
cat > 'docs/security/container-security/minimal-base-images.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Best Practice #1: Minimal Base Images

> **Less OS surface = fewer CVEs = smaller attack window.**

Most teams default to a full base image like `node:18` because it "just works". But every package in that image is a potential CVE vector — and the difference between a full and slim image is dramatic.

## The comparison at a glance

| Image | Size | Packages | CVEs |
|-------|------|----------|------|
| `node:25` (full) | 1.63 GB | 693 | 242 |
| `node:lts-slim` | 344 MB | ~272 | 34 |
| `node:25-slim` | 322 MB | 272 | 30 |
| `node:alpine` | 239 MB | ~150 | 34 |
| `dhi.io/node:25` | ~50 MB | 1 | 7\* |

> \*6 of 7 have upstream fixes pending. **0 critical, 0 high.**

## Update the Dockerfile base image

Open `catalog-service-node/Dockerfile` and replace the existing content with this:

```dockerfile
###########################################################
# Stage: base
###########################################################
FROM node:25-slim AS base

WORKDIR /usr/local/app
RUN useradd -m appuser && chown -R appuser /usr/local/app
USER appuser
COPY --chown=appuser:appuser package.json package-lock.json ./

###########################################################
# Stage: dev
###########################################################
FROM base AS dev
ENV NODE_ENV=development
RUN npm install
CMD ["yarn", "dev-container"]

###########################################################
# Stage: final
###########################################################
FROM base AS final
ENV NODE_ENV=production
RUN npm ci --production --ignore-scripts && npm cache clean --force
COPY ./src ./src

EXPOSE 3000

CMD ["node", "src/index.js"]
```

The single critical change:

```diff
- FROM node:18 AS base
+ FROM node:25-slim AS base
```

## Rebuild and re-scan

```bash
docker build -t catalog-service:slim --sbom=true --provenance=mode=max .
```

Compare image sizes:

```bash
docker images catalog-service
```

```text
IMAGE                    ID             DISK USAGE   CONTENT SIZE
catalog-service:latest   48806e62b871       1.62GB          413MB
catalog-service:slim     8d03cef7a79f        368MB         84.1MB
```

Now re-run the Scout quickview:

```bash
docker scout quickview catalog-service:slim --org <YOUR_ORG>
```

```text
  Target             │  catalog-service:slim  │    0C     2H     2M    24L
  Base image         │  node:25-slim          │    0C     1H     2M    24L
```

**One `FROM` change. Result:**

- ✅ **2 critical eliminated**
- ✅ **25 high eliminated**
- ✅ Image **4× smaller**

Continue to [BP#2: Multi-Stage Builds](multi-stage-builds.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/container-security/multi-stage-builds.md"
cat > 'docs/security/container-security/multi-stage-builds.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Best Practice #2: Multi-Stage Builds

> **Keep dev tools, compilers, and test frameworks out of production.**

A common antipattern is using a single Dockerfile stage that installs everything — dev dependencies, compilers, test frameworks, debuggers — and then ships that whole image to production. Everything that's only useful at build time becomes attack surface at runtime.

## What must NOT ship to production

- Source code beyond what's needed (after copy/compile)
- IDE tooling and editors
- Compilers and build tools
- Debuggers
- The full `npm install` set (which includes `devDependencies`)
- Non-deployable build artifacts

Multi-stage builds let you cleanly separate the build environment from the runtime environment.

## Examine the Dockerfile structure

Look at the `Dockerfile` you saved in the previous step. Three stages:

```text
FROM node:25-slim AS base     <-- shared foundation
  └─ FROM base AS dev          <-- installs ALL deps + dev tools
  └─ FROM base AS final        <-- npm ci --production only
```

The critical production line:

```dockerfile
RUN npm ci --production --ignore-scripts && npm cache clean --force
```

Each flag matters:

- `--production` — only production dependencies, `devDependencies` excluded
- `--ignore-scripts` — no post-install scripts (a common supply chain attack vector)
- `npm cache clean --force` — removes the npm cache from the layer, shrinking the image

## Build specific stages

You can build any stage by name with `--target`. This is useful in CI: run unit tests against the dev stage, ship the final stage to production.

Build the dev stage:

```bash
docker build -t catalog-service:dev --target dev .
```

Build the production stage:

```bash
docker build -t catalog-service:prod --target final .
```

Compare the two:

```bash
docker images catalog-service
```

The `dev` image is significantly larger — it contains all `devDependencies`. The `prod` image is lean: smaller attack surface, faster pulls, less risk.

## Why `--ignore-scripts` matters

Post-install scripts are a well-known supply chain attack vector. The 2022 [`node-ipc` incident](https://snyk.io/blog/peacenotwar-malicious-npm-node-ipc-package-vulnerability/) used a post-install script to wipe files on disks in specific countries. `--ignore-scripts` prevents `npm` from running these scripts during `ci` or `install`, blocking that entire class of attack at build time.

You can verify your prod image stayed clean of critical/high CVEs with Scout:

```bash
docker scout cves catalog-service:prod --only-severity critical,high --org <YOUR_ORG>
```

Continue to [BP#3: Non-Root User](non-root-user.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/container-security/non-root-user.md"
cat > 'docs/security/container-security/non-root-user.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Best Practice #3: Non-Root User

> **Never run containers as root.** Root inside a container is effectively root on the host if isolation fails.

By default, Docker containers run as `root` (UID 0). If an attacker exploits your app, they get root-level access inside the container — and potentially on the host if the container is misconfigured or running with a privileged socket.

## Why this matters

A container is just a Linux process with namespaces around it. If an attacker:

1. Gets code execution inside your container, AND
2. The container is running as root, AND
3. The container has access to a privileged resource (mounted Docker socket, `--privileged` flag, host volume, kernel exploit)

…then root-in-container can become root-on-host. Running as a non-root user is one of the cheapest, most effective mitigations available.

## Three ways to enforce non-root

### Option A — In the Dockerfile (recommended)

This is what we already have in our `Dockerfile`:

```dockerfile
RUN useradd -m appuser && chown -R appuser /usr/local/app
USER appuser
```

Setting `USER` in the Dockerfile means **every** invocation of the image runs as `appuser` by default. No flag required at `docker run` time, no chance of someone forgetting.

### Option B — At `docker run` time

You can override the user when starting a container:

```bash
docker run --rm --user 1000:1000 catalog-service:slim \
    node -e "console.log(process.getuid())"
```

Expected output: `1000` — not `0`.

### Option C — In `docker compose`

```yaml
services:
  catalog:
    build: .
    user: "${CURRENT_UID}"
```

Use the host user's UID/GID — particularly useful for development where bind-mounted volumes need to match host file ownership.

## Verify the running user

```bash
docker run --rm catalog-service:slim whoami
```

Expected output: `appuser` — not `root`.

## The hardened `docker init` pattern

When you run `docker init` in a new project, Docker scaffolds this hardened pattern automatically:

```dockerfile
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser
```

Extra hardening in this version:

- No home directory
- No login shell
- No password
- High UID (10001) to avoid colliding with host users

## Confirm Scout policy

```bash
docker scout quickview catalog-service:slim --org <YOUR_ORG>
```

Look for `Default non-root user` in the policy output — it should show ✓.

Continue to [BP#4: Read-Only Filesystem + Drop Capabilities](readonly-capabilities.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/container-security/readonly-capabilities.md"
cat > 'docs/security/container-security/readonly-capabilities.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Best Practice #4: Read-Only Filesystem + Drop Capabilities

> **Defence in depth:** Even if an attacker gains code execution, a read-only container with dropped Linux capabilities severely limits what they can do next.

This is the "even if everything else fails" layer. Assume your app has a vulnerability. Assume the attacker gets code execution. What can they do?

If the filesystem is writable and capabilities are intact: drop a payload, modify config, install a backdoor, escalate.

If the filesystem is read-only and capabilities are dropped: almost nothing.

## Linux capabilities — what gets dropped with `--cap-drop=ALL`

Linux capabilities split root's privileges into discrete chunks. Most apps need none of them. Dropping them all closes huge attack paths:

| Capability | What it allows |
|------------|----------------|
| `CHOWN` | Change file UIDs/GIDs |
| `DAC_OVERRIDE` | Bypass file read/write/execute permission checks |
| `NET_RAW` | Raw and packet sockets (used in some network attacks) |
| `SETUID` / `SETGID` | Change process UID/GID |
| `SYS_CHROOT` | `chroot()` — change root directory |
| `KILL` | Send signals to other processes |
| `MKNOD` | Create special files |

## Step 1 — Clean up any leftover containers

Run this first every time. It removes any containers from a previous attempt so names and ports are free.

```bash
docker rm -f catalog-hardened catalog-hardened-tmpfs 2>/dev/null
```

## Step 2 — Run with hardened flags

```bash
docker run \
    -d \
    -p 3100:3000 \
    --read-only \
    --cap-drop=ALL \
    --user=65532 \
    --name catalog-hardened \
    catalog-service:slim
```

Verify the container is up:

```bash
docker ps --filter name=catalog-hardened
```

Confirm the app responds:

```bash
curl http://localhost:3100
```

## Step 3 — Verify the filesystem is read-only

Try to write a file inside the container:

```bash
docker exec catalog-hardened sh -c "echo test > /tmp/test.txt"
```

Expected output: `sh: /tmp/test.txt: Read-only file system`

The attacker gained code execution but **cannot write anywhere** — no dropping payloads, no modifying config files, no creating SUID binaries.

## Step 4 — Prove the capability drop

```bash
docker inspect catalog-hardened \
    --format 'ReadonlyRootfs={{.HostConfig.ReadonlyRootfs}} CapDrop={{.HostConfig.CapDrop}}'
```

Expected output:

```text
ReadonlyRootfs=true CapDrop=[ALL]
```

## Step 5 — When your app needs a writable area: use `tmpfs`

Some apps genuinely need scratch space — caches, temp files, sessions. `tmpfs` is in-memory only — writable, but never persisted to disk and gone when the container stops:

```bash
docker run \
    -d \
    -p 3101:3000 \
    --read-only \
    --tmpfs /tmp:noexec,nosuid,size=64m \
    --cap-drop=ALL \
    --user=65532 \
    --name catalog-hardened-tmpfs \
    catalog-service:slim
```

Verify `/tmp` is writable but everything else is still read-only:

```bash
docker exec catalog-hardened-tmpfs sh -c "echo test > /tmp/test.txt && cat /tmp/test.txt"
```

Note the extra `tmpfs` flags:

- `noexec` — files in `/tmp` cannot be executed (blocks payload drop-and-run)
- `nosuid` — SUID bits on files in `/tmp` are ignored (blocks privilege escalation via dropped binaries)
- `size=64m` — caps memory usage to 64 MB (prevents tmpfs DoS)

## Step 6 — Clean up

```bash
docker rm -f catalog-hardened catalog-hardened-tmpfs
```

Continue to [BP#6, #7, #8: Secrets and Limiting Tools](secrets-and-tools.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/container-security/secrets-and-tools.md"
cat > 'docs/security/container-security/secrets-and-tools.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Best Practices #6, #7, #8: Secrets, Dev Tools, OS Tools

The last three best practices all share a common theme: **don't ship anything to production that an attacker could use against you**. That includes credentials, dev tooling, and standard OS utilities.

## BP#6: Secrets

Containers often need credentials: DB passwords, TLS certs, API keys, SSH keys for private package registries. Where you put them determines who can read them.

### The wrong approaches — all visible to attackers

| Location | Risk |
|----------|------|
| In source code | Visible to anyone with repo access |
| Built into the image | Visible via `docker history` |
| In execution scripts committed to SCM | Same as source code |
| In an environment variable | Shows in log dumps, visible to all processes |
| In a file on disk | Available to any process on the machine |
| **In a secrets vault** | **Only available to the process asking for it ✓** |

### Inspect image layers — confirm no secrets leaked

`docker history` shows every command that built the image — and exposes anything that was inlined into a layer:

```bash
docker history catalog-service:slim
```

Look through every layer — no credentials, tokens, or keys should be visible. If you see a `RUN echo "API_KEY=..."` or a `COPY .env`, that secret is now permanently embedded in the image.

### BuildKit build-time secrets

BuildKit's `--mount=type=secret` lets you use a secret during build **without it ever being written to any layer**:

```dockerfile
# WRONG — SSH key baked into layer forever
RUN cp /root/.ssh/id_rsa /app/key

# RIGHT — BuildKit secret, never written to any layer
RUN --mount=type=secret,id=mysecret cat /run/secrets/mysecret
```

```bash
docker build --secret id=mysecret,src=./mysecret.txt -t myapp .
```

The secret is mounted into the build container at `/run/secrets/mysecret`, used during the `RUN`, then disappears. It never lands in `docker history` and never ships in the image.

For runtime secrets, integrate with a real vault (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault) and fetch them at startup — never bake them in.

---

## BP#7: No dev tools in production

Verify the production image has no dev tooling beyond the runtime itself:

```bash
docker run --rm catalog-service:slim which npm   || echo "npm not found — good"
```

```bash
docker run --rm catalog-service:slim which yarn  || echo "yarn not found — good"
```

```bash
docker run --rm catalog-service:slim which git   || echo "git not found — good"
```

If any of these *do* exist in your prod image, you have either too much in the base layer or you're shipping the dev stage by mistake.

---

## BP#8: No OS tools in production

The same logic applies to standard OS utilities:

```bash
docker run --rm catalog-service:slim which curl    || echo "curl not found — good"
```

```bash
docker run --rm catalog-service:slim which wget    || echo "wget not found — good"
```

```bash
docker run --rm catalog-service:slim which apt-get || echo "apt-get not found — good"
```

```bash
docker run --rm catalog-service:slim which sudo    || echo "sudo not found — good"
```

> **Why no `curl`?** An attacker who gets code execution typically uses `curl` or `wget` to download additional payloads — a reverse shell, a crypto miner, a credential stealer. Removing these utilities meaningfully raises the cost of a successful exploit. The attacker now has to write their own networking code from inside the runtime they're stuck with.

> **Why no `apt-get`?** Without a package manager, the attacker can't install anything new — they're limited to whatever is already in the image. With a minimal image, that's almost nothing.

## Attack surface count so far

```bash
docker scout cves catalog-service:slim --format only-packages --org <YOUR_ORG>
```

Where we started: **693 packages** (`node:18`).

Where we are now: **~272 packages** (`node:25-slim`).

Where DHI takes us: **~12 packages**.

Continue to [Continuous Scanning with Scout](../scout-reactive/continuous-scanning.md), or jump straight to [Migrating to DHI](../dhi-proactive/overview.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/scout-reactive/overview.md"
cat > 'docs/security/scout-reactive/overview.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Docker Scout — The Reactive Approach

> **Scan and Fix.** Docker Scout helps you understand what's already in your images, find vulnerabilities, and remediate them — across the full SDLC.

This is the **reactive** half of the container security story: you have images today, they have CVEs today, and you need a systematic way to find and fix them. Scout gives you that.

The companion track, [Docker Hardened Images (Pro-active Approach)](../dhi-proactive/overview.md), goes the other direction: don't *create* the problem in the first place. In real production environments, you need both.

---

## What Scout does

| Capability | What it gives you |
|------------|-------------------|
| **Quickview** | Fast CVE summary for any image |
| **CVE drill-down** | Per-package vulnerability detail with severity filtering |
| **Compare** | Diff between two image versions — exactly what changed |
| **Recommendations** | Suggested base image upgrade paths |
| **Policy evaluation** | Pass/fail your image against organisational policies |
| **CI integration** | GitHub Action that fails the build on critical/high CVEs |
| **Background SBOM indexing** | Continuous analysis of every image you pull or build |

---

## When to use Scout

| Scenario | Scout role |
|----------|-----------|
| You inherited a fleet of images and need to triage | Quickview + CVE drill-down |
| A CVE was just disclosed — am I affected? | Background SBOM indexing alerts you |
| Reviewing a PR that bumps a base image | `compare` to see exactly what changed |
| Gating production deployments | `scout-action` in CI with `exit-code: true` |
| Choosing what to migrate to | `recommendations` shows the upgrade path |

---

## Workshop sections

| Section | What you'll do |
|---------|----------------|
| [Continuous Scanning](continuous-scanning.md) | The three core Scout commands and why scanning at build alone is not enough |
| [CI Integration](ci-integration.md) | Wire Scout into GitHub Actions and fail the build on critical/high CVEs |
| [Recommendations & Comparisons](recommendations.md) | Use `scout recommendations` and `scout compare` to find your upgrade path |

---

## The reactive cycle (and its limits)

The traditional reactive cycle looks like this:

1. Pull a base image
2. Build, ship
3. Scanner finds CVEs
4. Spend days researching fixes
5. Patch, rebuild
6. New CVEs disclosed against your image
7. Go to step 4

Scout makes every step of this cycle faster and more accurate — but you're still on the cycle. The pro-active answer is to start from a base that has near-zero CVEs and a 7-day SLA on remediation. That's [DHI](../dhi-proactive/overview.md).

> **Use both.** Scout for the images you have today. DHI for the images you build next.
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/scout-reactive/continuous-scanning.md"
cat > 'docs/security/scout-reactive/continuous-scanning.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Continuous Scanning, Not Just at Build

> **Best Practice #5:** New CVEs are disclosed every day against images you built months ago. Scanning must happen throughout the entire SDLC — at code, build, registry push, and in production.

A scan at build time tells you what was vulnerable when you built. It does *not* tell you whether yesterday's freshly-disclosed CVE affects the image you shipped last quarter. Continuous scanning closes that gap.

## The three core Scout commands

### 1. Quickview — fast summary

```bash
docker scout quickview catalog-service:slim --org <YOUR_ORG>
```

Use this as your default first look at any image. It returns CVE counts grouped by severity (Critical / High / Medium / Low / Unknown), plus the recommended base image upgrade.

### 2. CVE drill-down — see the actual vulnerabilities

```bash
docker scout cves catalog-service:slim \
    --only-severity critical,high \
    --org <YOUR_ORG>
```

This lists every CVE matching the severity filter, the affected package, the version, and (when available) the fix version. Filter aggressively in CI — most teams gate only on `critical,high`.

### 3. Compare — see exactly what changed between two images

```bash
docker scout compare \
    --ignore-unchanged \
    --to catalog-service \
    catalog-service:slim \
    --org <YOUR_ORG>
```

The `compare` output shows exactly which packages were added/removed/changed and which CVEs were introduced or eliminated — actionable signal, not just noise. This is the command that turns a scary "289 CVEs!" report into "here are the 3 packages that actually changed".

Use `compare` whenever you:

- Bump a base image version
- Bump a major dependency
- Review a PR that touches the Dockerfile
- Roll out a new image to production

## Recommendations — the upgrade path

```bash
docker scout recommendations catalog-service:slim --org <YOUR_ORG>
```

Scout shows the exact upgrade tag that resolves remaining CVEs, along with how many vulnerabilities each candidate eliminates. Instead of "the base image has CVEs, good luck", you get "upgrade to `node:25-slim` and 23 of these go away."

## Background SBOM indexing in Docker Desktop

Enable via **Settings → Features in development → Enable background Scout SBOM indexing** in Docker Desktop.

Once enabled, Scout continuously analyses every image you pull or build — you get alerts before you even think to scan. New CVE disclosed against an image you're running? Scout will tell you, automatically.

This is the missing piece for true continuous scanning: the CVE database changes every day, but most teams only scan at build time. Background indexing means your local images are always re-evaluated against the latest data.

## What about production?

For production fleets, the same principles apply but at registry-/cluster-scale:

- **Registry scanning** — Docker Hub and most registries can scan on push and continuously re-evaluate
- **Cluster scanning** — runtime scanners like Trivy, Grype, and Wiz can pull and analyse every image referenced by a running deployment
- **VEX integration** — DHI ships VEX documents that tell these scanners *which CVEs are non-applicable* (more in the [DHI attestations section](../dhi-proactive/attestations.md))

Continue to [CI Integration](ci-integration.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/scout-reactive/ci-integration.md"
cat > 'docs/security/scout-reactive/ci-integration.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Scout CI Integration

A scanner that doesn't fail the build is just a dashboard. Wiring Scout into CI as a **gate** is what turns reactive scanning into something that actually keeps vulnerable images out of production.

## The Scout GitHub Action

Open `catalog-service-node/.github/workflows/pipeline-docker-cloud.yaml` to see how Scout integrates into a real pipeline.

The key gate step:

```yaml
      - name: Docker Scout CVEs
        uses: docker/scout-action@v1
        with:
          command: cves
          image: ${{ steps.build.outputs.imageid }}
          only-severities: critical,high
          exit-code: true
```

Two flags do the heavy lifting:

- `only-severities: critical,high` — only fail on what actually matters; medium and low don't block the pipeline
- `exit-code: true` — makes the action **fail** the build when matching CVEs are found

That's the gate. If a critical or high CVE shows up, the PR can't merge and the image can't deploy.

## A more complete pipeline

A typical Scout-in-CI pipeline does several things in sequence:

```yaml
      # 1. Build with SBOM and provenance attached
      - name: Build image
        id: build
        uses: docker/build-push-action@v5
        with:
          tags: ${{ env.IMAGE_NAME }}
          sbom: true
          provenance: mode=max
          load: true

      # 2. Quickview — surfaces a summary in the action log
      - name: Docker Scout quickview
        uses: docker/scout-action@v1
        with:
          command: quickview
          image: ${{ steps.build.outputs.imageid }}

      # 3. Compare against the previous prod image
      - name: Docker Scout compare
        uses: docker/scout-action@v1
        with:
          command: compare
          image: ${{ steps.build.outputs.imageid }}
          to: registry.example.com/catalog-service:prod
          ignore-unchanged: true

      # 4. Hard gate on critical/high
      - name: Docker Scout CVE gate
        uses: docker/scout-action@v1
        with:
          command: cves
          image: ${{ steps.build.outputs.imageid }}
          only-severities: critical,high
          exit-code: true

      # 5. Policy gate
      - name: Docker Scout policy gate
        uses: docker/scout-action@v1
        with:
          command: policy
          image: ${{ steps.build.outputs.imageid }}
          exit-code: true
```

The order matters: `quickview` and `compare` run *before* the gate, so the developer sees what's wrong even when the gate fails. Nothing is more frustrating than a CI that says "FAILED" with no detail.

## Tuning the gate

A real-world gate has to balance security and developer flow. A few patterns that work well:

| Pattern | What it does |
|---------|--------------|
| `only-severities: critical,high` | Only block on CVEs that meaningfully matter |
| `only-fixed: true` | Only block on CVEs where a fix is actually available |
| `ignore-unchanged: true` | Don't re-flag CVEs that were already in the previous image |
| Block on `policy` not raw `cves` | Use organisational policy rather than every CVE everywhere |

## Local pre-flight check

Developers can run the same gate locally before pushing — fewer broken builds:

```bash
docker scout cves catalog-service:slim \
    --only-severity critical,high \
    --org <YOUR_ORG> \
    --exit-code
```

Exit code is non-zero if anything matches. Wire this into a pre-commit hook or a `make security` target.

Continue to [Recommendations & Comparisons](recommendations.md), or jump to the pro-active half of the workshop: [Migrating to DHI](../dhi-proactive/overview.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/scout-reactive/recommendations.md"
cat > 'docs/security/scout-reactive/recommendations.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Recommendations & Comparisons

Two of Scout's most useful commands aren't about finding CVEs — they're about figuring out **what to do next**: `recommendations` and `compare`.

## `docker scout recommendations` — what should I upgrade to?

Most CVE-fix advice from a generic scanner is "upgrade the package". For base images that's not always actionable — you don't pin individual OS packages, you pin a base image tag. Scout knows that and gives you tag-level upgrade paths instead.

```bash
docker scout recommendations catalog-service:slim --org <YOUR_ORG>
```

The output ranks candidate base image tags by:

- How many CVEs are eliminated
- Tag freshness
- Compatibility with your current image

Use this every time you do a base image bump. It turns "I think I should move to `node:25-slim` because I read it somewhere" into "Scout says `node:25-slim` removes 23 CVEs, here are the remaining 7."

## `docker scout compare` — what changed between two images?

`compare` is the command most teams underuse. It's the difference between a scary CVE report and an actionable one.

### Compare two local image tags

```bash
docker scout compare \
    --ignore-unchanged \
    --to catalog-service \
    catalog-service:slim \
    --org <YOUR_ORG>
```

This compares the new image (`catalog-service:slim`) against the baseline (`catalog-service`, the old vulnerable build). With `--ignore-unchanged`, you see only what's *different* — not every package both images share.

### Compare against the previous production image

In CI, you almost always want to compare against what's currently running in prod:

```bash
docker scout compare \
    --to registry.example.com/catalog-service:prod \
    catalog-service:candidate \
    --org <YOUR_ORG>
```

The output answers the question every reviewer actually wants the answer to: **"is this PR worse than what we have today?"**

### Reading the compare output

A typical block looks like this:

```text
  vulnerabilities │  0C  0H  0M  0L  │  2C  26H  25M  122L  4?
  size            │  40 MB (-358 MB)  │  398 MB
  packages        │  211 (-595)       │  806
```

Three signals at a glance:

- CVEs gone vs introduced
- Size delta
- Package count delta

If you're shipping to a tightly-controlled production environment, this is the table to put in your release notes.

## Putting it together: the upgrade decision flow

1. Run `docker scout quickview` on what you have today
2. Run `docker scout recommendations` to see candidate upgrades
3. Pick a candidate, build it
4. Run `docker scout compare` against your current prod image
5. If the comparison looks good, ship it. If not, revisit.

This is the **reactive loop done well** — fast, data-driven, and grounded in actual diffs rather than abstract advice.

> Ready to break out of the reactive loop entirely? Continue to [Migrating to DHI](../dhi-proactive/overview.md). DHI ships with near-zero CVEs by construction — and Scout still gives you visibility on top.
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/dhi-proactive/overview.md"
cat > 'docs/security/dhi-proactive/overview.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Docker Hardened Images — The Pro-active Approach

> **Start Secure.** Docker Hardened Images are purpose-built from the ground up to be extremely minimal — not stripped-down versions of something bloated.

This is the **pro-active** half of the container security story. Where [Scout](../scout-reactive/overview.md) helps you find and fix CVEs in images you already have, DHI helps you stop *creating* them in the first place.

The premise is simple: if your base image starts with **near-zero CVEs**, follows a **distroless philosophy**, and ships with **signed supply-chain attestations**, you've eliminated most of the reactive cycle before it begins.

---

## What makes a Docker Hardened Image different

| Property | Standard base image | DHI |
|----------|---------------------|-----|
| CVEs (critical/high) | dozens to hundreds | **0 critical, 0 high** |
| Package count | 200–700+ | **~12** |
| Shell in runtime | Yes (`sh`, `bash`) | **No** (distroless) |
| Non-root by default | Manual | **Built-in** (UID 65532) |
| SBOM | Build-time, optional | **Cryptographically signed** |
| VEX document | No | **Yes** (eliminates false positives) |
| SLSA provenance | Build-time, optional | **Verified, signed** |
| FIPS variant | No | **Yes** (`-fips` tag) |
| STIG variant | No | **Yes** |
| CVE remediation SLA | None | **7-day SLA** |

---

## DHI variants

DHI ships in two variants per language/runtime:

| Variant | Tag pattern | Use case |
|---------|-------------|----------|
| **Dev** | `<DHI_PREFIX>node:24-debian13-dev` | Building — has shell, `npm`, build tools |
| **Runtime** | `<DHI_PREFIX>node:24-debian13` | Production — distroless, no shell |

> Replace `<DHI_PREFIX>` with `dhi.io/` for the free tier or `<YOUR_ORG>/dhi-` for the paid tier (see [Setup](../container-security/setup.md)).

Because the runtime variant has no shell or `npm`, you use **multi-stage builds**: the dev image installs dependencies, the runtime image gets only the output. This isn't a constraint — it's how production images *should* be built.

---

## Workshop sections

| Section | What you'll do |
|---------|----------------|
| [Migrate to DHI](migration.md) | Convert `catalog-service-node` from `node:25-slim` to DHI, before/after Scout comparison |
| [Attestations & Scanner Integration](attestations.md) | Inspect SBOMs, VEX, SLSA provenance, FIPS, and pass them into Grype/Trivy |

---

## The four attack vectors, addressed

Recall the four attack vectors from the [Container Security overview](../container-security/overview.md):

| Vector | DHI's answer |
|--------|--------------|
| Image vulnerabilities | Near-zero CVEs by construction; 7-day SLA on remediation |
| Supply chain integrity | Signed SBOMs + SLSA provenance + VEX, all verifiable with `docker scout attest` |
| Runtime attack surface | Distroless: no shell, no package manager, no curl, no apt |
| Compliance | FIPS 140-validated and STIG variants ship out of the box |

That's why DHI is the **pro-active** answer. You're not finding CVEs and patching them — you're starting from a base where there are almost none, with cryptographic evidence to prove it.

> **Use both.** Scout for visibility on what you run. DHI for the foundation you build on.
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/dhi-proactive/migration.md"
cat > 'docs/security/dhi-proactive/migration.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Migrate to Docker Hardened Images

> **The pro-active approach: Start Secure.** DHI images are purpose-built from the ground up to be extremely minimal — not stripped-down versions of something bloated.

In this section we'll convert `catalog-service-node` from `node:25-slim` (where the [best-practices track](../container-security/overview.md) ended) to a Docker Hardened Image, then compare the results.

## Before you start

Make sure you have:

- Completed the [Setup](../container-security/setup.md) steps
- Decided on free vs paid DHI tier (and know your `<DHI_PREFIX>`)
- Logged in to `dhi.io` if using the free tier (`docker login dhi.io`)

## Update the Dockerfile

Open `catalog-service-node/Dockerfile` and replace it with this DHI-based version:

```dockerfile
###########################################################
# Stage: base (DHI dev variant — has shell + npm for builds)
###########################################################
FROM <DHI_PREFIX>node:24-debian13-dev AS base

WORKDIR /usr/local/app
COPY package.json package-lock.json ./

###########################################################
# Stage: dev
###########################################################
FROM base AS dev
ENV NODE_ENV=development
RUN npm install
CMD ["yarn", "dev-container"]

###########################################################
# Stage: production-dependencies
###########################################################
FROM base AS production-dependencies
ENV NODE_ENV=production
RUN npm ci --production --ignore-scripts && npm cache clean --force

###########################################################
# Stage: final (DHI runtime — distroless, no shell)
###########################################################
FROM <DHI_PREFIX>node:24-debian13 AS final
ENV NODE_ENV=production
COPY --from=production-dependencies /usr/local/app/node_modules ./node_modules
COPY ./src ./src
EXPOSE 3000
CMD ["node", "src/index.js"]
```

The two critical changes:

```diff
- FROM node:25-slim AS base
+ FROM <DHI_PREFIX>node:24-debian13-dev AS base   # build stage
+ FROM <DHI_PREFIX>node:24-debian13 AS final      # runtime — distroless
```

Notice the structure: the dev variant is used as the build environment (it has `npm`), but the final image is built `FROM` the **distroless runtime** variant. Only the compiled `node_modules` and `src` are copied in.

## Build the DHI version

```bash
docker build -t catalog-service:dhi --sbom=true --provenance=mode=max .
```

## Compare all three images

```bash
docker images catalog-service
```

```text
IMAGE                    ID             DISK USAGE   CONTENT SIZE
catalog-service:dhi      ac3a0d465de4        191MB         40.3MB
catalog-service:latest   48806e62b871       1.62GB          413MB
catalog-service:slim     8d03cef7a79f        368MB         84.1MB
```

The DHI runtime is **10× smaller than the original** and **half the size of the slim version** — and we still haven't looked at security.

## Scout quickview — all 7 policies green

```bash
docker scout quickview catalog-service:dhi --org <YOUR_ORG>
```

```text
Target     │  catalog-service:dhi  │    0C     0H     0M     0L

Policy status  SUCCEEDED  (7/7 policies met)

  Status │                              Policy                              │  Results
─────────┼──────────────────────────────────────────────────────────────────┼──────────
  ✓      │ Default non-root user                                            │
  ✓      │ No AGPL v3 licenses                                              │
  ✓      │ No fixable critical or high vulnerabilities                      │
  ✓      │ No high-profile vulnerabilities                                  │
  ✓      │ No unapproved base images                                        │
  ✓      │ Supply chain attestations                                        │
  ✓      │ No outdated base images                                          │
```

**7/7 policies met.** Up from 4/7 at the start of the workshop.

## Full before/after comparison

```bash
docker scout compare \
    --ignore-unchanged \
    --to catalog-service \
    catalog-service:dhi \
    --org <YOUR_ORG>
```

```text
  vulnerabilities │  0C  0H  0M  0L   │  2C  26H  25M  122L  4?
  size            │  40 MB (-358 MB)   │  398 MB
  packages        │  211 (-595)        │  806
```

The numbers:

- ✅ **595 packages removed** — 595 fewer potential CVE vectors
- ✅ **179 vulnerabilities removed** across all severities
- ✅ Image is **10× smaller**

## The no-shell demo

Because the DHI runtime is distroless, an attacker who gains code execution **cannot drop to a shell**:

```bash
docker run --rm catalog-service:dhi sh
```

Expected: error — `sh` does not exist in the image.

Compare to slim:

```bash
docker run --rm catalog-service:slim sh -c "echo 'shell available — attack surface'"
```

The slim image still gives the attacker a shell. The DHI image does not. That's a meaningful difference in what an exploit can do once it lands.

## DHI vs slim — property comparison

| Property | `node:25-slim` | DHI runtime |
|----------|---------------|-------------|
| CVEs (critical/high) | 0C 2H | **0C 0H** |
| Package count | ~272 | **~12** |
| Shell in runtime | Yes (`sh`) | **No (distroless)** |
| Non-root by default | Manual | **Built-in** |
| SBOM | Build-time only | **Cryptographically signed** |
| VEX document | No | **Yes** |
| SLSA provenance | Build-time only | **Verified** |
| FIPS variant | No | **Yes** (`-fips` tag) |
| STIG variant | No | **Yes** |
| 7-day CVE SLA | No | **Yes** |

Continue to [Attestations & Scanner Integration](attestations.md).
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> docs/security/dhi-proactive/attestations.md"
cat > 'docs/security/dhi-proactive/attestations.md' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
## Attestations & Scanner Integration

> **Built-in supply chain security:** Every DHI ships with signed SBOMs, VEX documents, and SLSA provenance for audit-ready pipelines.

This is what most teams don't realise about DHI: it's not just a smaller image with fewer CVEs. It's a fully-attested artifact. Every image carries cryptographic evidence of what's in it, where it came from, and what risks have been assessed.

## List all attestations

```bash
docker scout attest list <DHI_PREFIX>node:24-debian13
```

A single DHI image typically ships with all of the following:

| Attestation | What it is |
|-------------|------------|
| CycloneDX SBOM | Bill of materials — components, libraries, versions |
| SPDX SBOM | SBOM in SPDX format (widely adopted in open-source) |
| Scout SBOM | SBOM generated and signed by Docker Scout |
| OpenVEX | Identifies non-applicable CVEs and explains why |
| in-toto vulnerabilities | Known CVEs affecting the image's components |
| SLSA provenance | Source, build params, and environment details |
| SLSA verification summary | Image's compliance with SLSA requirements |
| Scout health | Signed summary of security and quality posture |
| Scout secret scan | Results of a secrets scan |
| Scout test report | Record of automated tests run against the image |

That's *evidence-grade* supply-chain documentation, available out of the box.

## View the SPDX SBOM

```bash
docker scout attest get <DHI_PREFIX>node:24-debian13 \
    --predicate-type https://spdx.dev/Document
```

The SPDX SBOM lists every package, version, license, and supplier. This is the document a compliance team will ask for during an audit.

## Inspect the SLSA provenance

```bash
docker buildx imagetools inspect <DHI_PREFIX>node:24-debian13 \
    --format '{{json .Provenance}}' | head -80
```

SLSA provenance answers "where did this image come from?" — source repository, commit, build parameters, builder identity. Combined with a signature, it becomes verifiable proof of origin.

## Verify the image signature

```bash
docker trust inspect --pretty <DHI_PREFIX>node:24-debian13
```

The signature ties the image bytes to a verified publisher. A modified image won't verify; an attacker can't substitute a tampered version without breaking the chain.

## FIPS compliance

DHI includes FIPS 140-validated cryptographic modules for regulated environments — government, healthcare, finance, defence.

```bash
docker scout attest get \
    --predicate-type https://docker.com/dhi/fips/v0.1 \
    --predicate \
    <DHI_PREFIX>node:24-debian13-fips
```

Sample output:

```text
"certification": "CMVP #4985",
"certificationUrl": "https://csrc.nist.gov/projects/cryptographic-module-validation-program/certificate/4985",
"name": "OpenSSL FIPS Provider",
"standard": "FIPS 140-3",
"status": "active",
"sunsetDate": "2030-03-10"
```

That's a real CMVP certificate number, queryable on NIST's site, attached as a signed predicate to the image. For regulated workloads, that's the difference between "we think we're compliant" and "here's the certificate".

## STIG attestation

```bash
docker scout attest get \
    --predicate-type https://docker.com/dhi/stig/v0.1 \
    --predicate \
    <DHI_PREFIX>node:24-debian13-fips
```

STIG (Security Technical Implementation Guide) attestations cover compliance with US DoD security baselines — required for many government deployments.

## VEX export — eliminate false positives in external scanners

VEX (Vulnerability Exploitability eXchange) documents tell external scanners (Grype, Trivy, Wiz) which CVEs have already been **assessed as non-exploitable** — eliminating false positives automatically.

This is the killer feature for teams already running third-party scanners. Instead of triaging the same CVE every week, the VEX document tells the scanner "this one's been reviewed, it doesn't apply to this image, move on."

View attestations on your migrated app image:

```bash
docker scout attest list catalog-service:dhi
```

Export the merged VEX document:

```bash
docker scout vex get catalog-service:dhi --output vex.json
```

Pass it to Grype:

```bash
grype catalog-service:dhi --vex vex.json
```

Pass it to Trivy:

```bash
trivy image --vex vex.json catalog-service:dhi
```

The same image, scanned with VEX, reports far fewer CVEs — because the noise has been pre-filtered out by people who actually understand whether a given CVE applies in this build.

## The complete supply chain story

| Question a security team will ask | DHI's answer |
|-----------------------------------|--------------|
| What's in this image? | Signed SBOM (CycloneDX + SPDX) |
| Where did it come from? | SLSA provenance |
| Who built it? | Image signature + provenance |
| Has it been tampered with? | `docker trust inspect` verifies the signature |
| Which CVEs apply? | Scout CVE scan + OpenVEX (filters non-applicable ones) |
| Is it FIPS-compliant? | FIPS attestation with CMVP certificate |
| Is it STIG-compliant? | STIG attestation |
| When are CVEs fixed? | 7-day SLA on critical/high |

## Key takeaway

> Securing your containers is step one.
> Securing your **supply chain** is the rest.
>
> 1. **Know what software you are running** — SBOMs, dependency trees, base image provenance
> 2. **Know what risks that software has** — continuous vulnerability scanning, VEX-aware
> 3. **Fix those risks quickly** — DHI gives you a **7-day SLA** on critical/high CVEs

[Get started with DHI →](https://docs.docker.com/dhi/get-started/)
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo "  -> mkdocs.yml"
cat > 'mkdocs.yml' <<'DOCKER_WORKSHOP_EOF_a8f7e2c1'
# Project information
site_name: Docker workshop
site_url: https://dockerworkshop.vercel.app
site_author: Ajeet Singh Raina

# Repository
repo_name: docker-workshop
repo_url: https://github.com/ajeetraina/docker-workshop
edit_uri: edit/master/docs

# Copyright
copyright: 'Copyright © 2026 Docker'

# Settings
docs_dir: 'docs'
site_dir: 'site'

# Navigation
nav:
  - Getting Started: index.md
  - Prerequisites: prereq/prereq.md
  - Docker 101:
    - Inner-Loop Development workflow:
      - Inner Vs Outer Loop Development workflow: lab1/overview.md
      - What is a container: lab1/what-is-a-container.md
      - Running Postgres Containers: lab1/postgres.md
    - Product catalog - A Sample Demo App:
      - Overview: product-catalog/overview.md
      - Tech stack: product-catalog/tech-stack.md
      - Develop: product-catalog/develop.md
      - Test: product-catalog/test.md
      - Build: product-catalog/build.md
      - Secure: product-catalog/secure.md
  - Docker and AI:
    - Docker Agent:
      - Overview: lab10/overview.md
      - Getting-started: lab10/getting-started.md
      - Concept:
        - Autonomy: lab10/concept/autonomy/autonomy.md
        - Perception: lab10/concept/perception/perception.md
        - Reasoning: lab10/concept/reasoning/reasoning.md
        - Action: lab10/concept/action/action.md
        - Goal-oriented: lab10/concept/goal/goal.md
      - Tools:
        - memory: lab10/tools/memory.md
        - think: lab10/tools/think.md
        - todo: lab10/tools/todo.md
        - shell: lab10/tools/shell.md
        - filesystem: lab10/tools/filesystem.md
        - environment: lab10/tools/environment.md
      - Integration:
        - Docker Agent with Model Context Protocol: lab10/integration/mcp.md
        - Docker Agent with Docker Model Runner: lab10/integration/dmr.md
        - Docker Agent with RAG: lab10/integration/rag.md
      - Projects:
        - Single Agent Systems:
          - A Simple Pirate Agent: lab10/projects/pirate.md
        - Multi-agent Systems:
          - Learning Agent with Alloy Models: lab10/projects/alloy.md
          - Developer Agent with Tools: lab10/projects/dev.md
          - Financial Analysis Team: lab10/projects/financial.md
          - Docker Expert Team: lab10/projects/docker-expert.md
          - Bug Investigator:
            - Overview: lab10/projects/bug-investigator/bug-investigator.md
          - Auto-Curator Agent:
            - Overview: lab10/projects/auto-curator-agent/auto-curator-agent.md
      - Sharing Agents: lab10/sharing.md
    - Docker Model Runner:
      - Overview: lab4/overview.md
      - Getting Started: lab4/getting-started.md
      - Projects:
        - Product Catalog Chatbot: lab4/projects/catalog-chatbot.md
        - GenAI Chatbot: lab4/projects/genai-chatbot.md
    - MCP Catalog and Toolkit:
      - Overview: lab5/overview.md
      - Getting Started: lab5/getting-started.md
      - Projects:
        - Visual Chatbot:
          - Getting Started: lab5/projects/visual-chatbot/visual-chatbot.md
          - Running your First MCP Server: lab5/projects/visual-chatbot/mcp.md
          - GitHub MCP Server and Claude Desktop: lab5/projects/GitHub-Claude.md
          - Docker MCP Server and Gordon: lab5/projects/Docker-CLI-With-Gordon.md
          - Docker MCP Server and VS Code: lab5/projects/Docker-CLI-With-VSCode.md
          - GitHub MCP Server and Gordon: lab5/projects/GitHub-MCP-Gordon.md
          - Kubernetes MCP Server and Claude: lab5/projects/Kubernetes-MCP.md
          - Slack MCP Server and Claude: lab5/projects/Slack-MCP-With-Claude.md
    - Agentic Compose:
      - Overview: lab6/overview.md
      - Getting Started: lab6/getting-started.md
      - Projects:
        - DevDuck:
          - Overview: lab6/projects/devduck/overview.md
          - Prerequisite: lab6/projects/devduck/prereq.md
          - Getting Started: lab6/projects/devduck/getting-started.md
          - Local Agent Interaction: lab6/projects/devduck/local-agent.md
          - Cerebras Interaction: lab6/projects/devduck/cerebras-interaction.md
        - Agentic Product Catalog: lab6/projects/agentic-catalog.md
        - Hackathon Recommender: lab6/projects/hackathon-recommender.md
        - A2A Multi-Agent Fact Checker: lab6/projects/a2a-multi-agent-fact-checker.md
    - Docker Sandboxes:
      - Overview: lab8/overview.md
      - Getting Started: lab8/getting-started.md
      - Concepts:
        - Why Agents Need Governance: lab8/projects/why-governance.md
      - Hands-on Modules:
        - Your First Sandbox: lab8/projects/first-sandbox.md
        - The Isolation Proof: lab8/projects/isolation-proof.md
        - Reviewing Agent Changes: lab8/projects/reviewing-agent-changes.md
        - Secrets Without Exposure: lab8/projects/secrets.md
        - Network Policy: lab8/projects/network-policy.md
        - Branch Mode: lab8/projects/branch-mode.md
        - Parallel Agents: lab8/projects/parallel-agents.md
        - Running Open-Source Models: lab8/projects/local-models.md
        - AI Governance at Scale: lab8/projects/governance-summary.md
      - Projects:
        - DevBoard: lab8/projects/devboard.md
  - Docker and Security:
    - Container Security:
      - Overview: security/container-security/overview.md
      - Setup: security/container-security/setup.md
      - Surface the Problem: security/container-security/surface-the-problem.md
      - "BP#1: Minimal Base Images": security/container-security/minimal-base-images.md
      - "BP#2: Multi-Stage Builds": security/container-security/multi-stage-builds.md
      - "BP#3: Non-Root User": security/container-security/non-root-user.md
      - "BP#4: Read-Only + Drop Capabilities": security/container-security/readonly-capabilities.md
      - "BP#6, #7, #8: Secrets and Limiting Tools": security/container-security/secrets-and-tools.md
    - Docker Scout (Reactive Approach):
      - Overview: security/scout-reactive/overview.md
      - Continuous Scanning: security/scout-reactive/continuous-scanning.md
      - CI Integration: security/scout-reactive/ci-integration.md
      - Recommendations & Comparisons: security/scout-reactive/recommendations.md
    - DHI (Pro-active Approach):
      - Overview: security/dhi-proactive/overview.md
      - Migrate to DHI: security/dhi-proactive/migration.md
      - Attestations & Scanner Integration: security/dhi-proactive/attestations.md
    - Docker Hardened Images (Reference):
      - Overview: lab9/dhi/overview.md
      - Getting Started: lab9/dhi/getting-started.md
      - Image Scanning: lab9/dhi/image-scanning.md
      - Switch to DHI: lab9/dhi/switch-to-dhi.md
      - Compliance & Attestations: lab9/dhi/compliance.md
  - Docker Offload:
    - Overview: lab7/overview.md
    - Getting Started: lab7/getting-started.md

theme:
  name: material
  language: en
  features:
    - navigation.sections
    - navigation.instant
    - navigation.top
    - search.highlight
    - search.share
  palette:
    primary: blue
    accent: blue
  font:
    text: Roboto
    code: Roboto Mono
  favicon: assets/images/favicon.png
  logo: 'images/docker-logo-white.svg'

extra_css:
  - css/styles.css
  - css/dark-mode.css
  - css/sidebar.css
DOCKER_WORKSHOP_EOF_a8f7e2c1

echo ""
echo "All files written successfully."
echo ""
echo "Next steps:"
echo "  1. Verify locally:    mkdocs serve"
echo "  2. Review changes:    git status"
echo "  3. Commit and push:"
echo "       git add docs/security mkdocs.yml"
echo "       git commit -m 'Add container security workshop sections'"
echo "       git push"
echo ""
echo "If anything looks wrong, restore the previous nav with:"
echo "       mv mkdocs.yml.bak mkdocs.yml"
