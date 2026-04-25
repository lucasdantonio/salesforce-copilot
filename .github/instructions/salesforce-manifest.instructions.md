---
description: "Repository-specific guidance for Salesforce manifest files such as package.xml."
applyTo: "manifest/*.xml"
---

# Salesforce Manifest Files

Use these rules when editing `manifest/package.xml` or related manifest files in a Salesforce DX project.

## Core Rules

- When a task creates deployable metadata or adds a metadata dependency, update the relevant manifest in the same change.
- Manifest members must use Salesforce metadata names, not source filenames. For example, use `AccountController`, not `AccountController.cls`.
- Keep `<types>` blocks ordered by metadata type name and keep `<members>` entries alphabetized within each type.
- Prefer explicit members for deploy or delta manifests. Use `*` only when the task intentionally manages an entire metadata type.
- Do not change the API version unless the task explicitly requires it.

## Mapping Rules

| Source path                                      | Manifest type              | Member example      |
| ------------------------------------------------ | -------------------------- | ------------------- |
| `classes/AccountController.cls`                  | `ApexClass`                | `AccountController` |
| `triggers/AccountTrigger.trigger`                | `ApexTrigger`              | `AccountTrigger`    |
| `lwc/dynamicLookup/*`                            | `LightningComponentBundle` | `dynamicLookup`     |
| `pages/notaFiscal.page`                          | `ApexPage`                 | `notaFiscal`        |
| `flows/TestFlowTrigger.flow-meta.xml`            | `Flow`                     | `TestFlowTrigger`   |
| `permissionsets/MyAccess.permissionset-meta.xml` | `PermissionSet`            | `MyAccess`          |

## Change Discipline

- Do not remove unrelated manifest members just because they are not part of the current task.
- If a new file is required for deployment, add its manifest entry before finishing the task.
- If a change introduces access metadata, include the corresponding `PermissionSet` or `Profile` member only when that metadata is part of the deliverable.

## Avoid

- Using file extensions in `<members>`.
- Reordering the whole file without a functional reason.
- Expanding a targeted manifest into a wildcard manifest during a small change.
