---
name: copilot-asset-validator
description: "Toolkit for validating GitHub Copilot instructions, skills, agents, docs, and bundled PowerShell scripts in a portable Salesforce DX repository. Use when asked to check asset quality, review frontmatter and required sections, detect broken relative links, flag weak descriptions, or catch portability risks before publishing or review."
---

# Copilot Asset Validator

Use this skill to run a cheap, repeatable quality pass over reusable Copilot assets before review or publication.

## When to Use This Skill

- Before opening a pull request that adds or updates instructions, skills, agents, docs, or bundled scripts.
- When a contributor asks for a consistency check across Copilot assets in a repository.
- When you want to catch broken relative links and weak discovery metadata early.
- When you want a portability-focused review without adding repo-specific automation.

## Scripts

- [`validate-assets.ps1`](./scripts/validate-assets.ps1) checks asset frontmatter, required sections, relative Markdown links, weak descriptions, portability risks, and PowerShell script help.

## Typical Workflow

1. Run the validator from the repository root.
2. Fix any reported errors first.
3. Review warnings for portability or discovery-quality follow-up.
4. Re-run the validator before opening or updating a pull request.

## Gotchas

- **The validator uses heuristics for quality and portability checks**. Review warnings as prompts for human judgment, not guaranteed defects.
- **Relative-link checks only verify file paths**. They do not validate in-document heading anchors.
- **This skill is self-contained**. It does not require `.github/scripts/salesforce/`.

## References

- [`docs/asset-authoring-checklist.md`](../../../docs/asset-authoring-checklist.md)
- [`docs/asset-type-decision-guide.md`](../../../docs/asset-type-decision-guide.md)
