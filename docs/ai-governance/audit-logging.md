# Audit Logging

```mermaid
flowchart LR
    GOV["Governance active for your org<br/>(required — else no audit)"] --> AUDITKIT
    subgraph HOST["Host machine"]
        AUDITKIT["auditkit"]
        TMP[".tmp (active, incomplete)"]
        JSONL["audit-*.jsonl (sealed)<br/>+ user · org · session"]
        AUDITKIT --> TMP
        TMP -- "seal & rename" --> JSONL
    end
    JSONL -- "collect *.jsonl only" --> SHIP["Splunk UF · Filebeat · LogScale"] --> SIEM["SIEM"]

    classDef pol fill:#fff7ed,stroke:#f59e0b,color:#000
    classDef audit fill:#f3e8fd,stroke:#9333ea,color:#000
    classDef idle fill:#f1f5f9,stroke:#94a3b8,color:#000
    class GOV pol
    class AUDITKIT,JSONL,SHIP,SIEM audit
    class TMP idle
```

*The purpose-built `auditkit` surface: one sealed JSONL event per decision, now carrying user, org, and session — the SIEM-grade trail **Observability** said was missing. Collect the `.jsonl` files, skip the `.tmp`.*

**Observability** looked at the raw `daemon.log` and was honest about its limits: it answered *what* was decided, but it had **no user identity, no org, no session correlation**. We noted user attribution was on the roadmap.

That roadmap item shipped. Docker AI Governance now writes a separate, purpose-built **audit log** through a component called `auditkit` - structured JSON Lines, one event per policy decision, **with the signed-in user, the org, and a session ID on every record**. This section is the SIEM-grade surface the security team actually asked for.

Substitute `<your-org>` with your Docker Hub organization (where you have admin rights).

!!! warning "Important"
    **Paid feature.** Audit logging is part of Docker AI Governance (a separate paid subscription) and **only activates when `<your-org>` enforces a centralized governance policy**. With no governance applied, no audit records are written. Confirm governance is live first with `sbx policy ls` - look for the `Governance: managed by <your-org>` header from **The Policy Model**.

**Time:** ~10 minutes
**Prerequisites:** Governance is enforced for `<your-org>`, and you've run the **Network Enforcement Demo** enforcement tests so there are decisions to inspect.

## Step 1 - Confirm governance is active

Audit records only exist when governance is on:

```bash
sbx policy ls
```

If you don't see `Governance: managed by <your-org>` at the top, audit logging isn't running - go back to **Network Enforcement Demo** and enforce a policy first.

## Step 2 - Find the audit directory

Unlike `daemon.log` (under `Application Support`), audit records live under a dedicated `auditkit` directory that varies by OS:

| OS | Path |
| --- | --- |
| **macOS** | `~/Library/Logs/com.docker.sandboxes/sandboxes/auditkit/` |
| **Linux** | `${XDG_STATE_HOME:-~/.local/state}/sandboxes/sandboxes/auditkit/` |
| **Windows** | `%LOCALAPPDATA%\DockerSandboxes\sandboxes\logs\auditkit\` |

List the directory for your platform:

=== "macOS"

    ```bash
    AUDIT_DIR="$HOME/Library/Logs/com.docker.sandboxes/sandboxes/auditkit"
    ls -lh "$AUDIT_DIR"
    ```

=== "Windows"

    ```powershell
    $AuditDir = "$env:LOCALAPPDATA\DockerSandboxes\sandboxes\logs\auditkit"
    Get-ChildItem $AuditDir
    ```

=== "Linux"

    ```bash
    AUDIT_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sandboxes/sandboxes/auditkit"
    ls -lh "$AUDIT_DIR"
    ```

Files are named `audit-<utc-timestamp>-<process-uuid>-<seq>.jsonl`.

!!! note
    **Only read sealed `.jsonl` files.** The daemon writes the active file as `.tmp`, then atomically renames it to `.jsonl` when it seals. **Exclude `.tmp` files** from any inspection or collection - they're incomplete. Sealing happens at a rotation threshold (by default 5 minutes, 1000 events, or 50 MiB - whichever comes first) or on daemon shutdown.

## Step 3 - Read a record

Each line is one self-contained JSON event. Here's a complete network **deny** record:

```json
{
  "audit_event_id": "95e7257f-93c9-4f29-bde7-88830e2dae80",
  "timestamp": "2026-05-28T19:15:00.728933Z",
  "schema_version": "1.82.0",
  "category": "AUDIT_CATEGORY_EVALUATION",
  "decision": "AUDIT_DECISION_DENY",
  "username": "jordandoe",
  "user_email": "jordandoe@example.com",
  "org_id": "9f8e7d6c-5b4a-3210-fedc-ba9876543210",
  "org_name": "Acme Inc",
  "audit_session_id": "8a3bc076-79d0-4502-baf3-cc6ad35fb578",
  "resource_id": "example.com:443",
  "os": "macos",
  "app_version": "v0.31.0",
  "client_name": "sbx",
  "hostname": "host-machine",
  "deny_reason": [
    "no applicable policies for op(action=net:connect:tcp, resource=net:domain:example.com:443)"
  ],
  "action_type": "network_egress",
  "network_egress": { "protocol": "tcp" }
}
```

Compare this to the `daemon.log` event from **Observability**. The fields **Observability** said were **missing** are now present:

| What **Observability** reported missing | In the audit record |
| --- | --- |
| User identity | ✅ `username` **and** `user_email` |
| Org context | ✅ `org_id` + `org_name` |
| Session correlation | ✅ `audit_session_id` |
| Stable schema for SIEM | ✅ `schema_version` (a versioned contract) |

This is the honest update to **Observability**'s roadmap table: **user attribution shipped.**

## Step 4 - Query it with `jq`

The records are JSONL, so the same `jq` patterns from **Observability** apply - just pointed at the audit directory and using the new field names:

```bash
AUDIT_DIR="$HOME/Library/Logs/com.docker.sandboxes/sandboxes/auditkit"

