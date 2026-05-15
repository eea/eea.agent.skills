# EEA Global Prohibitions

<!--
  EEA-Rule-Version: 1.0
  Type: prohibitions
  Scope: organization-wide
  Applies to: all AI agents working on EEA code
-->

These prohibitions apply without exception across all EEA projects, tools, and contexts.

---

## Security & Compliance

### SEC-01: Never Commit Secrets

**Prohibition:** Do not commit API keys, passwords, tokens, private keys, certificates, or any other credentials to version control.

**Why:** Secrets in git history are permanently exposed. Even if deleted, they remain in history and can be extracted.

**What to do instead:**
- Use environment variables (`.env` files that are `.gitignore`d)
- Use Docker secrets or secret management tools
- Use EEA's internal Vault or secret store
- If a secret is accidentally committed: rotate it immediately, do not just delete the file

**Detection:** Before any commit, scan for patterns matching:
- `api_key`, `apikey`, `api-key`
- `password`, `passwd`, `pwd`
- `secret`, `token`, `auth_token`
- `private_key`, `privatekey`
- Base64 strings that decode to recognizable credential formats
- High-entropy strings that look like generated tokens

---

### SEC-02: Do Not Expose Internal Infrastructure

**Prohibition:** Do not reference internal hostnames, IP addresses, registry URLs, or network topology in public commits without security review.

**Why:** Internal infrastructure details can aid attackers in reconnaissance.

**Exceptions:**
- Internal documentation in private repos
- Configuration files that are themselves internal-only
- After explicit security review and approval

**What to do instead:**
- Use environment variables or config maps for internal endpoints
- Use placeholder values in public examples (`registry.internal.example.com`)

---

### SEC-03: Do Not Bypass EEA Proxy

**Prohibition:** External network calls in EEA environments must respect `HTTP_PROXY` and `HTTPS_PROXY` settings. Do not hardcode proxy bypasses.

**Why:** EEA network policy requires all external traffic to flow through the approved proxy for security monitoring.

**What to do instead:**
- Respect environment variables: `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`
- Use `NO_PROXY` only for explicitly approved internal domains
- Document proxy requirements in deployment configs

---

### SEC-04: Do Not Disable Security Scans

**Prohibition:** Never remove, bypass, or disable CI security checks (SAST, dependency scanning, container image scanning, secret scanning).

**Why:** Security scans are the last line of defense against vulnerabilities reaching production.

**What to do instead:**
- If a scan produces a false positive: document it with justification
- If a scan is blocking: fix the underlying issue or escalate to security team
- If scan configuration needs adjustment: propose changes through normal PR process

---

## Operational Safety

### OPS-01: Do Not Modify CI/CD Without Explicit Request

**Prohibition:** Do not modify CI/CD configuration files (`.github/workflows/`, `.gitlab-ci.yml`, Jenkinsfiles, ArgoCD manifests) without the user explicitly asking.

**Why:** CI/CD changes affect all team members and can break builds or deployments.

**What to do instead:**
- Propose changes in a separate file or comment
- If modification is needed: show the diff and ask for explicit confirmation
- Document the change and its impact

---

### OPS-02: Do Not Run Destructive Commands Without Plan

**Prohibition:** Do not run destructive commands (`terraform apply`, `kubectl delete`, `helm uninstall`, database migrations, `rm -rf`, `DROP TABLE`) without first showing the execution plan and getting explicit confirmation.

**Why:** Destructive operations can cause data loss or service outages.

**Required workflow:**
1. Show the command or plan that would be executed
2. Explain what will be affected
3. Ask for explicit confirmation ("yes", "approve", "execute")
4. Only then execute

---

### OPS-03: Do Not Modify Production Without Explicit Signal

**Prohibition:** Do not modify production deployments, databases, or configurations unless the user explicitly says phrases like "production change", "deploy to prod", "update production".

**Why:** Production changes affect users and must be intentional.

**Safe indicators:**
- User says: "deploy to production"
- User says: "production change"
- User says: "update the live site"

**Unsafe indicators (do NOT proceed):**
- User says: "fix this" (ambiguous environment)
- User says: "make it work" (ambiguous environment)
- General troubleshooting without environment specified

---

### OPS-04: Do Not Merge Pull Requests Without Approval

**Prohibition:** Do not merge pull requests or approve code changes without explicit user approval.

**Why:** Code review is a mandatory control in EEA development process.

---

## Code Quality

### QUAL-01: Do Not Ignore Linting or Type Errors

**Prohibition:** Do not commit code with linting errors, type errors, or failing tests. Fix them or ask the user before proceeding.

**Why:** Broken code in main branch blocks other developers and degrades quality.

**What to do instead:**
- Run lint/typecheck before committing
- Fix errors as part of the change
- If fixing is out of scope: document the issue and propose a follow-up

---

### QUAL-02: Do Not Leave TODOs Without Context

**Prohibition:** Every TODO comment must include: what needs to be done, why it wasn't done now, and who should address it.

**Why:** Bare TODOs become permanent fixtures and don't get addressed.

**Required format:**
```
// TODO({owner}): {what} — {why not now}
// Example:
// TODO(dev-team): Add rate limiting — requires infrastructure team to deploy Redis first
```

---

### QUAL-03: Do Not Introduce Dependencies Without Justification

**Prohibition:** Do not add new dependencies (npm, pip, maven, etc.) without explaining why existing ones are insufficient.

**Why:** Each dependency increases attack surface, bundle size, and maintenance burden.

**Required justification:**
- What existing dependency was considered and why it doesn't work
- What the new dependency does
- Approximate size impact
- License compatibility check

---

## EEA-Specific

### EEA-01: Do Not Hardcode EEA-Specific Values in Reusable Skills

**Prohibition:** Reusable skills under `skills/` and `src/skills/` must not contain hardcoded EEA-specific values (registry URLs, proxy addresses, internal endpoints). These belong in `EEA-OVERRIDES.md`.

**Why:** Skills may be consumed by non-EEA users or published publicly.

**What to do instead:**
- Keep base skills generic
- Put EEA-specific values in `src/skills/{name}/EEA-OVERRIDES.md`
- The build script merges them into the distributable skill

---

*Last updated: 2026-05-14*
