# Installation Configuration Concerns

**Analysis Date:** 2026-05-16
**Scope:** `agentget.json` manifest vs. `scripts/install.sh` behavior vs. documentation
**Trigger:** User concern that `agentget install` may not produce the same result as running `scripts/install.sh` directly.

---

## Executive Summary

This document records a systematic comparison of every installation and distribution method defined in the `eea.agent.skills` repository. The primary finding is that the `agentget.json` manifest and the `scripts/install.sh` script are **not aligned** — they declare different files, target paths, and agent profiles. A user running `agentget install eea/eea.agent.skills` will receive a **different (and in some cases incomplete)** installation compared to cloning the repo and running `./scripts/install.sh`.

---

## Method 1: `agentget` Installer (One-Line Install)

**Source:** `plugins/agentget.json`, `docs/BOOTSTRAP.md`, `README.md`

**Command:**
```bash
agentget install eea/eea.agent.skills
```

**What it is supposed to do (per manifest):**
- Discover the repository via `agentget.json`
- Run `scripts/install.sh` (declared in manifest)
- Create symlinks per the `symlinks` array
- Copy config files per `configFiles` array
- Install skills to all paths listed in `skills.installPaths`
- Install rules from `rules.sourceDir` matching `rules.pattern`

**What the manifest declares:**

| Component | Source in Repo | Target Path(s) | Action |
|---|---|---|---|
| Harness | `harness/EEA-HARNESS.md` | `~/.claude/CLAUDE.md` | Symlink |
| Harness | `harness/EEA-HARNESS.md` | `~/.hermes/HERMES.md` | Symlink |
| Config | `docs/opencode-examples/global-opencode.json` | `~/.config/opencode/opencode.json` | Copy |
| Skills | `skills/*/` | `~/.config/opencode/skills/` | Copy |
| Skills | `skills/*/` | `~/.claude/skills/` | Copy |
| Skills | `skills/*/` | `~/.agents/skills/` | Copy |
| Rules | `rules/*.rules.md` | *(not specified in manifest)* | *(implied by convention)* |

**Supported agent profiles:** `opencode`, `claudecode`, `hermes`, `gemini`, `pi`

---

## Method 2: Install Script (`scripts/install.sh`)

**Source:** `scripts/install.sh`

**Command:**
```bash
git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness
~/.eea/agent-harness/scripts/install.sh [--global] [--local] [--agent <name>] [--force]
```

**What it actually does:**
1. Clones or updates repo to `~/.eea/agent-harness`
2. Auto-detects installed agents (OpenCode, Claude, Hermes)
3. Installs per-agent:
   - **OpenCode:** Writes `~/.config/opencode/opencode.json` with a **hardcoded** JSON heredoc (not the template file)
   - **Claude:** Symlinks `~/.claude/CLAUDE.md` → `~/.eea/agent-harness/harness/EEA-HARNESS.md`
   - **Hermes:** Symlinks `~/.hermes/HERMES.md` → `~/.eea/agent-harness/harness/EEA-HARNESS.md`
   - **Gemini / Pi:** Prints a warning and tells the user to read manual docs
4. Copies `skills/*/` to:
   - `~/.config/opencode/skills/`
   - `~/.claude/skills/`
   - *(NOT to `~/.agents/skills/`)*
5. Symlinks `rules/*.rules.md` to:
   - `~/.claude/rules/`
   - `~/.config/opencode/rules/`
   - `~/.hermes/rules/`
   - `~/.pi/agent/rules/`

---

## Method 3: Manual Git Clone + Symlink (Per-Agent)

**Source:** `docs/BOOTSTRAP.md`, `agents/*.md`

Manual version of what the install script automates. The user clones once, then creates symlinks manually. This method is correctly documented and matches the install script's behavior for Claude and Hermes. For Pi, the docs say to create `~/.pi/agent/AGENTS.md`, but the install script does **not** do this.

---

## Method 4: Remote URL Reference (OpenCode, Zero-Install)

**Source:** `agents/opencode.md`, `docs/BOOTSTRAP.md`, `README.md`

No local clone required. OpenCode fetches `EEA-HARNESS.md` directly from GitHub on every session start. This is purely a reference method — nothing is installed locally. It is the method recommended in `agents/opencode.md` as "Option A".

