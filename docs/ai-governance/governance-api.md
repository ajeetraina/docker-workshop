# Governance API

```mermaid
flowchart TB
    CLIENT["Admin / CI script (curl)"]
    CLIENT -->|"POST /v2/users/login"| TOKEN["JWT bearer token"]
    TOKEN --> OPS
    subgraph OPS["Policies API"]
        P["/v2/orgs/{org}/governance/policies<br/>create · get · patch · delete"]
        R["rules: create · patch · delete<br/>network: connect:tcp/udp<br/>fs: read/write"]
    end
    OPS --> POLICY[("Org policy — same store as the UI")]
    POLICY -. "≤5 min · sbx policy reset" .-> DEV["sbx policy ls → ORIGIN: remote"]

    classDef api fill:#eef2ff,stroke:#6366f1,color:#000
    classDef pol fill:#fff7ed,stroke:#f59e0b,color:#000
    class CLIENT,TOKEN,P,R api
    class POLICY,DEV pol
```

*The same control plane as the Admin Console, driven by HTTP: mint a token, CRUD policies and rules as plain REST resources, and they land in the same org policy — showing up as `remote` on a developer's machine within minutes.*

If you took the **API / CLI** path in **Network Enforcement Demo** and **Filesystem Enforcement Demo**, you've already driven this control plane once - the `setup-policies.sh` helper wraps exactly the calls below. This section unpacks what that script does, endpoint by endpoint, so you can build your own tooling on top.

The Admin Console UI is perfect for a human making a one-off change. It's the wrong tool for **codifying governance**: putting policies in version control, applying them from CI, or building admin tooling.

The **Docker AI Governance API** is the programmatic version of the same control plane. Same policies, same rules, same `<your-org>` - driven by HTTP instead of clicks.

Substitute `<your-org>` with your Docker Hub organization (where you have admin rights).

!!! warning "Important"
    **Admin + paid feature.** These endpoints manage org-wide governance for `<your-org>`. You need org-owner/admin credentials and an org with AI Governance enabled. The `curl` blocks below are templates - they need a real token and your org name, so they're not click-to-run.

**Time:** ~15 minutes
**Prerequisites:** You're an owner/admin of `<your-org>`. Conceptually, you've completed **The Policy Model** through **Filesystem Enforcement Demo** so the policy/rule model is familiar.

## The model

- **Base URL:** `https://hub.docker.com/v2`
- An **organization** contains **policies**. Each policy holds **rules**, grouped by **domain** - `network` or `filesystem`.
- Rules carry an **allow / deny** decision. **Deny always wins** when multiple rules match - the same precedence you proved by hand in **Network Enforcement Demo**.
- Changes **propagate to developer machines within five minutes** - the same sync you forced with `sbx policy reset`.

This is the API behind the buttons. Nothing new to learn about *how policy works* - only *how to drive it*.

## Step 1 - Get a bearer token

All calls use a JWT bearer token. Exchange your credentials (password, Personal Access Token, or Organization Access Token) at the auth endpoint:

```bash
curl -X POST https://hub.docker.com/v2/users/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "your-username",
    "password": "your-password-or-pat"
  }'
```

Response:

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

Capture it for the rest of the session. **Prefer a PAT or Organization Access Token over your account password** - scoped tokens are revocable and safer in scripts and CI:

```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## Step 2 - List existing policies

```bash
curl -X GET https://hub.docker.com/v2/orgs/<your-org>/governance/policies \
  -H "Authorization: Bearer $TOKEN"
```

Response (shallow summaries - note there are **no rules** here yet):

```json
{
  "data": [
    {
      "created_at": "2026-04-22T00:00:00Z",
      "id": "pol_06evsmp24r1pg71cm8500546pkbn",
      "name": "Security Research - hardened",
      "org": "<your-org>",
      "scope": {
        "teams": [
          "d290f1ee-6c54-4b01-90e6-d701748f0851"
        ]
      },
      "type": "allowlist_v0",
      "updated_at": "2026-04-22T00:00:00Z"
    }
  ]
}
```

The list view is intentionally shallow - to see a policy's rules you fetch it by ID (Step 4). `scope.teams` is how a policy targets a subset of the org rather than everyone.

## Step 3 - Create a policy

```bash
curl -X POST https://hub.docker.com/v2/orgs/<your-org>/governance/policies \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Security Research - hardened",
    "scope": {
      "teams": [
        "d290f1ee-6c54-4b01-90e6-d701748f0851"
      ]
    }
  }'
```

A `201` returns the new policy, including the generated `id` you'll use for every rule call:

```json
{
  "created_at": "2026-04-22T00:00:00Z",
  "id": "pol_06evsmp24r1pg71cm8500546pkbn",
  "name": "Security Research - hardened",
  "org": "<your-org>",
  "scope": {
    "teams": [
      "d290f1ee-6c54-4b01-90e6-d701748f0851"
    ]
  },
  "updated_at": "2026-04-22T00:00:00Z"
}
```

`scope` is optional - omit it for an org-wide policy.

```bash
export POLICY_ID="pol_06evsmp24r1pg71cm8500546pkbn"
```

## Step 4 - Add a network rule

This is the API equivalent of **Network Enforcement Demo**'s "allow AI services" rule. Network actions are `connect:tcp` and `connect:udp`:

```bash
curl -X POST https://hub.docker.com/v2/orgs/<your-org>/governance/policies/$POLICY_ID/rules \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      "connect:tcp",
      "connect:udp"
    ],
    "decision": "allow",
    "name": "allow research mirrors",
    "resources": [
      "research.mitre.org",
      "cve.mitre.org"
    ]
  }'
