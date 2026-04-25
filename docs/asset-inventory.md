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
| `.github/scripts/salesforce/*.psm1` | Shared scripts | Required by multiple skills |

## Deferred from v1

| Asset | Reason |
| --- | --- |
| `.github/workflows/jira-to-issue.yml` | Useful automation, but outside the core reusable Copilot-asset scope |
| Marketplace metadata and site/catalog files | Deliberately out of scope for a lean first release |

## Known assumptions

- Most PowerShell helpers assume the standard Salesforce DX metadata root `force-app/main/default/`.
- Manifest-aware scripts assume a conventional `manifest/` folder.
- Skill consumers should review and adapt heuristics before using them in a production release process.
