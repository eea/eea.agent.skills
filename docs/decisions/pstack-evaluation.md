# Decision: Port Selected pstack Skills as Frozen Forks (Three-PR Sequence)

**Date:** 2026-11-18
**Decision Owner:** Antonio De Marinis
**Status:** Accepted

## Context

[pstack](https://github.com/cursor/plugins/tree/main/pstack) (cursor/plugins, MIT, v0.15.43, by Lauren Tan, Cursor + React core team) is a rigorous-engineering skill set: one orchestrator skill (`poteto-mode`, 22 playbooks), 24 short engineering-principle skills, ~25 standalone skills, 2 subagents, and a Slack-triage automation pack. Evaluated 2026-11-17 to decide which parts are high value for this repo.

The repo's existing skills cover Plone/Volto, Jenkins/Docker quality gates, React, design, and security, but nothing for: writing style, vetting measured numbers, failing-test cadence, change-risk proof, or repeat-mistake elimination.

## Decision

Port pstack in three PRs as frozen forks (upstream body byte-identical, EEA deltas in `EEA-OVERRIDES.md`), in this order:

1. **PR 1 — quick wins (self-contained, no Cursor coupling):** `unslop`, `technical-writing`, `benchmark-checklist`, `tdd`, `blast-radius`, `correct`.
2. **PR 2 — needs EEA adaptation:** `engineering-principles` (the 24 principles consolidated into one skill with an inline index, not 24 catalog entries), `show-me-your-work`, `create-verification-skill`.
3. **PR 3 — orchestrator layer:** rigor-mode (port of the `poteto-mode` playbooks, including the 40-line PR template), `interrogate`, `how`/`why`.

Deferred: `statechart` (TLA+/TLC, needs Java, niche for the EEA stack), `arena`/`swarm` (multi-model fan-out; revisit once the mode skill exists), `no-comments`/`comment-sicko`, `benny` (Cursor-automation-bound; the triage pattern may become a bespoke EEA skill over Redmine), `typescript-best-practices` (overlaps `react-best-practices`). Skipped: `setup-pstack`, `poteto-help`, `automate-me`, `ketchup*`, `make-bot-ui`, `recall` (Cursor-coupled or personal-style).

## Porting Conventions (binding for all three PRs)

- Frontmatter normalized to `name` + `description` (handoff precedent): the Cursor-only `disable-model-invocation` field is removed; descriptions enriched where upstream ones are too thin for trigger matching.
- Cursor mechanics must be stripped or re-mapped on port: model slugs, `~/.cursor/rules/pstack-models.mdc`, `subagent_type`, `environment: "cloud"`, `agent-transcripts/` paths, `/loop` references.
- Soft references to not-yet-ported pstack skills/playbooks stay in the upstream body (descriptive, not links) and are flagged in the catalog `notes`.
- Re-sync against upstream deliberately (pin the version, as with caveman/handoff); do not track upstream commits.

## Gotchas Discovered

- **`catalog.yaml` values must not contain unquoted colons.** `validate-harness` does a strict YAML parse and fails the PR with `mapping values are not allowed here` (e.g. `description: Cut AI tells from writing: AI vocabulary...`). Keep descriptions colon-free or quoted. Caught on the first push of PR 1 (run 44299837990); four descriptions had to be rewritten.
- `verify.sh`'s "All source skills are built / No stale built skills" checks make `./scripts/build.sh` mandatory after touching `src/skills/` or `EEA-OVERRIDES.md` (already enforced by `build-sync` CI).

## Status

- **PR 1:** [#11](https://github.com/eea/eea.agent.skills/pull/11) — merged 2026-11-18.
- **PR 2:** branch `add-pstack-pr2-skills` — `engineering-principles`, `show-me-your-work`, `create-verification-skill`, plus a `build.sh` fix for subdirectory companion files. In review.
- **PR 3:** not started (rigor-mode playbooks, `interrogate`, `how`/`why`); forward references already noted in the PR 1 and PR 2 catalog entries.

## Related

- `catalog.yaml` — six new entries, new `writing` category
- `src/skills/{unslop,technical-writing,benchmark-checklist,tdd,blast-radius,correct}/` — frozen forks with `EEA-OVERRIDES.md`
- `CHANGELOG.md` — 2026-11-18 entry
- Upstream: https://github.com/cursor/plugins/tree/main/pstack (MIT)
