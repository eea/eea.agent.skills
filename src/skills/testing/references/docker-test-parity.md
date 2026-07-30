# Docker test parity

Use this model when Jenkins and developers must run the same tests.

## Minimum parity requirements

- Same Docker image (`Dockerfile.test`)
- Same mounted workspace behavior
- Same command string or clearly equivalent wrapper
- Same report paths for junit / coverage when CI needs them

## Recommended structure

- `Dockerfile.test`
- README section with exact commands
- optional helper scripts under `scripts/`
- Jenkinsfile invoking the same commands

## Example

```bash
docker build -f Dockerfile.test -t repo-test .
docker run --rm -v "$PWD:/workspace" -w /workspace repo-test bash -lc 'ruff check src tests && pytest tests'
```

If Jenkins runs something materially different, parity is broken.
