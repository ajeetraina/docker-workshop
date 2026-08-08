# Sandboxing the Agent

```mermaid
flowchart TB
    HUB["Docker Hub Org<br/>network + filesystem policy"]
    subgraph HOST["Host machine"]
        DAEMON["sbx daemon<br/>network proxy + policy (cached)<br/>injects real key"]
        WORK["~/workdemo (on host)"]
        SECRETS["~/.ssh · ~/.aws · ~/.docker<br/>NOT mounted"]
        KEY["OS keychain<br/>real API key"]
        subgraph VM["MicroVM (sandbox)"]
            AGENT["Agent<br/>ANTHROPIC_API_KEY = proxy-managed"]
            WS["workspace ~/workdemo<br/>(mounted)"]
            AGENT --- WS
        end
    end
    HUB -. "policy synced at docker login" .-> DAEMON
    WORK == "mount" ==> WS
    AGENT -. "cannot reach" .-> SECRETS
    AGENT -- "API calls" --> DAEMON
    KEY --> DAEMON
    DAEMON -- "real key on the wire" --> ANTHROPIC["api.anthropic.com"]

    classDef hub fill:#eef2ff,stroke:#6366f1,color:#000
    classDef vm fill:#ecfdf5,stroke:#10b981,color:#000
    classDef pol fill:#fff7ed,stroke:#f59e0b,color:#000
    classDef deny fill:#fef2f2,stroke:#ef4444,color:#000
    classDef key fill:#f3e8fd,stroke:#9333ea,color:#000
    class HUB hub
    class AGENT,WS vm
    class DAEMON pol
    class SECRETS deny
    class KEY,ANTHROPIC,WORK key
```

*Same agent, now inside a MicroVM. Only `~/workdemo` is mounted, the credential dirs never enter the box, and the API key it uses is a sentinel — the real key stays on the host and is injected at the proxy.*

The Problem Statement showed an agent reaching straight into your secrets. 
The fix is to stop running it on bare metal and run it inside a **sandbox** ~ an isolated MicroVM where the agent only sees the directory you hand it, never touches the rest of your host, and never holds your real API key.

This section gets `sbx` ready, wires up your agent, and runs it sandboxed. (Install and `docker login` were covered in **Setup**.)

**Time:** ~10 minutes

**Prerequisites:** **Setup** (sbx installed, logged in).

## Step 1 - Confirm sbx is ready

Every exercise from here depends on `sbx` running on your host. **Do not skip this.**

```bash
sbx version
```

Expected: a version string like `sbx 0.32.x`. If it's missing, jump back to **Setup** and install it.

Make sure you're logged in so org policy and secrets are available:

```bash
sbx login
```

Complete the on-screen prompts if needed.

## Step 2 - Set up your agent

This lab works with any mainstream coding agent. Pick the provider whose API key you have — the rest of the section adapts to your choice.

=== "Anthropic + Claude"

    ### Anthropic configuration

    You'll run **Claude Code** inside the sandbox, authenticated to Anthropic. Store your API key:

    ```bash
    sbx secret set -g anthropic
    ```

=== "OpenAI + Codex"

    ### OpenAI configuration

    You'll run **Codex** inside the sandbox, authenticated to OpenAI. Store your API key:

    ```bash
    sbx secret set -g openai
    ```

=== "Google + Gemini"

    ### Gemini configuration

    You'll run **Gemini CLI** inside the sandbox, authenticated to Google. Store your API key:

    ```bash
    sbx secret set -g google
    ```

Verify the secret was stored (the value is masked):

```bash
sbx secret ls
```

You should see a line for your provider with the value shown as `****…****`.

!!! warning "Important"
    Secrets live in your **OS keychain** and are injected at the network proxy — *after* the request leaves the sandbox. The agent inside never sees the raw API key. That's the credential-isolation guarantee, covered in depth in the **Credential Isolation** section.

## Step 3 - Run the agent, sandboxed

Now the usage. Create a workspace and launch your agent **inside** a sandbox:

```bash
mkdir -p ~/workdemo && cd ~/workdemo
sbx run <agent> .
```

You land in the agent, same as on the host in the Problem Statement — but now it's inside a MicroVM that only mounted *this* directory. Ask it the same question:

```
Search the host for API keys, cloud credentials, and SSH private keys —
check ~/.aws, ~/.ssh, ~/.docker, and any .env files. Show me what you found.
```

This time it comes up **empty**. Your `~/.ssh`, `~/.aws`, and `~/.docker` were never mounted into the sandbox, so they don't exist inside it — and even the API key the agent *uses* is only a sentinel, with the real value injected on the wire outside. The blast radius from the Problem Statement is gone.

!!! note
    Here the agent can't reach those paths simply because the sandbox didn't mount them. The **Network Enforcement Demo** and **Filesystem Enforcement Demo** add the next layer — **org policy** that governs which paths and hosts *any* sandbox may touch, enforced for every developer, including the workspace you *do* mount.

## What you've set up

- `sbx` verified and logged in
- Your provider's key stored as a governed secret (keychain, never in the sandbox)
- Your agent running inside an isolated sandbox instead of on bare metal

That's the shift: from an agent that runs *as you* to one that runs *inside a boundary*. What decides how wide that boundary is — which paths, which hosts, which tools — is **policy**. Next, **The Policy Model** shows how those policies are authored once and reach every developer.
