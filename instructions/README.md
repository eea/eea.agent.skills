# Instructions

This directory contains **generic organization-wide instruction templates** used by all EEA AI agents.

## What Goes Here

- Reusable instruction sets (e.g., "how to do a security review")
- Prompt fragments that apply across multiple skills
- Standard procedures that don't fit in a single skill

## What Does NOT Go Here

- Skill-specific instructions (those belong in `skills/` or `src/skills/`)
- Project-specific instructions (those belong in `{repo}/.agents/`)
- Tool-specific configuration (those belong in `agents/`)
- Prohibitions and mandatory rules (those belong in `rules/`)

## File Naming Convention

```
instructions/{topic}.instructions.md
```

## Usage

Instruction files are loaded by agents when the topic is relevant. They can be:
- Referenced from `harness/EEA-HARNESS.md` routing rules
- Loaded by skills that need standard procedures
- Used by workflows as building blocks

## Available Instructions

*(None yet — add as needed)*

---

*Last updated: 2026-05-14*
