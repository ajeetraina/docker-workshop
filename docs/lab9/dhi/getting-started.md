# Getting Started

## Prerequisites

Before starting this workshop, ensure you have:

- Docker Desktop installed (version 4.40 or later recommended)
- A Docker Hub account with access to a Docker organization that has DHI enabled
- Docker Scout CLI (included with Docker Desktop)

## Step 1: Mirror a DHI Node Image Repo

To use Docker Hardened Images, you first need to mirror them into your Docker Hub organization.

1. Navigate to the [Node DHI page](https://hub.docker.com) in your Docker Hub organization under **Hardened Images > Catalog > Node**.

2. Click on the **Mirror to repository** button.

3. In the pop-up dialog, set the name of the destination repository to `dhi-node`.

4. Click **Mirror**. In a few minutes, you'll see all available Node DHI tags in your `dhi-node` repository on Docker Hub.

!!! info "Mirrored repositories"
    Mirrored repositories work like any other repository in your Docker Hub organization. You can pull, push, and manage tags as usual.

## Step 2: Login with Docker

In order to use Docker Scout to analyze the image during this lab, you will need to be logged in.

```bash
docker login
```

You should see the following message:

```
Login Succeeded
```

If not, follow the instructions to complete the login.

## Step 3: Configure Docker Scout Organization

If your account is part of a paid organization, you may have additional output that reflects policy alignment.

```bash
docker scout config organization <YOUR_ORG_NAME>
```

!!! tip "Replace placeholders"
    Throughout this workshop, replace `<YOUR_ORG_NAME>` with your actual Docker Hub organization name.

To learn more about Policy Evaluation in Docker Scout, please follow the [Docker Scout Policy guides](https://docs.docker.com/scout/policy/).
