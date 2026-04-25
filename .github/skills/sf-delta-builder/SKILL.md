---
name: sf-delta-builder
description: "Toolkit for building Salesforce deployment deltas from git changes in a Salesforce DX project. Use when asked to generate package.xml, create destructiveChanges manifests, summarize changed metadata, compare branches or commits, or prepare a minimal deployment package for Apex, LWC, Visualforce, Flow, and related metadata."
---

# Salesforce Delta Builder

Use this skill to build a deployable metadata delta from git history instead of editing manifests by hand.

## When to Use This Skill

- The user asks for a delta deploy package.
- A pull request needs `package.xml` updates from changed metadata.
- A release includes deleted metadata and needs `destructiveChanges`.
- The user wants a summary of what changed between two refs.

## Scripts

- [`git-changed-files.ps1`](./scripts/git-changed-files.ps1) lists changed files with git status codes.
- [`build-package-xml.ps1`](./scripts/build-package-xml.ps1) generates a package manifest for added or modified metadata.
- [`build-destructive-changes.ps1`](./scripts/build-destructive-changes.ps1) generates a destructive manifest for deleted or renamed metadata.
- [`print-delta-summary.ps1`](./scripts/print-delta-summary.ps1) prints a metadata-aware summary of the delta.

## Typical Workflow

1. List changes between the base and head refs.
2. Generate a package manifest for additive metadata.
3. Generate a destructive manifest for deletions when needed.
4. Print a summary and review any unmapped files before deploying.

## Gotchas

- **Renames can behave like delete plus add**. Review the destructive manifest if a metadata member name changed.
- **Not every file under `force-app` is deployable metadata**. Unmapped files should be reviewed, not blindly ignored.
- **Do not overwrite the project's main `manifest/package.xml` by accident**. Use generated output paths unless the task explicitly requires replacing the primary manifest.
