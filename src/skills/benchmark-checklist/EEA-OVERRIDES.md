# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-18 -->

## EEA measurement context

- EEA quality gates run in Docker on Jenkins (`Dockerfile.test` contract, see the `testing` skill). A benchmark that only runs natively does not prove the Jenkins path; state which environment the number came from and make it comparable before comparing.
- Name the machine class in the report (local laptop vs Jenkins build agent). Numbers measured on different classes are not a before/after pair.