```

Response:

```json
{
  "actions": [
    "connect:tcp",
    "connect:udp"
  ],
  "decision": "allow",
  "id": "rule_06evsm9qjm1pdsk0a8nkfaxy7jna",
  "name": "allow research mirrors",
  "resources": [
    "research.mitre.org",
    "cve.mitre.org"
  ]
}
```

To make this a **deny** rule (**Network Enforcement Demo**'s `deny exfiltration`), flip `"decision": "deny"` and list the destinations to block.

## Step 5 - Add a filesystem rule

Filesystem rules use `read` / `write` actions and path resources - the API form of **Filesystem Enforcement Demo**:

```bash
curl -X POST https://hub.docker.com/v2/orgs/<your-org>/governance/policies/$POLICY_ID/rules \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      "read",
      "write"
    ],
    "decision": "allow",
    "name": "allow data directory",
    "resources": [
      "/data"
    ]
  }'
```

```json
{
  "actions": [
    "read",
    "write"
  ],
  "decision": "allow",
  "id": "rule_07fwtnr0kn2qetl1b9olfbyz8kob",
  "name": "allow data directory",
  "resources": [
    "/data"
  ]
}
```

!!! note
    **A rule lives in one domain.** A single rule's actions must all be network (`connect:*`) **or** all filesystem (`read`/`write`) - you can't mix domains in one rule. Updates (`PATCH`) can't change a rule's domain either.

## Step 6 - Read the full policy back

Fetching a single policy by ID returns its rules under `allowlist_v0`:

```bash
curl -X GET https://hub.docker.com/v2/orgs/<your-org>/governance/policies/$POLICY_ID \
  -H "Authorization: Bearer $TOKEN"
```

```json
{
  "allowlist_v0": {
    "domain": "network",
    "rules": [
      {
        "actions": [
          "connect:tcp",
          "connect:udp"
        ],
        "decision": "allow",
        "id": "rule_06evsm9qjm1pdsk0a8nkfaxy7jna",
        "name": "allow research mirrors",
        "resources": [
          "research.mitre.org",
          "cve.mitre.org"
        ]
      }
    ]
  },
  "created_at": "2026-04-22T00:00:00Z",
  "id": "pol_06evsmp24r1pg71cm8500546pkbn",
  "name": "Security Research - hardened",
  "org": "<your-org>",
  "scope": {
    "teams": [
      "d290f1ee-6c54-4b01-90e6-d701748f0851"
    ]
  },
  "updated_at": "2026-04-22T00:00:00Z"
}
```

## The full endpoint surface

| Operation | Method & path |
| --- | --- |
| Get token | `POST /v2/users/login` |
| List policies | `GET /v2/orgs/{org}/governance/policies` |
| Create policy | `POST /v2/orgs/{org}/governance/policies` |
| Get policy (with rules) | `GET /v2/orgs/{org}/governance/policies/{policy_id}` |
| Update policy | `PATCH /v2/orgs/{org}/governance/policies/{policy_id}` |
| Delete policy | `DELETE /v2/orgs/{org}/governance/policies/{policy_id}` |
| Create rule | `POST /v2/orgs/{org}/governance/policies/{policy_id}/rules` |
| Update rule | `PATCH /v2/orgs/{org}/governance/policies/{policy_id}/rules/{rule_id}` |
| Delete rule | `DELETE /v2/orgs/{org}/governance/policies/{policy_id}/rules/{rule_id}` |

## Error handling

Errors come back as an envelope with a `code` and a `message`. The codes you'll actually hit:

| HTTP | Code | Usually means |
| --- | --- | --- |
| 401 | `unauthenticated` | Missing/expired token - re-run Step 1 |
| 403 | `permission_denied` | Token isn't an admin/owner of `<your-org>` |
| 403 | `limit_exceeded` | You've hit a policy/rule quota |
| 400 | `invalid_argument` | Malformed body - e.g. mixing network + filesystem actions in one rule |
| 409 | `conflict` | Name collision or concurrent modification |
| 404 | `not_found` | Wrong `org`, `policy_id`, or `rule_id` |
| 500 | `internal` | Server-side - retry, then file a report |

## Verify it landed on a developer machine

The API and the CLI are two ends of one system. After creating rules via the API, confirm they reach a developer exactly like a Console change would - within ~5 minutes, or immediately after a `sbx policy reset`:

```bash
sbx policy reset   # force a sync; choose Balanced when prompted
sbx policy ls      # your API-created rules now show as ORIGIN: remote
```

This is the satisfying close of the loop: a rule you `POST`ed to Hub shows up as `remote` in `sbx policy ls` on a developer's laptop, and shows up again in `sbx policy log` / the audit record the moment it decides a request.

## What you just demonstrated

- Governance for `<your-org>` is fully scriptable - policies and rules are plain REST resources
- Network rules (`connect:tcp`/`connect:udp`) and filesystem rules (`read`/`write`) map one-to-one to what you set by hand in **Network Enforcement Demo** and **Filesystem Enforcement Demo**
- "Deny always wins" and the ~5-minute propagation are the same guarantees, regardless of whether a human or a pipeline made the change
- You can now put governance in version control and apply it from CI - the foundation for governance-as-code

The [`setup-policies.sh`](https://github.com/ajeetraina/labspace-docker-ai-governance/blob/main/labspace/assets/setup-policies.sh) helper offered in **Network Enforcement Demo** and **Filesystem Enforcement Demo** is a minimal, idempotent reference for all of the above - fork it as the starting point for your own pipeline.
