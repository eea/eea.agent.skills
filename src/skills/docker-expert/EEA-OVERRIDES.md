# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-04-21 -->

## EEA-Specific Patterns

### Internal Registry Access

When building containers for internal EEA services:

```dockerfile
# EEA internal registry pattern
FROM registry.eea.europa.eu/base/ubuntu:22.04

# Install EEA root certificates for internal HTTPS
COPY eeacerts.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates

# Use EEA proxy for external access
ENV HTTP_PROXY=http://proxy.eea.europa.eu:8080
ENV HTTPS_PROXY=http://proxy.eea.europa.eu:8080
ENV NO_PROXY=registry.eea.europa.eu,intranet.eea.europa.eu
```

### EEA Security Compliance

EEA-specific security requirements that extend upstream:

```dockerfile
# EEA security baseline
# - All containers must run as non-root (UID 10001+)
# - Base images must be scanned weekly
# - No external network calls without proxy exception
# - All secrets must be mounted from Docker secrets or Vault

# Non-root user with EEA UID range
RUN addgroup -g 10001 -S eea && \
    adduser -S eea-user -u 10001 -G eea

# Health check with internal endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1
```

### Docker Compose for EEA Services

```yaml
# docker-compose.eea.yml
version: '3.8'
services:
  app:
    build:
      context: .
      target: production
    environment:
      - EEA_ENV=production
      - EEA_SERVICE_NAME=${SERVICE_NAME}
    secrets:
      - eeas_db_password
    networks:
      - eea_internal
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/health"]
      interval: 30s
      timeout: 5s
      retries: 3

networks:
  eea_internal:
    driver: bridge
    internal: true
```

### Build Cache for EEA Nexus Registry

```dockerfile
# Use EEA Nexus as cache for package managers
FROM node:18-alpine AS deps
WORKDIR /app
COPY package*.json ./

RUN --mount=type=cache,target=/root/.npm \
    --mount=type=cache,target=/root/.cache \
    npm ci --only=production && \
    npm cache clean --force --prefix /root/.npm && \
    npm cache clean --force --prefix /root/.cache
```

## Handoff to Other EEA Skills

When the Docker task is complete, consider these EEA skills:

- **`eea-infra`** (future): Kubernetes manifests, Terraform for EEA cloud
- **`eea-security`** (future): Security scanning, compliance checks
- **`eea-deploy`** (future): EEA deployment pipelines, CI/CD integration

## Notes

- EEA uses `registry.eea.europa.eu` as primary registry
- All containers must comply with EEA security policy SC-01
- Proxy exceptions required for external dependencies
- Contact: EEA Platform Team for registry access issues

### Dockerfile.test for Jenkins Pipelines

When an EEA project needs Jenkins-based linting, unit tests, and integration tests in Docker:

```dockerfile
FROM node:20-bookworm
WORKDIR /app
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY . .
ENV CI=true
CMD ["npm", "run", "test:ci"]
```

Required contract for `Dockerfile.test`:
- The full repository source is copied into the image.
- Development and test dependencies are installed, not just production dependencies.
- The image can run linting, unit tests, and integration helpers.
- Unit test results can be copied out as `junit.xml`.
- Coverage can be copied out as `coverage/lcov.info` and `coverage/lcov-report/index.html`.
- The image should be suitable for `docker run --name <container> ...` so Jenkins can use `docker cp` and then `docker rm -v`.
- For mixed Python + Node repositories, prefer starting from a Node base image and installing Python tooling into it rather than copying `node` / `npm` binaries across images.
- If `requirements.txt`, `pyproject.toml`, and lockfiles disagree, inspect which dependency source is actually buildable before freezing the Dockerfile around the wrong install path.
- If `npm ci` fails because of peer dependency resolution in an existing project, use `--legacy-peer-deps` only as an explicit repository-specific decision, not as a universal default.

### Trivy CVE preflight for release Dockerfiles

Before considering a production `Dockerfile` finished (the one that builds
the release image — not `Dockerfile.test`), scan it locally the same way the
EEA Jenkins Trivy stage will, so the first Jenkins run doesn't fail on a CVE
that could have been fixed or accepted up front. This mirrors the gate
described in the `jenkins-pipeline` skill's "EEA Trivy severity gate".

1. Build the release image locally:
   ```bash
   docker build -t <repo>-release:preflight .
   ```
2. Scan it for `CRITICAL` findings — the same severity the Jenkins gate
   enforces:
   ```bash
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     aquasec/trivy:<pinned-version> image --no-progress --format table \
     --severity CRITICAL <repo>-release:preflight
   ```
   Also run a `HIGH,CRITICAL` pass so you see what will show up in the
   archived Jenkins report even though it won't gate the build — otherwise
   `HIGH` findings are a surprise the first time someone reads that report.
3. For each `CRITICAL` finding, check the `Fixed Version` column Trivy
   reports:
   - If a fixed version exists — a newer base image tag, or a pinnable
     package/dependency version — update the Dockerfile (bump the base
     image tag, pin the package to the fixed version, e.g.
     `apt-get install <pkg>=<fixed-version>`), then rebuild and rescan.
     Repeat until no fixable `CRITICAL` finding remains.
   - If `Fixed Version` is blank (no patch published upstream yet, e.g.
     Trivy status `affected` or `fix_deferred`), do not block on it or
     loosen the gate. Add it to `.trivyignore` instead, with a comment
     giving: the package/CVE, that no upstream fix exists as of the scan
     date, and whether the vulnerable package is even reachable from the
     application's own code (most OS/apt transitive dependencies are not).
4. Never add a finding to `.trivyignore` just because a fix is inconvenient
   — only for confirmed no-fix-available cases, each with its own comment
   explaining why. Don't blanket-ignore an entire severity tier.
5. Clean up the local preflight image and any containers created for the
   scan once done (`docker rmi <repo>-release:preflight`, `docker rm -v
   <name>` for named scan containers) — this is a local-only check, not
   something to leave running or leave images behind for.

