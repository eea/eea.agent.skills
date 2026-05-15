# Plugins

This directory contains **tool-specific adapters and manifests** that enable automated installation and discovery of the EEA AI Harness.

## What Goes Here

- Agentget manifests (`agentget.json`)
- Tool-specific configuration files
- Install adapters for various agent platforms

## What Does NOT Go Here

- Skills (those are in `skills/`)
- Agent profiles (those are in `agents/`)
- Rules (those are in `rules/`)

## Files

| File | Purpose |
|------|---------|
| `agentget.json` | Manifest for agentget installer — defines install paths, symlinks, skills |

## Agentget Manifest

The `agentget.json` file defines:
- Canonical harness file location
- Installation script
- Symlink targets for different agents
- Skills source directory and install paths
- Supported agent profiles

See [`agentget.json`](agentget.json) for the full manifest.

---

*Last updated: 2026-05-14*
