# Performance: How fast is it?

You run every project inside a Linux microVM on your Windows 11 laptop. The honest question is: does that cost you speed? Yes, there is real overhead, so this is not identical to native development. But for the way you actually work day to day, coding and driving agents, it is usually close enough that you will not notice. A sandbox trades a bit more resource use, a whole VM plus its own Docker daemon, for complete isolation. This page shows you exactly where the cost lands and how to keep it small.

---

## Where it is near-native

These parts of your workflow run about as fast as they would on bare metal.

| Workload | Why it stays fast |
| --- | --- |
| CPU-bound work (compiles, tests, package installs, `docker build`) | Hardware virtualization (KVM via the Windows Hypervisor Platform, or Apple Virtualization on a Mac) executes guest code near-native speed. |
| Docker inside the sandbox | The daemon reads and writes to the VM's own local disk, comparable to Docker Desktop and often better for Linux containers. |
| Warm startup | After the first run, the image is cached and the VM persists, so a session comes up in seconds. |

!!! note "First run is the slow one"
    The very first time you start a sandbox it pulls the image and boots a fresh VM. That is the cold path. Every start after that reuses the cached image and the persistent VM, so it is fast.

---

## Where you will feel the slowdown

The friction is almost entirely about files crossing the VM boundary.

- **Host-mounted workspace I/O.** A direct mount reaches your Windows files through a filesystem passthrough (virtiofs). Every read and write crosses the boundary. Caching, which is on by default, hides most of this for read-heavy work. But heavy small-file writes, like `npm install` into a bind-mounted `node_modules`, or writing large build artifacts back to the host, are noticeably slower.
- **Network-attached or synced storage.** This is a hard no. Mapped network drives, SMB/NFS shares, or cloud-synced folders used as a workspace make every file operation travel over the network. Agents touch thousands of files, so this slows performance dramatically.
- **Outbound network latency.** All outbound TCP is proxied through the host, which adds a small amount of latency to every connection.
- **Disk footprint.** Each sandbox carries its own VM image and Docker store (10 GB by default), and nothing is shared. The first build in each sandbox is cold.
- **Resource contention.** A `cpus: 0` setting means the sandbox may use all host CPUs. Run several like that and they fight each other, slowing the whole machine.

!!! warning "Never point a workspace at network or cloud storage"
    OneDrive, a mapped drive, or an NFS/SMB share as a workspace will make the sandbox crawl. Keep workspaces on local disk.

---

## How to keep it close to native

Work through these in order. The first one matters most.

1. **Keep generated and I/O-heavy directories off the bind mount.** `node_modules`, `.venv`, `target/`, `dist/`, and Docker volumes belong on the sandbox disk, not on the host-mounted workspace. Use a mountless setup or named volumes for them.
2. **Mount only source, not generated output.** This is the single biggest win. See [Workspaces & Naming](workspaces.md) for how to shape what you mount.
3. **Mount source, not a giant monorepo tree.** The less the passthrough has to track, the better it performs.
4. **Do not disable virtiofs caching.** It is on by default and does most of the heavy lifting for reads. The opt-out exists but you rarely want it:

    ```sh
    # Leave this alone; setting it to 0 turns caching OFF
    DOCKER_SANDBOXES_ENABLE_VIRTIOFS_CACHE=0
    ```

5. **Set explicit limits.** Use `sandboxOptions.cpus` and `sandboxOptions.memory` so no single sandbox grabs everything, and do not over-allocate across all your running sandboxes combined.
6. **Use clone mode or mountless for I/O-heavy or parallel-agent work.** When several agents run at once, copying source in beats fighting over a shared passthrough. See [Workspaces & Naming](workspaces.md).
7. **Never mount SMB, NFS, or cloud-synced folders.** Repeated for emphasis because it is the most common self-inflicted slowdown.
8. **Right-size the disk.** Tune `sandbox.disk.dockerVolume` so builds have room and are not fighting for space.

!!! tip "The pattern in one sentence"
    Mount your source code in, keep everything your tools generate on the sandbox disk.

---

## Compared with the alternatives

| Compared with | Result |
| --- | --- |
| Native Linux development | Slightly slower on host-mounted file I/O, near-identical on CPU and builds. The gap is smallest on a Linux host with native KVM. |
| WSL2 | Same class of virtualization. The sandbox adds a second boundary, a VM plus its own daemon, so it is a bit heavier, but far more isolated. |
| Docker Desktop | Usually similar or better for Linux containers, and much better isolated. |

---

## How to roll this out

Do not trust a general number. Benchmark one representative project on one laptop.

- Run `npm ci`, a full build, and the test suite natively on Windows.
- Run the exact same three steps inside a sandbox.
- Compare the real wall-clock times. That tells you more than any figure in a doc.

```bash
# Run inside the sandbox, then compare against the same commands natively
time npm ci
time npm run build
time npm test
```

Then apply the "generated dirs on the sandbox disk" pattern and measure again. You should see the I/O-heavy steps close most of the gap.

!!! note "Measure your project, not someone else's"
    A JavaScript app with a huge `node_modules` and a Go service that compiles a few packages behave very differently under virtiofs. Your own numbers are the only ones that count.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You understand the sandbox trades higher resource overhead for complete isolation.
- [ ] You know CPU-bound work and in-sandbox Docker run near-native, and warm starts take seconds.
- [ ] You can name where slowdowns come from: host-mounted file I/O, proxied network latency, per-sandbox disk, and CPU contention.
- [ ] You keep `node_modules`, `.venv`, `target/`, and `dist/` off the bind mount and on the sandbox disk.
- [ ] You mount only source and never point a workspace at SMB, NFS, or cloud-synced storage.
- [ ] You left virtiofs caching enabled and set explicit `cpus`/`memory` limits.
- [ ] You plan to benchmark one representative project both ways before rolling out.

Next: [Security & Guardrails](security.md).
