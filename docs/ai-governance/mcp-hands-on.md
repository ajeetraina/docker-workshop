# MCP Hands-On - Registering Servers with `sbx mcp`

**Pillar 2 - MCP Tool Governance** is framed as roadmap in *What's Next*. This section gets your hands on the part that's already shipping: the `sbx mcp` subcommand for registering MCP servers, fronted by the **Docker MCP Gateway**, that your sandboxed agents can call.

By the end you will have:

- A nightly `sbx` build with the `mcp` subtree enabled
- A local **MCP Gateway** that `sbx` talks to
- A registered MCP server (local stdio and a real remote OAuth server)
- A clear mental model of the registration modes (remote OAuth, docker.io image, local stdio) and when to use each

!!! info "At a glance"
    **Time:** ~15 minutes &nbsp;&nbsp;|&nbsp;&nbsp; **Prerequisites:** Setup and *Why AI Governance*. You do **not** need admin rights for your org - everything here runs locally.

---

## Why this isn't in the stable `--help`

The `sbx mcp` command exists in recent `sbx` builds but is **hidden** until an environment variable enables it:

```
SBX_MCP_URL is not set; MCP is not enabled
```

Once you set `SBX_MCP_URL` to any absolute http/https URL, the entire `mcp` subtree appears in `sbx --help`. That env var also tells `sbx` which **MCP Gateway / control plane** to talk to for hosted OAuth flows and managed server runs. We'll come back to that distinction below.

---

## Step 1 - Install or upgrade to the nightly `sbx`

The stable Homebrew formula may lag behind the nightly on MCP features. Use the nightly tap on macOS:

```bash
brew install docker/tap/sbx@nightly
```

If you already have stable installed, switch the symlink:

```bash
brew unlink sbx 2>/dev/null; brew link --overwrite sbx@nightly
```

