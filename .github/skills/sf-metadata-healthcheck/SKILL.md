---
name: sf-metadata-healthcheck
description: "Toolkit for running lightweight Salesforce metadata checks in a Salesforce DX project before PRs or deploys. Use when asked to find hardcoded IDs, identify risky profile diffs, verify Flow API versions, inspect destructive changes, spot duplicate metadata, or review missing permission and custom label follow-up work."
---

# Salesforce Metadata Healthcheck

Use this skill to catch cheap, high-signal metadata issues before deployment or review.

## When to Use This Skill

- Before opening or reviewing a pull request.
- Before generating a deploy delta.
- Before validating destructive changes.
- When a change touches profiles, permission sets, flows, custom fields, or Apex.

## Scripts

- [`check-hardcoded-ids.ps1`](./scripts/check-hardcoded-ids.ps1)
- [`check-missing-custom-labels.ps1`](./scripts/check-missing-custom-labels.ps1)
- [`check-missing-permset-fields.ps1`](./scripts/check-missing-permset-fields.ps1)
- [`check-destructive-without-backup.ps1`](./scripts/check-destructive-without-backup.ps1)
- [`check-profile-noise.ps1`](./scripts/check-profile-noise.ps1)
- [`check-flow-api-version.ps1`](./scripts/check-flow-api-version.ps1)
- [`check-duplicate-metadata.ps1`](./scripts/check-duplicate-metadata.ps1)

## Gotchas

- **Some checks are heuristic by design**. Treat warnings as review prompts, not guaranteed defects.
- **Hardcoded string detection is intentionally conservative**. It looks for likely user-facing literals, not every literal in source code.
- **Permission checks do not know your business intent**. They flag likely follow-up work when fields change without visible access updates.
