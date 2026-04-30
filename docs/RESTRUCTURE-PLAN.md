# Restructure Plan: Agentget Compatibility

## Goal

Restructure the repository so that merged (distributable) skills are discoverable
by `agentget` at the standard `/skills` path, while preserving the source
overlay pattern.

## Context

The [agentget](https://github.com/joeyism/agentget) framework discovers content
from these patterns in the target repo:

| Type         | Pattern                           |
|--------------|-----------------------------------|
| Agents       | `agents/*.agent.md`               |
| Instructions | `instructions/*.instructions.md`  |
| Skills       | `skills/*/SKILL.md` (whole folder)|
| Rules        | `rules/*.rules.md`                |
| Plugins      | `plugins/*/` (expanded recursively)|

Previously, our source skills lived under `/skills/` and merged distributable
skills under `/dist/skills/`. This meant agentget would discover the *source*
files (with separate `SKILL.md` and `EEA-OVERRIDES.md`) rather than the merged
output.

## Directory Mapping

| Current Path               | New Path                   | Purpose                                    |
|---------------------------|----------------------------|--------------------------------------------|
| `skills/docker-expert/`   | `src/skills/docker-expert/`| Source skill (upstream + EEA overrides)    |
| `dist/skills/docker-expert/`| `skills/docker-expert/`  | **Merged skill** — agentget discovers here |
| `skills/shared/` (empty)  | *(removed)*                | Root `shared/` remains                     |
| `skills/workflows/` (empty)| *(removed)*               | Root `workflows/` remains                  |
| —                         | `agents/`                  | Scaffolding for `agents/*.agent.md`        |
| —                         | `instructions/`            | Scaffolding for `instructions/*.instructions.md` |
| —                         | `rules/`                   | Scaffolding for `rules/*.rules.md`         |
| —                         | `plugins/`                 | Scaffolding for `plugins/*/`               |

## Files to Update

### Build & CI
1. `scripts/build.sh` — change `SKILLS_DIR` from `skills` to `src/skills`, change `DIST_DIR` from `dist/skills` to `skills`
2. `.github/workflows/validate-skills.yml` — update all `skills/` → `src/skills/`, `dist/` → `skills/`
3. `.github/workflows/release.yml` — package from `skills/` instead of `dist/`

### Documentation
4. `README.md` — update structure diagram, all installation paths (`dist/` → `skills/`), quick start examples
5. `CONTRIBUTING.md` — update source paths, rebuild workflow, skill structure convention
6. `docs/SYNC-STRATEGY.md` — update all path references, build diagrams, CI safeguard descriptions
7. `.github/CODEOWNERS` — update `skills/` → `src/skills/`

### Index
8. `catalog.yaml` — no changes needed (upstream paths refer to external repos)

### Changelog
9. `CHANGELOG.md` — add entry for this restructure

## New Scaffolding to Create

- `src/skills/README.md` — explains source structure, build step
- `skills/README.md` — warns these are auto-generated, do not edit directly
- `agents/README.md` — explains `agents/*.agent.md` pattern
- `instructions/README.md` — explains `instructions/*.instructions.md` pattern
- `rules/README.md` — explains `rules/*.rules.md` pattern
- `plugins/README.md` — explains `plugins/*/` pattern

## Rollback Safety

- `dist/` is currently committed; moving to `skills/` means the merged content stays tracked
- Git will see this as a move + creation of `src/skills/` + deletion of `dist/`
- No content loss risk since we are moving committed files

## Checklist

- [x] Write this plan to `docs/RESTRUCTURE-PLAN.md`
- [x] Move `skills/docker-expert/` → `src/skills/docker-expert/`
- [x] Move `dist/skills/docker-expert/` → `skills/docker-expert/`
- [x] Remove empty `skills/shared/` and `skills/workflows/`
- [x] Delete `dist/` directory
- [x] Update `scripts/build.sh`
- [x] Update `.github/workflows/validate-skills.yml`
- [x] Update `.github/workflows/release.yml`
- [x] Update `README.md`
- [x] Update `CONTRIBUTING.md`
- [x] Update `docs/SYNC-STRATEGY.md`
- [x] Update `.github/CODEOWNERS`
- [x] Create `agents/`, `instructions/`, `rules/`, `plugins/` with READMEs
- [x] Create `src/skills/README.md` and `skills/README.md`
- [x] Update `CHANGELOG.md`
- [x] Run `scripts/build.sh` to verify
