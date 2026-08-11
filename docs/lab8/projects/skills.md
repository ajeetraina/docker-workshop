# Sharing Agent Skills Across Sandboxes

You've governed *where* an agent can reach and *what* it can see. This module is about the other half of the story: giving the agent **new capabilities** - Agent Skills - without punching a hole in the isolation you just built.

An **Agent Skill** is a folder with a `SKILL.md` file: a name, a description, and a set of instructions the agent loads on demand when the task matches. Claude Code, Codex, Copilot, Cursor, and Droid all read skills from a directory in the user's home. The problem in a sandboxed world: that directory lives on your **host**, and the whole point of sbx is that the VM can't see your host home.

sbx solves this with a **central skills store** - a single directory you import skills into, which sbx mounts into every skills-enabled sandbox. Author a skill once on the host, import it, and every agent in every sandbox picks it up. Nothing else from your home directory comes along for the ride.

!!! note "Experimental"
    `sbx skills` is an experimental command and may change in a future release. The flow below was validated against `sbx v0.38.x`.

---

## How the skills store works

There are two pieces:

- **`sbx skills import`** - copies skill folders from the supported host directories into a persistent store that lives under the sbx state directory.
- **The mount** - any sandbox created with skills sharing enabled (the default) gets that store mounted **read-write** at `~/.agents/skills` inside the VM, where supported agents look for skills.

sbx scans these host source directories, in order (first match wins on a name conflict):

```
~/.agents/skills
~/.claude/skills
~/.copilot/skills
~/.cursor/skills
~/.factory/skills
```

If two sources contain a skill with the **same name**, the earlier source wins and the later one is skipped with a warning. This is deliberate: you get one canonical version of each skill in the store, not five copies fighting over the same name.

> **Why this matters:** The skill folder is the *only* thing that crosses into the VM. Your `~/.claude/settings.json`, your credentials, your shell history - none of it comes along. The store is a narrow, explicit channel: you choose what goes in with `sbx skills import`, and that's all the agent sees. It's the same principle as the workspace mount - share exactly one thing, on purpose.

---

## Step 1 - Author a skill on the host

A skill is just a directory with a `SKILL.md`. The YAML frontmatter's `description` is what the agent uses to decide *when* to load the skill, so make it specific.

Create one for the DevBoard app you've been working with:

```bash
mkdir -p ~/.claude/skills/devboard-triage
cat > ~/.claude/skills/devboard-triage/SKILL.md <<'EOF'
---
name: devboard-triage
description: Triage DevBoard issues. Use when asked to label, prioritize, or summarize bugs in the DevBoard FastAPI + Next.js issue tracker.
---

# DevBoard Triage

When triaging a DevBoard issue:

1. Read the issue title and body.
2. Assign a **severity**: `critical`, `high`, `medium`, or `low`.
3. Assign a **component**: `api`, `web`, `db`, or `infra`.
4. Suggest the smallest reproduction step.
5. Output a one-line summary in the form:
   `[severity][component] <short summary>`

Prefer `critical` for data loss, auth bypass, or crashes on startup.
EOF
```

!!! tip "You don't have to use `~/.claude`"
    Any of the five source directories works. If you don't run Claude Code on your host at all, drop the skill in `~/.agents/skills` instead - that's the vendor-neutral location sbx scans first.

---

## Step 2 - Preview the import

Before copying anything, do a dry run. It tells you exactly what *would* land in the store and flags any name collisions:

```bash
sbx skills import --dry-run
```

```
Would import skill "devboard-triage"
Dry run: 1 skill(s) would be imported into
  .../com.docker.sandboxes/sandboxes/agent-skills
```

If the same skill name exists in more than one source directory, you'll see a `skipping ... already imported from an earlier source` warning here - your cue to reconcile them before importing for real.

---

## Step 3 - Import into the store

```bash
sbx skills import
```

You'll be prompted before any **existing** skill in the store is overwritten (each replaced folder is backed up first, so a bad import can't silently clobber a good skill). To skip all prompts in a scripted setup, add `--force`.

Confirm what's in the store:

```bash
sbx skills ls
```

```
Skills store: .../com.docker.sandboxes/sandboxes/agent-skills
devboard-triage
```

> **Note:** Importing copies the skill into the store - it does **not** live-link your host folder. Edit the skill on the host and you must re-run `sbx skills import` to push the change. The reimport replaces the store folder wholesale, so stale files from an old version can't linger.

---

## Step 4 - Use the skill inside a sandbox

Skills are mounted at sandbox **creation** time, so create a fresh sandbox after importing (an already-running session won't pick up newly imported skills until it rescans). From your `~/sbx-lab` workspace:

```bash
cd ~/sbx-lab
sbx run sbxlab
```

Prove the store is actually inside the VM - open a shell into the sandbox (from the [SSH module](ssh-access.md), or with `sbx exec`) and look:

```bash
sbx exec sbxlab ls ~/.agents/skills
```

```
devboard-triage
```

There it is - mounted from the central store, not copied from your host home. Now give the agent a task that matches the skill's description:

```
Triage this DevBoard issue: "Login returns 500 when the email field is empty.
Stack trace points at auth/session.py."
```

The agent loads `devboard-triage` and responds in the format the skill defined - a severity, a component, and a one-line summary like `[critical][api] 500 on empty-email login`. You taught it a house style once; every sandbox now speaks it.

---

## Step 5 - Opt a sandbox out of skills

Sharing is on by default. When you want a sandbox with **none** of your skills - a clean-room run, or an untrusted workspace where you don't want your instructions influencing the agent - opt out at creation:

```bash
sbx create --no-share-skills --name cleanroom codex .
```

Inside that sandbox the store simply isn't mounted:

```bash
sbx exec cleanroom ls ~/.agents/skills
# ls: cannot access '/home/agent/.agents/skills': No such file or directory
```

The choice is made at creation and is per-sandbox, so you can run a skills-enabled sandbox and a clean-room sandbox on the same host at the same time.

---

## Where skills fit in the governance model

Skills sit on the same "share exactly what you mean to" principle as everything else in this lab:

| Concern | How the skills store handles it |
|---|---|
| **Explicit surface** | Only folders you `import` reach the VM - never your whole host home. |
| **One canonical copy** | First-source-wins dedup means one version per name, not five in conflict. |
| **No stale state** | Reimport replaces a skill folder wholesale; overwrites are backed up first. |
| **Per-sandbox opt-out** | `--no-share-skills` gives you a clean-room run with zero shared skills. |
| **Auditable & disposable** | The store is a plain directory; `sbx reset` clears it along with all sandbox state. |

A skill is instructions, not credentials - but it *is* input the agent will act on. Treat a skill you didn't write like any other untrusted content: read the `SKILL.md` before you import it, exactly as you'd read a dependency before adding it to a project.

!!! warning "Only supported agents get skills"
    The store is mounted for **Claude, Codex, Copilot, Cursor, and Droid** agents. A bare `shell` sandbox won't have `~/.agents/skills` at all - there's no agent there to consume them.

---

## ✅ Checkpoint

Before moving on, confirm:

- [ ] You authored a `SKILL.md` under one of the five source directories
- [ ] `sbx skills import --dry-run` previewed the import (and flagged any name clashes)
- [ ] `sbx skills import` copied it and `sbx skills ls` lists it in the store
- [ ] `sbx exec sbxlab ls ~/.agents/skills` shows the skill **inside** the VM
- [ ] The agent used the skill on a matching prompt
- [ ] `--no-share-skills` produced a sandbox with **no** skills mounted
- [ ] You understand the store is the *only* thing shared - not your host home

Next: the governance summary - the full architecture pulled together.
