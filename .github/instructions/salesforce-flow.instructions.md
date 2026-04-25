---
description: "Repository-specific guidance for Salesforce Flow metadata and flow definitions."
applyTo: "**/*.flow-meta.xml, force-app/main/default/flowDefinitions/*.flowDefinition-meta.xml"
---

# Salesforce Flow Metadata

Use these rules when editing Flow XML in a Salesforce DX project.

## Core Rules

- Treat Flow XML as generated metadata. Make the smallest change that solves the task and avoid noisy rewrites.
- Keep Flow API names stable unless the task explicitly requires a rename.
- Use descriptive names for screens, decisions, variables, and assignments so the XML remains understandable during reviews.
- Add or preserve fault handling paths for data updates, subflows, Apex actions, or external operations when the Flow surface supports them.
- When a new Flow depends on Apex, objects, fields, or permissions added in the same task, update the deployment manifests in the same change.

## Versioning and Activation

- Prefer creating or updating the intended Flow version rather than making broad edits across unrelated versions.
- Do not change active-version behavior casually. If activation state matters, make it explicit in the change.
- Keep labels aligned with API names closely enough that future diffs stay readable.

## Diff Hygiene

- Avoid reordering unrelated XML blocks.
- Preserve existing metadata values unless the task requires changing them.
- Keep new elements near the part of the Flow they support so future diffs remain local.

## Safety Checks

- Confirm entry criteria still match the intended object and event.
- Confirm added variables have a clear data direction and purpose.
- Confirm fault paths surface useful failure behavior instead of silently swallowing errors.