---

## Method 5: Git Submodule + File Reference (OpenCode)

**Source:** `agents/opencode.md`

For reproducible/pinned harness versions. Adds the repo as a Git submodule and references the local file in `opencode.json`. Works offline and is version-controlled with the project.

---

## Method 6: Local Clone + File Reference (OpenCode, Air-Gapped)

**Source:** `agents/opencode.md`

For restricted environments. Clone to `~/.eea/agent-harness`, then reference via absolute path in `opencode.json`.

---

## Method 7: Download from GitHub Releases (Pre-Built Artifacts)

**Source:** `.github/workflows/release.yml`, `README.md`

**Trigger:** Git tag push (`v*`)

The CI runs `./scripts/build.sh` to merge upstream `SKILL.md` + `EEA-OVERRIDES.md` into distributable `skills/` output, then packages `skills/` into zip and tar.gz artifacts attached to the GitHub Release.

Users can download pre-built merged skills without needing to run the build step themselves.

---

## Method 8: Per-Project Inline Copy (Project-Local AGENTS.md)

**Source:** `templates/dot-agents/`, `agents/*.md`, `docs/BOOTSTRAP.md`

For project-specific rules that add to (not replace) the org harness. The user creates `{repo}/AGENTS.md` and appends the full content of `EEA-HARNESS.md` inline. Template files are available in `templates/dot-agents/`.

---

## Detailed Mismatch Findings

### Finding 1: Pi Global Harness Symlink — Missing in Both

- **What docs say:** `agents/pi.md` and `BOOTSTRAP.md` instruct users to run:
  ```bash
  ln -sf ~/.eea/agent-harness/harness/EEA-HARNESS.md ~/.pi/agent/AGENTS.md
  ```
- **What `agentget.json` does:** The `symlinks` array does **not** include `~/.pi/agent/AGENTS.md`.
- **What `install.sh` does:** The `install_claude`/`install_hermes` pattern is **not** implemented for Pi. The script only links rules to `~/.pi/agent/rules`. It never creates the global harness symlink.
- **Impact:** Pi users using automated install will not get the global harness loaded. They will only receive rules. Pi is effectively unsupported despite being listed in `agentget.json` profiles.

### Finding 2: Skills Path `~/.agents/skills/` — Missing in `install.sh`

- **What `agentget.json` declares:** `skills.installPaths` includes `~/.agents/skills/` alongside `~/.config/opencode/skills/` and `~/.claude/skills/`.
- **What `install.sh` does:** The `install_skills` function only copies to OpenCode and Claude directories. It never touches `~/.agents/skills/`.
- **What `agents/opencode.md` says:** Confirms `~/.agents/skills/<name>/SKILL.md` is a valid discovery path for OpenCode.
- **Impact:** Users who rely on `~/.agents/skills/` (or who follow the OpenCode agent profile docs) will not have skills available there after running `install.sh`.

### Finding 3: OpenCode Config — Content Mismatch Between Template and Hardcoded Output

- **What `agentget.json` declares:** The `configFiles` array specifies `docs/opencode-examples/global-opencode.json` as the template to copy to `~/.config/opencode/opencode.json`.
- **What the template contains:** The file includes a `$schema` field plus the `instructions` array.
- **What `install.sh` does:** The `install_opencode` function generates its own JSON via a heredoc, containing **only** the `instructions` array and **omitting** the `$schema` field.
- **Impact:** The installed config does not match the canonical template. If OpenCode or tooling relies on the `$schema` field for validation or IDE support, the hardcoded output is inferior.

### Finding 4: Agent Name Inconsistency — `claudecode` vs `claude`

- **What `agentget.json` declares:** `"profiles": ["opencode", "claudecode", "hermes", "gemini", "pi"]` — the profile name is `claudecode`.
- **What `install.sh` accepts:** The `--agent` flag and internal `case` statement use `claude`, not `claudecode`.
- **Impact:** If an `agentget` implementation passes `claudecode` as the `--agent` argument to `install.sh`, the script will fail with "Unknown agent: claudecode". This breaks the contract between the manifest and the script.

