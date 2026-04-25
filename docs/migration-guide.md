# Migration guide

Use this guide when extracting Copilot assets from a private Salesforce repository into a reusable public collection.

## What to remove

Before publishing an asset, remove or rewrite:

- internal class names
- local prefixes
- org names
- usernames and emails
- repo-only workflows
- examples that depend on one codebase being present

## What to keep

Preserve guidance that reflects standard Salesforce DX practice:

- metadata path conventions
- Apex testing patterns
- deployment packaging rules
- destructive-change safety checks
- Flow and permission metadata considerations

## Safe generalization patterns

| Too specific | Better portable version |
| --- | --- |
| `Reuse TestDataFactory.cls` | `Reuse an existing shared test-data helper when available` |
| `This repo uses AccountServiceTest` | `Follow the dominant nearby naming convention` |
| `MF_` prefix heuristic | `Use project-agnostic broad-impact heuristics` |
| `Use this repository` | `Use this skill in a Salesforce DX project` |

## Migration checklist

- [ ] Remove repo-local examples or replace them with generic examples.
- [ ] Confirm relative links still point to files that exist in the public repo.
- [ ] Copy any shared modules that bundled scripts depend on.
- [ ] Review descriptions for automatic skill discovery quality.
- [ ] Document any standard-path assumptions instead of hiding them.

## Suggested extraction order

1. Instructions
2. Shared helper modules
3. Skills with bundled scripts
4. Agents
5. Documentation

This order makes it easier to catch broken references early.
