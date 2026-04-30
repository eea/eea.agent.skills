# Instructions

This directory is for **instruction files** used by the [agentget](https://github.com/joeyism/agentget)
framework.

## Expected Pattern

```
instructions/*.instructions.md
```

Each `.instructions.md` file contains a reusable instruction set or prompt
fragment.

## Example

```
instructions/
├── code-review.instructions.md
├── security-check.instructions.md
└── accessibility-audit.instructions.md
```

## Usage

Agentget auto-discovers `.instructions.md` files from this directory when the
repo is added as a source.
