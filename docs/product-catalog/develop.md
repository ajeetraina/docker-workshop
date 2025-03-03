# Development Environment Setup

In this section, you'll learn how to set up and run a containerized development environment for the Product Catalog application. This approach demonstrates how Docker simplifies the development process by providing consistent environments and dependencies.

## Prerequisites

Before you begin, ensure you have:

- Docker Desktop installed and running
- Git installed
- Node.js installed (for local development)
- A code editor (VS Code recommended)

## Getting Started

### 1. Clone the Repository

Start by cloning the sample repository:

```bash
git clone https://github.com/dockersamples/catalog-service-node
cd catalog-service-node
```

### 2. Initial Setup

Run the setup script to prepare your development environment:

```bash
cd demo/sdlc-e2e
./setup.sh
```

This script performs several key actions:
- Creates a new Git branch for your work
- Applies necessary patches to prepare the demo
- Installs npm dependencies
- Pulls required Docker images
- Configures Docker Build Cloud and Scout (optional)

### 3. Understanding the Development Environment

The development environment consists of several containerized services:

- **PostgreSQL**: Database for storing product information
- **Kafka**: Message broker for event publishing
- **LocalStack**: For simulating AWS S3 locally
- **WireMock**: Mocks the external inventory service
- **UI Client**: Web interface for testing the API
- **pgAdmin & Kafbat**: Admin UIs for database and Kafka visualization

This environment allows you to develop and test without needing to connect to external services.

### 4. Starting the Development Environment

Start all the required services using Docker Compose:

```bash
# Navigate back to the project root
cd ../..

# Start all services
docker compose up -d
```

You can verify the running containers with:

```bash
docker compose ps
```

Expected output:
```
NAME                             COMMAND                  SERVICE                CREATED             STATUS              PORTS
catalog-service-node-client-1    "docker-entrypoint.s…"   client                 3 minutes ago       Up 3 minutes        0.0.0.0:5173->5173/tcp
catalog-service-node-kafka-1     "/etc/confluent/dock…"   kafka                  3 minutes ago       Up 3 minutes        0.0.0.0:9092->9092/tcp
catalog-service-node-kafbat-1    "/app/entrypoint.sh"     kafbat                 3 minutes ago       Up 3 minutes        0.0.0.0:8080->8080/tcp
catalog-service-node-localstack-1  "docker-entrypoint.sh"   localstack             3 minutes ago       Up 3 minutes        0.0.0.0:4566-4583->4566-4583/tcp
catalog-service-node-pgadmin-1   "/entrypoint.sh"         pgadmin                3 minutes ago       Up 3 minutes        0.0.0.0:5050->80/tcp
catalog-service-node-postgres-1  "docker-entrypoint.s…"   postgres               3 minutes ago       Up 3 minutes        0.0.0.0:5432->5432/tcp
catalog-service-node-wiremock-1  "/docker-entrypoint.…"   wiremock               3 minutes ago       Up 3 minutes        0.0.0.0:8081->8080/tcp
```

### 5. Starting the API Service

Now, start the Node.js API service in development mode:

```bash
npm install
npm run dev
```

This will start the application in development mode with hot-reloading enabled.

## Exploring the Application

### 1. Accessing the Web Client

Open your browser and navigate to [http://localhost:5173](http://localhost:5173)

This simple UI allows you to:
- Create new products
- View existing products
- Upload product images

Try creating a few products to verify the setup is working correctly.

### 2. Examining the Database

#### Using pgAdmin

1. Open [http://localhost:5050](http://localhost:5050)
2. Log in with the following credentials:
   - Email: `admin@example.com`
   - Password: `admin`
3. Connect to the PostgreSQL server:
   - Right-click on "Servers" and select "Create" > "Server"
   - Name: `Catalog DB`
   - Connection tab:
     - Host: `postgres`
     - Port: `5432`
     - Username: `postgres`
     - Password: `postgres`
4. Navigate to Servers > Catalog DB > Databases > catalog > Schemas > public > Tables > products
5. Right-click on "products" and select "View/Edit Data" > "All Rows"

#### Using Postgres CLI

You can also access the database directly using the Postgres CLI:

```bash
# Connect to the PostgreSQL container
docker exec -it catalog-service-node-postgres-1 psql -U postgres

# Switch to the catalog database
postgres=# \c catalog

# Query the products table
catalog=# SELECT * FROM products;
```

You should see the products you created earlier:

```
 id |    name     |     upc      | price  | is_deleted
----+-------------+--------------+--------+------------
  1 | New Product | 100000000001 | 100.00 | f
  2 | New Product | 100000000002 | 100.00 | f
  3 | New Product | 100000000003 | 100.00 | f
```

### 3. Observing Kafka Messages

The application publishes events to Kafka when products are created, updated, or deleted.

1. Open the Kafka visualizer at [http://localhost:8080](http://localhost:8080)
2. Navigate to the "Topics" section
3. Select the "products" topic
4. Examine the messages

You'll notice that the Kafka messages don't include the UPC property:

![Kafka Messages Missing UPC](https://github.com/user-attachments/assets/a3e3ff3d-f08c-4168-bfb2-e59800be4d58)

## Fixing the UPC Issue in Kafka Events

Let's examine why the UPC is missing from Kafka events and fix it:

1. Open the `src/services/ProductService.js` file in your code editor
2. Find the `publishEvent` function call around line 52
3. Add the UPC field to the event payload:

```javascript
publishEvent({
  action: "product_created",
  id: newProductId,
  name: product.name,
  upc: product.upc, // Add this line
  price: product.price,
});
```

4. Save the file
5. The development server should automatically reload
6. Create a new product using the web UI
7. Check the Kafka messages again:

![Kafka Messages With UPC](https://github.com/user-attachments/assets/32c5ba6c-60c1-403b-9962-50c501a5e996)

Now you can see the UPC appears in the Kafka messages!

## Development Best Practices with Docker

Using Docker for development offers several advantages:

1. **Consistent Environments**: Everyone works with the same dependencies and services
2. **Isolated Services**: Each service runs in its own container
3. **Easy Cleanup**: When you're done, just run `docker compose down`
4. **Service Replication**: Local environment mirrors production services

### Docker Compose Tips

- Use `docker compose logs -f [service]` to follow service logs
- Restart a single service with `docker compose restart [service]`
- Access a container shell with `docker compose exec [service] bash`

## Next Steps

Now that you have the development environment running and have fixed the UPC issue, you're ready to:

1. Continue developing the application with the confidence that your changes will work across environments
2. Move on to the [Testing phase](test.md) to learn how to properly test your application with Testcontainers
