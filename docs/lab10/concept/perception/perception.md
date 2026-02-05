
Perception is **how the agent sees its environment**. An agent without toolsets is blind — it can only use training data. Each toolset you add is a new sensor.

## Step 1: Create a project with multiple "perception sources"

```bash
mkdir ~/perception-test && cd ~/perception-test

# Source 1: A config file with a problem
cat > config.json << 'EOF'
{
  "app_name": "MyApp",
  "version": "2.1.0",
  "database": {
    "host": "localhost",
    "port": 5432,
    "password": "admin123"
  },
  "debug": true,
  "api_key": "sk-1234567890abcdef"
}
EOF

# Source 2: A deployment script
cat > deploy.sh << 'EOF'
#!/bin/bash
echo "Deploying MyApp..."
docker run -e DB_PASSWORD=admin123 -e API_KEY=sk-1234567890abcdef myapp:latest
echo "Deploy complete"
EOF

# Source 3: A README with context
cat > README.md << 'EOF'
# MyApp
Production-ready application. 
Ensure no secrets are hardcoded before deploying.
Run security checks before every release.
EOF
```

## Step 2: Create agent with MULTIPLE perception layers

```yaml
# perception.yaml
version: "2"

agents:
  root:
    model: openai/gpt-5-mini
    description: Security auditor with multi-layer perception
    instruction: |
      You are a security auditor. You can perceive the environment through:
      
      1. FILESYSTEM perception - Read all files in the current directory
      2. SHELL perception - Run commands like `grep`, `find`, `cat` to scan
      3. WEB perception - Search for latest security best practices
      
      Audit this project for security issues. Use ALL your senses:
      - Read every file to find hardcoded secrets
      - Run shell commands to scan for patterns like passwords, API keys
      - Search the web for current best practices on secret management
      
      Report what you found using each perception method.
    toolsets:
      - type: filesystem
      - type: shell
      - type: mcp
        ref: docker:duckduckgo
```

## Step 3: Run it

```bash
export OPENAI_API_KEY=<your_key>
cagent run ./perception.yaml
```

Then type:

```
Audit this project for security issues. Use filesystem, shell, and web search.
```

## What you should see

```
✓ Read    config.json           ← FILESYSTEM perception (sees the file contents)
✓ Read    deploy.sh             ← FILESYSTEM perception (sees hardcoded secrets)
✓ Read    README.md             ← FILESYSTEM perception (sees project context)
✓ Shell   grep -r "password" .  ← SHELL perception (scans for patterns)
✓ Shell   grep -r "api_key" .   ← SHELL perception (finds exposed keys)
✓ Search  "secret management best practices 2025"  ← WEB perception (sees the internet)
```

## Key Teaching Point

| Toolset | What it "sees" | Analogy |
|---|---|---|
| `filesystem` | Files, code, configs | 👁 **Eyes** — reading documents |
| `shell` | System state, grep output, process info | 👂 **Ears** — listening to the system |
| `mcp: duckduckgo` | Live web, latest best practices | 📡 **Radar** — sensing the outside world |

**Remove a toolset = the agent goes partially blind.** Try removing the `mcp: duckduckgo` line and running again — the agent can no longer search the web. That's the proof that each toolset is literally a perception channel.

## Bonus: Prove perception matters

Create a version with NO toolsets:

```yaml
# blind-agent.yaml
version: "2"

agents:
  root:
    model: openai/gpt-5-mini
    description: Security auditor with NO perception
    instruction: |
      Audit this project for security issues.
    # No toolsets = no perception = blind agent
```

Run it and compare — the blind agent can only give generic advice. It cannot actually see your code. That's the difference between a chatbot and an agent.
