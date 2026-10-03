# Networking & Policy

A sandbox is not a wide-open shell on your Windows laptop. Each microVM starts sealed, and every outbound connection is checked against a policy before it leaves. On this team that is the point: a dev's agent can reach the shared Postgres server and a handful of registries, and nothing else. This page shows how that enforcement works and the exact allow list to run.

---

## Deny by default

A fresh sandbox blocks all outbound TCP, whether it is plain HTTP, HTTPS, or SSH. UDP is disabled unless you turn it on. ICMP is blocked, so pings will not leave the microVM. DNS is resolved through a proxy that applies the same policy, so you cannot sidestep a rule by using a raw address.

You open specific destinations with `sbx policy`. Rules are additive: you name a host, optionally a port, and that destination becomes reachable.

```sh
sbx policy ls
sbx policy allow network registry.npmjs.org
sbx policy allow network api.anthropic.com
sbx policy allow network github.com:443
sbx policy allow network 10.0.0.5:5432   # the on-prem shared DB
sbx policy deny  network example.com
sbx policy rm    network example.com
```

A rule without a port opens the common ports for that host; adding `:443` or `:5432` narrows it to a single port. Use `deny` to override a broader allow, and `rm` to delete a rule you added earlier.

!!! note "DNS follows the same rules"
    Because name resolution runs through the policy proxy, allowing `github.com` also makes its DNS lookups succeed. A host you have not allowed will not resolve, which is the first symptom you will see when a tool "hangs".

---

## First-run preset

The first time you run sbx you pick a global posture. This sets the starting point for every new sandbox; you can still tighten or loosen individual rules later.

| Preset | Behaviour |
| --- | --- |
| Open | All traffic allowed. No egress filtering. |
| Balanced | Default deny, with common developer sites pre-allowed. Recommended start. |
| Locked Down | Everything blocked until you explicitly allow each destination. |

For this team, start on **Balanced**: you get sensible defaults and still add the shared DB and your model provider on top.

---

## Reaching services on the host

Services running on the same machine as sbx are reachable from inside a sandbox through `host.docker.internal`. The proxy rewrites that name to `localhost` on the host, so you allow the **localhost** port, not the hostname.

```sh
sbx policy allow network localhost:11434
# then, from inside the sandbox:
curl http://host.docker.internal:11434
```

!!! warning "Critical for the team design"
    On a laptop sandbox, `host.docker.internal` means **the laptop**, not the shared server. The shared Postgres lives on the on-prem Linux box, so reach it by the server's hostname or IP with an allow rule:

    ```sh
    sbx policy allow network <server>:5432
    ```

    Only use `host.docker.internal` for something running on the very same machine as sbx, such as a local model.

---

## What is always blocked

Some boundaries are fixed and no policy rule can open them. This is deliberate isolation, not a missing feature:

- The host filesystem outside your mounted workspaces and the shared skills store.
- The host Docker daemon.
- Direct network communication between two sandboxes (they cannot see each other).
- Direct external ICMP (pings leaving the microVM).

---

## Recommended allow list for this team

These are the destinations a dev actually needs. Allow only what you use.

| Purpose | Rule |
| --- | --- |
| Model provider | `sbx policy allow network <provider-domain>` (e.g. `api.anthropic.com`, `api.x.ai`, `opencode.ai`) |
| Package registries | `registry.npmjs.org`, `pypi.org`, `files.pythonhosted.org`, `proxy.golang.org`, `crates.io` |
| Source control | `github.com:443`, plus your Git host |
| Shared DB | `sbx policy allow network <db-host>:5432` |
| Local model (if used) | `sbx policy allow network localhost:11434` |

A ready-to-run script, parameterised by the DB host:

```sh
#!/usr/bin/env sh
# Usage: sh allowlist.sh <db-host>
set -eu
DB_HOST="${1:?usage: sh allowlist.sh <db-host>}"
# Shared database on the on-prem Linux server
sbx policy allow network "${DB_HOST}:5432"
# Model provider (keep only the one(s) you use)
sbx policy allow network api.anthropic.com
sbx policy allow network api.x.ai
sbx policy allow network opencode.ai:443
# Package registries / source control
sbx policy allow network registry.npmjs.org
sbx policy allow network pypi.org
sbx policy allow network files.pythonhosted.org
sbx policy allow network proxy.golang.org
sbx policy allow network crates.io
sbx policy allow network github.com:443
echo "--- active rules ---"
sbx policy ls
```

!!! tip "Bake it into a kit"
    Rather than asking every dev to run the script, encode the standard egress in a kit so the whole team inherits the same rules automatically. See [Environments, Kits & Templates](environments.md).

---

## Central governance (optional, paid)

If your organization uses sbx governance, admins centrally manage network, filesystem, and MCP policies across all local sandboxes, enforce sign-in, and collect audit logs. This is a separate paid subscription.

!!! note "How it changes the rules"
    When org governance is active, only the organization's allow rules grant access. Local allow rules are ignored. Local **deny** rules still apply on top, so a dev can further restrict but never widen what the org permits.

---

## Upstream and corporate proxies

If your network forces traffic through a corporate proxy, sbx can chain through it. It supports HTTP, HTTPS, and SOCKS5 proxies, PAC files, or the OS proxy setting, with separate configuration for sandbox traffic versus daemon traffic.

```sh
sbx settings set proxy http://proxy.corp:3128
sbx settings set no_proxy "registry.internal,10.0.0.0/8"
sbx daemon restart
```

!!! warning "Exclusions are not permissions"
    Listing a host in `no_proxy` only tells sbx to bypass the upstream proxy for that host. It does **not** grant network access. The policy still applies, so you must also allow the destination with `sbx policy allow network ...`.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You understand that a sandbox denies all outbound TCP, UDP, and ICMP until a rule allows it.
- [ ] You can list, allow, deny, and remove rules with `sbx policy`.
- [ ] You picked the Balanced preset as your starting posture.
- [ ] You reach the shared DB by the server's host/IP, not `host.docker.internal`.
- [ ] You ran the team allow-list script (or inherited the rules from a kit).
- [ ] You know that org governance, if active, overrides local allow rules.
- [ ] You configured an upstream proxy only if your network requires one.

Next: [Performance](performance.md).
