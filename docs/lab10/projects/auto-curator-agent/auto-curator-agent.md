# 🤖 Auto-Curator Agent - Self-Maintaining Awesome List

A multi-agent system built with Docker cagent that **maintains itself** — it discovers new Docker cagent resources, validates links, and submits PRs to keep the [awesome-docker-cagent](https://github.com/collabnix/awesome-docker-cagent) list fresh.

## 🎯 What You'll Learn

1. Build a 4-agent system with specialized roles (Curator, Discoverer, Validator, Publisher)
2. Configure GitHub Models as a free LLM provider for cagent
3. Use custom providers via the `providers:` YAML section
4. Integrate MCP tools (GitHub, DuckDuckGo, Fetch)
5. Work with cagent skills for domain-specific knowledge
6. Handle token limits when using free-tier APIs

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      CURATOR (Root)                             │
│                                                                 │
│  • Coordinates all maintenance tasks                           │
│  • Formats entries using awesome-list table syntax             │
│  • Decides what to add, update, or remove                      │
└─────────────────────┬───────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
┌───────────────┐ ┌───────────┐ ┌───────────┐
│  DISCOVERER   │ │ VALIDATOR │ │ PUBLISHER  │
│               │ │           │ │            │
│ • Web search  │ │ • Check   │ │ • Create   │
│ • GitHub API  │ │   URLs    │ │   branches │
│ • Find repos  │ │ • Quality │ │ • Update   │
│ • Find blogs  │ │   scoring │ │   README   │
│               │ │ • Freshness│ │ • Open PRs │
└───────────────┘ └───────────┘ └───────────┘
      │                 │             │
      ▼                 ▼             ▼
┌───────────┐    ┌───────────┐  ┌──────────┐
│ DuckDuckGo│    │   Fetch   │  │  GitHub  │
│    MCP    │    │   Tool    │  │   MCP    │
└───────────┘    └───────────┘  └──────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker Desktop 4.49+ (includes cagent)
- GitHub Personal Access Token with `repo` + `models:read` permissions

### Step 1: Set Up Your GitHub Token

Create a fine-grained PAT at [github.com/settings/personal-access-tokens](https://github.com/settings/personal-access-tokens) with:

| Permission | Scope | Why |
|-----------|-------|-----|
| `repo` | Repository | Read/write awesome-list repo, create branches and PRs |
| `models:read` | Account | Access GitHub Models API for LLM inference |

```bash
export GITHUB_TOKEN=your_github_pat
```

### Step 2: Clone and Run

```bash
git clone https://github.com/ajeetraina/docker-workshop
cd docker-workshop/docs/lab10/projects/auto-curator-agent/

# Run the lite version (recommended for GitHub Models free tier)
cagent run ./cagent-curator-lite.yaml "Find new cagent blog posts"
```

## ⚡ Two Configs: Full vs Lite

| | `cagent-curator.yaml` (Full) | `cagent-curator-lite.yaml` (Lite) |
|---|---|---|
| **Skills** | ✅ 3 skill files loaded | ❌ Disabled (saves ~2,500 tokens) |
| **Instructions** | Detailed with examples | Condensed essentials |
| **Sub-agent model** | gpt-4o (smart) | gpt-4o-mini (fast) |
| **Token budget** | ~4,500+ tokens overhead | ~1,500 tokens overhead |
| **Best for** | Paid GitHub Models / other providers | GitHub Models **free tier** |

!!! warning "GitHub Models Free Tier Token Limit"
    GitHub Models free tier limits gpt-4o to **8,000 input tokens per request**.
    Skills + detailed instructions + fetched content can easily exceed this.
    Use the **lite** version unless you have paid GitHub Models or another provider.

## 📋 Usage Examples

### Discover New Resources

```bash
# Basic discovery
cagent run ./cagent-curator-lite.yaml "Find new Docker cagent blog posts published this week"

# Specific and targeted (recommended)
cagent run ./cagent-curator-lite.yaml "Search for blog posts that specifically mention \
  'cagent' the Docker multi-agent runtime tool. Only include posts that discuss \
  cagent YAML configs, cagent run commands, or multi-agent orchestration. \
  Exclude generic Docker or Docker Model Runner posts."

# With deduplication against existing list
cagent run ./cagent-curator-lite.yaml "Read the current README from \
  collabnix/awesome-docker-cagent, then search for new blog posts about \
  Docker cagent that are NOT already in the list."
```

### Validate Existing Links

```bash
cagent run ./cagent-curator-lite.yaml "Read the awesome-docker-cagent README \
  and check all URLs for broken links"
```

### Submit Updates via PR

```bash
cagent run ./cagent-curator-lite.yaml "Find new cagent resources, validate them, \
  and create a PR adding them to the awesome list"
```

## 🔧 Configuration Deep Dive

### GitHub Models as a Custom Provider

There is **no built-in `github` provider** in cagent. We define one using the `providers:` section:

```yaml
providers:
  github:
    api_type: openai_chatcompletions
    base_url: https://models.github.ai/inference
    token_key: GITHUB_TOKEN

models:
  smart:
    provider: github
    model: openai/gpt-4o      # vendor prefix required!
    max_tokens: 4096
  fast:
    provider: github
    model: openai/gpt-4o-mini
    max_tokens: 2048
```

!!! danger "Common Pitfall: Model Name Format"
    GitHub Models requires the **`openai/` vendor prefix** in model names.
    Using just `gpt-4o` results in `403 Forbidden: No access to model: /gpt-4o`.
    Always use `openai/gpt-4o`, `openai/gpt-4o-mini`, etc.

### GitHub Models Free Tier Rate Limits

| Limit | gpt-4o | gpt-4o-mini |
|-------|--------|-------------|
| Input tokens/request | 8,000 | 8,000 |
| Output tokens/request | 4,096 | 4,096 |
| Requests/minute | 10 | 15 |
| Requests/day | 50 | 150 |

## 💡 Prompting Tips

The lite config trades detailed skill instructions for token headroom. **Your prompt quality matters more:**

| ❌ Too Vague | ✅ Specific |
|---|---|
| `"Find new cagent blog posts"` | `"Search for posts that specifically mention 'cagent' the Docker multi-agent runtime. Exclude generic Docker or DMR posts."` |
| `"Check links"` | `"Read the awesome-docker-cagent README and check all URLs in the MCP Servers section for broken links"` |

**Key tips:**

- **Say "cagent" explicitly** — helps distinguish from generic Docker content
- **Mention what to exclude** — "Exclude Docker Model Runner, Claude Code posts"
- **Ask it to read the README first** — enables deduplication
- **One task per prompt** — saves tokens within the 8K limit

## 🐛 Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `403 no_access to model: /gpt-4o` | Missing vendor prefix | Use `openai/gpt-4o` not `gpt-4o` |
| `403 no_access to model: openai/gpt-4o` | Token missing models permission | Add `models:read` to your PAT |
| `413 Request Entity Too Large` | Input exceeds 8K tokens | Switch to `cagent-curator-lite.yaml` |
| `429 Too Many Requests` | Rate limit hit | Wait and retry (10 req/min for gpt-4o) |
| Results include generic Docker posts | Prompt too vague | Be specific — see Prompting Tips above |

## 📦 Skills (Full Version Only)

The full config loads 3 skills from `.claude/skills/`:

| Skill | Purpose |
|-------|----------|
| `awesome-list-format` | Table syntax, section structure, categorization rules |
| `link-validation` | URL checking, GitHub activity monitoring, content freshness |
| `resource-discovery` | Search strategies, quality scoring, deduplication |

## 🔄 Automation with GitHub Actions

```yaml
# .github/workflows/curate.yml
name: Weekly Curation
on:
  schedule:
    - cron: '0 9 * * 1'  # Every Monday at 9am
  workflow_dispatch:

jobs:
  curate:
    runs-on: ubuntu-latest
    steps:
      - uses: docker/cagent-action@v1
        with:
          config: cagent-curator-lite.yaml
          prompt: "Search for blog posts that specifically mention cagent the Docker multi-agent runtime. Read the current README first to avoid duplicates. Create a PR with any new findings."
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## 📦 Push to Docker Hub

```bash
docker login
cagent push ./cagent-curator-lite.yaml docker.io/YOUR_USERNAME/awesome-cagent-curator:latest
```

## 📊 Workshop Flow

```
┌──────────────────────────────────────────────────────────────────┐
│              AUTO-CURATOR AGENT WORKFLOW                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. CONFIGURE          2. DISCOVER          3. PUBLISH           │
│  ───────────          ───────────          ──────────            │
│                                                                  │
│  ┌──────────┐        ┌──────────┐        ┌──────────────┐       │
│  │  GitHub  │        │  Search  │        │   Create PR  │       │
│  │  Models  │───────▶│  + Check │───────▶│   to Update  │       │
│  │  + PAT   │        │  + Score │        │  Awesome List│       │
│  └──────────┘        └──────────┘        └──────────────┘       │
│       │                   │                     │                │
│       ▼                   ▼                     ▼                │
│  Custom provider     DuckDuckGo MCP        GitHub MCP           │
│  via providers:      + Fetch tool          creates branch       │
│  section             validates URLs        + opens PR            │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## 🎓 Key Concepts Covered

| Concept | Description |
|---------|-------------|
| **Custom Providers** | Defining GitHub Models as an OpenAI-compatible provider via `providers:` |
| **Token Budgeting** | Managing free-tier API limits with lite vs full configs |
| **Multi-Agent Coordination** | 4 agents with specialized roles collaborating on a task |
| **MCP Tools** | GitHub, DuckDuckGo, and Fetch tools via Model Context Protocol |
| **cagent Skills** | Domain-specific knowledge loaded from `.claude/skills/` |
| **Vendor Prefixes** | GitHub Models requires `openai/gpt-4o` format |
| **Self-Maintaining Systems** | Agents that keep a community resource list up to date |
