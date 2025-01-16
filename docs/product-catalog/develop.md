
### Clone the repo

```
git clone https://github.com/dockersamples/catalog-service-node
```

### Run the Compose

```
docker compose up -d
```

## Setting up the Demo


Bring up the API service 


```
npm install
npm run dev
```

## Apply the patch:

```
git apply demo/e2e.patch
```

### Accessing the Web Client

Open the web client (http://localhost:5173) and create a few products.

### Accessing the database visualizer 

Open [http://localhost:5050](http://localhost:5050) and validate the products exist in the database. 
"Good! We see the UPCs are persisted in the database"


Use the following Postgres CLI to check if the products are added or not.

```
# psql -U postgres
psql (17.1 (Debian 17.1-1.pgdg120+1))
Type "help" for help
postgres=# \c catalog
You are now connected to database "catalog" as user "postgres".
catalog=# SELECT * FROM products;
  1 | New Product | 100000000001 | 100.00 | f
  2 | New Product | 100000000002 | 100.00 | f
  3 | New Product | 100000000003 | 100.00 | f
```



### Access the Kafka Visualizer

Before we access visualizer, let's apply the patch:



Open the Kafka visualizer [http://localhost:8080](http://localhost:8080) and look at the published messages. 
"Ah! We see the messages don't have the UPC"

<img width="1213" alt="image" src="https://github.com/user-attachments/assets/a3e3ff3d-f08c-4168-bfb2-e59800be4d58" />



## Let's fix it...


### Configuring 

In VS Code, open the `src/services/ProductService.js` file and add the following to the publishEvent on line ~52:

```
upc: product.upc,
```

Save the file and create a new product using the web UI. 


<img width="1191" alt="image" src="https://github.com/user-attachments/assets/32c5ba6c-60c1-403b-9962-50c501a5e996" />

Validate the message has the expected contents.

