# Distributable Skills

This directory contains **merged, distributable skills** ready for agentget
discovery and direct installation.

Each subdirectory follows the agentget convention:

```
skills/<skill-name>/
└── SKILL.md              # Merged: upstream + EEA overrides
```

## Auto-Generated

**Do not edit files in this directory directly.** They are produced by the build
script from the source files in `src/skills/`.

## Installation

### Manual copy
```bash
cp skills/docker-expert/SKILL.md ~/.claude/skills/docker-expert/SKILL.md
```

### Agentget auto-discovery
```bash
agentget add eea/eea.agent.skills
```

## Rebuilding

After editing source files in `src/skills/`, rebuild:

```bash
./scripts/build.sh
```

Then commit both `src/skills/` and `skills/` changes.
