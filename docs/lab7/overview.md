## How It Works?

### Architecture Overview

When you use Docker Offload, Docker Desktop creates a secure SSH tunnel to a Docker daemon running in the cloud. Your containers are created, managed, and executed entirely in the remote environment while providing a seamless local experience.
The Process
1. Connection: Docker Desktop connects securely to dedicated cloud resources
2. Execution: Docker Offload pulls required images and starts containers in the cloud
3. Interaction: The connection remains active while containers run, supporting features like bind mounts and port forwarding
4. Cleanup: When containers stop or after 30 minutes of inactivity, the environment automatically shuts down and cleans up

### Session Management

Docker Offload provisions ephemeral cloud environments for each session:

- Environment remains active during Docker Desktop interaction or container usage
- Automatic shutdown after ~30 minutes of inactivity
- Complete cleanup of containers, images, and volumes when sessions end
- No persistent state between sessions ensures security and cost efficiency

### Cloud Builds with Docker Offload

#### Enhanced Build Performance

When you use Docker Offload for builds, the docker buildx build command executes on remote BuildKit instances in the cloud instead of locally. Your workflow remains identical—only the execution environment changes.

#### Build Infrastructure

- Isolated Environment: Each cloud builder runs on dedicated Amazon EC2 instances with EBS volumes
- Shared Cache: Accelerate builds across machines and team members with intelligent caching
- Multi-Platform Support: Native support for multiple architectures (linux/amd64, linux/arm64)
- Secure Transfer: Build results are encrypted in transit and sent to your specified destination
- Automatic Management: Docker handles all infrastructure provisioning and maintenance

#### Performance Benefits

- Faster Builds: Powerful cloud instances outperform typical development machines
- Consistent Results: Standardized build environment eliminates "works on my machine" issues
- Resource Efficiency: No local CPU/memory consumption during builds
- Team Collaboration: Shared cache improves build times across the entire team

#### GPU-Accelerated Workloads

Docker Offload supports GPU-enabled instances with NVIDIA L4 GPUs, enabling:

- AI Inferencing: Run large language models and machine learning pipelines
- Media Processing: Handle video encoding, image processing, and graphics workloads
- General-Purpose GPU Computing: Accelerate any CUDA-compatible applications
- Hardware-Accelerated CI: Run GPU-dependent tests and validation
