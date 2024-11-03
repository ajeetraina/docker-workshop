

![stars](https://img.shields.io/github/stars/ajeetraina/wad2024-workshop)
![Twitter](https://img.shields.io/twitter/follow/ajeetsraina?style=social)




# Welcome to Docker workshop

Are you tired of inconsistent development setups and slow testing environments slowing down your inner loop? This 2 hour workshop to learn the best practices, applied to an inner-loop development workflow, so you learn everything from getting set up, coding, testing and debugging your code locally without altering your existing development environment.


In this workshop, you will:

- Learn how to build, run, and debug containerized applications directly within your existing IDE, eliminating the need to switch environments.
- Discover how your IDE integrates with Docker, allowing you to seamlessly manage containerized applications throughout the development process – from initial coding and testing to secure packaging and deployment.
- Learn how to spin up mock cloud services locally within containers, enabling efficient and isolated testing without complex external setups.


These hands-on labs will be a combination of theory and practical exercises.

[Access the Workshop Here!](https://dockerworkshop.vercel.app/)

## Benefits of this workshop


- Get familiar with Inner-Loop Vs Outer-Loop Development Workflow
- Understanding of Container-first Vs Container-supported Development Workflow
- Overview of Docker Developer Workflow
- Docker Image Building Best Practices
- Docker Init
- Docker Compose File Watch
- Building a todo-list Application using AWS S3 and Mongo

 [Download the workshop slides](https://github.com/ajeetraina/docker-workshop/blob/7c4b31c41e1e8b64252bb15859d5bdce18428973/WeAreDevelopers-workshop.pdf)

## Contribution Guidelines

We welcome contributors to improve this lab workshop. 

### Building the Lab locally

```
docker build -t docker-wad-workshop:1.0
docker run -d -p 8000:8000 docker-wad-workshop:1.0
```

Open your browser and access the lab via `http://localhost:8000`



