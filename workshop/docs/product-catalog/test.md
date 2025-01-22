

```
npm run unit-test
npm run integration-test
```


## How does this work?

In your `package.json` file, several scripts are being defined related to testing your application:

- test: This command runs all tests using Jest, with the --detectOpenHandles flag to detect and report any open handles.
- unit-test: This command runs unit tests using Jest, with the --detectOpenHandles flag and a specific testPathIgnorePatterns to exclude integration tests.
- integration-test: This command runs integration tests using Jest, with the --detectOpenHandles flag and a specific test pattern to include only integration tests.
- test-watch: This command runs Jest in watch mode, allowing you to run tests as you make changes to your code.
- prepare: This command runs the husky install script, which sets up Git hooks for your project.

To determine which tests are executed when you run `npm run integration-test`, you need to look at the command itself. 
The command is:

```
env-cmd --file .env.node -- jest "test/integration/.*\\.spec\\.js" --detectOpenHandles
```

In this command, Jest is executed with the `--testPathPattern` option set to "test/integration/.*\\.spec\\.js". This pattern matches all files in the test/integration directory that end with .spec.js. Therefore, only the integration tests will be executed when you run npm run integration-test.

The other scripts, such as `test`, `unit-test`, and `test-watch`, are configured to run different types of tests based on the specified options. The unit-test script excludes integration tests by using the `--testPathIgnorePatterns` option. 

The `test-watch` script runs Jest in watch mode, allowing you to run tests as you make changes to your code.

By running `npm run integration-test`, you can ensure that only the integration tests are executed, providing a focused and targeted testing experience.




##  What's inside integration/.*\\.spec\\.js file?

The file integration/.*\\.spec\\.js is a JavaScript file containing integration tests for your application. The file name pattern .*\\.spec\\.js is a regular expression that matches any file ending with .spec.js in the integration directory.

Inside the integration/.*\\.spec\\.js file, you'll find the following components:

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

## How about the unit-tests?

Unit tests are tests that focus on individual components or units of your application, validating the functionality and behavior of specific parts of your code. They are essential for catching and identifying issues at a granular level, ensuring the reliability and correctness of your application.

For example, the "Product creation" test suite includes tests such as:
- "should publish and return a product when creating a product"
- "should publish a Kafka message when creating a product"
- "should upload a file correctly"
- "doesn't allow duplicate UPCs"

When you run `npm run unit-test`, the following steps are executed based on the configuration in your package.json file:

1. The `env-cmd` command is executed with the `--file .env.node option`, which loads environment variables from the `.env.node` file.

2. The jest command is executed with the specified options:

- `--detectOpenHandles`: This flag detects and reports any open handles.
- `--testPathIgnorePatterns "test/integration/.*\\.spec\\.js"`: This option excludes integration tests by using a regular expression pattern that matches the file names of integration test files.
The jest command runs the unit tests defined in your project. The  `--testPathIgnorePatterns` option ensures that only unit tests are executed, excluding integration tests.

In summary, when you run `npm run unit-test`, the unit tests are executed using Jest, with the specified options to exclude integration tests and detect open handles.