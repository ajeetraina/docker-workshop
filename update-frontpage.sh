#!/usr/bin/env bash
# =============================================================================
# update-frontpage.sh — Improve docker-workshop frontpage (docs/index.md)
# Run from INSIDE the docker-workshop directory:
#   cd ~/work/docker-workshop
#   bash update-frontpage.sh
# =============================================================================

set -euo pipefail

if [ ! -f "mkdocs.yml" ]; then
  echo "❌  Run this from inside docker-workshop (mkdocs.yml not found)"
  exit 1
fi

echo "✅  Writing improved docs/index.md..."

cat > docs/index.md << 'FRONTPAGE'
# Welcome to Docker Workshop

A hands-on, 3-hour workshop covering the full Docker developer experience — from inner-loop workflows and containerization basics all the way to AI agents, MCP servers, security hardening, and GPU offloading.

**Presented by [Ajeet Singh Raina](https://www.linkedin.com/in/ajeetsraina/)** — Docker Captain & DevRel @ [Docker](https://docker.com)
· [GitHub Source](https://github.com/ajeetraina/docker-workshop)

---

## 🗺️ What's Covered

### 🐳 Docker 101

Get comfortable with core Docker concepts and a real-world sample app.

| Topic | Link |
|-------|------|
| Inner vs Outer Loop Development | [Start →](lab1/overview/) |
| What is a Container | [Start →](lab1/what-is-a-container/) |
| Running Postgres Containers | [Start →](lab1/postgres/) |
| Product Catalog — Overview | [Start →](product-catalog/overview/) |
| Product Catalog — Tech Stack | [Start →](product-catalog/tech-stack/) |
| Product Catalog — Develop | [Start →](product-catalog/develop/) |
| Product Catalog — Test | [Start →](product-catalog/test/) |
| Product Catalog — Build | [Start →](product-catalog/build/) |
| Product Catalog — Secure | [Start →](product-catalog/secure/) |

---

### 🤖 Docker Agent

Build, run, and share AI agents using Docker's declarative multi-agent runtime.

| Topic | Link |
|-------|------|
| Overview | [Start →](lab10/overview/) |
| Getting Started | [Start →](lab10/getting-started/) |
| **Concepts** | |
| Autonomy | [Start →](lab10/concept/autonomy/autonomy/) |
| Perception | [Start →](lab10/concept/perception/perception/) |
| Reasoning | [Start →](lab10/concept/reasoning/reasoning/) |
| Action | [Start →](lab10/concept/action/action/) |
| Goal-oriented | [Start →](lab10/concept/goal/goal/) |
| **Built-in Tools** | |
| memory | [Start →](lab10/tools/memory/) |
| think | [Start →](lab10/tools/think/) |
| todo | [Start →](lab10/tools/todo/) |
| shell | [Start →](lab10/tools/shell/) |
| filesystem | [Start →](lab10/tools/filesystem/) |
| environment | [Start →](lab10/tools/environment/) |
| **Integrations** | |
| Docker Agent with MCP | [Start →](lab10/integration/mcp/) |
| Docker Agent with Docker Model Runner | [Start →](lab10/integration/dmr/) |
| Docker Agent with RAG | [Start →](lab10/integration/rag/) |
| **Projects** | |
| A Simple Pirate Agent | [Start →](lab10/projects/pirate/) |
| Learning Agent with Alloy Models | [Start →](lab10/projects/alloy/) |
| Developer Agent with Tools | [Start →](lab10/projects/dev/) |
| Financial Analysis Team | [Start →](lab10/projects/financial/) |
| Docker Expert Team | [Start →](lab10/projects/docker-expert/) |
| Bug Investigator | [Start →](lab10/projects/bug-investigator/bug-investigator/) |
| Auto Curator Agent | [Start →](lab10/projects/auto-curator-agent/auto-curator-agent/) |
| Sharing Agents | [Start →](lab10/sharing/) |

---

### 🧠 Docker Model Runner

Run AI models locally inside Docker — no cloud required.

| Topic | Link |
|-------|------|
| Overview | [Start →](lab4/overview/) |
| Getting Started | [Start →](lab4/getting-started/) |
| Product Catalog Chatbot | [Start →](lab4/projects/catalog-chatbot/) |
| GenAI Chatbot | [Start →](lab4/projects/genai-chatbot/) |

---

### 🔌 MCP Catalog and Toolkit

Connect AI models to real tools via the Model Context Protocol.

| Topic | Link |
|-------|------|
| Overview | [Start →](lab5/overview/) |
| Getting Started | [Start →](lab5/getting-started/) |
| Visual Chatbot | [Start →](lab5/projects/visual-chatbot/visual-chatbot/) |
| Running your First MCP Server | [Start →](lab5/projects/visual-chatbot/mcp/) |
| GitHub MCP Server and Claude Desktop | [Start →](lab5/projects/GitHub-Claude/) |
| Docker MCP Server and Gordon | [Start →](lab5/projects/Docker-CLI-With-Gordon/) |
| Docker MCP Server and VS Code | [Start →](lab5/projects/Docker-MCP-With-VSCode/) |
| GitHub MCP Server and Gordon | [Start →](lab5/projects/GitHub-MCP-Gordon/) |
| Kubernetes MCP Server and Claude | [Start →](lab5/projects/Kubernetes-MCP/) |
| Slack MCP Server and Claude | [Start →](lab5/projects/Slack-MCP-With-Claude/) |

---

### 🧩 Agentic Compose

Multi-agent workflows orchestrated with Docker Compose.

| Topic | Link |
|-------|------|
| Overview | [Start →](lab6/overview/) |
| Getting Started | [Start →](lab6/getting-started/) |
| DevDuck — Overview | [Start →](lab6/projects/devduck/overview/) |
| DevDuck — Prerequisite | [Start →](lab6/projects/devduck/prereq/) |
| DevDuck — Getting Started | [Start →](lab6/projects/devduck/getting-started/) |
| DevDuck — Local Agent Interaction | [Start →](lab6/projects/devduck/local-agent/) |
| DevDuck — Cerebras Interaction | [Start →](lab6/projects/devduck/cerebras-interaction/) |
| Agentic Product Catalog | [Start →](lab6/projects/agentic-catalog/) |
| Hackathon Recommender | [Start →](lab6/projects/hackathon-recommender/) |
| A2A Multi-Agent Fact Checker | [Start →](lab6/projects/a2a-multi-agent-fact-checker/) |

---

### 🔒 Docker and Security

Harden your images and meet compliance requirements with Docker Hardened Images.

| Topic | Link |
|-------|------|
| Overview | [Start →](lab9/dhi/overview/) |
| Getting Started | [Start →](lab9/dhi/getting-started/) |
| Image Scanning | [Start →](lab9/dhi/image-scanning/) |
| Switch to DHI | [Start →](lab9/dhi/switch-to-dhi/) |
| Compliance & Attestations | [Start →](lab9/dhi/compliance/) |

---

### 🧪 Docker Sandboxes

AI-powered browser testing with Playwright inside Docker.

| Topic | Link |
|-------|------|
| Overview | [Start →](lab8/overview/) |
| Getting Started | [Start →](lab8/getting-started/) |
| Playwright Browser Testing | [Start →](lab8/projects/playwright-browser-testing/) |

---

### ⚡ Docker Offload

Offload GPU-intensive workloads to the cloud seamlessly.

| Topic | Link |
|-------|------|
| Overview | [Start →](lab7/overview/) |
| Getting Started | [Start →](lab7/getting-started/) |

---

## ⏱️ Workshop Structure

This is a 3-hour hands-on workshop. Here's the recommended flow:

| Time | Section |
|------|---------|
| 0:00 – 0:30 | Docker 101 — Containers, inner loop, Postgres |
| 0:30 – 1:00 | Docker Model Runner — Run AI locally |
| 1:00 – 1:30 | MCP Catalog — Connect models to tools |
| 1:30 – 2:00 | Docker Agent — Build multi-agent systems |
| 2:00 – 2:30 | Agentic Compose — Orchestrate agent teams |
| 2:30 – 3:00 | Security (DHI) + Docker Offload |
FRONTPAGE

echo "✅  docs/index.md updated"

git add docs/index.md
git commit -m "feat: improve frontpage with full lab coverage table

- Add all 8 sections: Docker 101, Docker Agent, Model Runner,
  MCP Toolkit, Agentic Compose, Security, Sandboxes, Offload
- Each section lists every topic with direct links
- Added workshop timing guide"

echo ""
echo "✅  Committed. Run: git push origin main"
