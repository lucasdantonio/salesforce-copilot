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
- [`check-hardcoded-ids.sh`](./scripts/check-hardcoded-ids.sh)
- [`check-missing-custom-labels.ps1`](./scripts/check-missing-custom-labels.ps1)
- [`check-missing-custom-labels.sh`](./scripts/check-missing-custom-labels.sh)
- [`check-missing-permset-fields.ps1`](./scripts/check-missing-permset-fields.ps1)
- [`check-missing-permset-fields.sh`](./scripts/check-missing-permset-fields.sh)
- [`check-destructive-without-backup.ps1`](./scripts/check-destructive-without-backup.ps1)
- [`check-destructive-without-backup.sh`](./scripts/check-destructive-without-backup.sh)
- [`check-profile-noise.ps1`](./scripts/check-profile-noise.ps1)
- [`check-profile-noise.sh`](./scripts/check-profile-noise.sh)
- [`check-flow-api-version.ps1`](./scripts/check-flow-api-version.ps1)
- [`check-flow-api-version.sh`](./scripts/check-flow-api-version.sh)
- [`check-duplicate-metadata.ps1`](./scripts/check-duplicate-metadata.ps1)
- [`check-duplicate-metadata.sh`](./scripts/check-duplicate-metadata.sh)

## Example

- [Sample healthcheck summary](./examples/healthcheck-summary.txt)

## Gotchas

- **Some checks are heuristic by design**. Treat warnings as review prompts, not guaranteed defects.
- **Hardcoded string detection is intentionally conservative**. It looks for likely user-facing literals, not every literal in source code.
- **Permission checks do not know your business intent**. They flag likely follow-up work when fields change without visible access updates.

## Related Skills

- [`sf-delta-builder`](../sf-delta-builder/SKILL.md)
- [`sf-apex-test-runner`](../sf-apex-test-runner/SKILL.md)
- [`sf-sandbox-refresh-helper`](../sf-sandbox-refresh-helper/SKILL.md)
