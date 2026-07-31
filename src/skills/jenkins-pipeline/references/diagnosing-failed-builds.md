# Diagnosing and fixing a failed Jenkins build

EEA Jenkins publishes build status as **GitHub Checks** — one overall
`Jenkins` check plus one per named stage (e.g. `Tests / Unit test`, `Tests
/ Integration test`), confirmed both by the `github-checks` plugin being
installed (see `references/eea-available-plugins.md`) and by real build
logs showing lines like `[GitHub Checks] GitHub check (name: Tests / Unit
test, status: completed) has been published`.

This is **not** the same thing as Jenkins users logging into the Jenkins
UI via GitHub OAuth — that's a human login flow on the Jenkins side and
doesn't give an API caller any special access to Jenkins itself. What
actually gives the agent visibility is the other direction: Jenkins
reports results *to* GitHub, and GitHub's own API/`gh` CLI can read them
directly — no Jenkins credentials needed.

## 1. Check status via GitHub first, before asking the user for logs

For a PR:
```bash
gh pr checks <PR-number>
```
For a specific commit (e.g. a branch build with no PR yet):
```bash
gh api repos/<owner>/<repo>/commits/<sha>/check-runs
```
Both list each check's name and conclusion (`success`/`failure`) plus a
`details_url` pointing at the actual Jenkins build page. Some Jenkins
GitHub Checks configurations also populate `output.summary`/`output.text`
with a short failure description — worth checking before assuming the
full console log is needed:
```bash
gh api repos/<owner>/<repo>/commits/<sha>/check-runs --jq '.check_runs[] | {name, conclusion, output}'
```

This requires `gh` installed and authenticated in the working environment
(`gh auth status`). If it isn't available, fall back to asking the user
for the check status or the relevant console log excerpt directly — that
fallback has worked throughout this skill's own development.

## 2. Identify which stage failed

The check name maps to a Jenkinsfile stage (`Tests / Unit test` → the
`Unit test` stage, `Sonarqube` → the `Sonarqube test` stage, etc.). Read
that stage in the actual Jenkinsfile to find the exact command it runs —
that's the same command the "Required workflow" preflight in
`jenkins-pipeline`'s `SKILL.md` should already have validated once; it's
still the source of truth here.

## 3. Reproduce locally with the exact same command — don't guess

Run the failing stage's exact command, copied verbatim from the
Jenkinsfile (not paraphrased or approximated):
- Natively, if the installed tool version matches what `Dockerfile.test`
  pins — see `code-quality`'s "Native tools vs Docker for pre-commit
  auto-fix".
- Via `docker build -f Dockerfile.test -t <repo>-test:debug .` +
  `docker run`, when versions don't match, or for stages that only make
  sense inside the test image (integration tests, anything Docker-based).

## 4. Fix, verify locally, then push

Apply auto-fixers for mechanical failures; fix non-mechanical ones (real
bugs, type errors, failing tests, non-fixable lint findings) directly —
see `code-quality`'s "Nothing known-broken gets committed". Rerun the
exact same command until it passes locally *before* pushing a new commit.
Don't push a speculative fix and wait for Jenkins to say whether it
worked — that burns a real CI run to verify something checkable locally
first.

## 5. When the GitHub Check summary genuinely isn't enough

Some failures need the full Jenkins console log to diagnose — a
Docker-outside-of-Docker path issue, a SonarQube sensor warning, anything
not captured in the check's `output` fields. If the developer has set up a
Jenkins API token (section 6), fetch the log directly. Otherwise, ask the
user to paste the relevant section from the Jenkins UI
(`https://ci.eionet.europa.eu/...`, from the check's `details_url`) rather
than guessing at the cause from the pass/fail status alone.

## 6. Reading the full Jenkins console log directly (optional — needs a personal API token)

GitHub Checks (sections 1–5) cover most cases without any extra setup. If
a developer wants the agent to read the actual Jenkins console log
directly instead of pasting excerpts, that needs a personal Jenkins API
token — `ci.eionet.europa.eu` isn't otherwise reachable with the agent's
GitHub credentials; the GitHub-OAuth login on the Jenkins side is a human
browser login flow, not something an API caller can reuse.

### Generating the token (one-time, per developer)

1. Go to `https://ci.eionet.europa.eu/user/<github-username>/security/`
   (`<github-username>` is the same username used to log into Jenkins via
   GitHub OAuth).
2. Under "API Token", add a new token, name it something identifiable
   (e.g. `claude-code`), and copy it immediately — Jenkins only shows the
   value once.
3. Give it to the agent as environment variables for the session (e.g.
   `JENKINS_USER=<github-username>`, `JENKINS_API_TOKEN=<token>`) — never
   write it into a file in the repository, a Jenkinsfile, or commit it
   anywhere. It's a personal credential, scoped to that one Jenkins user
   account's permissions — not a service account to share across a team.

### Fetching a build's console log

```bash
curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" \
  "https://ci.eionet.europa.eu/job/EEA-AI/job/<repo>/job/<branch>/lastBuild/consoleText"
```

Nested-folder jobs need `/job/<segment>` repeated for every path segment
(`EEA-AI/job/<repo>/job/<branch>`) — the same job-path shape already used
for the Jenkins README badge URL. Useful build selectors in place of a
specific number:
- `lastBuild` — most recent build regardless of outcome
- `lastFailedBuild` — most recent failing build (the common case here)
- `lastSuccessfulBuild` — for comparing against a known-good run
- a specific number (e.g. `42`), once known from a check's `details_url`

### Fetching build metadata/status as JSON

```bash
curl -s -u "$JENKINS_USER:$JENKINS_API_TOKEN" \
  "https://ci.eionet.europa.eu/job/EEA-AI/job/<repo>/job/<branch>/lastBuild/api/json"
```

### Notes

- These are read-only `GET` requests; Jenkins doesn't require a CSRF crumb
  for reads, only for state-changing calls (triggering builds, etc.) —
  don't reach for crumb handling, and don't use a token to trigger or
  modify builds without the developer explicitly asking for that.
- Prefer the GitHub Checks route (sections 1–5) first — it needs no token
  setup and covers most cases. Reach for the direct Jenkins log only when
  the check summary genuinely isn't enough to diagnose the failure.
