# Rules

This directory is for **rule files** used by the [agentget](https://github.com/joeyism/agentget)
framework.

## Expected Pattern

```
rules/*.rules.md
```

Each `.rules.md` file defines a set of constraints, guidelines, or rules that
agents should follow.

## Example

```
rules/
├── python-style.rules.md
├── commit-message.rules.md
└── api-design.rules.md
```

## Usage

Agentget auto-discovers `.rules.md` files from this directory when the repo is
added as a source.
