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
