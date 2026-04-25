# Agent guidance

Use this repository to build **portable Salesforce Copilot assets**.

## Core rules

- Keep every asset reusable across multiple Salesforce DX projects.
- Prefer standard Salesforce DX conventions over company-specific structure.
- Remove repo-local references such as internal class names, custom prefixes, usernames, or org identifiers.
- Write all docs and instructions in English.
- When a script depends on a path convention, either document it clearly or make it configurable.

## Editing guidance

- Preserve the folder contract for bundled assets:
  - `.github/instructions/`
  - `.github/skills/`
  - `.github/agents/`
  - `.github/scripts/salesforce/`
- Do not move shared PowerShell modules out of `.github/scripts/salesforce/` unless all importing skills are updated.
- Keep skill descriptions concrete and discoverable.
- Do not add repo-specific examples unless they are clearly marked as examples and remain generally useful.

## Quality bar

- Skills should explain when to use them and what to avoid.
- Instructions should be concise, actionable, and pattern-based.
- Agents should focus on a specialized responsibility with clear guardrails.
- Shared scripts should be safe, readable, and easy to adapt to another Salesforce DX repo.
