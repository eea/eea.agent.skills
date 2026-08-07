---
name: testing
description: >
  Keep developer test commands identical to Jenkins, and raise real test
  coverage with tests that exercise actual behavior — because Jenkins and
  SonarQube gate on presence and a coverage number, not on whether a test
  is meaningful.
license: MIT
metadata:
  author: EEA
  version: "1.0.0"
  eeaspecific: "true"
---

# Testing

Use this skill when a repository needs a test workflow developers and Jenkins run identically, or when coverage needs to go up for real rather than by gaming the number.

## Primary goal

Two goals, in order:
1. **Parity** — the same test commands run identically for the developer, the agent, and Jenkins. Mostly mechanical; see "Parity contract" below, which defers detail to `docker-expert` and `jenkins-pipeline` rather than restating it.
2. **Quality** — coverage increases come from tests that exercise real behavior, not from tests written to move a number. This is the harder, ongoing part, and where this skill should keep growing.

## When to use

Use this skill when you need to:
- close a real coverage gap (e.g. moving from 60% to 80%) with tests that exercise actual behavior, not just whichever lines are easiest to hit
- audit whether existing tests are meaningful or just inflate the coverage number
- define canonical test commands for a repository and confirm Jenkins and local testing run them identically
- avoid relying on Make as the only entrypoint for running tests

## Parity contract

The commands Jenkins runs must be the same commands a developer can run locally with Docker. Jenkins must never hide the real commands inside Groovy only, and Make — if the repository uses it — must never be the only usable interface; a developer without Make must still be able to run the equivalent command.

For every Jenkins quality/test stage, be able to answer:
- what exact Docker command does Jenkins run?
- what exact Docker command should a developer run locally?
- are these the same command, or an obviously equivalent wrapper?

If the answer is no, fix that before touching test content — a coverage number from a stage you can't reproduce locally isn't one you can trust.

For the `Dockerfile.test` contract (what the image must contain, dependency-install rules, mixed-language guidance), see `docker-expert/EEA-OVERRIDES.md`'s "Dockerfile.test for Jenkins Pipelines" — that's the canonical source, not restated here. For the Jenkinsfile phases that build, preflight, and generate around it, see `jenkins-pipeline`'s Required workflow.

Do not bind-mount the repository into the test container (`-v "$PWD:/workspace"` or similar) to satisfy parity — rely on `COPY . .` baked into the image instead. This isn't just a style preference: on EEA Jenkins `docker-host` agents, `$WORKSPACE` is a path inside the Jenkins agent, not a real path on the host the Docker daemon runs on, so a bind mount silently resolves to an empty directory there — see `jenkins-pipeline/EEA-OVERRIDES.md`'s "EEA Docker-outside-of-Docker constraint". A bind-mounted command works on a developer's own machine (daemon and `$PWD` share a filesystem there) but is not the same command Jenkins can run; baked-in source from the start means the exact same command string works unmodified in both places.

## Test quality over test presence

Jenkins and SonarQube only check two things: did the suite pass, and did coverage clear a threshold. Neither checks whether a test exercises real behavior. That gap means coverage can go up while the suite's actual value stays flat — a project can hit an 80% target with tests that would never catch a real regression.

Signs a test is padding the number rather than protecting the code:
- the only assertion is that a call didn't throw, or that a result `is not None`
- the test mocks the exact unit under test, so it verifies the mock, not the code
- a whole test — or the assertions inside it — is commented out, skipped, or wrapped in a bare `try/except: pass`
- the test hits a line without exercising the branch that makes that line interesting (e.g. always calls a function with only the happy-path input)
- a snapshot/golden-file test whose snapshot nobody has read since it was generated

None of these are visible to Jenkins. They pass, they count toward coverage, and they hide the real gap.

## Closing a coverage gap

When the goal is a real coverage increase (e.g. 60% → 80%), work from the actual report, not the percentage alone:

1. Run the same coverage command already established under the parity contract above — the number must come from the command Jenkins runs, or it isn't the number that matters.
2. Read the coverage report itself (HTML/LCOV, not just the summary line) to find which files and which branches are untested. A file already at 90% can still be missing the one error-handling branch that matters most.
3. Prioritize by risk, not by ease: business logic and conditionals/error-handling paths before boilerplate, generated code, or trivial getters/setters. The hardest-to-reach edge case is usually the one most worth testing.
4. Write tests with real assertions: concrete inputs, concrete expected outputs, mocking only at the boundary of the unit under test — never the unit itself. Cover the branch, not just the line; a conditional needs a case for each side.
5. Re-run the same coverage command locally and confirm the number moved for the intended reason before pushing. Jenkins should never be the first place a coverage regression — or a fake improvement — is discovered.

## Output requirements

When using this skill, provide:
1. the canonical Docker commands for lint, unit, and integration tests, and confirmation Jenkins uses the same ones
2. for a coverage-improvement task: which files/branches were untested, which tests were added, and why they were prioritized over the alternatives
3. any required Docker prerequisites for developers

---

<!-- BEGIN EEA-OVERRIDES -->
# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-07-29 -->

## EEA parity policy

For EEA projects, the developer must be able to reproduce Jenkins locally without reading Jenkins internals.

The preferred model is:
- Docker installed locally
- `Dockerfile.test` checked into the repository
- canonical Docker commands documented in README or helper scripts
- Jenkins calls those same commands

## EEA guidance on wrappers

Wrappers such as `Makefile`, shell scripts, or package scripts are acceptable only if:
- the underlying Docker command is still obvious
- the developer can run an equivalent command without needing Make
- the wrapper does not hide environment assumptions unique to Jenkins

## EEA recommendation

When generating or updating a Jenkinsfile, also generate the exact local developer command examples alongside it.

<!-- END EEA-OVERRIDES -->

<!-- Merged Build: upstream SKILL.md + EEA-OVERRIDES.md -->
<!-- Auto-generated by scripts/build.sh - DO NOT EDIT DIRECTLY -->
<!-- Source: https://github.com/eea/eea.agent.skills -->
