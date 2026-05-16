# EEA Mandatory Actions

<!--
  EEA-Rule-Version: 1.0
  Type: mandatory
  Scope: organization-wide
  Applies to: all AI agents working on EEA code
-->

These actions are mandatory — agents must perform them without exception when the triggering conditions are met.

---

## Session End Protocol

### MAND-01: Show Git Status Before Commit

**Trigger:** User indicates work completion ("done", "wrap up", "commit", "finish", "push")

**Action:**
1. Run `git status` and display the output
2. Summarize: number of modified files, untracked files, deletions
3. Show the diff summary (files changed, insertions/deletions)

**Why:** The user must see what will be committed before it happens.

---

### MAND-02: Propose Conventional Commit Message

**Trigger:** User indicates work completion

**Action:**
1. Draft a commit message using [Conventional Commits](https://www.conventionalcommits.org/)
2. Format: `type(scope): description`
3. Include body only if the "why" isn't obvious from the description

**Commit types:**
| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, missing semicolons, etc. |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `perf` | Performance improvement |
| `test` | Adding or correcting tests |
| `chore` | Build process, dependencies, auxiliary tools |
| `ci` | CI/CD configuration |
| `security` | Security fix |

**Example:**
```
feat(auth): add OAuth2 login with EEA SSO

Integrates with EEA's centralized identity provider
using the standard OAuth2 authorization code flow.
```

---

### MAND-03: Ask for Confirmation Before Committing

**Trigger:** User indicates work completion

**Action:**
1. Present the proposed commit message
2. Present the list of files to be committed
3. Ask: "Commit these changes?" or "Approve this commit?"
4. **Wait for explicit confirmation** ("yes", "approve", "commit", "go ahead")
5. Only then execute `git commit`

**Why:** Prevents accidental commits of incomplete or wrong changes.

**If user says no:**
- Ask what they'd like to change
- Allow them to modify the commit message or staging
- Do not commit until they explicitly approve

---

### MAND-04: Log Significant Decisions

**Trigger:** Session introduced new architecture decisions, gotchas, or EEA-specific constraints

**Action:**
1. Propose an addition to project documentation
2. Suggest location:
   - `docs/decisions/{topic}.md` for architecture decisions
   - `docs/adr/{number}-{topic}.md` for formal ADRs
   - `docs/gotchas.md` for troubleshooting insights
   - `shared/{category}/{topic}.md` for org-wide knowledge
3. Format proposal:
   ```
   File: {path}
   Content: {what to add}
   Reason: {why this matters}
   ```
4. Ask user if they want to add it now or defer

**Why:** Captures organizational knowledge that would otherwise be lost.

---

## Verification Protocol

### MAND-05: Verify Before Destructive Operations

**Trigger:** About to execute a destructive command

**Action:**
1. **STOP** — do not execute
2. Show the exact command or plan
3. Explain what will be affected (resources, data, services)
4. Explain the rollback plan if something goes wrong
5. Ask for explicit confirmation
6. Only proceed if user explicitly confirms

**Destructive commands include:**
- `terraform apply`, `terraform destroy`
- `kubectl delete`, `helm uninstall`
- Database migrations that drop tables or columns
- `rm -rf` on non-temporary directories
- `DROP`, `TRUNCATE` SQL statements
- Any operation that deletes or overwrites production data

---

### MAND-06: Verify Tests Pass Before Marking Complete

**Trigger:** User asks to mark work as complete or asks to commit

**Action:**
1. Check if the project has tests (look for test files, `package.json` scripts, `pytest`, `jest`, etc.)
2. If tests exist: run them and report results
3. If tests fail: fix them or explain why they can't be fixed in this session
4. Only mark complete if tests pass or user explicitly accepts test failures

**Why:** Commits with failing tests break CI and block other developers.

---

## Security Protocol

### MAND-07: Scan for Secrets Before Commit

**Trigger:** About to commit changes

**Action:**
1. Scan changed files for patterns that look like secrets:
   - High-entropy strings (>80 bits)
   - Patterns matching `api_key`, `password`, `secret`, `token`
   - Base64 strings that decode to recognizable formats
   - Hardcoded URLs with credentials (`http://user:pass@host`)
2. If potential secrets found: **STOP** and alert the user
3. Do not commit until secrets are removed or user explicitly confirms they are safe (e.g., test fixtures)

**Why:** One accidental secret commit requires rotating credentials and rewriting git history.

---

## Communication Protocol

### MAND-08: Explain "Why" Not Just "What"

**Trigger:** Any significant code change or recommendation

**Action:**
1. Explain what you did or are proposing
2. Explain why you chose that approach
3. Mention alternatives considered and why they were rejected

**Why:** Helps the user learn and makes future maintenance easier.

**Example:**
```
What: I refactored the authentication middleware into a separate module.
Why: The current file is 800 lines and handles 3 concerns (auth, logging, rate limiting).
   Separating auth makes it testable in isolation and follows SRP.
Alternatives considered:
   - Keep as-is: rejected because it's already causing merge conflicts
   - Use a library: rejected because EEA has custom SSO requirements
```

## Documentation Protocol

### MAND-09: Update CHANGELOG on Major Code Changes

**Trigger:** The work session includes changes that add, remove, or alter behavior of the project

**Action:**
1. Before committing, check if `CHANGELOG.md` exists in the project root
2. If yes, check if your changes qualify as "major" (see criteria in `rules/changelog.process.md`)
3. If major: add an entry to `CHANGELOG.md` under the current date
4. Use format: `YYYY-MM-DD — Brief description`
5. Categorize under: `Added`, `Changed`, `Fixed`, `Removed`, or `Documentation`
6. Keep entries concise but specific enough that a future developer can understand the impact

**Why:** CHANGELOGs are the fastest way for humans to understand project evolution. Git history requires archaeology; release notes are often too sparse. A maintained CHANGELOG saves hours during incident response, compliance audits, and onboarding.

**Applies to:** All EEA project repositories. Not optional.

**If no CHANGELOG.md exists:** Propose creating one. Use this repo's `CHANGELOG.md` as a template.

---

*Last updated: 2026-05-16*
