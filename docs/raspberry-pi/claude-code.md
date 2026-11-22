# Run Claude Code and Clean Up

## Create the agent sandbox

```bash
mkdir -p ~/Projects/pi-sbx-claude
sbx create --name pi-claude --cpus 2 --memory 2g claude ~/Projects/pi-sbx-claude
```

The first create took 152 seconds here, including the image download.

```bash
sbx exec pi-claude claude --version
sbx exec pi-claude uname -m
```

Real output:

```
2.1.330 (Claude Code)
aarch64
```

## Give it credentials

A new sandbox has none of your Pi's logins. Without one, Claude Code answers:

```
Not logged in · Please run /login
```

Choose one:

- **Sign in interactively:** run the command below, then use `/login`.
- **API key:** store it on the host as shown in the [sbx pre-flight checklist](../lab8/getting-started.md). The key stays outside the workspace.

```bash
sbx run --name pi-claude
```

!!! note "Not captured"
    The sign-in and the prompt below need your own account, so no output is shown.

## Try a Pi task

> Write a Python script called pi_temp.py that reads /sys/class/thermal/thermal_zone0/temp and prints the temperature in Celsius. Handle the file being missing.

Read the script, then run it **on the Pi**, outside the sandbox:

```bash
python3 ~/Projects/pi-sbx-claude/pi_temp.py
```

The agent wrote the code in isolation. You decided to run it on real hardware.

## Clean up

!!! warning "This deletes the lab sandboxes"
    Files in the workspace folders stay on the Pi. Installed packages, images and containers inside the sandboxes are lost.

```bash
sbx rm pi-lab pi-lab-2 pi-lab-3 pi-claude
sbx ls
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `/dev/kvm` missing or denied | No KVM access | Check the `kvm` group, then run `sbx diagnose` |
| `403` from `curl` in a sandbox | Host not allowed by policy | `sbx policy log pi-lab`, then allow it |
| `exec format error` | amd64 image | Use an arm64 image |
| Sandbox shows `stopped` | Idle | Run `sbx exec` or `sbx run` again |
| `Not logged in` | No agent credentials | Sign in or store a secret |
