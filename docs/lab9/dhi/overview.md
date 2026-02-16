# Docker Hardened Images

👋 Welcome to the **Docker Hardened Images (DHI)** workshop! This lab outlines the benefits of Docker Hardened Images and walks you through the migration process for a Node.js application.

> **Source:** This workshop is based on the [labspace-dhi-node](https://github.com/dockersamples/labspace-dhi-node) labspace.

## What are Docker Hardened Images?

Docker Hardened Images are **Secure, Minimal, Production-Ready Images** with near-zero CVEs and enterprise-grade SLA for rapid remediation.

These images follow a distroless philosophy, removing unnecessary components to significantly reduce the attack surface. The result? Smaller images that pull faster, run leaner, and provide a secure-by-default foundation for production workloads.

### Key Benefits

- **Near-zero exploitable CVEs:** Continuously updated, vulnerability-scanned, and published with signed attestations to minimize patch fatigue and eliminate false positives.
- **Seamless migration:** Drop-in replacements for popular base images, with `-dev` variants available for multi-stage builds.
- **Up to 95% smaller attack surface:** Unlike traditional base images that include full OS stacks with shells and package managers, distroless images retain only the essentials needed to run your app.
- **Built-in supply chain security:** Each image includes signed SBOMs, VEX documents, and SLSA provenance for audit-ready pipelines.

## Workshop Structure

This workshop is organized into the following sections:

| Section | Description |
|---------|-------------|
| [Getting Started](getting-started.md) | Mirror a DHI Node image and set up Docker Scout |
| [Image Scanning](image-scanning.md) | Build and scan a Node.js app with Docker Scout |
| [Switch to DHI](switch-to-dhi.md) | Migrate from community images to Docker Hardened Images |
| [Compliance & Attestations](compliance.md) | Explore DHI attestations, FIPS compliance, and scanner integration |

## Sample Application

The demo application used in this workshop is a simple Hello World Node.js server built with the `http` module. The source code is available in the [labspace-dhi-node](https://github.com/dockersamples/labspace-dhi-node) repository.

**app.js:**

```javascript
const http = require('http');

const port = 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('Hello World!');
  } else {
    res.writeHead(404);
    res.end('Not Found');
  }
});

server.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
```

**Dockerfile (starting point):**

```dockerfile
FROM node:24-trixie-slim AS dev

ENV BLUEBIRD_WARNINGS=0 \
NODE_ENV=production \
NODE_NO_WARNINGS=1 \
NPM_CONFIG_LOGLEVEL=warn \
SUPPRESS_NO_CONFIG_WARNING=true

WORKDIR /app

COPY package.json ./

RUN apt-get update \
 && apt-get install -y --no-install-recommends npm \
 && npm install --no-optional \
 && npm cache clean --force \
 && apt-get remove -y npm \
 && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*

COPY . .


#-- Prod stage --
FROM node:24-trixie-slim AS prod

WORKDIR /app

COPY --from=dev /app /app

ENTRYPOINT ["node"]
CMD ["app.js"]
EXPOSE 3000
```

## Learn More

- [Docker Hardened Images](https://www.docker.com/products/hardened-images/) — Enterprise-ready, secure container images with built-in compliance and minimal vulnerabilities.
- [Docker Scout](https://www.docker.com/products/docker-scout/) — Software supply chain security for container images.
