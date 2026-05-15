# ADR: Slimmed Runtime Harness with Lazy-Loaded Rules

**Status:** Accepted  
**Date:** 2026-05-15  
**Deciders:** EEA AI Harness maintainers  

---

## Context

The EEA AI Harness (`harness/EEA-HARNESS.md`) had grown to 260 lines, mixing runtime behavior rules with installation documentation, governance prose, and reference tables. An external review ([`harness/REVIEW-1.md`](../../harness/REVIEW-1.md)) identified this as **instruction dilution** — critical safety rules lose salience when surrounded by low-signal content.

LLMs prioritize by recency, density, and attention distribution. A bloated harness means:
- Safety rules compete with install docs for attention
- Higher token usage for every session
- Worse composability (skills should be primary scaling mechanism)

## Decision

Adopt a **three-layer hierarchical architecture**:

```
Layer 1 (always loaded) → Tiny runtime harness: safety kernel + routing
Layer 2 (lazy-loaded)  → Skills + rules, loaded only when triggered
Layer 3 (repo-local)   → Project conventions (AGENTS.md)
```

### 1. Slim Runtime Harness

**What changed:**
- Reduced `harness/EEA-HARNESS.md` from 260 → ~115 lines
- Removed: install docs, tool wiring, distribution methods, evolution policy, reference tables
- Kept: Safety Kernel (3 critical rules), Skill & Rule Routing YAML, Knowledge Accumulation

**Rationale:** Every token in the root harness is injected into every session. Non-runtime content is waste.

### 2. Lazy-Loaded Rules

**What changed:**
- Removed inline Core Rules (11 bullets) and Session Protocol (4 steps)
- Created `rules/eeaprohibitions.rules.md` — security, compliance, operational safety
- Created `rules/eeamandatory.rules.md` — end-of-session actions, verification steps
- Harness routes to these on trigger match, same mechanism as skills

**Rationale:** Same mistake-prevention logic as skills. Load only when context requires it. Token economics.

### 3. Self-Contained Routing

**What changed:**
- Inline compact YAML routing roster with all trigger keywords
- Added `eea-style-guide`, `eeaprohibitions`, `eeamandatory` to routing block
- Removed reference to `catalog.yaml` (agents don't have sibling file access)

**Rationale:** Remote-URL agents (OpenCode) only receive the harness file. Relative paths to `catalog.yaml` fail. Inline roster makes routing discoverable.

### 4. "Skipping is Prohibited" Language

**What changed:**
- Added `Skipping is prohibited.` after lazy-load routing instructions
- Changed Knowledge Accumulation trigger from `Before each significant response` → `Before each response`
- Added `Skipping is prohibited.` to Knowledge Accumulation

**Rationale:** Article insight: "If you leave room for the agent to judge, it will decide on its own that it's probably fine to skip this time." Removing discretion stabilizes behavior.

### 5. Symlinked Rules Distribution

**What changed:**
- `scripts/install.sh` symlinks `rules/*.rules.md` to agent config dirs (`~/.claude/rules/`, `~/.config/opencode/rules/`, etc.)
- Added `--local` flag for dev mode using current repo
- Added warning when no rule files found

**Rationale:** Rules change more often than skills. Symlinks auto-update on `git pull` without re-running installer.

### 6. Public Repository

**What changed:**
- Made `eea/eea.agent.skills` public on GitHub

**Rationale:** The entire harness architecture depends on `raw.githubusercontent.com/.../EEA-HARNESS.md` being accessible. Private repo = 404 = broken remote instructions for all OpenCode users.

### 7. Enforcement Gap Transparency

**What changed:**
- Added note after Safety Kernel: "These Markdown rules are weaker than mechanical enforcement (linters, CI gates)."

**Rationale:** Honest about limits. Markdown instructions are middle-strength: stronger than volatile prompts, weaker than mechanical gates. Managing expectations prevents false confidence.

## Consequences

### Positive

- **Lower token usage** per session (especially for OpenCode, Claude Code, smaller-context models)
- **Better agent behavior** — critical rules more salient in compact harness
- **Better composability** — skills become primary scaling mechanism
- **Self-documenting routing** — no hidden dependencies on `catalog.yaml`
- **Auto-updating rules** — symlinks reflect latest `git pull`

### Negative

- **Lazy-loaded rules may be missed** if agent doesn't recognize trigger keywords (mitigated by "Skipping is prohibited")
- **Remote-URL agents get stale content** until they refresh (mitigated by YAML roster being complete)
- **Loss of inline examples** — install docs moved to `docs/BOOTSTRAP.md`, but agents don't read this at runtime

## Alternatives Considered

### Option A: Keep everything inline (rejected)

Keep full rules, install docs, and reference tables in `EEA-HARNESS.md`. Rejected because token bloat and instruction dilution are real failure modes.

### Option B: URL-reference lazy-loaded files (rejected)

Instead of routing keywords, embed URLs like `Load https://raw.githubusercontent.com/.../eeaprohibitions.rules.md`. Rejected because agents don't auto-fetch referenced URLs reliably. Routing keywords work with agent-specific skill/rule loading mechanisms.

### Option C: Machine-readable routing only (rejected)

Replace YAML block with pure `catalog.yaml` reference. Rejected because agents don't have file-system access to sibling `catalog.yaml` when loaded via remote URL.

## Related Decisions

- `docs/adr/2026-05-14-harness-initialization.md` — Original harness design
- `harness/REVIEW-1.md` — External review that triggered this refactoring

---

*Last updated: 2026-05-15*
