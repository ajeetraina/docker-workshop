# Files, Ports & SSH

A cloud sandbox has **no host workspace** - it can't see your laptop's filesystem. So the two everyday questions are: *how do I get my code in and my results out*, and *how do I reach a service the agent is running*. This module answers both, plus SSH for a full shell.

**Prerequisite:** A running cloud sandbox from [Your First Cloud Sandbox](first-cloud-sandbox.md). The examples assume one named `cloud-project`.

---

## Copying files in and out

`sbx --cloud cp` moves files between your machine and the sandbox, just like `docker cp`. Sandbox paths are absolute and prefixed with the sandbox name.

```bash
# Push your project in
sbx --cloud cp ./src cloud-project:/home/agent/workspace/src

# Pull a result back out
sbx --cloud cp cloud-project:/home/agent/workspace/result.json ./result.json

# Follow symlinks instead of copying the link itself
sbx --cloud cp -L source cloud-project:/destination
```

!!! warning "Copy results out before you delete"
    A cloud sandbox's filesystem is gone the moment it's deleted (or hits a `delete` timeout). Always `cp` artifacts back to your machine before `sbx --cloud rm`.

A common full loop:

```bash
sbx --cloud cp . cloud-project:/home/agent/workspace/app   # upload project
sbx --cloud exec cloud-project bash -lc 'cd /home/agent/workspace/app && npm test'
sbx --cloud cp cloud-project:/home/agent/workspace/app/report ./report  # retrieve
```

---

## Publishing a port

If the agent starts a web server inside the sandbox, publish its port to get a reachable URL:

```bash
sbx --cloud ports cloud-project --publish 8080   # expose sandbox port 8080
sbx --cloud ports cloud-project                  # list exposed ports + URLs
sbx --cloud ports cloud-project --unpublish 8080 # remove the exposure
```

Grab the URL programmatically from `inspect`:

```bash
sbx --cloud inspect cloud-project --format json | jq -r '.ports[]? | .url // empty'
```

---

## SSH access

For a full interactive shell (editors, debuggers, `rsync`), set up SSH once:

```bash
sbx --cloud setup ssh
```

Then connect using the sandbox's SSH identity against the `sbx_cloud` host alias the setup configures:

```bash
ssh sbx_01abc123@sbx_cloud
```

Replace `sbx_01abc123` with your sandbox's SSH user (shown by `sbx --cloud inspect`). With SSH configured you can also point VS Code Remote-SSH or JetBrains Gateway at the sandbox and edit in the cloud directly.

---

## ✅ Checkpoint

- [ ] Uploaded a directory with `sbx --cloud cp ./... cloud-project:/...`
- [ ] Pulled a file back out with `sbx --cloud cp cloud-project:/... ./...`
- [ ] Published a port and retrieved its URL
- [ ] Ran `sbx --cloud setup ssh` and connected with `ssh`
- [ ] Confirmed you copy results **out before deleting** the sandbox

Next: [Environment Files](environment-files.md).

> **Source:** [Use cloud sandboxes](https://docs.docker.com/ai/sandboxes/cloud/usage/).
