# salesforce-copilot

A lean, public collection of reusable GitHub Copilot assets for Salesforce DX projects.

This repository packages practical **instructions**, **skills**, **agents**, and **helper scripts** that can be copied into another Salesforce repository and adapted with minimal work. It is inspired by [`github/awesome-copilot`](https://github.com/github/awesome-copilot), but it stays intentionally narrow: no marketplace catalog, no site generation, and no unrelated workflow automation in v1.

## What is included

| Asset type | Location | Purpose |
| --- | --- | --- |
| Instructions | `.github/instructions/` | Project-wide guidance applied by file pattern |
| Skills | `.github/skills/` | Reusable task workflows for Salesforce development |
| Agents | `.github/agents/` | Specialized Copilot agents for focused work |
| Shared scripts | `.github/scripts/salesforce/` | Shared PowerShell modules and shell helpers used by bundled skills |
| Docs | `docs/` | Installation, structure, workflow selection, migration, and inventory guidance |

## Included assets

### Instructions

- `salesforce-apex.instructions.md`
- `salesforce-destructive-changes.instructions.md`
- `salesforce-flow.instructions.md`
- `salesforce-lwc.instructions.md`
- `salesforce-manifest.instructions.md`
- `salesforce-profile-permissions.instructions.md`
- `salesforce-visualforce.instructions.md`
- `powershell.instructions.md`
- `markdown.instructions.md`
- `instructions.instructions.md`
- `agents.instructions.md`
- `agent-skills.instructions.md`
- `github-actions-ci-cd.instructions.md`

### Skills

- `create-apex-test-class`
- `sf-apex-test-runner`
- `sf-delta-builder`
- `sf-metadata-healthcheck`
- `sf-org-drift-detector`
- `sf-sandbox-refresh-helper`

### Agents

- `salesforce-release-packager.agent.md`
- `salesforce-copilot-asset-evolver.agent.md`

## Design goals

- Keep the collection **portable** across Salesforce DX repositories.
- Prefer **standard conventions** over org-specific assumptions.
- Preserve **high-signal guidance** without overfitting to one codebase.
- Ship **standalone skill folders** together with the shared modules they need.

## Assumptions

The initial version targets Salesforce DX projects that use common conventions such as:

- `force-app/main/default/`
- `manifest/`
- `sfdx-project.json`

Some bundled scripts assume that layout. Where that assumption matters, it is documented explicitly instead of hidden.

## Quick start

1. Copy `.github/instructions/` into your Salesforce repo.
2. Copy the skills you want from `.github/skills/`.
3. Copy `.github/scripts/salesforce/` as well if you use skills that rely on shared PowerShell modules or shell wrappers.
4. Copy `.github/agents/` if you want the packaged agent definitions.
5. Review the copied assets and adjust naming conventions, test heuristics, and config paths for your project.

## Portable script configuration

Bundled scripts still default to standard Salesforce DX conventions, but you can now override the most common layout assumptions with environment variables:

- `SALESFORCE_COPILOT_METADATA_ROOT`
- `SALESFORCE_COPILOT_MANIFEST_PATH`
- `SALESFORCE_COPILOT_SANDBOX_CONFIG_ROOT`
- `SALESFORCE_COPILOT_WORK_ROOT`

Use the bundled `.sh` wrappers on macOS or Linux when `pwsh` is available, or call the `.ps1` scripts directly.

## Start with these assets

- Use `sf-delta-builder` for deploy package generation.
- Use `sf-metadata-healthcheck` for cheap metadata checks before review or deployment.
- Use `sf-apex-test-runner` for safer Apex test-scope decisions.
- Use `create-apex-test-class` when you want reusable Apex testing guidance without repo-local examples.
- Use [the skill selection guide](./docs/skill-selection-guide.md) when you need to combine multiple skills for one Salesforce workflow.
- Use `salesforce-copilot-asset-evolver.agent.md` when you want a research-first specialist to identify relevant ecosystem changes and update the repository assets they affect.

## What is intentionally out of scope

- Full `awesome-copilot` parity
- Marketplace packaging
- Site generation or search catalogs
- Non-Copilot workflow automation that is unrelated to reusable Salesforce Copilot assets

## Documentation

- [Installation guide](./docs/install.md)
- [Skill selection guide](./docs/skill-selection-guide.md)
- [Repository structure](./docs/structure.md)
- [Migration guide](./docs/migration-guide.md)
- [Asset inventory](./docs/asset-inventory.md)

## License

This repository is licensed under the [MIT License](./LICENSE).
