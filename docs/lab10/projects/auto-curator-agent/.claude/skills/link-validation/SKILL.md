---
name: link-validation
description: Link validation patterns for the awesome list
---

# Link Validation Skill

## Check Each URL
- 200 OK → ✅ Live
- 301/302 → ⚠️ Update to final URL
- 403 → ⚠️ May be rate-limited, retry
- 404 → ❌ Broken, remove or replace
- 5xx → ⚠️ Temporary, recheck

## GitHub Repo Checks
1. Repo exists (not 404)
2. Not archived
3. Last commit < 6 months
4. Note star count for MCP entries

## Content Check
- Must mention "cagent" (not just generic Docker)
- Not outdated or deprecated

## Report Format
- ✅ VALID: URL works, content relevant
- ⚠️ WARNING: Works but may be outdated
- ❌ BROKEN: Returns error
- 🚫 REJECTED: Doesn't meet quality standards
