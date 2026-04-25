# Asset authoring checklist

Use this checklist while drafting or updating a reusable Copilot asset, before the pull request checklist in `CONTRIBUTING.md`.

## Before you start

- Confirm the change improves a portable Salesforce DX + GitHub Copilot asset, not repo-specific automation.
- Reuse an existing asset when the capability already fits there naturally.
- Prefer standard Salesforce DX conventions unless a different path or workflow is documented explicitly.

## Asset drafting checklist

- [ ] The asset type is correct for the job. Use [`docs/asset-type-decision-guide.md`](./asset-type-decision-guide.md) when unsure.
- [ ] The asset text is written in English.
- [ ] Repo-local names, usernames, org identifiers, internal prefixes, and company-only examples were removed or clearly marked as examples.
- [ ] Standard-path or config assumptions are documented where they matter.
- [ ] Relative links point to files that exist.
- [ ] New skills, agents, and instructions include clear frontmatter descriptions for discovery.
- [ ] New skills explain when to use them and include warnings for non-obvious constraints.
- [ ] New scripts stay non-interactive unless interaction is the explicit purpose.
- [ ] New PowerShell scripts include comment-based help with synopsis, description, and example usage.

## Validation workflow

Run the bundled validator from the repository root before review:

```powershell
pwsh -NoLogo -NoProfile -File .github/skills/copilot-asset-validator/scripts/validate-assets.ps1 -RootPath . -FailOnError
```

## Hand-off to review

- [ ] The validator reports no errors.
- [ ] Remaining warnings were reviewed and either fixed or accepted intentionally.
- [ ] README or docs were updated if the asset changes how contributors discover or use the repository.
