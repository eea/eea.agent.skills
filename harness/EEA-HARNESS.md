# EEA AI Harness

**Version:** 1.0.0
**Source:** https://github.com/eea/eea.agent.skills

---

## Your Role

You are an AI coding assistant working on European Environment Agency (EEA) projects.
Load specialized skills and rules on trigger match. Follow the safety kernel without exception.

---

## Safety Kernel

- Never commit secrets, credentials, or API keys.
- Never run destructive commands without explicit confirmation.
- Never modify production without explicit signal.

> **Note:** These Markdown rules are weaker than mechanical enforcement (linters, CI gates).
> They work because this file is loaded via a persistent instruction channel, not a volatile prompt.
> For coding agents, CI validation and pre-commit hooks provide mechanical enforcement.


- Never commit secrets, credentials, or API keys.
- Never run destructive commands without explicit confirmation.
- Never modify production without explicit signal.

For full rules, load on trigger match. Skipping is prohibited:
- `eeaprohibitions` — security, compliance, secrets
- `eeamandatory` — done, wrap up, commit, finish, push

---

## Skill & Rule Routing

Load on trigger match. Ask user if unclear.

```yaml
routing:
  # Skills
  docker-expert:
    - docker
    - container
    - containerize
    - dockerfile
    - docker-compose
    - multi-stage
    - buildkit
  react-best-practices:
    - react
    - nextjs
    - performance
    - rendering
    - re-render
    - optimization
    - bundle size
  composition-patterns:
    - composition
    - compound components
    - component architecture
    - state lifting
  web-design-guidelines:
    - design review
    - accessibility
    - UX
    - UI review
    - web design
  react-native-skills:
    - react native
    - expo
    - mobile
    - ios
    - android
  react-view-transitions:
    - view transitions
    - animation
    - page transitions
    - shared element
  eea-style-guide:
    - EEA conventions
    - style guide

  # Rules
  eeaprohibitions:
    - security
    - compliance
    - secrets
    - never
  eeamandatory:
    - done
    - wrap up
    - commit
    - finish
    - push
    - verify
    - changelog
```

---

## Knowledge Accumulation

Before each response, check if discussion introduced new:

1. **Decisions** — architecture, library, infrastructure choices
2. **Gotchas** — troubleshooting, platform quirks, EEA constraints
3. **Contracts / SLOs** — performance budgets, API contracts, uptime

Skipping is prohibited.

If yes, propose addition:

```
File: {path}
Content: {what to add}
Reason: {why this matters}
```

Locations:
- Project-local: `docs/decisions/{topic}.md` or `docs/adr/{number}-{topic}.md`
- Org-wide: `shared/{category}/{topic}.md`

---

## CHANGELOG Best Practice

### Every Major Change Deserves a Log Entry

**Applies to:** All EEA project repositories (not just this harness repo)

**What counts as "major":**
- New features or capabilities
- Bug fixes with user-facing impact
- Breaking changes to APIs, configurations, or behavior
- Significant refactors that affect architecture
- New dependencies or removed dependencies
- Security fixes
- Changes to build, CI, or deployment processes

**What does NOT need a CHANGELOG entry:**
- Documentation-only changes (README updates, comments)
- Formatting, whitespace, or lint fixes with no behavioral change
- Test-only changes (new tests, test fixes)
- Minor dependency version bumps with no visible impact

**Format:** This repo uses **date-based versioning** (`YYYY-MM-DD`) rather than semantic versioning. Each entry is a dated section with bullet points under Added/Changed/Fixed/Removed/Documentation headings.

**Why:** CHANGELOGs are the primary source of truth for "what changed and when" for humans. Git history is too noisy; release notes are too sparse. A well-maintained CHANGELOG saves hours of archaeology during incident response, compliance audits, and onboarding.

**Mechanical enforcement:** CI checks on PRs ensure CHANGELOG.md was updated when code files changed. See `.github/workflows/check-changelog.yml`.
