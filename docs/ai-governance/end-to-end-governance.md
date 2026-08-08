# Putting It All Together

```mermaid
flowchart TB
    HUB["Docker Hub Org<br/>one policy engine<br/>network · filesystem<br/>credential · MCP"]
    subgraph HOST["Host machine"]
        DAEMON["sbx daemon + gateway<br/>enforces policy (cached)"]
        subgraph VM["MicroVM (sandbox)"]
            ROGUE["Rogue / prompt-injected agent"]
            WS["workspace ~/workdemo/capstone<br/>(only this is mounted)"]
            ROGUE --- WS
        end
    end
    HUB -. "policy synced at login" .-> DAEMON
    DAEMON -. enforces .-> VM
    ROGUE -->|"1 · mount ~/.ssh"| A1["403 at creation<br/>(filesystem)"]
    ROGUE -->|"2 · curl paste.ee"| A2["403 at proxy<br/>(network)"]
    ROGUE -->|"3 · read $ANTHROPIC_API_KEY"| A3["proxy-managed sentinel<br/>(credential)"]
    ROGUE -->|"4 · rogue MCP tool"| A4["denied at gateway<br/>(MCP)"]

    classDef hub fill:#eef2ff,stroke:#6366f1,color:#000
    classDef pol fill:#fff7ed,stroke:#f59e0b,color:#000
    classDef vm fill:#ecfdf5,stroke:#10b981,color:#000
    classDef rogue fill:#fef2f2,stroke:#ef4444,color:#000
    classDef deny fill:#fee2e2,stroke:#dc2626,color:#000
    class HUB hub
    class DAEMON pol
    class WS vm
    class ROGUE rogue
    class A1,A2,A3,A4 deny
```

*The capstone: one rogue agent tries all four attacks in a single sandbox, and one policy engine stops each — fail-closed, at a different point in the lifecycle, with no per-attack setup.*

You proved each control on its own - network (**Network Enforcement Demo**), filesystem (**Filesystem Enforcement Demo**), credential isolation (**Credential Isolation**), and MCP (**MCP Hands-On**). This section puts all four together against a **single rogue agent** in **one sandbox**, then hands you a one-page scorecard you can walk a security team through.

The point: governance isn't four separate features you remember to turn on. It's one policy engine, one source of truth for `<your-org>`, enforcing four boundaries at once - so an agent that tries all four attacks in a single session is stopped four times without any per-attack setup.

Substitute `<your-org>` with your Docker Hub organization (where you have admin rights).

**Time:** ~15 minutes
**Prerequisites:** You completed **Network Enforcement Demo**, **Filesystem Enforcement Demo**, **Credential Isolation**, and **MCP Hands-On**. The `Labspace AI Governance` network and filesystem policies are active (`sbx policy ls` shows them with `ORIGIN: remote`).

## What you'll prove

- A single sandbox enforces **network, filesystem, credential, and MCP** boundaries simultaneously
- The "blast radius" an unconstrained agent has on the host is **empirically gone** inside the sandbox
- Every boundary fails **closed** - denied by default, no per-attack configuration required
- You can summarize the whole story in one scorecard for a CISO

## The scenario - one agent, four attacks