### Finding 5: Gemini & Pi — Listed as Supported but Not Automated

- **What `agentget.json` declares:** Both `gemini` and `pi` are listed in `agents.profiles`.
- **What `install.sh` does:** For both agents, the script prints `log_warn "Gemini requires manual setup. See agents/gemini.md"` and `log_warn "Pi requires manual setup. See agents/pi.md"`. It does **not** create symlinks, copy configs, or install anything for these agents.
- **Impact:** The manifest claims full support, but the installer explicitly refuses to set them up. This is a misleading contract.

### Finding 6: Rules Target Directories — Underspecified in `agentget.json`

- **What `agentget.json` declares:** The `rules` object only has `sourceDir: "rules/"` and `pattern: "*.rules.md"`. It does **not** specify where the matched files should be installed.
- **What `install.sh` does:** Installs rules to four directories: `~/.claude/rules`, `~/.config/opencode/rules`, `~/.hermes/rules`, `~/.pi/agent/rules`.
- **Impact:** An `agentget` implementation has no manifest guidance for rules installation paths. It must either hardcode the same four paths or implement its own convention, creating divergence risk.

### Finding 7: `install.sh` Ignores Its Own Declared Template

- **What `agentget.json` declares:** `"template": "docs/opencode-examples/global-opencode.json"` for the OpenCode config file.
- **What `install.sh` does:** It does not `cp` the template. It hardcodes inline content.
- **Impact:** Any future change to `global-opencode.json` (e.g., adding new fields) will **not** be reflected in `install.sh` output unless the script is also manually updated. This is a maintenance liability.

---

## Summary Table: All Installation Methods

| # | Method | Best For | What Gets Installed | Where |
|---|---|---|---|---|
| 1 | `agentget install` | Unified, automated setup | Full repo + symlinks + skills + rules | `~/.eea/agent-harness`, agent config dirs |
| 2 | `scripts/install.sh` | Automated shell-based setup | Same as agentget (but with gaps) | Same as agentget |
| 3 | Manual clone + symlink | Offline use, manual control | Harness symlinked, skills copied manually | `~/.eea/agent-harness`, `~/.claude/`, etc. |
| 4 | Remote URL (OpenCode) | Zero-install, always latest | Nothing locally; fetched on demand | Project `opencode.json` |
| 5 | Git submodule | Reproducible/pinned versions | Full repo as submodule | `.harness/eea.agent.skills/` in project |
| 6 | Local clone + file ref | Air-gapped environments | Full repo cloned locally | `~/.eea/agent-harness` |
| 7 | GitHub Release download | Pre-built skills only | Merged `skills/` directory | Downloaded zip, then copied to agent skills dir |
| 8 | Per-project inline copy | Project self-containment | Project `AGENTS.md` with harness inlined | `{repo}/AGENTS.md` or `{repo}/.claude/CLAUDE.md` |

---

## Cross-Reference: Key Files Supporting Installation

| File | Purpose | Risk |
|---|---|---|
| `scripts/install.sh` | One-shot automated installer for all agents | Out of sync with `agentget.json` |
| `scripts/build.sh` | Merges upstream + EEA overrides into `skills/` | No test coverage |
| `plugins/agentget.json` | Machine-readable manifest for `agentget` tool | Underspecifies rules; claims unsupported agents |
| `catalog.yaml` | Skill index with IDs, triggers, upstream sources | No schema validation beyond parse |
| `docs/BOOTSTRAP.md` | Step-by-step onboarding guide for EEA developers | Recommends `agentget` which may under-deliver |
| `agents/opencode.md` | OpenCode wiring (4 options) | Option A (remote URL) conflicts with `install.sh` global config |
| `agents/pi.md` | Pi wiring (symlink, per-project, agentget) | agentget path is broken (no Pi harness symlink) |
| `templates/dot-agents/AGENTS.md` | Template for project-local instructions | Not referenced by any installer |
| `templates/dot-agents/opencode.json` | Template for project `opencode.json` | Not referenced by any installer |
| `.github/workflows/release.yml` | Builds and packages `skills/` on tag push | Builds from `skills/` which may be out of date |

---

*Report generated: 2026-05-16*
