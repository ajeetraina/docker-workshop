### 1. Docker Desktop

[Download and Install Docker Desktop 4.41+](https://www.docker.com/products/docker-desktop/) on your system. 

 - [Apple Chip](https://desktop.docker.com/mac/main/arm64/Docker.dmg)
 - [Intel Chip](https://desktop.docker.com/mac/main/amd64/Docker.dmg)
 - [Windows with NVIDIA GPUs](https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe)
 - [Linux](https://docs.docker.com/desktop/linux/install/)


### 2. Download your preferred IDEs (optional)

- IntelliJ IDEA

### 3. Access to the repositories

- [https://github.com/dockersamples/genai-model-runner-metrics](https://github.com/dockersamples/genai-model-runner-metrics)
- [https://github.com/ajeetraina/docker-workshop](https://github.com/ajeetraina/docker-workshop)


### 4. Enable Docker Model Runner

```
docker desktop enable model-runner
```

### 5. Download the models

Ensure that you have sufficient space to download these models on your Macbook.

```
docker model pull ai/llama3.2:1B-Q8_0
docker model pull ai/qwen3
```

### 5. Download the following images from the Docker Hub

```
docker pull grafana/grafana:10.1.0
docker pull jaegertracing/all-in-one:1.46
docker pull prom/prometheus:v2.45.0
```

### 6. Install and configure your preferred MCP Client

```
Ask Gordon
Claude Desktop (optional)
Cursor (optional)
Continue.dev (optional)
```