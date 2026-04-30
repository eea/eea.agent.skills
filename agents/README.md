# Agents

This directory is for **agent definitions** used by the [agentget](https://github.com/joeyism/agentget)
framework.

## Expected Pattern

```
agents/*.agent.md
```

Each `.agent.md` file defines a reusable agent persona or role.

## Example

```
agents/
├── devops-agent.agent.md
├── frontend-agent.agent.md
└── data-analyst-agent.agent.md
```

## Usage

Agentget auto-discovers `.agent.md` files from this directory when the repo is
added as a source.
