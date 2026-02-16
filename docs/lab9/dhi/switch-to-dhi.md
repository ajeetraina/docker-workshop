# Making the Switch to Docker Hardened Images

Switching to a Docker Hardened Image is straightforward. All we need to do is replace the base image `node:24-trixie-slim` with a DHI equivalent.

## DHI Image Variants

Docker Hardened Images come in two variants:

- **Dev variant** (`<YOUR_ORG_NAME>/dhi-node:24-debian13-dev`) — Includes a shell and package managers, making it suitable for building and testing.
- **Runtime variant** (`<YOUR_ORG_NAME>/dhi-node:24-debian13`) — Stripped down to only the essentials, providing a minimal and secure footprint for production.

This makes them perfect for use in multi-stage Dockerfiles. We can build the app in the dev image, then copy the built application into the runtime image, which will serve as the base for production.

## Step 1: Update the Dockerfile

Update the `Dockerfile` to use DHI images:

**Change the dev stage:**

```dockerfile
FROM <YOUR_ORG_NAME>/dhi-node:24-debian13-dev AS dev
```

**Change the production stage:**

```dockerfile
FROM <YOUR_ORG_NAME>/dhi-node:24-debian13 AS prod
```

## Step 2: Non-root User (Already Built-in!)

Looking back at the Scout output, the `No default non-root user found` policy was not met. To resolve this, we would typically need to add a non-root user to the Dockerfile.

The good news is that DHI comes with a **nonroot user built-in**, so no changes are needed!

## Step 3: Rebuild and Scan

Now let's rebuild and scan the new image:

```bash
docker buildx build --provenance=true --sbom=true -t <YOUR_ORG_NAME>/demo-node-dhi:v1 .
```

```bash
docker scout quickview <YOUR_ORG_NAME>/demo-node-dhi:v1
```

You will see output similar to:

```
 Target     │  <org>/demo-node-dhi:v1              │    0C     0H     0M     0L
   digest   │  cec31e6f0a36                         │
 Base image │  <org>/dhi-node:24-debian13           │

Policy status  SUCCESS  (9/9 policies met)

  Status │                     Policy                     │        Results
─────────┼────────────────────────────────────────────────┼───────────────────
  ✓      │ AGPL v3 licenses found                         │    0 packages
  ✓      │ Default non-root user                          │
  ✓      │ No AGPL v3 licenses                            │    0 packages
  ✓      │ No embedded secrets                            │    0 deviations
  ✓      │ No embedded secrets (Rego)                     │    0 deviations
  ✓      │ No fixable critical or high vulnerabilities    │    0C  0H  0M  0L
  ✓      │ No high-profile vulnerabilities                │    0C  0H  0M  0L
  ✓      │ No unapproved base images                      │    0 deviations
  ✓      │ Supply chain attestations                      │    0 deviations
```

🎉 **Hooray! There are zero CVEs and all policies pass!**

## Step 4: Compare Image Size and Packages

Docker Scout offers a helpful `docker scout compare` command that allows you to analyze and compare two images. Let's evaluate the difference in size and package footprint:

```bash
docker scout compare local://<YOUR_ORG_NAME>/demo-node-dhi:v1 \
  --to local://<YOUR_ORG_NAME>/demo-node-doi:v1
```

Scroll up the output and you will see a summary similar to:

```
## Overview

                    │          Analyzed Image                │         Comparison Image
────────────────────┼────────────────────────────────────────┼──────────────────────────────────
  Target            │  local://<org>/demo-node-dhi:v1        │  local://<org>/demo-node-doi:v1
    vulnerabilities │    0C     0H     0M     8L             │    0C     2H     2M    20L
                    │           -2     -2    -20             │
    size            │ 59 MB (-40 MB)                         │ 97 MB
    packages        │ 648 (-214)                             │ 858
  Base image        │  <org>/dhi-node:24                     │  node:24-trixie-slim
    vulnerabilities │    0C     0H     0M     0L             │    0C     1H     2M    20L
```

The DHI-based image is **~40 MB (around 40%) smaller**, contains **214 fewer packages**, and has **near-zero CVEs** compared to the original `node:24-trixie-slim`-based image.

## Step 5: Validate the Application

After migrating to a DHI base image, verify that the application still functions as expected:

```bash
docker run --rm -d --name demo-node -p 3005:3000 <YOUR_ORG_NAME>/demo-node-dhi:v1
```

Open your browser and navigate to [http://localhost:3005](http://localhost:3005) to confirm the app is running.

Then stop the container:

```bash
docker stop demo-node
```
