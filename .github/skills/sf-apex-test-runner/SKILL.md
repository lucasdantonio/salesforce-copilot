---
name: sf-apex-test-runner
description: "Toolkit for deciding and running the safest Apex test scope for Salesforce changes in a Salesforce DX project. Use when asked which tests to run, whether RunLocalTests is necessary, how to find tests related to changed Apex or metadata, or to execute specified, changed-related, all-local, or no-test plans."
---

# Salesforce Apex Test Runner

Use this skill when a task needs a deliberate Apex test scope instead of defaulting to the most expensive option.

## When to Use This Skill

- The user asks which Apex tests should run for a change.
- A deploy or validation needs the smallest safe test scope.
- A pull request changed Apex, triggers, flows, object metadata, or permission-sensitive code.
- The user wants to run explicit test classes by name.

## Modes

- `all-local`: use when metadata impact is broad or uncertain.
- `specified`: use when the user passes exact tests or only a few test classes changed.
- `changed-related`: use when related tests can be found confidently from changed metadata.
- `none`: use when the change is documentation-only or otherwise outside Apex impact.

## Scripts

- [`detect-test-scope.ps1`](./scripts/detect-test-scope.ps1) chooses the best mode for the current diff.
- [`find-related-tests.ps1`](./scripts/find-related-tests.ps1) lists candidate tests related to changed files.
- [`print-test-plan.ps1`](./scripts/print-test-plan.ps1) prints a human-readable plan.
- [`run-apex-tests.ps1`](./scripts/run-apex-tests.ps1) runs the selected scope with Salesforce CLI.

## Gotchas

- **Changed-related is heuristic**. If the repository impact is broad, prefer `all-local`.
- **Specified tests still need to exist in the org**. Keep local source and deployed source aligned.
- **Metadata-only changes can still affect Apex behavior** when they touch objects, flows, layouts, or permissions.
