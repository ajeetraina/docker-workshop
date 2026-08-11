# Why AI Governance

```mermaid
flowchart LR
    ADMIN["Docker Hub Org<br/>define policy once"]
    subgraph PILLARS["Three pillars"]
        P1["1 · Sandbox policies"]
        P2["2 · MCP tool governance"]
        P3["3 · Audit + visibility"]
    end
    ADMIN --> PILLARS --> AGENT["AI agent<br/>contained by policy"]

    classDef admin fill:#eef2ff,stroke:#6366f1,color:#000
    classDef pillar fill:#fff7ed,stroke:#f59e0b,color:#000
    classDef agent fill:#ecfdf5,stroke:#10b981,color:#000
    class ADMIN admin
    class P1,P2,P3 pillar
    class AGENT agent
```

*The concept: define policy once in the Docker Hub org, and three pillars keep the agent inside the guardrails. This lab focuses on Pillar 1.*

AI agents such as Claude, Copilot, Cursor, custom MCP servers run with the same blast radius as the developer running them. That means access to your filesystem, your secrets, your network, your everything.

This is fine when the agent does what you expect. It's a disaster when:

- A prompt-injected agent uploads SSH keys to `paste.ee`
- A misconfigured MCP server exfiltrates source code to an unknown destination
- An agent acting on hallucinated instructions pushes a malicious commit to `main`
- A coding agent reads your `.env` and posts it to the model API alongside your code

The standard answer ~ **"don't let agents do that"** doesn't scale. Developers want agents. 
They'll find a way. The right answer is to put guardrails around the agent's execution environment so it physically *cannot* exceed its scope.

That's AI governance.


<img width="1261" height="638" alt="image" src="https://github.com/user-attachments/assets/072758ac-f40d-44b0-b169-c520b340131e" />

## The three pillars

Docker AI Governance gives you three layers of control, defined once in the Admin Console and enforced everywhere agents run.

### 1. Sandbox policies
Network allowlists, filesystem mount rules, resource limits. Enforced at the proxy and mount layer. The agent never sees data or destinations it isn't allowed to touch. The same sandbox boundary also isolates **credentials** - the real API keys and tokens the agent uses stay on the host and are injected per request, so the agent never holds a live secret.

### 2. MCP tool governance
Which MCP servers and tools your org's agents can use. Defined centrally, enforced for every developer, audited.

### 3. Audit + visibility
Every policy decision generates a structured event with user identity, timestamp, session context, and triggering rule. Exports to your SIEM. CISOs get the trail.

## What this lab covers

| Section | What you'll do |
| --- | --- |
| The Problem Statement | Watch an unsandboxed agent read your secrets first-hand |
| Sandboxing the Agent | Put the agent inside an isolated sandbox and re-run — the secrets vanish |
| The Policy Model | Understand how org policies flow to developer machines |
| Network Enforcement Demo | Prove network policies enforce with three `curl`s |
| Filesystem Enforcement Demo | Prove filesystem policies enforce on a credentials directory |
| Credential Isolation | Prove the real API keys never enter the sandbox |
| Sandbox Kits | Package a reproducible, compliant sandbox as a declarative kit - governance as code |
| Putting It All Together | **The capstone** - stop one rogue agent's four attacks in a single sandbox, then read the CISO scorecard |
| What's Next | Preview audit trails and MCP governance |

The lab focuses on **Pillar 1 (sandbox policies)** because that's what's broadly available today and what you can prove enforces in a 20-minute demo. Pillars 2 and 3 are previewed in **What's Next**.

By the end you'll have a working, defensible enforcement story you can walk a security team through.
