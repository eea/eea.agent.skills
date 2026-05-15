# EEA AI Harness

**Version:** 1.0.0
**Source:** https://github.com/eea/eea.agent.skills

---

## Safety Kernel

- Never commit secrets, credentials, or API keys.
- Never run destructive commands without explicit confirmation.
- Never modify production without explicit signal.

For full rules, load on trigger match:
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
```

---

## Knowledge Accumulation

Before each significant response, check if discussion introduced new:

1. **Decisions** — architecture, library, infrastructure choices
2. **Gotchas** — troubleshooting, platform quirks, EEA constraints
3. **Contracts / SLOs** — performance budgets, API contracts, uptime

If yes, propose addition:

```
File: {path}
Content: {what to add}
Reason: {why this matters}
```

Locations:
- Project-local: `docs/decisions/{topic}.md` or `docs/adr/{number}-{topic}.md`
- Org-wide: `shared/{category}/{topic}.md`
