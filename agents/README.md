# Agents

This directory is reserved for **agentget-compatible sub-agent prompts** (`*.agent.md`).

## Purpose

In the [agentget](https://github.com/joeyism/agentget) framework, the `agents/` directory contains **sub-agent system prompts** — specialized agent definitions that can be dispatched by a main agent for specific tasks (e.g., code review, planning, exploration).

These are distinct from **per-tool installation profiles** (OpenCode, Claude Code, etc.), which live in [`docs/agent-profiles/`](../docs/agent-profiles/).

## What Goes Here

- Sub-agent prompt files following the `*.agent.md` naming convention
- Specialized agent definitions for multi-agent orchestration
- Prompts designed to be loaded by agentget or compatible installers

## What Does NOT Go Here

- Tool-specific wiring instructions → [`docs/agent-profiles/`](../docs/agent-profiles/)
- Org-wide rules → `rules/`
- Reusable skills → `skills/`
- Generic instructions → `instructions/`

## File Naming Convention

```
agents/{name}.agent.md
```

Example:
```
agents/code-reviewer.agent.md
agents/planner.agent.md
```

## Current Status

*(No sub-agent prompts yet — add as needed for multi-agent workflows.)*

---

*See [`docs/agent-profiles/`](../docs/agent-profiles/) for OpenCode, Claude Code, Hermes, Gemini, and Pi setup instructions.*

*Last updated: 2026-05-17*
