---
description: "Repository-specific guidance for Salesforce profile and permission set metadata."
applyTo: "**/*.profile-meta.xml, **/*.permissionset-meta.xml"
---

# Salesforce Profiles and Permission Sets

Use these rules when editing access metadata in a Salesforce DX project.

## Core Rules

- Prefer `PermissionSet` changes over `Profile` changes for new or incremental access work.
- If the task only needs object, field, tab, class, page, or app access, update the narrowest metadata required.
- Keep diffs minimal. Do not rewrite large generated blocks that are unrelated to the requested access change.
- When new metadata is introduced in the same task, add only the access entries needed for that metadata to work.
- Remove access only when the task explicitly requires it.

## Review Discipline

- Match each access change to a concrete metadata addition or behavior requirement.
- Avoid broad admin-style grants when a narrower permission meets the requirement.
- Keep naming and labels consistent with the target metadata so reviewers can trace why the permission exists.

## Packaging

- If the deployment depends on a new or updated permission asset, include the `PermissionSet` or `Profile` member in the manifest changes for the same task.
- Prefer permission set packaging for feature delivery when both profile and permission set approaches are possible.

## Avoid

- Adding wide permission changes without a corresponding feature need.
- Reformatting or reordering the entire metadata file during a small edit.
- Using profile edits as the default when a permission set can express the same access safely.
