

![vscode-copilot](images/gordon-dockercli.png)


## Prerequisites

Before we start, make sure you have:

- Docker Desktop 4.41.0+ with the MCP Toolkit Extension installed
- Node.js (v18 or later) for running the frontend


## Setting Up the Sample Database

Instead of using an empty Postgres database, let's use a real example with actual data.
We'll use a sample product catalog service:

## Step 1. Clone the sample catalog service

```
git clone https://github.com/dockersamples/catalog-service-node
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



## Step 7. Start chatting with your Docker Desktop

## Prompt 1: 

"List out all the containers running on my Docker Desktop"

![gordoncli](./images/gordon-cli.png)

## Prompt 2:

"Create a new nginx container with the name 'my-nginx' and run it on port 87"


![gordoncli2](./images//gordon-cli2.png)

## Containerising the application

```
git clone https://github.com/dockersamples/docker-init-demos
cd docker-init-demos/python
```

## Prompt 3:


```
docker ai "can you containerise this application for me"
```
