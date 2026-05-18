#!/usr/bin/env bash
set -euo pipefail

# EEA AI Harness Verification Script
# Usage: ./scripts/verify.sh
#
# Performs a health-check of the current system against the intended
# installation state produced by scripts/install.sh.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT=""
HARNESS_DIR="${HOME}/.eea/agent-harness"
EEA_HARNESS_URL="https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
WARN_COUNT=0
FAIL_COUNT=0

# Colors (must be defined before usage)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_pass() { echo -e "${GREEN}  ✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}  ⚠${NC} $1"; WARN_COUNT=$((WARN_COUNT + 1)); }
log_fail() { echo -e "${RED}  ✗${NC} $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
log_info() { echo -e "${BLUE}  ℹ${NC} $1"; }
log_section() { echo ""; echo -e "${BLUE}==>${NC} $1"; }

usage() {
    echo "EEA AI Harness Health Check"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --harness-dir <path>  Use a specific harness source directory"
    echo "  --help                Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Auto-detect harness directory"
    echo "  $0 --harness-dir /path      # Use specific harness source"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --harness-dir)
            HARNESS_DIR="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Determine if running from the harness repo itself
if [ -f "${SCRIPT_DIR}/../catalog.yaml" ] && [ -d "${SCRIPT_DIR}/../src/skills" ]; then
    REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
fi

# Auto-detect harness source if the default doesn't look right
if [ ! -f "${HARNESS_DIR}/harness/EEA-HARNESS.md" ]; then
    # Try to infer from existing agent symlinks
    if [ -L "${HOME}/.claude/CLAUDE.md" ]; then
        CLAUDE_TARGET=$(readlink "${HOME}/.claude/CLAUDE.md")
        if [[ "$CLAUDE_TARGET" == */harness/EEA-HARNESS.md ]]; then
            HARNESS_DIR="${CLAUDE_TARGET%/harness/EEA-HARNESS.md}"
        fi
    fi
fi

# Fall back to current repo if we are inside it
if [ ! -f "${HARNESS_DIR}/harness/EEA-HARNESS.md" ] && [ -n "${REPO_ROOT}" ] && [ -f "${REPO_ROOT}/harness/EEA-HARNESS.md" ]; then
    HARNESS_DIR="${REPO_ROOT}"
fi

# ---------------------------------------------------------------------------
# Harness Repository
# ---------------------------------------------------------------------------
check_harness_repo() {
    log_section "Harness Repository"

    if [ ! -d "${HARNESS_DIR}" ]; then
        log_fail "Harness directory not found: ${HARNESS_DIR}"
        log_info "Fix: Run ./scripts/install.sh or clone manually:"
        log_info "  git clone https://github.com/eea/eea.agent.skills.git ~/.eea/agent-harness"
        return
    fi

    if [ ! -d "${HARNESS_DIR}/.git" ]; then
        log_fail "Harness directory exists but is not a git repo: ${HARNESS_DIR}"
        return
    fi

    log_pass "Harness repo exists at ${HARNESS_DIR}"

    if [ ! -f "${HARNESS_DIR}/harness/EEA-HARNESS.md" ]; then
        log_fail "EEA-HARNESS.md missing in harness directory"
    else
        log_pass "EEA-HARNESS.md present"
    fi

    # Optional: check if behind origin/main
    if command -v git &>/dev/null; then
        local behind
        behind=$(cd "${HARNESS_DIR}" && git rev-list --count HEAD..origin/main 2>/dev/null || echo "?")
        if [ "$behind" != "?" ] && [ "$behind" -gt 0 ]; then
            log_warn "Harness is ${behind} commit(s) behind origin/main"
            log_info "Fix: cd ${HARNESS_DIR} && git pull origin main"
        elif [ "$behind" = "0" ]; then
            log_pass "Harness is up to date with origin/main"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Agent Detection
# ---------------------------------------------------------------------------
detect_agents() {
    local agents=()

    if [ -d "${HOME}/.config/opencode" ] || command -v opencode &>/dev/null; then
        agents+=("opencode")
    fi

    if [ -d "${HOME}/.claude" ] || command -v claude &>/dev/null; then
        agents+=("claude")
    fi

    if [ -d "${HOME}/.hermes" ] || command -v hermes &>/dev/null; then
        agents+=("hermes")
    fi

    if [ -d "${HOME}/.pi/agent" ] || command -v pi &>/dev/null; then
        agents+=("pi")
    fi

    if [ -d "${HOME}/.gemini" ] || command -v gemini &>/dev/null; then
        agents+=("gemini")
    fi

    echo "${agents[@]}"
}

# ---------------------------------------------------------------------------
# OpenCode — checks all instruction sources, warns on duplication
# ---------------------------------------------------------------------------
check_opencode() {
    log_section "OpenCode Configuration"

    local source_count=0
    local sources_found=""

    # Source 1: opencode.json / opencode.jsonc
    local config_dir="${HOME}/.config/opencode"
    local config_json="${config_dir}/opencode.json"
    local config_jsonc="${config_dir}/opencode.jsonc"
    local in_json=false

    for f in "${config_json}" "${config_jsonc}"; do
        if [ -f "$f" ]; then
            if command -v python3 &>/dev/null; then
                local has_url
                has_url=$(python3 -c "
import sys, json
try:
    with open('$f') as fp:
        data = json.load(fp)
    instructions = data.get('instructions', [])
    print('yes' if '$EEA_HARNESS_URL' in instructions else 'no')
except Exception:
    print('error')
" 2>/dev/null)
                if [ "$has_url" = "yes" ]; then
                    in_json=true
                fi
            else
                if grep -q "$EEA_HARNESS_URL" "$f" 2>/dev/null; then
                    in_json=true
                fi
            fi
        fi
    done

    if [ "$in_json" = true ]; then
        source_count=$((source_count + 1))
        sources_found="${sources_found}opencode.json "
    fi

    # Source 2: ~/.config/opencode/AGENTS.md
    local global_agents="${config_dir}/AGENTS.md"
    if [ -f "$global_agents" ] && grep -qi "eea" "$global_agents" 2>/dev/null; then
        source_count=$((source_count + 1))
        sources_found="${sources_found}~/.config/opencode/AGENTS.md "
    fi

    # Source 3: ~/.claude/CLAUDE.md (Claude Code compatibility)
    local claude_compatibility=true
    if [ -n "${OPENCODE_DISABLE_CLAUDE_CODE_PROMPT:-}" ]; then
        claude_compatibility=false
    fi

    if [ "$claude_compatibility" = true ]; then
        local claude_file="${HOME}/.claude/CLAUDE.md"
        local in_claude=false
        if [ -L "$claude_file" ]; then
            local target
            target=$(readlink "$claude_file")
            [[ "$target" == *"EEA-HARNESS.md" ]] && in_claude=true
        elif [ -f "$claude_file" ] && grep -q "EEA Global Harness" "$claude_file" 2>/dev/null; then
            in_claude=true
        fi

        if [ "$in_claude" = true ]; then
            source_count=$((source_count + 1))
            sources_found="${sources_found}~/.claude/CLAUDE.md "
        fi
    fi

    # Evaluate
    if [ $source_count -eq 0 ]; then
        log_fail "EEA harness not found in any OpenCode instruction source"
        log_info "Fix: Add the EEA harness URL to your opencode.json instructions:"
        log_info "  \"${EEA_HARNESS_URL}\""
        log_info "Or symlink ~/.claude/CLAUDE.md to the harness (OpenCode will inherit it)"
    elif [ $source_count -eq 1 ]; then
        log_pass "EEA harness found in OpenCode via: ${sources_found}"
    else
        log_pass "EEA harness found in OpenCode via: ${sources_found}"
        log_warn "Harness is present in ${source_count} OpenCode sources — potential duplication in LLM context"
        log_info "Fix: Keep only one source. If you use both OpenCode and Claude Code,"
        log_info "      leave ~/.claude/CLAUDE.md as the single source and remove the URL from opencode.json"
        log_info "      (or set OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1 to force opencode.json-only)"
    fi
}

# ---------------------------------------------------------------------------
# OpenCode AGENTS.md should not contain the full EEA harness
# ---------------------------------------------------------------------------
check_opencode_agents_md() {
    local agents_md="${HOME}/.config/opencode/AGENTS.md"

    if [ ! -f "$agents_md" ]; then
        return
    fi

    # Check if AGENTS.md contains the EEA harness (by looking for Version line or EEA references)
    local has_eea_version=false
    local has_eea_reference=false

    if grep -q '^\*\*Version:\*\*' "$agents_md" 2>/dev/null; then
        has_eea_version=true
    fi

    if grep -qi "EEA AI Harness\|EEA-HARNESS\|eeaprohibitions\|eeamandatory" "$agents_md" 2>/dev/null; then
        has_eea_reference=true
    fi

    if [ "$has_eea_version" = true ] || [ "$has_eea_reference" = true ]; then
        log_warn "~/.config/opencode/AGENTS.md contains EEA harness content"
        log_info "  AGENTS.md is intended for personal global instructions, not org-wide rules."
        log_info "  Copied harness content will go stale (as of today it already is)."
        log_info "  Fix: Remove the EEA harness content from this file."
        log_info "        Add the EEA harness URL to ~/.config/opencode/opencode.json instead:"
        log_info "          \"${EEA_HARNESS_URL}\""
    fi
}

# ---------------------------------------------------------------------------
# Claude Code
# ---------------------------------------------------------------------------
check_claude() {
    log_section "Claude Code Configuration"

    local claude_file="${HOME}/.claude/CLAUDE.md"

    if [ ! -e "${claude_file}" ]; then
        log_warn "CLAUDE.md not found at ${claude_file}"
        return
    fi

    if [ -L "${claude_file}" ]; then
        local target
        target=$(readlink "${claude_file}")
        if [[ "$target" == *"EEA-HARNESS.md" ]]; then
            log_pass "CLAUDE.md is symlinked to EEA harness"
        else
            log_warn "CLAUDE.md is a symlink but not to EEA-HARNESS.md"
            log_info "  Target: ${target}"
        fi
    else
        if grep -q "EEA Global Harness" "${claude_file}" 2>/dev/null; then
            log_pass "CLAUDE.md contains EEA harness reference section"
        else
            log_fail "CLAUDE.md exists but does not reference EEA harness"
            log_info "Fix: Run ./scripts/install.sh --agent claude"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Hermes
# ---------------------------------------------------------------------------
check_hermes() {
    log_section "Hermes Agent Configuration"

    local hermes_file="${HOME}/.hermes/HERMES.md"

    if [ ! -e "${hermes_file}" ]; then
        log_warn "HERMES.md not found at ${hermes_file}"
        return
    fi

    if [ -L "${hermes_file}" ]; then
        local target
        target=$(readlink "${hermes_file}")
        if [[ "$target" == *"EEA-HARNESS.md" ]]; then
            log_pass "HERMES.md is symlinked to EEA harness"
        else
            log_warn "HERMES.md is a symlink but not to EEA-HARNESS.md"
            log_info "  Target: ${target}"
        fi
    else
        if grep -q "EEA Global Harness" "${hermes_file}" 2>/dev/null; then
            log_pass "HERMES.md contains EEA harness reference section"
        else
            log_fail "HERMES.md exists but does not reference EEA harness"
            log_info "Fix: Run ./scripts/install.sh --agent hermes"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Pi
# ---------------------------------------------------------------------------
check_pi() {
    log_section "Pi Agent Configuration"

    local pi_file="${HOME}/.pi/agent/AGENTS.md"

    if [ ! -e "${pi_file}" ]; then
        log_warn "AGENTS.md not found at ${pi_file}"
        return
    fi

    if [ -L "${pi_file}" ]; then
        local target
        target=$(readlink "${pi_file}")
        if [[ "$target" == *"EEA-HARNESS.md" ]]; then
            log_pass "AGENTS.md is symlinked to EEA harness"
        else
            log_warn "AGENTS.md is a symlink but not to EEA-HARNESS.md"
            log_info "  Target: ${target}"
        fi
    else
        if grep -q "EEA Global Harness" "${pi_file}" 2>/dev/null; then
            log_pass "AGENTS.md contains EEA harness reference section"
        else
            log_fail "AGENTS.md exists but does not reference EEA harness"
            log_info "Fix: Run ./scripts/install.sh --agent pi"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Gemini
# ---------------------------------------------------------------------------
check_gemini() {
    log_section "Gemini Configuration"

    local gemini_file="${HOME}/.gemini/GEMINI.md"

    if [ ! -e "${gemini_file}" ]; then
        log_warn "GEMINI.md not found at ${gemini_file}"
        return
    fi

    if [ -L "${gemini_file}" ]; then
        local target
        target=$(readlink "${gemini_file}")
        if [[ "$target" == *"EEA-HARNESS.md" ]]; then
            log_pass "GEMINI.md is symlinked to EEA harness"
        else
            log_warn "GEMINI.md is a symlink but not to EEA-HARNESS.md"
            log_info "  Target: ${target}"
        fi
    else
        if grep -q "EEA Global Harness" "${gemini_file}" 2>/dev/null; then
            log_pass "GEMINI.md contains EEA harness reference section"
        else
            log_fail "GEMINI.md exists but does not reference EEA harness"
            log_info "Fix: Run ./scripts/install.sh --agent gemini"
        fi
    fi
}

# ---------------------------------------------------------------------------
# Skills
# ---------------------------------------------------------------------------
check_skills() {
    log_section "Skills Installation"

    if [ ! -d "${HARNESS_DIR}/skills" ]; then
        log_fail "Skills source directory missing: ${HARNESS_DIR}/skills"
        log_info "Skipping skills check until harness is installed"
        return
    fi

    local harness_skills=()
    for d in "${HARNESS_DIR}/skills"/*/; do
        [ -d "$d" ] && harness_skills+=("$(basename "$d")")
    done

    if [ ${#harness_skills[@]} -eq 0 ]; then
        log_warn "No skills found in harness source directory"
        return
    fi

    log_pass "Found ${#harness_skills[@]} skill(s) in harness"

    local agent_skill_dirs=(
        "${HOME}/.config/opencode/skills"
        "${HOME}/.claude/skills"
        "${HOME}/.agents/skills"
    )

    for agent_dir in "${agent_skill_dirs[@]}"; do
        if [ ! -d "${agent_dir}" ]; then
            log_info "Skill directory not found (agent may not be installed): ${agent_dir}"
            continue
        fi

        log_info "Checking skills in ${agent_dir}..."

        # Missing: harness skills not in agent dir
        for skill in "${harness_skills[@]}"; do
            if [ ! -d "${agent_dir}/${skill}" ]; then
                log_warn "Missing skill '${skill}' in ${agent_dir}"
                log_info "Fix: Run ./scripts/install.sh or:"
                log_info "  cp -r ${HARNESS_DIR}/skills/${skill} ${agent_dir}/"
            else
                if [ ! -f "${agent_dir}/${skill}/SKILL.md" ]; then
                    log_warn "Skill '${skill}' in ${agent_dir} is missing SKILL.md"
                fi
            fi
        done

        # Stale / orphaned: agent skills not in harness
        for d in "${agent_dir}"/*/; do
            [ -d "$d" ] || continue
            local skill_name
            skill_name=$(basename "$d")
            local found=false
            for hs in "${harness_skills[@]}"; do
                if [ "$hs" = "$skill_name" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                log_warn "Orphaned skill '${skill_name}' in ${agent_dir} (not in harness)"
                log_info "Fix: Remove manually if no longer needed: rm -rf ${agent_dir}/${skill_name}"
            fi
        done
    done
}

# ---------------------------------------------------------------------------
# Rules
# ---------------------------------------------------------------------------
check_rules() {
    log_section "Rules Installation"

    if [ ! -d "${HARNESS_DIR}/rules" ]; then
        log_fail "Rules source directory missing: ${HARNESS_DIR}/rules"
        log_info "Skipping rules check until harness is installed"
        return
    fi

    local harness_rules=()
    for f in "${HARNESS_DIR}/rules"/*.rules.md; do
        [ -f "$f" ] && harness_rules+=("$(basename "$f")")
    done

    if [ ${#harness_rules[@]} -eq 0 ]; then
        log_warn "No rules found in harness source directory"
        return
    fi

    log_pass "Found ${#harness_rules[@]} rule file(s) in harness"

    local agent_rule_dirs=(
        "${HOME}/.claude/rules"
        "${HOME}/.config/opencode/rules"
        "${HOME}/.hermes/rules"
        "${HOME}/.pi/agent/rules"
    )

    for agent_dir in "${agent_rule_dirs[@]}"; do
        if [ ! -d "${agent_dir}" ]; then
            log_info "Rules directory not found (agent may not be installed): ${agent_dir}"
            continue
        fi

        log_info "Checking rules in ${agent_dir}..."

        for rule in "${harness_rules[@]}"; do
            local rule_path="${agent_dir}/${rule}"
            if [ ! -e "${rule_path}" ]; then
                log_warn "Missing rule '${rule}' in ${agent_dir}"
                log_info "Fix: Run ./scripts/install.sh or:"
                log_info "  ln -sf ${HARNESS_DIR}/rules/${rule} ${rule_path}"
            elif [ -L "${rule_path}" ]; then
                if [ ! -e "${rule_path}" ]; then
                    log_fail "Broken symlink for '${rule}' in ${agent_dir}"
                    log_info "Fix: Remove broken symlink and re-run ./scripts/install.sh"
                else
                    log_pass "Rule '${rule}' linked in ${agent_dir}"
                fi
            else
                log_warn "Rule '${rule}' in ${agent_dir} is a regular file, not a symlink"
                log_info "Consider converting to symlink for automatic updates:"
                log_info "  rm ${rule_path} && ln -sf ${HARNESS_DIR}/rules/${rule} ${rule_path}"
            fi
        done
    done
}

# ---------------------------------------------------------------------------
# Repo Consistency (only when running from the repo)
# ---------------------------------------------------------------------------
check_repo_consistency() {
    if [ -z "${REPO_ROOT}" ]; then
        return
    fi

    log_section "Repository Consistency (from ${REPO_ROOT})"

    # catalog.yaml vs src/skills
    local catalog_skills=""
    if [ -f "${REPO_ROOT}/catalog.yaml" ]; then
        catalog_skills=$(awk '/^  - id:/{print $3}' "${REPO_ROOT}/catalog.yaml")
    fi

    if [ -n "$catalog_skills" ]; then
        local missing_src=0
        while IFS= read -r skill_id; do
            [ -z "$skill_id" ] && continue
            if [ ! -d "${REPO_ROOT}/src/skills/${skill_id}" ]; then
                log_warn "Catalog references skill '${skill_id}' but src/skills/${skill_id}/ does not exist"
                missing_src=$((missing_src + 1))
            fi
        done <<< "$catalog_skills"

        if [ $missing_src -eq 0 ]; then
            log_pass "All catalog skills have corresponding src/skills/ directories"
        fi
    else
        log_info "Could not parse catalog.yaml for skill IDs"
    fi

    # Built skills match source
    local built_skills=()
    for d in "${REPO_ROOT}/skills"/*/; do
        [ -d "$d" ] && built_skills+=("$(basename "$d")")
    done

    local src_skills=()
    for d in "${REPO_ROOT}/src/skills"/*/; do
        [ -d "$d" ] && src_skills+=("$(basename "$d")")
    done

    local missing_build=0
    for skill in "${src_skills[@]}"; do
        if [ ! -d "${REPO_ROOT}/skills/${skill}" ]; then
            log_warn "Source skill '${skill}' not built into skills/ directory"
            log_info "Fix: Run ./scripts/build.sh ${skill}"
            missing_build=$((missing_build + 1))
        fi
    done

    if [ $missing_build -eq 0 ] && [ ${#src_skills[@]} -gt 0 ]; then
        log_pass "All source skills are built"
    fi

    local stale_build=0
    for skill in "${built_skills[@]}"; do
        if [ ! -d "${REPO_ROOT}/src/skills/${skill}" ]; then
            log_warn "Built skill '${skill}' has no corresponding source in src/skills/"
            stale_build=$((stale_build + 1))
        fi
    done

    if [ $stale_build -eq 0 ] && [ ${#built_skills[@]} -gt 0 ]; then
        log_pass "No stale built skills"
    fi
}

# ---------------------------------------------------------------------------
# Remote Version Check
# ---------------------------------------------------------------------------
extract_version() {
    local file="$1"
    grep -m1 '^\*\*Version:\*\*' "$file" 2>/dev/null | sed -E 's/\*\*Version:\*\*[[:space:]]*//' | tr -d '\r'
}

check_remote_version() {
    log_section "Harness Version (Remote Check)"

    local remote_url="https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"
    local sources=()
    local versions=()

    # Build a list of all local harness files that agents actually read.
    # We check multiple paths because the harness can be wired in
    # different places (canonical install, dev repo, AGENTS.md, etc.)

    # 1. Canonical installed harness
    if [ -f "${HOME}/.eea/agent-harness/harness/EEA-HARNESS.md" ]; then
        sources+=("${HOME}/.eea/agent-harness/harness/EEA-HARNESS.md")
    fi

    # 2. Detected harness source (may be dev repo or local clone)
    if [ -f "${HARNESS_DIR}/harness/EEA-HARNESS.md" ]; then
        # Only add if different from canonical to avoid duplicates
        if [ "${HARNESS_DIR}/harness/EEA-HARNESS.md" != "${HOME}/.eea/agent-harness/harness/EEA-HARNESS.md" ]; then
            sources+=("${HARNESS_DIR}/harness/EEA-HARNESS.md")
        fi
    fi

    # 3. OpenCode global AGENTS.md (loaded in addition to / instead of harness URL)
    if [ -f "${HOME}/.config/opencode/AGENTS.md" ]; then
        sources+=("${HOME}/.config/opencode/AGENTS.md")
    fi

    # 4. Claude symlink target (used by Claude Code AND OpenCode compatibility mode)
    if [ -L "${HOME}/.claude/CLAUDE.md" ]; then
        local claude_target
        claude_target=$(readlink "${HOME}/.claude/CLAUDE.md")
        if [ -f "$claude_target" ]; then
            # Only add if not already in the list
            local already=false
            for s in "${sources[@]}"; do
                [ "$s" = "$claude_target" ] && already=true
            done
            if [ "$already" = false ]; then
                sources+=("$claude_target")
            fi
        fi
    fi

    # 5. Hermes / Pi / Gemini harness files
    for f in "${HOME}/.hermes/HERMES.md" "${HOME}/.pi/agent/AGENTS.md" "${HOME}/.gemini/GEMINI.md"; do
        if [ -f "$f" ]; then
            local already=false
            for s in "${sources[@]}"; do
                [ "$s" = "$f" ] && already=true
            done
            if [ "$already" = false ]; then
                sources+=("$f")
            fi
        fi
    done

    if [ ${#sources[@]} -eq 0 ]; then
        log_warn "Cannot check version: no local EEA-HARNESS.md or agent harness files found"
        return
    fi

    # Extract versions from all sources
    local min_version=""
    local min_source=""
    for src in "${sources[@]}"; do
        local ver
        ver=$(extract_version "$src")
        if [ -n "$ver" ]; then
            log_info "  ${ver}  —  $(realpath --relative-to="${HOME}" "$src" 2>/dev/null || echo "$src")"
            versions+=("$ver")
            if [ -z "$min_version" ] || [ "$ver" \< "$min_version" ]; then
                min_version="$ver"
                min_source="$src"
            fi
        else
            log_warn "  (no Version line) — $(realpath --relative-to="${HOME}" "$src" 2>/dev/null || echo "$src")"
        fi
    done

    if [ -z "$min_version" ]; then
        log_warn "Could not parse Version line from any local harness file"
        return
    fi

    # Try to fetch remote version (gracefully skip if offline)
    local remote_content
    remote_content=$(curl -fsSL --connect-timeout 5 --max-time 10 "$remote_url" 2>/dev/null || true)

    if [ -z "$remote_content" ]; then
        log_warn "Could not reach GitHub to verify latest version (offline or timeout)"
        log_info "Fix: Ensure internet connectivity, or run verification later"
        return
    fi

    local remote_version
    remote_version=$(echo "$remote_content" | grep -m1 '^\*\*Version:\*\*' | sed -E 's/\*\*Version:\*\*[[:space:]]*//' | tr -d '\r')

    if [ -z "$remote_version" ]; then
        log_warn "Could not parse Version line from remote EEA-HARNESS.md"
        return
    fi

    log_info "Remote version: ${remote_version}"

    if [ "$min_version" = "$remote_version" ]; then
        log_pass "Local harness matches latest remote version (${min_version})"
    elif [ "$min_version" \< "$remote_version" ]; then
        log_warn "Stale harness detected: ${min_version} < ${remote_version}"
        log_info "  Stale source: $(realpath --relative-to="${HOME}" "$min_source" 2>/dev/null || echo "$min_source")"

        # Context-aware fix message
        local min_source_abs
        min_source_abs=$(realpath "$min_source" 2>/dev/null || echo "$min_source")
        local harness_abs
        harness_abs=$(realpath "${HARNESS_DIR}" 2>/dev/null || echo "${HARNESS_DIR}")

        if [[ "$min_source_abs" == "$harness_abs"/* ]]; then
            # Stale file is inside the harness repo → git pull
            log_info "Fix: cd ${HARNESS_DIR} && git pull origin main"
        elif [ "$min_source" = "${HOME}/.config/opencode/AGENTS.md" ]; then
            # Stale AGENTS.md → recommend opencode.json instead
            log_info "Fix: This file is not part of the harness repo and will go stale."
            log_info "      Remove the EEA harness content from this file."
            log_info "      Add the EEA harness URL to ~/.config/opencode/opencode.json instead:"
            log_info "        \"${EEA_HARNESS_URL}\""
            log_info "      AGENTS.md is for personal global instructions; opencode.json is for org-wide."
        else
            # Generic stale standalone file
            log_info "Fix: This file is not part of the harness repo and will go stale."
            log_info "      Consider referencing the remote harness URL instead of copying content."
            log_info "      Or copy the latest content from:"
            log_info "        ${HARNESS_DIR}/harness/EEA-HARNESS.md"
        fi
    else
        log_warn "Local harness is newer than remote (${min_version} > ${remote_version}) — local modifications?"
    fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
print_summary() {
    echo ""
    echo "========================================"
    echo "  Verification Summary"
    echo "========================================"
    echo -e "  Passed:   ${GREEN}✓${NC}"
    echo -e "  Warnings: ${YELLOW}${WARN_COUNT}${NC}"
    echo -e "  Failures: ${RED}${FAIL_COUNT}${NC}"
    echo ""

    if [ $FAIL_COUNT -eq 0 ] && [ $WARN_COUNT -eq 0 ]; then
        echo -e "  ${GREEN}All checks passed!${NC}"
    elif [ $FAIL_COUNT -eq 0 ]; then
        echo -e "  ${YELLOW}All critical checks passed, but warnings were found.${NC}"
    else
        echo -e "  ${RED}Some checks failed. Review the output above and apply fixes.${NC}"
        echo "  Common fix: ./scripts/install.sh [--force] [--agent <name>]"
    fi
    echo "========================================"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    echo "========================================"
    echo "  EEA AI Harness Health Check"
    echo "========================================"

    check_harness_repo

    local detected_agents
    detected_agents=$(detect_agents)

    if [ -z "${detected_agents}" ]; then
        log_info "No agents detected on this system"
    else
        log_info "Detected agents: ${detected_agents}"

        for agent in ${detected_agents}; do
            case "${agent}" in
                opencode) check_opencode ;;
                claude)   check_claude ;;
                hermes)   check_hermes ;;
                pi)       check_pi ;;
                gemini)   check_gemini ;;
            esac
        done
    fi

    # Additional OpenCode-specific check (runs regardless of detection)
    check_opencode_agents_md

    check_skills
    check_rules
    check_repo_consistency
    check_remote_version
    print_summary

    if [ $FAIL_COUNT -gt 0 ]; then
        exit 1
    elif [ $WARN_COUNT -gt 0 ]; then
        exit 2
    else
        exit 0
    fi
}

main "$@"
