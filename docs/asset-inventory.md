# Asset inventory

This inventory summarizes what was included in v1 and what was intentionally left out.

## Publish now

| Asset | Type | Portability notes |
| --- | --- | --- |
| `.github/instructions/*.md` | Instructions | Mostly portable after wording cleanup |
| `create-apex-test-class` | Skill | Generalized to remove repo-local class references |
| `sf-apex-test-runner` | Skill | Reusable for standard Salesforce DX repositories |
| `sf-delta-builder` | Skill | Reusable for standard manifest-based delta packaging |
| `sf-metadata-healthcheck` | Skill | Reusable with documented standard-path assumptions |
| `sf-org-drift-detector` | Skill | Reusable for shared-org drift checks |
| `sf-sandbox-refresh-helper` | Skill | Reusable with documented `config/sandbox` convention |
| `salesforce-release-packager.agent.md` | Agent | Portable after wording cleanup |
| `salesforce-copilot-asset-evolver.agent.md` | Agent | Portable research-first specialist for evolving reusable Copilot assets |
| `.github/scripts/salesforce/*.psm1` and `run-skill-ps1.sh` | Shared scripts | Required by multiple skills |
| skill `examples/` and `templates/` folders | Bundled resources | Safe starting points and sample outputs for copied skills |
| GitHub community health files | Repo metadata | Public contribution templates aligned with portable asset rules |

## Deferred from v1

| Asset | Reason |
| --- | --- |
| `.github/workflows/jira-to-issue.yml` | Useful automation, but outside the core reusable Copilot-asset scope |
| Marketplace metadata and site/catalog files | Deliberately out of scope for a lean first release |

## Known assumptions

- Most helpers default to the standard Salesforce DX metadata root `force-app/main/default/`.
- Manifest-aware scripts default to `manifest/package.xml`.
- Sandbox refresh scripts default to `config/sandbox/` and `.sf/copilot/`.
- Skill consumers should review and adapt heuristics before using them in a production release process.

## Configurable overrides

Use these environment variables when a copied repository uses different locations:

- `SALESFORCE_COPILOT_METADATA_ROOT`
- `SALESFORCE_COPILOT_MANIFEST_PATH`
- `SALESFORCE_COPILOT_SANDBOX_CONFIG_ROOT`
- `SALESFORCE_COPILOT_WORK_ROOT`
