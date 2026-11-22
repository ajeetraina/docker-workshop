# Your First Sandbox on the Pi

## Create it

```bash
mkdir -p ~/Projects/pi-sbx-lab
cd ~/Projects/pi-sbx-lab
echo "hello from the Pi host" > hello.txt

sbx create --name pi-lab --cpus 2 --memory 2g shell .
```

Real output:

```
SANDBOX
  Name:       pi-lab
  Agent:      shell
  Workspace:  /home/ajeetraina/Projects/pi-sbx-lab (rw)
  CPU:        2
  Memory:     2g

  ✓ image — ready

  ✓ Created sandbox pi-lab
```

This took 12 seconds here. The `shell` agent gives you a plain sandbox with no AI agent, so this part needs no API key.

!!! tip "Always set --cpus and --memory on a Pi"
    By default a sandbox gets every CPU and half of the host's memory. That is too generous when 8 GB is shared with a desktop.

## Two kernels, one Pi

```bash
uname -rm                     # on the Pi
sbx exec pi-lab uname -rm     # in the sandbox
```

Real output:

```
7.3.0-1003-raspi aarch64
7.0.14 aarch64
```

The kernel versions differ. A container would report the host's kernel. The sandbox is a virtual machine with its own.

## Limits are enforced

```bash
sbx exec pi-lab nproc
sbx exec pi-lab free -m
```

Real output:

```
2
               total        used        free      shared  buff/cache   available
Mem:            1989          98        1693           0         216        1891
Swap:              0           0           0
```

## The workspace is shared

```bash
sbx exec pi-lab cat hello.txt
sbx exec pi-lab sh -c 'echo "written in sandbox" > from-sandbox.txt'
cat from-sandbox.txt
```

Real output:

```
hello from the Pi host
written in sandbox
```

Files move both ways, and the new file is owned by your own user on the Pi.

## Stopped is normal

With nothing running in it, the sandbox stopped by itself after about 30 seconds here. The next `sbx exec` starts it again, and took about 3.4 seconds:

```
  ✓ sandbox pi-lab — started
```
