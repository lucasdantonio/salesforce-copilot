---
name: sf-sandbox-refresh-helper
description: "Toolkit for post-refresh Salesforce sandbox tasks. Use when asked to reconfigure endpoints, disable real integrations, create integration users, assign permission sets, import seed data, or run a repeatable sandbox post-refresh workflow after a sandbox refresh."
---

# Salesforce Sandbox Refresh Helper

Use this skill to reduce the manual checklist after a sandbox refresh.

## When to Use This Skill

- Right after refreshing a sandbox.
- When integration endpoints need sandbox-safe values.
- When seed data, integration users, or permission assignments need to be recreated.
- When a repeatable post-refresh flow should run from config instead of manual clicks.

## Config Convention

By default, these scripts look for optional config files under `config/sandbox/`:

- `post-refresh-package.xml`
- `post-refresh.apex`
- `integration-users.json`
- `permset-assignments.json`
- `seed-data-plan.json`

Override those defaults with:

- `SALESFORCE_COPILOT_SANDBOX_CONFIG_ROOT`
- `SALESFORCE_COPILOT_WORK_ROOT`

## Scripts

- [`post-refresh.ps1`](./scripts/sandbox/post-refresh.ps1)
- [`fix-named-credentials.ps1`](./scripts/sandbox/fix-named-credentials.ps1)
- [`create-integration-users.ps1`](./scripts/sandbox/create-integration-users.ps1)
- [`assign-permsets.ps1`](./scripts/sandbox/assign-permsets.ps1)
- [`load-seed-data.ps1`](./scripts/sandbox/load-seed-data.ps1)

## Templates

- [Example post-refresh package](./templates/post-refresh-package.xml)
- [Example post-refresh Apex](./templates/post-refresh.apex)
- [Example integration users config](./templates/integration-users.json)
- [Example permission set assignments](./templates/permset-assignments.json)
- [Example seed-data plan](./templates/seed-data-plan.json)

## Gotchas

- **Keep production integrations disabled by default** in post-refresh Apex or metadata config.
- **Use fake or sandbox-safe emails** for seeded users and test data.
- **Treat config files as automation inputs**, not one-off scripts hidden on a laptop.

## Related Skills

- [`sf-metadata-healthcheck`](../sf-metadata-healthcheck/SKILL.md)
- [`sf-delta-builder`](../sf-delta-builder/SKILL.md)
