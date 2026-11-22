# Prove the Isolation

An agent on your Pi could reach your SSH keys, and also the hardware wired to the GPIO header. Check that the sandbox can reach neither.

## Your home directory

```bash
sbx exec pi-lab ls -la $HOME
sbx exec pi-lab ls $HOME/.ssh $HOME/.claude
```

Real output:

```
drwxr-xr-t 3 root  root  4096 Nov 22 10:52 .
drwxr-xr-x 1 root  root  4096 Nov 22 10:52 ..
drwxr-xr-t 4 agent agent 4096 Nov 22 10:52 Projects

ls: cannot access '/home/ajeetraina/.ssh': No such file or directory
ls: cannot access '/home/ajeetraina/.claude': No such file or directory
```

The path exists only to hold the workspace mount. Nothing else from your home is there.

## The user

```bash
sbx exec pi-lab id
```

Real output:

```
uid=1000(agent) gid=1000(agent) groups=1000(agent),27(sudo),999(docker)
```

The agent can be powerful inside its VM without being you on the Pi.

## Pi hardware

```bash
sbx exec pi-lab sh -c 'cat /proc/device-tree/model; ls /dev/i2c* /dev/gpiochip* /dev/kvm /dev/vcio'
```

Real output:

```
cat: /proc/device-tree/model: No such file or directory
ls: cannot access '/dev/i2c*': No such file or directory
ls: cannot access '/dev/gpiochip*': No such file or directory
ls: cannot access '/dev/kvm': No such file or directory
ls: cannot access '/dev/vcio': No such file or directory
```

| On the Pi | In the sandbox |
|---|---|
| `/dev/i2c-*` (displays, sensors) | Absent |
| `/dev/gpiochip*` (GPIO pins) | Absent |
| `/dev/kvm` | Absent |

!!! warning "The trade-off"
    Code in this sandbox can't drive an OLED, a fan, or a sensor. Let the agent write hardware code in the workspace, review it, then run it on the Pi yourself.

## What isn't protected

The workspace is mounted read-write. An agent can change or delete anything in it, so keep secrets out and use Git.
