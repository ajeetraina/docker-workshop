# Product Catalog

```mermaid
flowchart TB
    HUB["Docker Hub Org<br/>network + filesystem policy"]
    subgraph HOST["Host machine"]
        DAEMON["sbx daemon<br/>proxy + policy (cached)"]
        SRC["~/workdemo/catalog-service-node<br/>(source on host)"]
        subgraph STACK["Running app (for you)"]
            APP["catalog-service<br/>Postgres · Kafka · S3"]
        end
        subgraph VM["MicroVM (sandbox)"]
            AGENT["Claude (autonomous)"]
            WS["catalog source<br/>(bind-mounted)"]
            DIND["sandbox Docker daemon<br/>Testcontainers run here"]
            AGENT --- WS
            AGENT --- DIND
        end
    end
    HUB -. "policy synced" .-> DAEMON
    SRC == "bind mount" ==> WS
    WS -. "edits land on host → git diff" .-> SRC
    AGENT -- "anthropic · npm (allow)" --> DAEMON --> NET["approved hosts"]
    AGENT -. "paste.ee / ~/.ssh (deny)" .-> BLOCK["blocked"]

    classDef hub fill:#eef2ff,stroke:#6366f1,color:#000
    classDef vm fill:#ecfdf5,stroke:#10b981,color:#000
    classDef pol fill:#fff7ed,stroke:#f59e0b,color:#000
    classDef app fill:#eff6ff,stroke:#3b82f6,color:#000
    classDef deny fill:#fef2f2,stroke:#ef4444,color:#000
    class HUB hub
    class AGENT,WS,DIND vm
    class DAEMON,NET pol
    class APP,SRC app
    class BLOCK deny
```

*A real autonomous agent on a real service: it edits bind-mounted source (diff lands on your laptop), builds and tests in the sandbox's own Docker daemon, reaches only approved hosts — host Docker, SSH keys, and off-policy destinations all stay out of reach.*

The first demos proved governance with synthetic tests - `curl` to a denylisted host, a mount of `~/.ssh`. This section proves it on a **real application** with a **real autonomous coding agent**.

You'll point Claude at the [Product Catalog service](https://github.com/dockersamples/catalog-service-node) - a Node.js + Express API backed by Postgres, S3, Kafka, and an external inventory service - and hand it an autonomous task: fix a known bug and prove the fix with the project's Testcontainers integration suite. The whole time, the network and filesystem policies you configured in **Network Enforcement Demo** and **Filesystem Enforcement Demo** are the only thing standing between "autonomous" and "uncontained."

**Time:** ~15 minutes
**Prerequisites:** You completed **Network Enforcement Demo** (network) and **Filesystem Enforcement Demo** (filesystem). You have an Anthropic API key **or** a Claude Pro/Max subscription.

## What you'll prove

- A coding agent runs **inside the sandbox microVM**, not on your host
- The agent builds and tests using the **sandbox's own Docker daemon** - never your host Docker
- The agent edits **bind-mounted source**, so its file changes land in your local tree for review
- The sandbox is only created because the workspace path matches a filesystem **allow** rule
- The agent reaches `api.anthropic.com` and package registries only because network policy **allows** them - and still can't exfiltrate to a denylisted host

## The mental model

Two things share the name "Product Catalog"; keep them separate:

| | The running app | The code the agent works on |
| --- | --- | --- |
| **What** | Live service + Postgres/Kafka/S3 stack | The repo files in `src/`, `test/` |
| **Where** | Your host (`docker compose up`), for *you* to explore | Bind-mounted into the sandbox, for the *agent* to edit |

The sandbox is the agent's **workbench**, not a deployment target. The catalog never "runs as a service" in the sandbox - it enters only as source to be modified, built, and tested.

## Step 1 - Allow the workspace path

The agent works on the catalog source on your laptop, so the sandbox needs to mount it. That mount only succeeds if a filesystem **allow** rule covers the path (the **Filesystem Enforcement Demo** lesson).

