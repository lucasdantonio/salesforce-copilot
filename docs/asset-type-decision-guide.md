# Asset type decision guide

Use this guide when deciding whether a new capability belongs in an instruction file, a skill, an agent, or a shared script.

## Choose the lightest asset that still solves the problem

| If the need is... | Prefer this asset | Why |
| --- | --- | --- |
| File-pattern-specific coding guidance | Instruction | Instructions apply automatically by file type and keep rules close to the code being generated. |
| A reusable workflow that Copilot should load on demand | Skill | Skills are discoverable, portable, and can bundle scripts or references with the workflow. |
| A specialized role with focused responsibilities and guardrails | Agent | Agents are best when the task needs a distinct operating model, not just a reusable workflow. |
| Deterministic logic reused by multiple skills | Shared script | Shared scripts reduce duplication only after reuse is proven across more than one skill. |

## Decision rules

### Create an instruction when

- the guidance depends on file type or metadata pattern
- the main value is rules, heuristics, or examples
- no bundled execution logic is necessary

### Create a skill when

- the workflow is reusable across multiple Salesforce DX repositories
- Copilot should load it only when the user asks for that kind of task
- the asset may need bundled scripts, references, or checklists

### Create an agent when

- the work benefits from a specialized persona with a narrow mission
- the agent needs explicit responsibilities, workflow steps, and guardrails
- the task is broader than a single skill invocation

### Create a shared script when

- the logic is deterministic and should not be regenerated in prose each time
- more than one bundled skill needs the same helper
- keeping the script inside one skill would create duplication or inconsistent behavior

## Script placement rules

- Keep a script inside the skill folder when only that skill uses it.
- Move logic into `.github/scripts/salesforce/` only after more than one skill needs the same helper.
- Document any path convention or dependency the script assumes.

## Portability checks

Before adding any asset, ask:

- Can this be copied into another Salesforce DX repository without renaming internal classes, users, or org-specific terms?
- Does it rely on a non-standard folder or config path that needs to be documented?
- Does the description help Copilot discover the asset from a natural user request?

## Recommended drafting flow

1. Pick the asset type with the smallest safe scope.
2. Draft the asset using the relevant instruction file and current repo patterns.
3. Run the validator skill before review.
4. Update README or docs only when the new asset changes discovery or usage.
