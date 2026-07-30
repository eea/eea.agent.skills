---
name: testing
description: >
  Define and run developer-reproducible test commands that match Jenkins exactly,
  with Docker as the canonical execution environment for EEA projects.
license: MIT
metadata:
  author: EEA
  version: "1.0.0"
  eeaspecific: "true"
---

# Testing

Use this skill when a repository needs a reliable testing workflow that developers and Jenkins can run the same way.

## Primary goal

Make test execution identical between:
- the developer's local environment
- the agent's environment
- Jenkins

For EEA projects, Docker is the preferred parity mechanism.

## When to use

Use this skill when you need to:
- define canonical test commands for a repository
- make Jenkins and local testing identical
- document exactly how developers can reproduce CI failures locally
- create Docker-based unit/integration test flows
- avoid relying on Make as the only entrypoint

## Core rule

The commands Jenkins runs must be the same commands a developer can run locally with Docker.

Do not create a pipeline where:
- Jenkins hides the real commands inside Groovy only
- developers need special knowledge of Jenkins logs to reproduce failures
- Make is the only usable interface if developers may not have it

## Required workflow

1. Inspect the repository and identify all test layers:
   - lint / format
   - type checks
   - unit tests
   - integration tests
   - e2e tests
2. Choose a canonical Docker-based execution path.
3. Make Jenkins call that path.
4. Expose the same commands to developers in plain shell form.
5. Verify that the commands run the same image, same files, same entrypoints, and same report paths.

## Preferred EEA testing pattern

1. Create or update `Dockerfile.test`.
2. Put canonical test commands in plain shell form in documentation and/or helper scripts.
3. Have Jenkins call those exact Docker commands.
4. Have developers run those same Docker commands locally.

## Avoid hidden Make-only workflows

Using a `Makefile` in production is acceptable, but it must not be the only way to understand or execute tests.

If a repository uses Make:
- document the equivalent Docker command explicitly
- ensure the agent can discover the underlying command
- do not force developers to install Make just to reproduce Jenkins

## Good command design

Prefer commands like these in docs or helper scripts:

```bash
docker build -f Dockerfile.test -t myapp-test .
docker run --rm -v "$PWD:/workspace" -w /workspace myapp-test pytest tests
```

or, for integration tests:

```bash
docker run --rm -v "$PWD:/workspace" -w /workspace myapp-test bash -lc 'pytest tests/test_api.py'
```

The important part is that Jenkins uses the same command string or a trivial wrapper around it.

## Developer reproducibility contract

For every Jenkins quality/test stage, the repository should be able to answer:
- what exact Docker command does Jenkins run?
- what exact Docker command should a developer run locally?
- are these the same command or an obviously equivalent wrapper?

If the answer is no, the workflow is not good enough yet.

## Output requirements

When using this skill, provide:
1. the canonical Docker commands for lint, unit, and integration tests
2. where those commands are documented or stored
3. confirmation that Jenkins uses the same commands
4. any required Docker prerequisites for developers

## Reference

See `references/docker-test-parity.md` for the EEA parity model.
