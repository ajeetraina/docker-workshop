
## Prerequisites

Before we start, make sure you have:

- Docker Desktop 4.41.0+ with the MCP Toolkit Extension installed
- Node.js (v18 or later) for running the frontend
- Claude Desktop installed
- Basic familiarity with Docker and JavaScript/TypeScript
- Basic SQL knowledge

## Setting Up the Sample Database

Instead of using an empty Postgres database, let's use a real example with actual data. 
We'll use a sample product catalog service:

## Clone the sample catalog service

```
git clone https://github.com/ajeetraina/catalog-service-node
cd catalog-service-node
```

## Start the backend services (includes Postgres with sample data)

```
docker compose up -d --build
```

This will spin up:


- A Postgres database on port 5432 with sample catalog data
- A Node.js backend service
- Sample data including products, categories, and inventory

Now let's bring up the frontend to see what data we're working with:

```
# Install frontend dependencies
npm install

# Start the development server
npm run dev
```

Open your browser to `http://localhost:5173 to see the catalog application. 
This gives you a visual understanding of the data structure we'll be querying with Claude.


Hit "Create Product" button and start adding the new items to your Product catalog system.

Perfect! Now we have a realistic database to work with instead of an empty one.
