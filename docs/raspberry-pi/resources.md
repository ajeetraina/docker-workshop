# Fit It on 8 GB

## Memory limits hold

Ask for 3 GB inside the 2 GB sandbox:

```bash
sbx exec pi-lab python3 -c "b=bytearray(3*1024**3); print(len(b))"
```

Real output:

```
MemoryError
```

The program fails inside the VM. The Pi and the sandbox kept running.

## Run several sandboxes

```bash
for i in 2 3; do
  mkdir -p ~/Projects/pi-sbx-lab-$i
  sbx create --name pi-lab-$i --cpus 1 --memory 1g shell ~/Projects/pi-sbx-lab-$i
done
sbx ls
free -m
```

Measured on the Pi, with a GNOME desktop and Claude Code also running:

| State | Used | Available |
|---|---|---|
| Before any lab sandbox | 2344 MB | 5581 MB |
| `pi-lab` and one 1 GB sandbox running | 3180 MB | 4745 MB |
| `pi-lab` and two 1 GB sandboxes running | 3471 MB | 4454 MB |

Each extra sandbox took 7 seconds to create with the image cached. These sandboxes were idle, and a busy one can use up to its limit, so plan with the `--memory` value.

| Workload | Suggested starting point |
|---|---|
| `shell` sandbox | `--cpus 1 --memory 1g` |
| One coding agent | `--cpus 2 --memory 2g` |

These are starting points, not benchmarks.

## Watch the heat

Load two sandbox CPUs for 45 seconds:

```bash
sbx exec pi-lab sh -c 'for i in 1 2; do (timeout 45 sh -c "while :; do :; done") & done; wait'
```

In a second terminal on the Pi:

```bash
watch -n 2 'cat /sys/class/thermal/thermal_zone0/temp /sys/class/hwmon/hwmon*/fan1_input'
```

| | Temperature | CPU fan |
|---|---|---|
| Idle | 51°C | 2736 RPM |
| 40 seconds into the load | 56°C | 2755 RPM |

This is a short run in an open case. Longer jobs on all four cores will run hotter.

## Disk

```bash
sbx df
```

Sandbox images total about 4 GB here with the `shell` and `claude` images pulled. Allow for that on a small SD card.
