# EEA-Specific Overrides
<!-- EEA-Overrides-Version: 1.0 -->
<!-- Last-Sync: 2026-11-18 -->

## Transcripts on OpenCode

- There is no `agent-transcripts/` directory under the workspace. Audit the log against the current session's own conversation and the committed artifacts. Never read session or transcript files belonging to other projects.
- If no transcript is available for the audit, say the audit could not be run against a transcript, and list the rows that remain unverified.

## Cross-model review of the trail

- Spawn the reviewing subagent with the OpenCode `subagent` tool. If only one model is available, say the cross-model review did not run; a same-model review is a fallback, not a substitute.
