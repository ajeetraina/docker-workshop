# Run Docker Inside the Sandbox

The Pi has no Docker Engine. The sandbox does.

```bash
which docker || echo "no docker on the Pi"
sbx exec pi-lab docker version --format '{{.Server.Version}} {{.Server.Arch}}'
```

Real output:

```
no docker on the Pi
29.10.0 arm64
```

## Run an arm64 container

```bash
sbx exec pi-lab docker run --rm alpine uname -m
```

Real output (after the image pull):

```
aarch64
```

## What about amd64 images?

```bash
sbx exec pi-lab docker run --rm --platform linux/amd64 alpine uname -m
```

Real output:

```
exec /bin/uname: exec format error
```

The sandbox has no amd64 emulation set up. Use images with an arm64 variant.

## Publish a port to the Pi

Start nginx in the sandbox:

```bash
sbx exec pi-lab docker run -d --name web -p 8080:80 nginx:alpine
```

Publish the sandbox port:

```bash
sbx port publish pi-lab 8080:8080
sbx port ls pi-lab
curl -s http://127.0.0.1:8080 | grep -i '<title>'
```

Real output:

```
Published 127.0.0.1:8080 -> 8080/tcp4
HOST IP     HOST PORT   SANDBOX PORT   PROTOCOL
127.0.0.1   8080        8080           tcp4
<title>Welcome to nginx!</title>
```

The port is bound to `127.0.0.1`, so other machines on your network can't reach it.

```bash
sbx port unpublish pi-lab 8080:8080
```

## Stop and start

```bash
sbx stop pi-lab
sbx exec pi-lab docker ps -a --format '{{.Names}} {{.Status}}'
```

Real output:

```
web Exited (255) 1 second ago
```

Images and containers survive a stop, but a container without a restart policy doesn't start again by itself.
