This project provides a basic todo-list application. It demonstrates all of
the current Docker best practices, ranging from the Compose file, to the
Dockerfile, to CI (using GitHub Actions), and running tests. It's intended to 
be a well-documented to ensure anyone can come in and easily learn.

## Tech Stack

- Frontend: React, Vite, CSS Pre-processor
- Backend: Node.js
- Database: MySQL, PhpMyAdmin for administrating MySQL

![image](https://github.com/docker/getting-started-todo-app/assets/313480/c128b8e4-366f-4b6f-ad73-08e6652b7c4d)


This sample application is a simple React frontend that receives data from a
Node.js backend. 

When the application is packaged and shipped, the frontend is compiled into
static HTML, CSS, and JS and then bundled with the backend where it is then
served as static assets. So no... there is no server-side rendering going on
with this sample app.

During development, since the backend and frontend need different dev tools, 
they are split into two separate services. This allows [Vite](https://vitejs.dev/) 
to manage the React app while [nodemon](https://nodemon.io/) works with the 
backend. With containers, it's easy to separate the development needs!



## 1. Clone the repository:




```sh
git clone https://github.com/dockersamples/getting-started-todo-app
cd getting-started-todo-app
```



## 2. Bring up the services:

```
docker compose up -d --build
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



