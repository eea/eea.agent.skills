# Harness Maintenance

**For humans maintaining the EEA AI Harness.**

---

## Philosophy

When you observe an agent mistake that this harness should have prevented, follow this rule:

> **Change the environment, not the prompt.**

If an agent makes the same mistake twice, the harness has a gap. Do not just rewrite your prompt — add a rule to the appropriate file so the mistake cannot happen again.

This is the core principle of harness engineering:

```
Agent makes mistake → Identify root cause → Add rule to harness → Mistake prevented forever
```

Not:

```
Agent makes mistake → Rewrite prompt → Next session, mistake happens again
```

---

## Where to Add Rules

| When the agent... | Add to... |
|---|---|
| Commits secrets, bypasses security scans, exposes internal infra | `rules/eeaprohibitions.rules.md` |
| Forgets git status, skips confirmation, doesn't log decisions | `rules/eeamandatory.rules.md` |
| Lacks EEA-specific context for a skill | `src/skills/{name}/EEA-OVERRIDES.md` |
| Needs a new capability entirely | New skill under `src/skills/{name}/` |

---

## Process

1. **Observe** — Note the exact mistake and the context in which it happened
2. **Classify** — Is this a prohibition (never do), mandatory (always do), or skill gap?
3. **Draft** — Write the rule in the appropriate file using the existing format
4. **Test** — Rebuild skills if applicable (`./scripts/build.sh {name}`)
5. **Commit** — Open a PR against `eea/eea.agent.skills` with rationale
6. **Distribute** — After merge, run `./scripts/install.sh` or wait for agents to auto-update

---

## Rule Quality Checklist

Good rules are:

- **Specific** — Not "be careful with secrets" but "Never commit API keys, passwords, or tokens to git"
- **Actionable** — Tells the agent exactly what to do or not do
- **Permanent** — Written in a file that persists across sessions
- **Reviewed** — Checked by another human before merging

Avoid:

- **Vague triggers** — "When appropriate" gives the agent discretion to skip
- **Duplication** — Check if a similar rule already exists
- **Token bloat** — Keep rule files focused; split by concern when they grow

---

## Version Control

All harness changes go through Git:

```bash
# Propose a change
git checkout -b harness/add-secrets-scan-rule
# Edit rules/eeaprohibitions.rules.md
git commit -m "rules: add pre-commit secrets scan requirement"
git push origin harness/add-secrets-scan-rule
# Open PR with rationale
```

This preserves history: "When was this prohibition added?" "Which rule change made things stable?" — all traceable via `git log` and `git blame`.

---

## Escalation

If a rule needs to change but you're unsure:

- Open an issue at `eea/eea.agent.skills` describing the gap
- Tag it `harness-gap` for visibility
- Reference the specific agent behavior that triggered it

---

*Last updated: 2026-05-15*
