## 1. Clone the repository:

```sh
git clone https://github.com/dockersamples/getting-started-todo-app
cd getting-started-todo-app
```



## 2. Bring up the services:

```
docker compose up -d
```

## 5. Access the app

Open [http://localhost:80](http://localhost:80) to access the todo-list app.



You'll see several container images get downloaded from Docker Hub and, after a
moment, the application will be up and running! No need to install or configure
anything on your machine!

Simply open to [http://localhost](http://localhost) to see the app up and running!

Any changes made to either the backend or frontend should be seen immediately
without needing to rebuild or restart the containers.

## 6. Accessing the PhpMyAdmin

To help with the database, the development stack also includes phpMyAdmin, which
can be access at [http://db.localhost](http://db.localhost) (most browsers will 
resolve `*.localhost` correctly, so no hosts file changes should be required).

## 7. Tearing it down

When you're done, simply remove the containers by running the following command:

```
docker compose down
```



