## Testing

```
npm run unit-test
npm run integration-test
```


The script includes the following key components:

Test > src > integration > 

- KafkaSupport
- containerSupport
- productCreation.integration.*.js


##  How it works?

## 1.Importing required modules:


- fs for reading image files.
- containerSupport for creating and managing Docker containers for testing.
- kafkaSupport for consuming messages from Kafka.


## 2.Setting up and tearing down test environment:


- Starting Docker containers for PostgreSQL, Kafka, and Localstack using the containerSupport module.
- Creating an instance of the KafkaConsumer for consuming messages from Kafka.
- Importing the ProductService and PublisherService for testing the product creation feature.
- Disconnecting from Kafka and tearing down the test environment after all tests have completed.


## 3.Defining unit and integration tests:


- "Product creation" test suite:
- "should publish and return a product when creating a product": Tests the creation of a product, verification of the product's properties, and retrieval of the product from the product service.
- "should publish a Kafka message when creating a product": Tests the creation of a product and verification of the corresponding Kafka message.
- "should upload a file correctly": Tests the upload of an image file, verification of the corresponding Kafka message, and retrieval of the image file from the product service.
- "doesn't allow duplicate UPCs": Tests the prevention of creating products with duplicate UPCs.

The script also includes a timeout value for starting the Docker containers and waiting for messages from Kafka, ensuring that the tests have enough time to complete.

Overall, the script provides a comprehensive set of unit and integration tests for the "Product creation" feature, ensuring that the functionality is working as expected and providing valuable feedback on the overall system.

## Accessing Testcontainers Desktop App 

Open Testcontainer Desktop app and you'll notice that 3 containers appear and clean up once the test gets completed.

<img width="940" alt="image" src="https://github.com/user-attachments/assets/9277a932-2227-4cf2-97ab-758e1dd3ea38" />