In **[app.docker.com/accounts/<your-org>](https://app.docker.com/accounts/<your-org>)** → **AI governance** → **Filesystem access**, confirm the `allow workdemo` rule from **The Policy Model** covers where you'll clone the repo:

Substitute `<your-org>` with your Docker Hub organization (where you have admin rights).

- Action: **Allow**
- Filesystem path: `~/workdemo/**`
- Action scope: **Read, Write**
- Name: `allow workdemo`

!!! note
    Use `**`, not `*` - a single `*` won't match across `/`, so `~/workdemo/*` would miss `~/workdemo/catalog-service-node/src`.

After editing any governance policy, force a fresh pull so the sandbox daemon doesn't serve a stale cache:

```bash
sbx logout && sbx login
sbx policy ls --include-inactive | grep -i filesystem
```

You should see the allow rule with `ORIGIN: remote` before continuing.

## Step 2 - Clone the Product Catalog into the allowed path

```bash
cd ~/workdemo
git clone https://github.com/dockersamples/catalog-service-node
cd catalog-service-node
```

The repo ships a known bug - a Kafka message drops the `upc` field when a product is published - plus a full Testcontainers integration suite that proves whether the bug is fixed. A clear goal with real tests: the ideal autonomous task.

## Step 3 - Give the agent its credentials

The sandbox proxy injects credentials so the key never enters the sandbox directly.

**API key:**

```bash
echo 'sk-ant-api03-...' | sbx secret set -g anthropic -f
```

**Or Claude Pro/Max subscription** - mint a long-lived token on the host, then inject it as a custom secret the proxy swaps in for calls to `api.anthropic.com`:

```bash
claude setup-token   # prints sk-ant-oat01-...
sbx secret set-custom -g \
  --host api.anthropic.com \
  --env CLAUDE_CODE_OAUTH_TOKEN \
  --placeholder 'sk-ant-oat01-{rand}' \
  --value 'sk-ant-oat01-...'
```

!!! note
    `api.anthropic.com:443` is already in the AI-services network allow rule from **Network Enforcement Demo** - the agent can reach Anthropic, and nothing else off-policy.

## Step 4 - Launch the autonomous agent

```bash
sbx run --name catalog claude
```

This creates the sandbox (the filesystem allow rule lets the catalog directory mount) and drops you into Claude **inside the microVM**. Confirm the sandbox has its own Docker daemon - this is where all builds and tests will run:

```bash
sbx exec catalog -- docker version --format '{{.Server.Version}}'
```

A version prints from a daemon that is **not** your host's. Container builds and Testcontainers happen here, fully isolated.

## Step 5 - Hand it the goal

In the agent session, give it the task in plain language:

```
There's a bug where the Kafka message published on product creation drops
the upc field. Find it, fix it, and prove the fix by running the integration
test suite. Iterate until the tests pass.
```

Now watch. The agent will, **entirely inside the sandbox**:

1. Read `src/services/PublisherService.js` and locate the dropped field
2. Edit the source (changes appear in your host tree via the bind mount)
3. Run `yarn integration-test` - which spins up **throwaway** Postgres, Kafka, and LocalStack containers via Testcontainers, inside the sandbox's Docker daemon
4. Read the results, iterate if needed, and stop when the suite is green

## Step 6 - Review the changes on your laptop

Because the source is bind-mounted, the agent's edits are already in your local tree. Open a host terminal:

```bash
cd ~/workdemo/catalog-service-node
git diff
```

You review a small, contained diff - the agent never had access to your host's Docker, your SSH keys, or any off-policy network destination while producing it.

## Step 7 - Read the results

| Concern | Where it happened | Why it was safe |
| --- | --- | --- |
| Agent reasoning + edits | Sandbox microVM | Isolated VM; only the mounted workspace is visible |
| `docker build` / Testcontainers | Sandbox's own Docker daemon | Never touches host Docker - no blast radius |
| Reaching `api.anthropic.com` + npm registry | Through the proxy | Allowed by network policy; everything else denied |
| Exfil to `paste.ee` / unapproved host | Blocked | Network deny rule (**Network Enforcement Demo**) |
| Mounting `~/.ssh` or an unapproved dir | Would 403 at creation | Filesystem rules (**Filesystem Enforcement Demo**) |
| The fix itself | Bind-mounted source | Lands in your local tree for human review |

## What you just demonstrated

This is the **golden path**: a developer (or CI) runs `sbx run claude`, the agent works fully autonomously on a real service - editing, building, running real integration tests - and produces a reviewable diff, all without a single approval prompt and without any ability to step outside the policy boundary.

Autonomy and governance aren't a trade-off here. The policies from **Network Enforcement Demo** and **Filesystem Enforcement Demo** are exactly what make hands-off autonomy *safe*:

- **Compute** is contained - builds and tests run in the sandbox's Docker, not yours
- **Network** is contained - the agent reaches only approved hosts
- **Filesystem** is contained - the agent mounts only approved paths, and its writes land only where allowed
- **Review** stays human - the diff surfaces on your laptop before anything merges

This is the payoff of the whole lab: **define policy once in the Admin Console, and a real autonomous agent on a real codebase stays inside the lines - automatically.**
