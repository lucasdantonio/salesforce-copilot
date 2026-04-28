# Skill selection guide

Use this guide to choose the smallest reusable asset set for a common Salesforce DX workflow.

## Deployment preparation

1. Start with `sf-metadata-healthcheck` for cheap metadata review.
2. Use `sf-delta-builder` to generate `package.xml` and `destructiveChanges` outputs.
3. Use `sf-apex-test-runner` to choose the safest test scope for the same change.

## Apex change delivery

1. Use `create-apex-test-class` to create or improve focused test coverage.
2. Use `sf-apex-test-runner` to choose related or all-local test execution.
3. Add `sf-metadata-healthcheck` if the change also touches profiles, permission sets, or flows.

## Sandbox refresh

1. Use `sf-sandbox-refresh-helper` to apply post-refresh config, Apex, user, and seed-data steps.
2. Use `sf-metadata-healthcheck` if refresh work also changes deployable metadata.

## Release packaging

1. Use `sf-org-drift-detector` before packaging when manual org changes are a risk.
2. Use `sf-delta-builder` to prepare deploy and destructive manifests.
3. Use `sf-apex-test-runner` to select the validation scope for the release.

## Repository maintenance

1. Use `salesforce-copilot-asset-evolver.agent.md` when the repository needs research-backed updates.
2. Use the bundled issue templates and PR template to keep improvements discoverable and portable.
