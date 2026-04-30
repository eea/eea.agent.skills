# Source Skills

This directory contains the **source** skill files. Each skill is maintained as a
two-file overlay:

```
src/skills/<skill-name>/
├── SKILL.md              # Upstream base content
├── EEA-OVERRIDES.md      # EEA-specific customizations
└── references/           # Optional deep reference material
```

## Building Distributable Skills

Run the build script to merge upstream + EEA overrides into the `skills/`
directory (which is what agentget discovers):

```bash
# Build all skills
./scripts/build.sh

# Build a specific skill
./scripts/build.sh docker-expert
```

The merged output lands in `skills/<skill-name>/SKILL.md`.

## Do not edit `skills/` directly

The `skills/` directory at the repo root is **auto-generated**. Always edit files
in `src/skills/` and then run the build script.
