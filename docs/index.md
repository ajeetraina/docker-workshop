# Welcome to Docker Workshop

A hands-on, workshop covering the full Docker developer experience - from inner-loop workflows and containerization basics all the way to AI agents, MCP servers, security hardening, and Sandboxing.


## 🗺️ What's Covered

Pick any track and go - each card links to that track's starting point.

### 🐳 Docker Fundamentals

<div class="grid cards" markdown>

-   🐳 __Docker 101__

    ---

    Core container concepts and a real-world sample app - inner vs outer loop, running Postgres, and the Product Catalog develop → test → build → secure flow.

    [Start →](lab1/overview/)

-   ☸️ __Kubernetes 101__

    ---

    Deploy a real app to a live cluster and learn the building blocks hands-on - Pods, Deployments, Services, scaling, rolling updates, and Ingress.

    [Start →](kubernetes-101/overview/)

</div>

---

### 🧠 Docker & AI

Run models locally, wire them to tools via MCP, build agents, and safely sandbox AI-generated actions - all inside Docker.

<div class="grid cards" markdown>

-   🤖 __Docker Agent__

    ---

    Build, run, and share AI agents with Docker's declarative multi-agent runtime - concepts, built-in tools, MCP/DMR/RAG integrations, and projects.

    [Start →](lab10/overview/)

-   🚀 __Docker Model Runner__

    ---

    Run LLMs locally inside Docker - no cloud required, GPU-accelerated inference out of the box.

    [Start →](lab4/overview/)

-   🔌 __MCP Catalog & Toolkit__

    ---

    Connect AI models to real tools and services via the Model Context Protocol, managed securely through Docker.

    [Start →](lab5/overview/)

-   🧩 __Agentic Compose__

    ---

    Multi-agent workflows orchestrated with Docker Compose - DevDuck, agentic Product Catalog, and an A2A fact checker.

    [Start →](lab6/overview/)

-   🧪 __Docker Sandboxes__

    ---

    Run AI coding agents in isolated microVMs with the `sbx` CLI - credential proxying, network policy, and governance at scale.

    [Start →](lab8/overview/)

-   ☁️ __Cloud Sandboxes__

    ---

    Scale `sbx` agents onto Docker-managed infrastructure - the same CLI with a `--cloud` flag.

    [Start →](cloud-sandbox/overview/)

-   🛡️ __AI Governance__

    ---

    Enforce policy on agents - network and filesystem controls, MCP guardrails, observability, and sandbox kits.

    [Start →](ai-governance/setup/)

</div>

---

### 🔒 Docker & Security

<div class="grid cards" markdown>

-   🧱 __Container Security__

    ---

    Harden images with best practices - minimal base images, multi-stage builds, non-root users, read-only filesystems, and secrets handling.

    [Start →](security/container-security/overview/)

-   🔎 __Docker Scout__

    ---

    A reactive approach - continuous scanning, CI integration, and recommendations to fix vulnerabilities.

    [Start →](security/scout-reactive/overview/)

-   🛡️ __Docker Hardened Images__

    ---

    A proactive approach - migrate to DHI, image scanning, compliance, and attestations.

    [Start →](lab9/dhi/overview/)

-   🔗 __Supply Chain with dhictl__

    ---

    Secure the supply chain end-to-end - browse the DHI catalog and migrate to hardened images with `dhictl`.

    [Start →](dhictl/introduction/)

</div>

---

### ⚡ Docker Offload

Offload builds and GPU-intensive workloads to the cloud seamlessly - same Docker commands, cloud execution.

<div class="grid cards" markdown>

-   ⚡ __Overview & Getting Started__

    ---

    Enable Docker Offload, start a session, and run GPU workloads on cloud infrastructure.

    [Start →](lab7/overview/)

-   ☁️ __Cloud Sandboxes Workshop__

    ---

    Master the cloud sandbox lifecycle hands-on - sizing, idle timeout, TTL, stop/resume/delete, multi-machine workflows, and cost control.

    [Start →](lab7/cloud-sandboxes/overview/)

</div>

---

## 🗓️ Suggested Learning Paths

This workshop is **self-paced and modular** - pick any topic and go. Here are a few suggested paths based on your goals:

| Goal | Suggested Topics |
| --- | --- |
| 🐣 New to Docker | Docker 101 → Product Catalog |
| 🤖 Build AI Apps | Docker Model Runner → Docker MCP → Docker Agent → Agentic Compose |
| 🔐 Focus on Security | Docker 101 → Docker and Security (DHI) |
| 🧠 Multi-Agent Systems | Docker Agent → Agentic Compose → Docker MCP |
| ⚡ GPU & Cloud Offload | Docker Model Runner → Docker Offload |
| 🔒 Safe AI Execution | Docker Model Runner → Sandboxing with Docker |
