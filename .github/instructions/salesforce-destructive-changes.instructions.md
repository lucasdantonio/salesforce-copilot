---
description: "Repository-specific guidance for Salesforce destructiveChanges manifest files."
applyTo: "manifest/destructiveChanges*.xml"
---

# Salesforce Destructive Changes

Use these rules when creating or editing destructive deployment manifests in a Salesforce DX project.

## Core Rules

- Add destructive changes only when the task explicitly removes metadata.
- Use the exact Salesforce metadata member name with the correct case and namespace format.
- Remove code and metadata references before adding the destructive entry. Do not rely on deployment order to hide unresolved dependencies.
- Keep destructive manifests narrowly scoped. Do not batch unrelated deletions together.

## Pre vs Post

- Default to `destructiveChangesPost.xml` when deletion can happen after the deployment package is applied.
- Use `destructiveChangesPre.xml` only when metadata must be removed before the rest of the deployment can succeed.
- When choosing pre-deploy deletion, document the dependency reason in the task summary or change notes.

## Packaging Rules

- Keep the companion `package.xml` aligned with the deployment being performed.
- Do not mix unrelated additive metadata and destructive metadata without a clear release reason.
- Never add profile or permission deletions casually; access metadata often has hidden dependencies.

## Safety Checks

- Confirm all Apex, LWC, Visualforce, Flow, layout, and permission references are already removed.
- Confirm the member belongs to the correct destructive metadata type.
- Confirm the manifest contains only the metadata intended for deletion in this task.
