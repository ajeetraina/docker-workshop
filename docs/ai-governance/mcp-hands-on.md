# MCP Hands-On - Registering Servers with `sbx mcp`

**Pillar 2 - MCP Tool Governance** is framed as roadmap in *What's Next*. This section gets your hands on the part that's already shipping: the `sbx mcp` subcommand for registering MCP servers that your sandboxed agents can call.

By the end you will have:

- A nightly `sbx` build with the `mcp` subtree enabled
- A registered MCP server you can invoke from `sbx run --mcp`
- A clear mental model of the four registration modes and when to use each

!!! info "At a glance"
    **Time:** ~15 minutes &nbsp;&nbsp;|&nbsp;&nbsp; **Prerequisites:** Setup and *Why AI Governance*. You do **not** need admin rights for your org - everything here runs locally.

---

## Why this isn't in the stable `--help`

The `sbx mcp` command exists in recent `sbx` builds but is **hidden** until an environment variable enables it:

```
SBX_MCP_URL is not set; MCP is not enabled
```

Once you set `SBX_MCP_URL` to any absolute http/https URL, the entire `mcp` subtree appears in `sbx --help`. That env var also tells `sbx` which **MCP control plane** to talk to for hosted OAuth flows and managed-infrastructure server runs. We'll come back to that distinction below.

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

## Step 3 - Enable `sbx mcp`

`SBX_MCP_URL` is the gate. Any reachable http/https URL turns the command on - pick whichever variant below fits your setup.

### Variant A - Community registry (zero infra)

The simplest path. Point at the public MCP community registry:

```bash
export SBX_MCP_URL=https://registry.modelcontextprotocol.io
sbx --help | grep mcp
sbx mcp --help
```

### Variant B - Your own local MCP Gateway

The open-source [`docker/mcp-gateway`](https://github.com/docker/mcp-gateway) is the data-plane half of the MCP architecture - it proxies MCP traffic to backing servers over stdio/SSE/streaming. Running it locally is useful for fully offline labs, internal demos, and to teach the gateway side of the picture.

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

!!! warning "What this does and doesn't do"
    Setting `SBX_MCP_URL` to a local gateway **unlocks the `sbx mcp` subtree** (any URL does that), but the local gateway is the **data plane** - it doesn't implement the OAuth/catalog control-plane endpoints that `sbx mcp add --url <hosted-server>` expects. So:

    - ✅ Modes 2/3 (community registry) and Mode 4 (local stdio) work normally
    - ❌ Mode 1 (`--url https://...`) will still try OAuth discovery against the *target* server, not your local gateway - same behavior as Variant A

    The local gateway is most useful when you separately invoke MCP tools through it (e.g., from Claude Desktop or a custom client pointed at `http://localhost:8811`) rather than as a control plane for `sbx`.

### Variant C - 🔒 Hosted Docker MCP Gateway 

If you're on a Docker team or in the preview program, `SBX_MCP_URL` should point at Docker's **hosted MCP control plane** - the service that brokers per-server OAuth on your Docker Hub identity and manages gateways inside each sandbox. Ask in the internal sbx Slack channel for the current URL. With that URL set, `sbx mcp add <name>` against catalog-backed servers (Notion, GitHub, Linear) walks you through a hosted OAuth flow on your Hub login.

---

Whichever variant you picked, the `mcp` subtree is now live: `add`, `ls`, `inspect`, `rm`, `bundle`, etc.

---

## Step 4 - The four registration modes

`sbx mcp add --help` documents four ways to register a server. Knowing which to use is most of the battle.

| # | Mode | When to use | Flags |
| --- | --- | --- | --- |
| 1 | Remote OAuth MCP endpoint | A hosted MCP server with OAuth (Notion, Linear, GitHub) | `--url https://...` |
| 2 | Community registry (managed) | A server published to `registry.modelcontextprotocol.io`, runs in managed infra | `--url https://registry.modelcontextprotocol.io/v0/servers/<name>/versions/latest` |
| 3 | Community registry (local) | Same as 2, but the OCI container runs on your host | `--url ...` + `--local` |
| 4 | Local stdio command | An MCP server you run as a subprocess on the host | `--command <exe> --args "a,b,c"` |

A few rules baked into the binary that will save you debugging time:

- **`--url` must be https** for direct MCP endpoints. Plain http fails with `issuer URL must use https scheme` because `sbx` does RFC 8414 OAuth discovery against the URL.
- **`--args` is comma-separated**, not space-separated. `--args "run,-i,--rm,mcp/postgres"` is one value.
- **`--command` is an executable path**, not a shell string. Don't pass `"docker run ..."` as one big string; use `--command docker --args "run,..."`.
- **`--skip_auth`** lets you register an OAuth server without starting the hosted OAuth flow - useful if you don't have control-plane access yet.

---

## Step 5 - Try Mode 4 (local stdio) - works everywhere

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
    They have your full user permissions - filesystem, network, secrets, everything. Use them for development, not for code you don't trust. The `add --help` text spells this out: *"no identity, no verifiable supply chain, and no sandboxing."*

---

## Step 6 - Try Mode 2 (community registry) - fully public path

The community registry hosts MCP servers as OCI images. `sbx` pulls the registry entry, extracts the image reference, and (in managed mode) runs it in the MCP gateway infrastructure.

```bash
sbx mcp add fetch --url https://registry.modelcontextprotocol.io/v0/servers/fetch-mcp/versions/latest
```

If managed-infrastructure mode isn't available in your environment (no control plane), append `--local` to run the OCI image directly on your host via `docker run`:

```bash
sbx mcp add fetch-local --url https://registry.modelcontextprotocol.io/v0/servers/fetch-mcp/versions/latest --local
```

---

## Step 7 - Try Mode 1 (remote OAuth) - needs an https endpoint

Pointing `sbx` at a real hosted MCP server triggers OAuth discovery. With `--skip_auth` you can register the entry without going through the hosted OAuth dance:

```bash
sbx mcp add notion --url https://mcp.notion.com/mcp --skip_auth
```

!!! note "🔒 Docker Insiders bonus"
    Without `--skip_auth` (and with `SBX_MCP_URL` pointing at the real hosted control plane), this command opens a browser tab, walks you through Notion OAuth tied to your Docker Hub identity, and registers the resulting credentials in the control plane so they're available to every sandbox you spin up - not stored as plaintext env vars on disk.

---

## Step 8 - Clean up

Remove the test servers when you're done:

```bash
sbx mcp rm local-ddg fetch fetch-local notion 2>/dev/null; sbx mcp ls
```

---

## How this connects to Pillar 2

*What's Next* describes **MCP Tool Governance** as the layer where org admins decide *which* MCP servers and tools agents in your org are allowed to call. Everything you just did was on the **developer side** of that picture - registering servers from your CLI.

The governance side - the org admin approving catalogs, restricting tool sets, injecting per-request secrets - sits in front of the same `sbx mcp` machinery, gated by the hosted control plane that `SBX_MCP_URL` points at. The CLI you used here is exactly the surface that enterprise policy will constrain once MCP Gateway Enterprise is generally available.

In other words: today you control what's registered; tomorrow your org admin controls what's registerable.

---

## Quick recap

You proved:

- `sbx mcp` exists today, gated behind `SBX_MCP_URL`
- Four distinct registration modes cover the realistic ways to wire up an MCP server
- The public paths (community registry + local stdio) work with zero internal access
- The hosted OAuth + managed infrastructure paths are what MCP Tool Governance will sit on top of

That's the developer half of Pillar 2 in your hands.
