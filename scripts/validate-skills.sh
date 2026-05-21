#!/usr/bin/env bash
set -euo pipefail

# Validate all skills against the official Agent Skills specification.
# Uses the skills-ref reference library (PyPI: agentskills).
#
# Usage: ./scripts/validate-skills.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

ERR_COUNT=0
PASS_COUNT=0
AGENTSKILLS_CMD=""

# ---------------------------------------------------------------------------
# Detect or install agentskills
# ---------------------------------------------------------------------------
resolve_agentskills() {
    if command -v agentskills &>/dev/null; then
        AGENTSKILLS_CMD="agentskills"
        return
    fi

    # Try uv (fast, preferred)
    if command -v uv &>/dev/null; then
        local venv_dir
        venv_dir="$(mktemp -d)"
        uv venv "$venv_dir" >/dev/null 2>&1
        uv pip install --python "$venv_dir/bin/python" skills-ref >/dev/null 2>&1
        AGENTSKILLS_CMD="$venv_dir/bin/agentskills"
        return
    fi

    # Fallback to python3 venv
    if command -v python3 &>/dev/null; then
        local venv_dir
        venv_dir="$(mktemp -d)"
        python3 -m venv "$venv_dir" >/dev/null 2>&1
        "$venv_dir/bin/pip" install skills-ref >/dev/null 2>&1
        AGENTSKILLS_CMD="$venv_dir/bin/agentskills"
        return
    fi

    echo "ERROR: agentskills not found and neither uv nor python3 is available."
    echo "Install manually: pip install skills-ref"
    exit 1
}

# ---------------------------------------------------------------------------
# Validate a single skill directory
# ---------------------------------------------------------------------------
validate_skill() {
    local skill_dir="$1"
    local label="$2"

    if [ ! -f "$skill_dir/SKILL.md" ]; then
        echo "  ✗  $label — missing SKILL.md"
        ERR_COUNT=$((ERR_COUNT + 1))
        return 1
    fi

    if $AGENTSKILLS_CMD validate "$skill_dir" >/dev/null 2>&1; then
        echo "  ✓  $label"
        PASS_COUNT=$((PASS_COUNT + 1))
        return 0
    else
        echo "  ✗  $label — validation failed"
        # Show details on stderr
        $AGENTSKILLS_CMD validate "$skill_dir" 2>&1 | sed 's/^/     /'
        ERR_COUNT=$((ERR_COUNT + 1))
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    echo "========================================"
    echo "  Skill Validation (agentskills)"
    echo "========================================"
    echo ""

    resolve_agentskills
    echo "Using: $AGENTSKILLS_CMD"
    echo ""

    # --- Source skills ---
    echo "Source skills (src/skills/):"
    for skill_dir in "$REPO_ROOT"/src/skills/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name="$(basename "$skill_dir")"
        validate_skill "$skill_dir" "$name"
    done
    echo ""

    # --- Built / merged skills ---
    echo "Built skills (skills/):"
    for skill_dir in "$REPO_ROOT"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name="$(basename "$skill_dir")"
        validate_skill "$skill_dir" "$name"
    done
    echo ""

    # --- Summary ---
    echo "========================================"
    echo "  Summary: $PASS_COUNT passed, $ERR_COUNT failed"
    echo "========================================"

    if [ $ERR_COUNT -gt 0 ]; then
        exit 1
    fi
    exit 0
}

main "$@"