Picture a prompt-injected coding agent. Its hidden instructions tell it to do what the [horror-story agent](https://github.com/ajeetraina/labspace-docker-ai-governance/blob/main/project/horror-story-agent/inventory.sh) from **Why AI Governance** catalogued:

1. **Read** your SSH and cloud credentials off disk (`~/.ssh`, `~/.aws`)
2. **Exfiltrate** them to a paste site (`paste.ee`)
3. **Steal** the live API key it authenticates with (`ANTHROPIC_API_KEY`)
4. **Reach** an unapproved tool server to broaden its access (rogue MCP backend)

On an ungoverned laptop, all four succeed. Let's watch `<your-org>`'s governance stop each one - in the same sandbox, in one sitting.

## Step 1 - Establish the blast radius on the host

First, see what the agent *would* have on an ungoverned machine. The inventory script is **read-only** - it checks which secret stores exist and which exfil destinations are reachable, and transmits nothing. Fetch and run it on your **host** terminal:

```bash
mkdir -p ~/workdemo/capstone && cd ~/workdemo/capstone
curl -fsSL https://raw.githubusercontent.com/ajeetraina/labspace-docker-ai-governance/main/project/horror-story-agent/inventory.sh -o inventory.sh
bash inventory.sh
```

On a typical developer machine you'll see a wall of `[FOUND]` secrets and `[REACHABLE]` destinations:

```
=== What an unconstrained agent could read ===

[FOUND] SSH keys in ~/.ssh/
  - id_ed25519
[FOUND] AWS credentials at ~/.aws/credentials
[FOUND] Docker config at ~/.docker/config.json (may contain registry tokens)
...
=== What an unconstrained agent could reach (network) ===

[REACHABLE] api.anthropic.com:443
[REACHABLE] hooks.slack.com:443
[REACHABLE] paste.ee:443
[REACHABLE] pastebin.com:443
```

Every `[FOUND]` line is a secret the agent could read. Every `[REACHABLE]` line is somewhere it could send them. **That's the blast radius.** Now let's close it.

## Step 2 - Attack 1 blocked: the agent can't even mount your secrets

The strongest boundary fires before the agent runs. Try to launch a sandbox that mounts your SSH directory - exactly what a credential-stealing agent needs:

```bash
cd ~/workdemo/capstone
sbx run shell . ~/.ssh:ro
```

**Expected:**

```
ERROR: failed to create sandbox: ... status 403: mount policy denied:
/Users/<you>/.ssh: ... action=fs:mount:read,
resource=fs:path:/Users/<you>/.ssh
```

✅ The `deny credentials` rule blocks the mount **at creation time**. The sandbox never starts, so `~/.ssh` never exists inside it. There's no race, no partial read - the secret simply isn't in the box. *(**Filesystem Enforcement Demo**)*

## Step 3 - Launch the governed sandbox

Now start the sandbox the way it's meant to run - workspace only, no credential mounts:

```bash
cd ~/workdemo/capstone
sbx run shell .
```

You land at a shell prompt inside the microVM. The next three attacks all run from **inside** this one sandbox.

## Step 4 - Attack 1 confirmed: the secrets aren't reachable from inside

Re-run the same inventory script from **inside** the sandbox to compare against the host baseline. Copy it into the workspace first if it isn't already there:

```bash
ls ~/.ssh ~/.aws 2>&1
bash inventory.sh
```

**Expected:** `ls` reports the credential directories don't exist, and the inventory's `[FOUND]` credential lines from Step 1 are **gone** - there are no SSH keys, AWS creds, or Docker config to find. The default-deny filesystem posture means only your allowed workspace (`~/workdemo/**`) was ever mounted.

!!! note
    The inventory script's network probes use raw `/dev/tcp` sockets, not the proxy-aware path. Treat its credential (`[FOUND]`) results as the authoritative filesystem proof; use the `curl` test in the next step as the authoritative **network** proof, since that's exactly what the proxy enforces.

## Step 5 - Attack 2 blocked: exfiltration is refused at the proxy

Still inside the sandbox, have the "agent" try to ship data to a paste site, and compare against an allowed destination:

```bash
curl -sS https://api.anthropic.com -o /dev/null -w "anthropic:  %{http_code}\n"
curl -sS https://paste.ee        -o /dev/null -w "paste.ee:   %{http_code}\n"
curl -sS https://example.com     -o /dev/null -w "example.com: %{http_code}\n"
```

**Expected:**

```
anthropic:  200
paste.ee:   403
example.com: 403
```

✅ `paste.ee` is refused by the `deny exfiltration` rule; `example.com` is refused by default-deny. The `403` comes from the **sbx proxy**, not the destination - the exfil target never received the connection. *(**Network Enforcement Demo**)*

## Step 6 - Attack 3 blocked: there's no live key to steal

The agent authenticates to Anthropic on every call - so surely the key is in its environment? Check:

```bash
echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY"
```

**Expected:**

```
ANTHROPIC_API_KEY=proxy-managed
```

✅ The sandbox holds only a **sentinel**. The real key lives on the host and is injected by the proxy per request - the allowed call in Step 5 succeeded *without* the key ever entering the box. A prompt injection or a leaky log has nothing usable to exfiltrate. *(**Credential Isolation**)*

Exit the sandbox before the last attack:

```bash
exit
```

## Step 7 - Attack 4 blocked: no path to an unapproved tool server

The final move: reach a tool server the org never approved - a rogue MCP backend that could read the repo or call out. Governance closes this two ways, and you can prove both.

### 7a - The agent only ever sees the governed gateway

With the `mcp` subtree enabled (`SBX_MCP_URL` from **MCP Hands-On**), launch a sandbox with your **approved** server attached:

```bash
sbx run claude --static-mcp local-wiki
```

Inside the agent, run `/mcp`:

```
Manage MCP servers
1 server
  mcp-gateway · ✔ connected · 24 tools
```

✅ Exactly **one** endpoint - the `mcp-gateway`. Every backend is aggregated *behind* it; the agent has no affordance to open a direct socket to an arbitrary server. Whatever it calls flows through the gateway, where policy and audit apply. *(**MCP Hands-On**)*

### 7b - A tool outside the allow-list is denied

The Cedar policy from **MCP Hands-On** permits exactly one tool - `get_me` on `github-official`. Because MCP governance is **default-deny**, an invocation of *any* other server or tool is refused at the gateway. Point `sbx` at the hosted gateway, register a server the policy doesn't allow, and attach it:

```bash
export SBX_MCP_URL=https://gateway.docker.com
sbx daemon stop                                    # restarts on the next sbx call, inheriting the URL
sbx mcp add notion --url https://mcp.notion.com/mcp --skip_auth
sbx run claude --static-mcp notion
```

Inside the agent, ask it to use the server:

```
Use the notion tools to list my recent documents.
```

**Expected:** the agent tries to call a notion tool, but the gateway evaluates the `invoke` against the Cedar allow-list, finds no matching `permit` (only `github-official`/`get_me` is allowed), and **denies** it by default. The agent reports the tool call was blocked by policy; the denial is logged (**Audit Logging**).

✅ The gateway authorizes **every tool call** against the org's Cedar allow-list. Anything outside it - a different tool, a different server - is denied by default and audited, no matter what the developer registers. *(**MCP Hands-On**)*

!!! note
    **7a** proves the single governed endpoint on any gateway. **7b's denial comes from the org's MCP policy**, enforced by the hosted gateway (`gateway.docker.com`) - the same author-once, sync-everywhere control plane as your network and filesystem rules.

Clean up:

```bash
sbx mcp rm notion 2>/dev/null; sbx mcp ls
```

## The governance scorecard

One sandbox, four boundaries, one policy engine. This is the table to put in front of a security team:

| # | Attack the agent tried | Pillar | Where it's enforced | When it fails | Proof you ran |
| --- | --- | --- | --- | --- | --- |
| 1 | Read `~/.ssh`, `~/.aws` off disk | Filesystem | Mount layer, host-side | Sandbox **creation** | `sbx run shell . ~/.ssh:ro` → `403 mount policy denied` |
| 2 | Exfiltrate to `paste.ee` | Network | Egress proxy | Per **request** | `curl https://paste.ee` → `403` (proxy) |
| 3 | Steal `ANTHROPIC_API_KEY` | Credential | Host-side injection | Never held in sandbox | `echo $ANTHROPIC_API_KEY` → `proxy-managed` |
| 4 | Reach an unapproved tool server | MCP | MCP Gateway | Attach / provision time | `/mcp` → one gateway; rogue attach → daemon `allowed:false` |

Read the columns together and the model is obvious:

- **Default-deny everywhere.** Attacks 1 and 2 didn't need a rule *naming* the specific target - anything not explicitly allowed is blocked. You don't have to enumerate every threat.
- **Fail-closed timing.** Filesystem fails at *creation*, network at *request*, credential at *injection*, MCP at *registration*. The earlier the boundary, the less the agent ever touches.
- **One source of truth.** All four trace back to policy for `<your-org>` - authored once in the Admin Console or the Governance API, synced to every developer, un-overridable locally.

## What you just demonstrated

You took the exact blast radius the horror-story agent measured in **Why AI Governance** - readable secrets, reachable exfil destinations, a live API key, open tool access - and watched `<your-org>`'s governance close **all four** in a single sandbox, with no per-attack setup. Each boundary is enforced by the same engine, fails closed, and leaves an audit trail (**Audit Logging**).

That is the defensible, end-to-end story: *"Show me an agent doing something dangerous, and I'll show you where the policy stops it - and where the CISO sees it happen."*

Next, the **Observability** and **Audit Logging** sections show these same decisions as a live dashboard and a queryable event stream - the visibility half of the story.
