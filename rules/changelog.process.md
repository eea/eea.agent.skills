# CHANGELOG Best Practice

<!--
  EEA-Rule-Version: 1.0
  Type: process
  Scope: organization-wide
  Applies to: all AI agents working on EEA code
-->

---

## Every Major Change Deserves a Log Entry

### What counts as "major"

- New features or capabilities
- Bug fixes with user-facing impact
- Breaking changes to APIs, configurations, or behavior
- Significant refactors that affect architecture
- New dependencies or removed dependencies
- Security fixes
- Changes to build, CI, or deployment processes

### What does NOT need a CHANGELOG entry

- Documentation-only changes (README updates, comments)
- Formatting, whitespace, or lint fixes with no behavioral change
- Test-only changes (new tests, test fixes)
- Minor dependency version bumps with no visible impact

---

## Format

Follow the versioning and formatting convention already used in the project's `CHANGELOG.md`. If the project does not have a `CHANGELOG.md`, propose one that matches its versioning scheme (e.g., CalVer `YYYY-MM-DD`, SemVer `X.Y.Z`, or plain date-based sections).

---

## Why

CHANGELOGs are the primary source of truth for "what changed and when" for humans. Git history is too noisy; release notes are too sparse. A well-maintained CHANGELOG saves hours of archaeology during incident response, compliance audits, and onboarding.

---

*Last updated: 2026-05-16*
