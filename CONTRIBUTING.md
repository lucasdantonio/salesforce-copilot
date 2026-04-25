# Contributing

Thanks for contributing to `salesforce-copilot`.

## Contribution standard

Every contribution should make the collection more reusable across Salesforce DX projects, not more coupled to a single repository or org.

## Scope

Good contributions usually do one or more of the following:

- improve a reusable skill, instruction, or agent
- remove project-specific assumptions
- document a standard Salesforce DX convention more clearly
- add helper scripts that support bundled skills
- fix broken links, references, or portability issues

Avoid contributions that:

- hardcode local class names, org names, usernames, or internal prefixes
- assume one company-specific release process
- add unrelated GitHub Actions automation to the core collection
- introduce assets that cannot be used outside one codebase

## Authoring rules

- Write all files and docs in English.
- Keep asset descriptions explicit so Copilot can discover them.
- Prefer standard Salesforce DX folder conventions.
- If a script depends on a convention, document it clearly.
- If an asset is only safe for a narrow workflow, state that in the asset itself.

## Authoring workflow

Before opening a pull request, draft against the [asset authoring checklist](./docs/asset-authoring-checklist.md) and use the [asset type decision guide](./docs/asset-type-decision-guide.md) when deciding where new logic belongs.

## Pull request checklist

- [ ] The change is reusable across multiple Salesforce DX projects.
- [ ] Project-specific references were removed or documented as examples only.
- [ ] `copilot-asset-validator` was run and any errors were fixed.
- [ ] Relative links and bundled-resource references still work.
- [ ] New or updated docs are written in English.
- [ ] PowerShell scripts remain non-interactive unless interaction is the explicit purpose.

## Repository layout

See [docs/structure.md](./docs/structure.md) for the intended structure and [docs/migration-guide.md](./docs/migration-guide.md) for guidance on turning repo-local assets into portable ones.
