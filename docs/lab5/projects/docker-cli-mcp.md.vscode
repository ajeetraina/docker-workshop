

![vscode-copilot](images/vscode-copiliot-docker.png)


## Prerequisites

Before we start, make sure you have:

- Docker Desktop 4.41.0+ with the MCP Toolkit Extension installed
- Node.js (v18 or later) for running the frontend
- VS Code (or any IDE of your choice)

## Setting Up the Sample Database

Instead of using an empty Postgres database, let's use a real example with actual data.
We'll use a sample product catalog service:

## Step 1. Clone the sample catalog service

```
git clone https://github.com/ajeetraina/catalog-service-node
cd catalog-service-node
```

## Step 2. Start the backend services (includes Postgres with sample data)

```
docker compose up -d --build
```

This will spin up:


- A Postgres database on port 5432 with sample catalog data
- A Node.js backend service
- Sample data including products, categories, and inventory

Now let's bring up the frontend to see what data we're working with:


## Step 3. Install frontend dependencies

```
npm install
```

## Step 4. Start the development server

```
npm run dev
```

Open your browser to `http://localhost:5173 to see the catalog application.
This gives you a visual understanding of the data structure we'll be querying with Claude.


Hit "Create Product" button and start adding the new items to your Product catalog system.

Perfect! Now we have a realistic database to work with instead of an empty one.


## Step 5. Setting up MCP Toolkit

Open Docker Desktop and navigate to the MCP Toolkit extension.

Enable Docker MCP Server

![docker cli](./images/docker-cli.png)

## Step 6. Configuring the VS Code Extension 

Open `mcp.json` file under .vscode directory and configure the MCP server:

```json
{
  "inputs": [
    // The "inputs" section defines the inputs required for the MCP server configuration.
    {
      "type": "promptString"
    }
  ],
  "servers": {
    // The "servers" section defines the MCP servers you want to use.
    "postgres": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "mcp/postgres",
        "postgresql://postgres:postgres@host.docker.internal:5432/catalog"
      ]
    }
  }
}
```


![vscode](./images/vscode_dockercli.png)

## Step 7. Start chatting with your Docker Desktop

Prompt: "list out all the containers running on my Docker Desktop"

![nginx](./images/nginx-dockercli.png)

## Step 8. Using Docker MCP Toolkit with VS Code

Open `docker-mcp-runtime.json` file under .vscode directory and configure the MCP server:

```json
{
  "inputs": [
    // The "inputs" section defines the inputs required for the MCP server configuration.
    {
      "type": "promptString"
    }
  ],
  "servers": {
    // The "servers" section defines the MCP servers you want to use.
    "MCP_DOCKER": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "alpine/socat",
        "STDIO",
        "TCP:host.docker.internal:8811"
      ]
    }
  }
}
```