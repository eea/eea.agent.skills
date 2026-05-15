# Workflows

This directory contains **multi-step orchestration recipes** that chain multiple skills together to accomplish complex tasks.

## What Goes Here

- Cross-project workflows (e.g., "EEA-standard PR review")
- Multi-skill recipes (e.g., "generate chart + document + spreadsheet")
- End-to-end processes that span multiple domains

## What Does NOT Go Here

- Single-skill tasks (those belong in `skills/`)
- Project-specific workflows (those belong in `{repo}/docs/workflows/`)
- Generic instructions (those belong in `instructions/`)

## File Format

Workflows are Markdown files that describe a sequence of steps, each potentially invoking a different skill.

## Available Workflows

| File | Description | Skills Used |
|------|-------------|-------------|
| `data-report.md` | Generate chart + document + spreadsheet | chart, doc, xlsx |

## Adding a Workflow

1. Create `{name}.md` in this directory
2. Define the workflow steps
3. Reference required skills
4. Update the table above

---

*Last updated: 2026-05-14*
