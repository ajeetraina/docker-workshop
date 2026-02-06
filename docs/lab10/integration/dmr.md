## cagent with Docker Model Runner

Docker Model Runner lets you run AI models locally on your machine. No API keys, no recurring costs, and your data stays private.

Docker Model Runner can run any compatible model. Models can come from:

- Docker Hub repositories (docker.io/namespace/model-name)
- Your own OCI artifacts packaged and pushed to any registry
- HuggingFace models directly (hf.co/org/model-name)
- The Docker Model catalog in Docker Desktop

## Getting Started

- Enable Docker Model Runner in Settings > AI > Enable Docker Model Runner
- Docker Engine (Linux) - Install with `sudo apt-get install docker-model-plugin` or `sudo dnf install docker-model-plugin`.

### 1. Pull AI Model using DMR

```
docker model pull ai/llama3.2:1B-Q8_0
```

### 2. To see models available to the local Docker catalog, run:

```
docker model list --openai
{
    "object": "list",
    "data": [
        {
            "id": "docker.io/ai/llama3.2:1B-Q8_0",
            "object": "model",
            "created": 1742911288,
            "owned_by": "docker"
        }
    ]
}
```

To use a model, reference it in your configuration. DMR automatically pulls models on first use if they're not already local.

### 3. Configure your agent to use Docker Model Runner with the dmr provider

```
agents:
  root:
    model: dmr/ai/llama3.2:1B-Q8_0
    instruction: You are a helpful assistant
    toolsets:
      - type: filesystem
```

### 4. Run the agent

```
cagent run dmr.yaml
```

Type a prompt stating "Hello. What you can do for me?"

When you first run your agent, cagent prompts you to pull the model if it's not already available locally.

### 5. verify if requests are logged in using Docker Dashboard

<img width="967" height="424" alt="image" src="https://github.com/user-attachments/assets/637aca84-2784-4b46-b97c-eb5dd93a6690" />

### How it works

When you configure an agent to use DMR, cagent automatically connects to your local Docker Model Runner and routes inference requests to it. 
If a model isn't available locally, cagent prompts you to pull it on first use. No API keys or authentication are required.
