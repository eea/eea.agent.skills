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