On Linux or Windows, grab the latest pre-release asset from the [releases page](https://github.com/docker/sbx-releases/releases) - look for `DockerSandboxes-linux.tar.gz`, the `.deb`/`.rpm` packages, or `DockerSandboxes.msi`. Do **not** download "Source code (tar.gz)" - that repo has no source, only release assets.

Verify your version:

```bash
sbx version
```

---

## Step 2 - Confirm the gating

Before setting the env var, look at what's in `sbx --help`:

```bash
sbx --help | grep -iE "mcp|Available Commands" | head -20
```

You'll see the usual commands (`create`, `run`, `policy`, `secret`, etc.) but **no `mcp`**.

---

## Step 3 - Enable `sbx mcp` with the MCP Gateway

`SBX_MCP_URL` is the gate. Any reachable http/https URL turns the command on - point it at an **MCP Gateway**.

### Variant A - Your own local MCP Gateway (focus of this lab)

The open-source [`docker/mcp-gateway`](https://github.com/docker/mcp-gateway) is the data-plane half of the MCP architecture - it proxies MCP traffic to backing servers over stdio/SSE/streaming. Running it locally is the cleanest way to teach the gateway side of the picture, works fully offline, and needs zero internal access.

Create a working directory and pull the lab's prebuilt Compose file:

```bash
mkdir -p ~/mcp-gateway-lab && cd ~/mcp-gateway-lab
curl -fsSL https://raw.githubusercontent.com/ajeetraina/labspace-ai-governance/main/labspace/assets/mcp-gateway-compose.yaml -o compose.yaml
cat compose.yaml
```

The Compose file runs `docker/mcp-gateway` with the DuckDuckGo server enabled, mounts the Docker socket so the gateway can spawn MCP server containers, and exposes the SSE transport on port 8811.

Start it and point `sbx` at it:

```bash
docker compose up -d
export SBX_MCP_URL=http://localhost:8811
sbx mcp --help
```

The `mcp` subtree is now live. The full set of subcommands:

```
sbx mcp
Register and manage MCP servers for use with sandbox sessions.

Available Commands:
  add         Register an MCP server
  auth        Authorize MCP servers
  bundle      Manage MCP server bundles
  inspect     Show MCP server details
  load        Load an already-registered MCP server into a running sandbox
  ls          List registered MCP servers
  rm          Remove a registered MCP server
```

Note `load` - that's the command that actually attaches a registered server to a running sandbox (there is no `--mcp` flag on `sbx run`; more on that in Step 6).

!!! warning "What the local gateway is and isn't"
    The local gateway **unlocks the `sbx mcp` subtree** (any URL does that) and is the **data plane** that actually proxies tool calls. It does **not** implement the hosted OAuth/catalog control-plane endpoints. So:

    - ✅ Local stdio servers (Mode C below) and docker.io image servers (Mode B) work normally through the gateway
    - ✅ Remote OAuth servers (Mode A) still register - `sbx` runs OAuth discovery against the *target* server (e.g. Notion), not against your gateway

### Variant B - 🔒 Hosted Docker MCP Gateway

If you're on a Docker team or in the preview program, `SBX_MCP_URL` should point at Docker's **hosted MCP control plane** - the service that brokers per-server OAuth on your Docker Hub identity and manages gateways inside each sandbox. Ask in the internal sbx Slack channel for the current URL. With that URL set, `sbx mcp add <name>` against catalog-backed servers (Notion, GitHub, Linear) walks you through a hosted OAuth flow tied to your Hub login and stores the credentials in the control plane instead of as plaintext env vars on disk.

---

## Step 4 - The registration modes

`sbx mcp add <name>` takes either `--url` or `--command`. `sbx` **auto-detects** the input type. With the MCP Gateway as your control point, the modes that matter for this lab are:

| Mode | When to use | Flags |
| --- | --- | --- |
| **A - Remote OAuth MCP endpoint** | A hosted MCP server with OAuth (Notion, Linear, GitHub) | `--url https://mcp.<vendor>.com/mcp` |
| **B - docker.io OCI image** | A containerized MCP server published as an OCI image - transport/port/path auto-detected from image labels | `--url docker.io/<org>/<image>:<tag>` |
| **C - Local stdio command** | An MCP server you run as a subprocess/container on the host | `--command <exe> --args "a,b,c"` |

> `sbx mcp add --help` also documents a public community-registry URL form. This lab deliberately skips it and stays on the gateway-native paths above - remote OAuth, docker.io images, and local stdio.

A few rules baked into the binary that will save you debugging time:

- **`--url` must be https** for remote MCP endpoints. Plain http fails with `issuer URL must use https scheme` because `sbx` does RFC 8414 OAuth discovery against the URL.
- **OCI image refs must be on `docker.io`.** Other registries (gcr.io, ghcr.io, ECR) are rejected in v1. Transport is read from the `io.modelcontextprotocol.transport` label (falling back to a TCP `EXPOSE` → `streamable-http`, else `stdio`); override with `--transport` / `--port` / `--path`.
- **`--command` is an executable path**, not a shell string. Don't pass `"docker run ..."` as one big string; use `--command docker --args "run,-i,--rm,mcp/postgres"`. `--args` is a string list - comma-separate multiple values.
- **`--skip_auth`** lets you register an OAuth server without starting the hosted OAuth flow - useful if you don't have control-plane access yet.

!!! tip "Registering only records the server - then attach it"
    Per the help text, `sbx mcp add` *"only registers the server."* To actually use it you either bring it up with a sandbox (`sbx create`/`sbx run --static-mcp <name>`) or load it into one that's already running (`sbx mcp load <name>`). See Step 6.

---

## Step 5 - Try Mode C (local stdio) - works everywhere

The most reliable path that needs nothing beyond your machine. Register a local DuckDuckGo MCP server that runs as a Docker container in stdio mode:

```bash
sbx mcp add local-ddg --command docker --args "run,-i,--rm,--init,mcp/duckduckgo"
```

List what's registered:

```bash
sbx mcp ls
```

Inspect the server you just added:

```bash
sbx mcp inspect local-ddg
```

!!! warning "Local stdio servers run on the HOST, not in the sandbox"
    They have your full user permissions - filesystem, network, secrets, everything. Use them for development, not for code you don't trust. The `add --help` text spells this out: *"no identity, no verifiable supply chain, and no sandboxing."* This is exactly the risk the MCP Gateway exists to govern.

---

## Step 6 - Try Mode A (remote OAuth) - register a real hosted server

Pointing `sbx` at a real hosted MCP server triggers OAuth discovery and the full authorization flow. Register Notion:

```bash
sbx mcp add notion --url https://mcp.notion.com/mcp
```

On a first run `sbx` starts its background daemon and walks the OAuth flow:

```
Starting sandboxd daemon...
Daemon started (PID: 15909, socket: .../sandboxd.sock)
Resolving MCP server "notion"...
INFO: mcpruntime: discovering remote server spec
INFO: mcpruntime: remote server spec discovered
MCP server "notion" authorized
MCP server "notion" registered (type: remote)
```

Confirm it landed and inspect the OAuth metadata `sbx` discovered:

```bash
sbx mcp ls
```

```
NAME                 TYPE     URL/COMMAND
notion               remote   https://mcp.notion.com/mcp
```

```bash
sbx mcp inspect notion
```

```
Name:      notion
Type:      remote
URL:       https://mcp.notion.com/mcp
Transport: streamable-http
OAuth:     required
  Issuer:       https://mcp.notion.com
  Registration: https://mcp.notion.com/register
```

!!! note "Don't have OAuth access yet?"
    Append `--skip_auth` to register the entry without running the OAuth dance:
    `sbx mcp add notion --url https://mcp.notion.com/mcp --skip_auth`. The server shows up in `sbx mcp ls`, but calls won't be authorized until you complete auth.

!!! warning "The flag is `--static-mcp`, not `--mcp`"
    `sbx run claude --mcp notion` fails with `ERROR: unknown flag: --mcp` - that flag doesn't exist. Registering a server only *records* it; attach it one of two ways:

    ```bash
    # Bring up a sandbox with the server attached from the start
    sbx run claude --static-mcp notion

    # ...or load it into a sandbox that's already running
    sbx mcp load notion
    ```

    Both routes go through the MCP Gateway. Use `sbx mcp ls` / `sbx mcp inspect` to confirm what's registered, `sbx mcp auth` to (re)authorize an OAuth server, and `sbx mcp bundle` to manage a named set of servers.

---

## Step 7 - Clean up

Remove the test servers when you're done:

```bash
sbx mcp rm local-ddg notion 2>/dev/null; sbx mcp ls
```

---

## How this connects to Pillar 2

*What's Next* describes **MCP Tool Governance** as the layer where org admins decide *which* MCP servers and tools agents in your org are allowed to call. Everything you just did was on the **developer side** of that picture - registering servers from your CLI, fronted by the MCP Gateway.

The governance side - the org admin approving catalogs, restricting tool sets, injecting per-request secrets - sits in front of the same `sbx mcp` machinery and the same gateway that `SBX_MCP_URL` points at. The CLI you used here is exactly the surface that enterprise policy will constrain once MCP Gateway Enterprise is generally available.

In other words: today you control what's registered; tomorrow your org admin controls what's registerable.

---

## Quick recap

You proved:

- `sbx mcp` exists today, gated behind `SBX_MCP_URL` pointing at an MCP Gateway
- Three gateway-native registration modes - remote OAuth, docker.io image, and local stdio - cover the realistic ways to wire up an MCP server
- The local stdio path works with zero internal access; the remote OAuth path (Notion) authorizes and registers as a `remote` server
- The attach flag is `--static-mcp` (not `--mcp`); `sbx mcp load` attaches into an already-running sandbox - both fronted by the gateway

That's the developer half of Pillar 2 in your hands.
