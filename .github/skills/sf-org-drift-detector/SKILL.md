---
name: sf-org-drift-detector
description: "Toolkit for detecting Salesforce org drift before development starts. Use when asked to compare the repo with an org, retrieve critical metadata for drift checks, generate a drift report, or fail when production has manual changes outside Git for Flows, validation rules, permission sets, profiles, objects, fields, layouts, record types, Apex classes, and triggers."
---

# Salesforce Org Drift Detector

Use this skill before starting work on shared Salesforce metadata so manual org changes do not get silently overwritten.

## When to Use This Skill

- Before beginning work on shared metadata.
- Before a deploy to production or a shared sandbox.
- When developers suspect metadata changed directly in the org.
- When release validation must prove the org still matches Git.

## Drift Scope

This skill monitors:

- Flows
- Validation Rules
- Permission Sets
- Profiles
- Custom Objects
- Custom Fields
- Layouts
- Record Types
- Apex Classes
- Apex Triggers

## Scripts

- [`retrieve-org-metadata.ps1`](./scripts/drift/retrieve-org-metadata.ps1)
- [`compare-with-repo.ps1`](./scripts/drift/compare-with-repo.ps1)
- [`report-drift.ps1`](./scripts/drift/report-drift.ps1)
- [`fail-if-prod-drift.ps1`](./scripts/drift/fail-if-prod-drift.ps1)

## Example

- [Sample drift report](./examples/drift-report.json)

## Typical Workflow

1. Retrieve the monitored metadata from the target org into a temp directory.
2. Compare the retrieved source with the project state in Git.
3. Generate a drift report with additions, deletions, and content mismatches.
4. Fail fast if the target is production and unexpected drift exists.

## Gotchas

- **Run this before coding on shared metadata**, not after the branch is already deep.
- **Production drift is usually a release blocker** because the next deploy can overwrite manual fixes.
- **Custom object retrieval covers many child metadata types**, but the manifest also requests field, record type, and validation rule coverage explicitly to keep the intent obvious.

## Related Skills

- [`sf-delta-builder`](../sf-delta-builder/SKILL.md)
- [`sf-metadata-healthcheck`](../sf-metadata-healthcheck/SKILL.md)