# Concatenate sealed files only (skip .tmp), newest decisions last
cat "$AUDIT_DIR"/*.jsonl 2>/dev/null | jq -c 'select(.category == "AUDIT_CATEGORY_EVALUATION")' | tail -20

# Only denies, with who/what/why on one line
cat "$AUDIT_DIR"/*.jsonl 2>/dev/null \
  | jq -r 'select(.decision == "AUDIT_DECISION_DENY")
           | "\(.timestamp)  \(.user_email)  \(.resource_id)  \(.deny_reason[0])"'

# Count denies per user (the cross-user question Observability couldn't answer)
cat "$AUDIT_DIR"/*.jsonl 2>/dev/null \
  | jq -r 'select(.decision == "AUDIT_DECISION_DENY") | .user_email' \
  | sort | uniq -c | sort -rn
```

## The record schema

| Field | Purpose |
| --- | --- |
| `audit_event_id` | Unique ID for this event |
| `timestamp` | UTC time of the decision |
| `schema_version` | Record schema version - a stable contract for your SIEM parsers |
| `category` | `AUDIT_CATEGORY_EVALUATION` (a policy decision) or `AUDIT_CATEGORY_MANAGEMENT` (session lifecycle) |
| `decision` | `AUDIT_DECISION_ALLOW` or `AUDIT_DECISION_DENY` |
| `username` / `user_email` | The signed-in Docker user |
| `org_id` / `org_name` | The organization whose policy applied |
| `audit_session_id` | Identifies the daemon run; every evaluation record carries the matching session's ID |
| `action_type` | The kind of access, e.g. `network_egress` |
| `resource_id` | The evaluation target - host and port (or path) |
| `deny_reason` | Array explaining a denial |
| `os` / `app_version` / `client_name` / `hostname` | Environment context for the machine that made the decision |

### Two categories of record

- **Evaluation records** (`AUDIT_CATEGORY_EVALUATION`) - one per policy decision: the resource, the action, the verdict, and the deny reason. These are what you'll query most.
- **Session lifecycle records** (`AUDIT_CATEGORY_MANAGEMENT`) - mark daemon start/stop. Every evaluation record shares the `audit_session_id` of the management record that opened its session, so you can correlate decisions back to a specific daemon run.

## Step 5 - Ship it to your SIEM

This is the whole point: the directory is designed to be tailed by a standard log shipper. Point any of these at the `auditkit` directory:

- Splunk Universal Forwarder
- Elastic Filebeat
- CrowdStrike Falcon LogScale

Two operational rules to bake into the shipper config:

1. **Only collect `*.jsonl`** - exclude `*.tmp` so you never ingest a half-written file.
2. **Retention is your responsibility.** The daemon rotates and seals files but does not delete them on a retention schedule for you - your log shipper or housekeeping process owns retention. Records stay on the originating machine until something collects them.

## What you just demonstrated

- A dedicated, SIEM-ready audit surface (`auditkit`) exists separately from the raw `daemon.log`
- Every decision now carries **user, org, and session** attribution - closing the biggest honesty gap from **Observability**
- The `.tmp` → `.jsonl` seal-and-rename pattern means safe collection is just "grab the `.jsonl` files"
- Standard forwarders turn this into org-wide, cross-machine audit once aggregated in your SIEM

Next: managing the policies behind all of this programmatically, via the Governance API.
