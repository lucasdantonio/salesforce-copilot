# Installation

This repository is designed to be copied into an existing Salesforce DX project.

## Minimum install

Copy the assets you need into the target repository:

1. `.github/instructions/`
2. `.github/skills/`
3. `.github/agents/` if you want the packaged agent
4. `.github/scripts/salesforce/` if you use any bundled PowerShell-driven skills or shell wrappers

## Recommended install flow

1. Start with the instruction files that match your project.
2. Add only the skills your team will actually use.
3. Copy the shared script helpers before running skills that import them.
4. Review every copied skill for naming or path conventions that should match your repository.

## Shared script dependency

Several skills import helper modules from:

```text
.github/scripts/salesforce/
```

If you copy a skill folder without those shared helpers, some scripts will fail to import required functions or shell launchers.

## Shell usage on macOS and Linux

Several core skills now include `.sh` wrappers beside the original `.ps1` scripts.

- The wrappers still require `pwsh` in `PATH`.
- Use the `.sh` entrypoints when your shell workflow prefers POSIX paths and quoting.
- Use the `.ps1` files directly on Windows or when PowerShell is already your standard shell.

## Project assumptions

The current version assumes common Salesforce DX conventions such as:

- `force-app/main/default/`
- `manifest/package.xml`
- `sfdx-project.json`

If your project uses a different layout, set one or more of these environment variables before running the bundled scripts:

- `SALESFORCE_COPILOT_METADATA_ROOT`
- `SALESFORCE_COPILOT_MANIFEST_PATH`
- `SALESFORCE_COPILOT_SANDBOX_CONFIG_ROOT`
- `SALESFORCE_COPILOT_WORK_ROOT`

The defaults stay aligned with standard Salesforce DX repos.

## Suggested first rollout

1. Install all instruction files.
2. Install `sf-delta-builder`.
3. Install `sf-metadata-healthcheck`.
4. Install `sf-apex-test-runner`.
5. Review the bundled templates and examples before adapting the remaining skills.
