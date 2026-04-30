# Installation

This repository is designed to be copied into an existing Salesforce DX project.

## Minimum install

Copy the assets you need into the target repository:

1. `.github/instructions/`
2. `.github/skills/`
3. `.github/agents/` if you want the packaged agent
4. `.github/scripts/salesforce/` if you use any bundled PowerShell-driven skills

## Recommended install flow

1. Start with the instruction files that match your project.
2. Add only the skills your team will actually use.
3. Copy the shared PowerShell modules before running skills that import them.
4. Review every copied skill for naming or path conventions that should match your repository.

## Shared script dependency

Several skills import helper modules from:

```text
.github/scripts/salesforce/
```

If you copy a skill folder without those shared modules, some scripts will fail to import required functions.

The `copilot-asset-validator` skill is self-contained and does not depend on `.github/scripts/salesforce/`.

## Project assumptions

The current version assumes common Salesforce DX conventions such as:

- `force-app/main/default/`
- `manifest/package.xml`
- `sfdx-project.json`

If your project uses a different layout, adapt the copied scripts or document your equivalent paths locally.

## Suggested first rollout

1. Install all instruction files.
2. Install `copilot-asset-validator`.
3. Install `sf-delta-builder`.
4. Install `sf-metadata-healthcheck`.
5. Install `sf-apex-test-runner`.
6. Add the remaining skills only after validating they fit your project workflow.
