# Dockerfile.test template

Use this template when the repository needs a dedicated Docker image for linting, unit tests, and integration tests.

```dockerfile
FROM node:20-bookworm

WORKDIR /app

COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY . .

RUN mkdir -p /app/coverage/lcov-report

ENV CI=true
ENV FORCE_COLOR=1

CMD ["npm", "run", "test:ci"]
```

For mixed Python + Node repositories, prefer a single test image based on the runtime that already supports the stricter frontend toolchain, then install the secondary language toolchain into that image. In practice, this often means using a Node base image and adding Python, rather than copying Node/NPM binaries into a Python image.

Expected command contract:
- `npm run lint`
- `npm run test:ci`
- `npm run start:ci`
- `npm run test:integration:ci`

Expected artifact contract inside the container:
- `/app/junit.xml`
- `/app/coverage/lcov.info`
- `/app/coverage/lcov-report/index.html`
- optional `/app/integration-junit.xml`

Adapt the base image and package manager to the repository. The important part is the artifact contract, not Node.js specifically.
