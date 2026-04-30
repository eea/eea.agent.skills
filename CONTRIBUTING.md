# Contributing to EEA Agent Skills

Welcome! This guide explains how to add skills, update existing ones, and maintain the sync with upstream sources.

## Adding a New Skill

### Option A: Fork from Upstream (Recommended)

When adding a skill that exists upstream:

1. **Create the skill directory:**
   ```bash
   mkdir -p skills/<skill-name>/references
   ```

2. **Fetch upstream content into `SKILL.md`:**
   ```bash
   # Example for docker-expert
   curl -s https://raw.githubusercontent.com/sickn33/antigravity-awesome-skills/main/skills/docker-expert/SKILL.md \
     > skills/docker-expert/SKILL.md
   ```

3. **Create `EEA-OVERRIDES.md`:**
   ```bash
   echo "# EEA-Specific Overrides\n\nAdd EEA customizations here." \
     > skills/docker-expert/EEA-OVERRIDES.md
   ```

4. **Update `catalog.yaml`:**
   Add the skill entry with upstream metadata.

5. **Open a PR** with the new skill.

### Option B: Create New (No Upstream)

When creating a skill without upstream:

```bash
mkdir -p skills/<new-skill>/references
```

Create `SKILL.md` following the skill template below.

---

## Updating Existing Skills

### Syncing from Upstream

When upstream has new content you want to pull:

```bash
# 1. Fetch latest upstream
curl -s https://raw.githubusercontent.com/<upstream>/main/skills/<skill>/SKILL.md \
  > skills/<skill>/SKILL.md

# 2. Verify EEA-OVERRIDES.md still exists and is valid
# 3. Run validation: npm run validate
# 4. Open PR with the sync
```

### Adding EEA Overrides

Edit `EEA-OVERRIDES.md` to add EEA-specific customizations:

```markdown
# EEA-Specific Overrides

## EEA-Specific Patterns

### Internal Registry Access
When building containers for internal EEA services:
- Use `registry.eea.europa.eu` as base registry
- Authenticate with EEA service accounts

### Security Compliance
EEA-specific security requirements:
- All containers must run as non-root (UID 10001+)
- Base images must be scanned weekly
- No external network calls without proxy exception
```

---

## Skill Structure Convention

Each skill directory follows this structure:

```
skills/<skill-name>/
├── SKILL.md              # Required: Core skill instructions
├── EEA-OVERRIDES.md       # Required (for forked skills): EEA customizations
├── references/            # Optional: Deep reference material
│   ├── topic-1.md
│   └── topic-2.md
└── upstream/              # Optional: Frozen upstream content (for sync)
    └── SKILL.md
```

### SKILL.md Requirements

- Maximum ~500 lines / 5k tokens (agent context limit)
- Clear "When invoked" section
- "Core Expertise Areas" with practical patterns
- "Code Review Checklist" section
- "Integration & Handoff Guidelines" for multi-skill workflows

### EEA-OVERRIDES.md Requirements

- Version tag: `<!-- EEA-Overrides-Version: 1.0 -->` at top of file
- Clear section headers: `## EEA-Specific Patterns`
- No duplication of upstream content
- Only additive: extend, don't modify core upstream patterns
- Version-stamped: `<!-- EEA-Overrides: v1.0 -->` at top

---

## Committing Changes

### Always rebuild and commit `dist/`

The `dist/` directory contains pre-built merged skills and is **committed to the repository**. This allows users to install skills directly without running the build script.

**After modifying any `SKILL.md` or `EEA-OVERRIDES.md`:**

```bash
# Rebuild all merged skills
./scripts/build.sh

# Stage both source and built files
git add skills/ dist/
git commit -m "feat: update docker-expert with EEA proxy configuration"
```

**CI will fail if `dist/` is out of sync.** The `build-sync` job rebuilds from source and checks that the committed `dist/` matches.

---

## Catalog Update

After adding/updating a skill, update `catalog.yaml`:

```yaml
skills:
  - id: <skill-id>
    name: <Skill Name>
    description: <one-line description>
    category: <devops|frontend|backend|security|...>
    upstream:
      source: <org/repo>
      path: skills/<skill>
      url: https://github.com/<org>/<repo>
    triggers:
      - <keyword1>
      - <keyword2>
    version: "1.0"
    eeaspecific: <true|false>
```

---

## Validation

Before opening a PR, run:

```bash
# Lint SKILL.md files
npm run validate

# Check token count
npm run check-tokens
```

GitHub Actions run validation on every PR automatically.

---

## Questions?

Open an issue at https://github.com/eea/eea.agent.skills/issues