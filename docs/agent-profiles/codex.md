# Codex Agent Profile

Codex reads global instructions from `${CODEX_HOME:-~/.codex}/AGENTS.md`. If `AGENTS.override.md` exists in that directory, it takes precedence. It also reads a repository's root and nested `AGENTS.md` files. Skills are discovered from `~/.agents/skills` and repository-local `.agents/skills` directories.

## Install from a local clone

```bash
./scripts/install.sh --local --agent codex
```

The installer links the EEA harness as Codex's global instructions when no personal instruction file exists. If one exists, it backs it up and adds a short directive to read the local harness, leaving the personal instructions in place. It chooses `AGENTS.override.md` if that is the active global file. The script also copies merged skills from `skills/` into `~/.agents/skills`. `--agent codex` does not create OpenCode or Claude configuration.

An existing skill directory is left untouched by default. After updating this repository, use `--update` to refresh installed EEA skills and add new ones. The installer skips a same-named skill that does not carry the EEA build marker. Replaced skill directories are backed up under `~/.eea/agent-skill-backups/`, outside Codex's skill discovery path, unless `--no-backup` is specified.

## Update after new repository changes

```bash
cd /path/to/eea.agent.skills
git pull --ff-only
./scripts/install.sh --local --agent codex --update
./scripts/verify.sh --agent codex --harness-dir "$(pwd)"
```

The global harness link follows the updated checkout. Copied skill files need the `--update` step. Start a new Codex session to pick up changed instructions and skills.

The global harness applies whenever you use Codex under this account, including outside EEA projects. Use a repository-local `AGENTS.md` if you want to limit EEA instructions to individual projects instead. The repository's `.agents/AGENTS.md` template is not an instruction file that Codex discovers automatically; put project instructions in the repository root `AGENTS.md`.

If `CODEX_HOME` is set, the installer uses that directory for global instructions. The skill directory remains `~/.agents/skills`.

## Verify

```bash
./scripts/verify.sh --agent codex --harness-dir "$(pwd)"
```

Check the `Codex Configuration` and `Skills Installation` sections. Start a new Codex session after installation so it reads the new global guidance. Ask Codex to list the EEA skills available to it and to identify the harness file it loaded.

## Limitations

- Codex does not read `opencode.json` or the rule directories used by other agents. The EEA harness must be connected through Codex's `AGENTS.md` discovery.
- A short reference added to an existing personal `AGENTS.md` asks Codex to read the local harness when working on EEA projects; the harness text itself is not injected until Codex reads that file.
- Some skills were ported from Cursor or OpenCode. The EEA overrides in the merged `skills/` directory provide Codex paths for the affected workflows. Use `.agents/skills` for generated Codex skills.
- The `agentget` manifest includes the shared skill path, but use `install.sh` for Codex instruction wiring.

Codex instruction and skill locations: [AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md), [skills](https://learn.chatgpt.com/docs/build-skills).
