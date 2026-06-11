![stars](https://img.shields.io/github/stars/ajeetraina/docker-workshop)
![Twitter](https://img.shields.io/twitter/follow/ajeetsraina?style=social)

# Welcome to the Docker Workshop

A hands-on workshop covering modern Docker development — from inner-loop workflows and containerizing apps to building AI agents, securing the software supply chain, and running on Kubernetes. Each track mixes short theory with practical, copy-paste-ready exercises.

👉 **[Access the Workshop Here!](https://dockerworkshop.vercel.app/)**

## What you'll learn

- Build, run, test, and debug containerized apps directly in your IDE without altering your local environment.
- Develop and run AI agents and GenAI apps locally with Docker Model Runner, the MCP Catalog & Toolkit, and Agentic Compose.
- Govern and sandbox AI agents safely, and secure your images and supply chain.
- Take your applications from Compose to Kubernetes.

## Workshop tracks

### Docker 101
- **Inner-Loop Development Workflow** — Inner vs. outer loop, what is a container, running Postgres containers.
- **Product Catalog (Sample Demo App)** — Overview, tech stack, develop, test, build, and secure.

### Docker and AI
- **Docker Agent** — Concepts (autonomy, perception, reasoning, action, goal-oriented), tools (memory, think, todo, shell, filesystem, environment), integrations (MCP, Docker Model Runner, RAG), single- and multi-agent projects, and sharing agents.
- **Docker Model Runner** — Getting started, plus Product Catalog Chatbot and GenAI Chatbot projects.
- **MCP Catalog and Toolkit** — Run your first MCP server; integrate GitHub, Docker, Kubernetes, and Slack MCP servers with Claude Desktop, Gordon, and VS Code.
- **Agentic Compose** — DevDuck (local + Cerebras agents), Agentic Product Catalog, Hackathon Recommender, and an A2A Multi-Agent Fact Checker.
- **Docker Sandboxes** — Why agents need governance, your first sandbox, the isolation proof, reviewing agent changes, secrets, network policy, branch mode, parallel agents, running open-source models, governance at scale, and the DevBoard project.
- **AI Governance** — The policy model, network and filesystem enforcement demos, MCP hands-on, observability, and Sandbox Kits (mixin kits, network & credentials, forking agent kits, stacking & community kits).

### Docker and Security
- **Container Security** — Best practices: minimal base images, multi-stage builds, non-root user, read-only + dropped capabilities, secrets, and limiting tools.
- **Docker Scout (Reactive)** — Continuous scanning, CI integration, recommendations & comparisons.
- **DHI (Proactive)** — Migrating to DHI, attestations & scanner integration.
- **Docker Hardened Images (Reference)** — Getting started, image scanning, switching to DHI, compliance & attestations.
- **Securing the Supply Chain with dhictl** — Meet the Product Catalog, introducing vulnerabilities, browsing the DHI catalog, migrating to a hardened image, and dhictl capabilities.

### Docker Offload
- Getting started with offloading builds and workloads.

### Kubernetes 101
- Your cluster, Pods, Deployments, Services, scaling & rolling updates, Ingress, plus bonus tracks on Compose Bridge and running GenAI on Kubernetes.

## Running the Lab locally

This site is built with [MkDocs](https://www.mkdocs.org/) + the Material theme.

### Using Docker Compose (recommended)

Bring the docs site up with live reload powered by [Compose Watch](https://docs.docker.com/compose/how-tos/file-watch/):

```bash
docker compose up --watch
```

Then open <http://localhost:8000>. Edits to anything under `docs/` or to `mkdocs.yml` sync into the container and the MkDocs dev server reloads automatically. Changes to `requirements.txt` trigger an image rebuild.

### Using Docker directly

```bash
docker build -t docker-workshop:1.0 .
docker run -d -p 8000:8000 docker-workshop:1.0
```

Open <http://localhost:8000>.

### Without Docker

```bash
pip install -r requirements.txt
mkdocs serve
```

## Contribution Guidelines

We welcome contributions to improve this workshop. Content lives under `docs/`, and the navigation is defined in `mkdocs.yml`. Please open a pull request with your changes.

## License

Licensed under the [MIT License](LICENSE).
