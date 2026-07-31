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
not captured in the check's `output` fields. In that case ask the user to
paste the relevant section from the Jenkins UI
(`https://ci.eionet.europa.eu/...`, from the check's `details_url`) rather
than guessing at the cause from the pass/fail status alone.
