# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-07-29 -->

## EEA routing

Use this skill when the `jenkins-pipeline` skill or `code-quality` skill detects that a repository already fails its current quality checks before a new Jenkinsfile is finalized.

## EEA repair expectations

For EEA repositories:
- verify against the actual repository commands, not generalized substitutes
- prefer the same Docker-based command path Jenkins will use when available
- keep fixes small and auditable
- do not mark work complete until the failing Jenkins-quality commands pass

## EEA first-push goal

When this skill is used before introducing or updating a Jenkinsfile, the objective is to reduce the chance that the first push-triggered Jenkins run fails because of pre-existing, already-known code-quality issues.
