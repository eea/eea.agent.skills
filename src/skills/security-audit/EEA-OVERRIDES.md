# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-16 -->

## EEA-Specific Patterns

### Finding Handling at EEA

- Treat all findings as confidential internal material. Do not publish `REPORT.md`, `FINDINGS-DETAIL.md`, or `findings.json` outside the project repository's normal review flow, and never upload them to external services.
- Coordinate confirmed findings with the project's security contact before public disclosure, per EEA incident and vulnerability-handling procedures.
- This skill complements, not replaces, the existing EEA quality gates: Trivy covers dependency and image scanning in Jenkins, while this skill targets logic, trust-boundary, and configuration flaws that scanners do not reach.

### Sandbox for Target-Controlled Execution

EEA developer machines do not ship a dedicated agent sandbox. A compliant sandbox for the skill's execution rules can be assembled from locally available Docker:

```bash
# Network-disallowed, read-only target, resource-limited, scratch-only writes
docker run --rm --network none \
  --read-only \
  --memory=512m --cpus=1 --pids-limit=64 \
  -v "$TARGET_SRC":/target:ro \
  -v "$TOOLCHAIN":/toolchain:ro \
  -v "$SCRATCH":/scratch \
  -e HOME=/scratch/home \
  <local-base-image> /bin/sh -c '<bounded check command>'
```

- Use only images and toolchains already present on the host; do not let the container pull dependencies.
- If the required controls (network disable, resource limits, scratch-only writes) cannot all be enforced, do not execute target code. Keep the lead as `needs_validation` and report the missing sandbox capability, as the skill requires.

### EEA Project Context

- Common EEA audit targets: Plone 6 backends (Python), Volto frontends (React/TypeScript), Dockerfiles and Jenkins pipeline definitions. Select the matching companion files accordingly (e.g. `WEB-PROTOCOL-AND-AUTH.md` for Plone/Volto request handling, `SUPPLY-CHAIN-AND-RELEASE.md` for Docker/Jenkins release paths).
- Never audit against or probe live EEA environments, dashboards, or shared infrastructure, including intranet endpoints; source and sandboxed local evidence only.
