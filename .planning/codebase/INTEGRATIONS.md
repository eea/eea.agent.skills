# External Integrations

**Analysis Date:** 2026-05-16

## APIs & External Services

**GitHub:**
- **GitHub API** (`api.github.com`) — Used in CI upstream sync check to fetch latest commit SHA from upstream repositories (`.github/workflows/validate-skills.yml:98`)
- **Raw GitHub Content Delivery** (`raw.githubusercontent.com`) — Used to fetch upstream `SKILL.md` source files during manual sync workflows (`docs/SYNC-STRATEGY.md:108`, `CONTRIBUTING.md:19`) and to serve the harness remotely to agent frameworks (`harness/EEA-HARNESS.md`)

**Agent Platforms (Consumers):**
- These are the runtimes that load and execute skill content. They are not networked integrations of this repository, but they are the intended consumers:
  - **OpenCode** — Auto-discovers skills from `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/`, or project-local `.opencode/skills/`
  - **Claude Code** — Discovers skills from `~/.claude/skills/`
  - **Cursor** — May load skill-like instruction files
  - **GitHub Copilot** — Agent skill support

**Skill Installation Tools:**
- **agentget** (`joeyism/agentget`) — Optional third-party CLI tool for auto-discovering and installing skills from this repository; consumed via `plugins/agentget.json` manifest

## Data Storage

**Databases:**
- Not applicable. No database or persistent data store is used.

**File Storage:**
- Local filesystem only. All assets are version-controlled in Git.

**Caching:**
- `graphify-out/cache/` — Local cache directory for graphify knowledge graph generation (excluded from Git via `.gitignore`)

## Authentication & Identity

**Auth Provider:**
- None required for repository operation.
- GitHub Actions uses the implicit `GITHUB_TOKEN` provided by the GitHub Actions runner for repository checkout and CI operations.

## Monitoring & Observability

**Error Tracking:**
- None

**Logs:**
- GitHub Actions workflow logs (standard GitHub CI output)

## CI/CD & Deployment

**Hosting:**
- GitHub (`github.com/eea/eea.agent.skills`) — Source repository and canonical distribution point
- **GitHub Releases distribution discontinued** as of 2026-05-16. Skills are now always installed from source via `scripts/install.sh` or agentget. No release artifacts are published.

**CI Pipeline:**
- **GitHub Actions** (`ubuntu-latest`)
  - `.github/workflows/validate-skills.yml` — Runs on push/PR; validates skill structure, token counts, catalog schema, build sync, and upstream SHA fetch
  - `.github/workflows/validate-harness.yml` — Runs on push/PR when harness/rules/agents/skills/catalog change; validates harness file existence, markdown structure, referenced files, agent profiles, catalog YAML validity, and scans for secret patterns
  - `.github/workflows/check-changelog.yml` — Runs on PR open/synchronize/reopen; enforces that code changes include an updated `CHANGELOG.md`

## Upstream Sources

This repository forks and extends content from upstream skill libraries. These are content dependencies, not package dependencies:

- **`sickn33/antigravity-awesome-skills`** — Source for `docker-expert` skill
  - Path: `src/skills/docker-expert`
  - Sync method: Manual `curl` fetch of raw `SKILL.md`

- **`vercel-labs/agent-skills`** — Source for frontend/mobile skills
  - Skills: `composition-patterns`, `react-best-practices`, `react-native-skills`, `react-view-transitions`, `web-design-guidelines`
  - Sync method: Manual `curl` fetch of raw `SKILL.md`

## Environment Configuration

**Required env vars:**
- None for local development or build.

**Secrets location:**
- No secret files present in the repository.
- GitHub Actions `GITHUB_TOKEN` is provided automatically by the GitHub Actions runner.

## Webhooks & Callbacks

**Incoming:**
- None

**Outgoing:**
- None (the upstream sync job performs outbound `curl` requests to GitHub API, but these are not webhook callbacks)

## Notes on Skill Content vs. Repository Integrations

The Markdown skill files contain extensive references to technologies like Docker, React, Next.js, npm, AWS, Vercel, Supabase, etc. These are **subject matter** documented within the skills (e.g., `docker-expert/SKILL.md` describes `npm ci` inside Dockerfiles). They do not represent runtime dependencies or live integrations of the `eea.agent.skills` repository itself.

---

*Integration audit: 2026-05-16*
