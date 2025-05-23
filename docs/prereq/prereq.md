## 1. Docker Desktop

[Download and Install Docker Desktop 4.40+](https://www.docker.com/products/docker-desktop/) on your system. 

 - [Apple Chip](https://desktop.docker.com/mac/main/arm64/Docker.dmg)
 - [Intel Chip](https://desktop.docker.com/mac/main/amd64/Docker.dmg)
 - [Windows with NVIDIA GPUs](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
 - [Linux](https://docs.docker.com/desktop/linux/install/)


## 2. Access to the repositories

- [https://github.com/dockersamples/genai-model-runner-metrics](https://github.com/dockersamples/genai-model-runner-metrics)
- [https://github.com/ajeetraina/docker-workshop](https://github.com/ajeetraina/docker-workshop)


## 3. Enable Docker Model Runner

```
docker desktop enable model-runner
```

## Download the models

Ensure that you have sufficient space to download these models on your Macbook.

```
docker model pull ai/llama3.2:1B-Q8_0
docker model pull ai/qwen3
```

## Download the following images from the Docker Hub

```
grafana/grafana:10.1.0
jaegertracing/all-in-one:1.46
prom/prometheus:v2.45.0
```

