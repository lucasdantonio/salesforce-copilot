# Repository structure

```text
salesforce-copilot/
├── README.md
├── LICENSE
├── CONTRIBUTING.md
├── AGENTS.md
├── .github/
│   ├── agents/
│   ├── instructions/
│   ├── scripts/
│   │   └── salesforce/
│   └── skills/
└── docs/
```

## Directory roles

| Path | Role |
| --- | --- |
| `.github/instructions/` | File-pattern-based instructions for Copilot |
| `.github/skills/` | Self-contained skill folders with `SKILL.md` and bundled scripts |
| `.github/agents/` | Custom agent definitions |
| `.github/scripts/salesforce/` | Shared PowerShell modules used by several skills |
| `docs/` | Human-readable guidance for installation and adaptation |

## Structural rules

- Keep skills self-contained whenever possible.
- Use `.github/scripts/salesforce/` only for helpers shared by multiple skills.
- Do not add unrelated workflows to the public collection by default.
- Keep the repository easy to browse without requiring a separate catalog site.

## Why the shared script folder exists

Some skills rely on common metadata and test-planning helpers. Duplicating those helpers in every skill would make fixes harder to maintain, so this repository keeps them in one shared location and documents that dependency explicitly.
