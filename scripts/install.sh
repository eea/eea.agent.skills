#!/usr/bin/env bash
set -euo pipefail

# EEA AI Harness Installation Script
# Usage: ./scripts/install.sh [--global] [--agent <name>] [--force] [--no-backup]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HARNESS_DIR="${HOME}/.eea/agent-harness"
FORCE=false
GLOBAL=false
LOCAL=false
NO_BACKUP=false
SPECIFIC_AGENT=""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
    echo "EEA AI Harness Installer"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --global        Install globally for all projects (default)"
    echo "  --local         Use current repo instead of cloning from GitHub"
    echo "  --agent <name>  Install only for specific agent (opencode, claude, hermes, gemini, pi)"
    echo "  --force         Overwrite existing installations"
    echo "  --no-backup     Skip creating backups before modifying existing files"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Full install for all detected agents"
    echo "  $0 --local                  # Install from local repo (dev mode)"
    echo "  $0 --agent opencode         # Install only for OpenCode"
    echo "  $0 --force                  # Reinstall everything"
    echo "  $0 --no-backup              # Skip backups (not recommended)"
}

log_info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --global)
            GLOBAL=true
            shift
            ;;
        --local)
            LOCAL=true
            shift
            ;;
        --agent)
            SPECIFIC_AGENT="$2"
            shift 2
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --no-backup)
            NO_BACKUP=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Backup helper: creates a timestamped copy of any file or directory
backup_file() {
    local file="$1"
    if [ -e "$file" ]; then
        local backup
        backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
        cp -a "$file" "$backup"
        log_success "Backed up: ${file} → ${backup}"
    fi
}

# Check if a symlink already points to the EEA harness
is_linked_to_eea() {
    local file="$1"
    if [ -L "$file" ]; then
        local target
        target=$(readlink "$file")
        [[ "$target" == *"EEA-HARNESS.md" ]] && return 0
    fi
    return 1
}

# Merge EEA harness URL into an existing opencode.json or opencode.jsonc
merge_opencode_config() {
    local config_file="$1"
    local eea_url="$2"

    if ! command -v python3 &> /dev/null; then
        log_warn "python3 not found. Cannot auto-merge opencode config."
        log_info "Please manually add this URL to your instructions array:"
        echo "  ${eea_url}"
        return
    fi

    python3 - "$config_file" "$eea_url" << 'PYEOF'
import sys, json

config_file = sys.argv[1]
ea_url = sys.argv[2]

def strip_jsonc_comments(text):
    result = []
    in_string = False
    escape = False
    i = 0
    while i < len(text):
        char = text[i]
        if escape:
            result.append(char)
            escape = False
            i += 1
            continue
        if char == '\\' and in_string:
            result.append(char)
            escape = True
            i += 1
            continue
        if char == '"' and not in_string:
            in_string = True
            result.append(char)
            i += 1
            continue
        if char == '"' and in_string:
            in_string = False
            result.append(char)
            i += 1
            continue
        if not in_string:
            if char == '/' and i + 1 < len(text) and text[i+1] == '/':
                while i < len(text) and text[i] != '\n':
                    i += 1
                continue
            if char == '/' and i + 1 < len(text) and text[i+1] == '*':
                i += 2
                while i < len(text) - 1 and not (text[i] == '*' and text[i+1] == '/'):
                    i += 1
                i += 2
                continue
        result.append(char)
        i += 1
    return ''.join(result)

def remove_trailing_commas(text):
    import re
    return re.sub(r',(\s*[\]\}])', r'\1', text)

with open(config_file, 'r') as f:
    content = f.read()

try:
    data = json.loads(content)
except json.JSONDecodeError:
    content = strip_jsonc_comments(content)
    content = remove_trailing_commas(content)
    data = json.loads(content)

if 'instructions' not in data:
    data['instructions'] = []

if ea_url not in data['instructions']:
    data['instructions'].append(ea_url)

with open(config_file, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
PYEOF
}

# Append an EEA harness reference section to an existing markdown file
append_eea_reference_to_markdown() {
    local md_file="$1"

    cat >> "$md_file" << 'EOF'

---

## EEA Global Harness

This session is also governed by the EEA AI Harness for org-wide rules, skills, and mandatory actions.

**Harness file:** ~/.eea/agent-harness/harness/EEA-HARNESS.md
EOF
}

# Clone or update harness repo
install_harness_repo() {
    if [ "${LOCAL}" = true ]; then
        HARNESS_DIR="${REPO_ROOT}"
        log_info "Local mode: using ${HARNESS_DIR}"
        return
    fi

    log_info "Installing EEA AI Harness..."

    if [ -d "${HARNESS_DIR}/.git" ]; then
        if [ "${FORCE}" = true ]; then
            log_warn "Removing existing harness directory..."
            rm -rf "${HARNESS_DIR}"
        else
            log_info "Harness already installed at ${HARNESS_DIR}"
            log_info "Updating..."
            cd "${HARNESS_DIR}" && git pull origin main
            log_success "Harness updated"
            return
        fi
    fi

    mkdir -p "$(dirname "${HARNESS_DIR}")"
    git clone https://github.com/eea/eea.agent.skills.git "${HARNESS_DIR}"
    log_success "Harness cloned to ${HARNESS_DIR}"
}

# Install for OpenCode
install_opencode() {
    log_info "Setting up OpenCode..."

    local config_dir="${HOME}/.config/opencode"
    local config_json="${config_dir}/opencode.json"
    local config_jsonc="${config_dir}/opencode.jsonc"
    local eea_url="https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"

    mkdir -p "${config_dir}"

    # Determine which config file to target
    local target_config=""
    if [ -f "${config_jsonc}" ] && [ -f "${config_json}" ]; then
        log_warn "Both opencode.json and opencode.jsonc exist. Merging into opencode.jsonc (remove one to avoid confusion)"
        target_config="${config_jsonc}"
    elif [ -f "${config_jsonc}" ]; then
        target_config="${config_jsonc}"
    elif [ -f "${config_json}" ]; then
        target_config="${config_json}"
    fi

    if [ -n "${target_config}" ]; then
        if [ "${NO_BACKUP}" != true ]; then
            backup_file "${target_config}"
        fi

        merge_opencode_config "${target_config}" "${eea_url}"
        log_success "Merged EEA harness into ${target_config}"

        if [[ "${target_config}" == *.jsonc ]]; then
            log_warn "Comments in .jsonc were stripped during merge. Original preserved in backup."
        fi

        log_info "Your original config is backed up (see above)"
        return
    fi

    # No existing config: copy template
    cp "${HARNESS_DIR}/docs/opencode-examples/global-opencode.json" "${config_json}"
    log_success "OpenCode configured at ${config_json}"
}

# Install for Claude Code
install_claude() {
    log_info "Setting up Claude Code..."

    local claude_dir="${HOME}/.claude"
    local claude_file="${claude_dir}/CLAUDE.md"

    mkdir -p "${claude_dir}"

    if [ -L "${claude_file}" ] || [ -f "${claude_file}" ]; then
        # Already linked to EEA harness? Skip.
        if is_linked_to_eea "${claude_file}"; then
            log_info "Claude Code already linked to EEA harness"
            return
        fi

        if [ "${NO_BACKUP}" != true ]; then
            backup_file "${claude_file}"
        fi

        # If it's a symlink to something else, convert to a real file
        if [ -L "${claude_file}" ]; then
            local real_file
            real_file=$(readlink -f "${claude_file}")
            rm -f "${claude_file}"
            cp "${real_file}" "${claude_file}"
        fi

        append_eea_reference_to_markdown "${claude_file}"
        log_success "Appended EEA harness reference to ${claude_file}"
        log_info "Your original config is backed up (see above)"
        return
    fi

    ln -sf "${HARNESS_DIR}/harness/EEA-HARNESS.md" "${claude_file}"
    log_success "Claude Code configured at ${claude_file}"
}

# Install for Hermes
install_hermes() {
    log_info "Setting up Hermes Agent..."

    local hermes_dir="${HOME}/.hermes"
    local hermes_file="${hermes_dir}/HERMES.md"

    mkdir -p "${hermes_dir}"

    if [ -L "${hermes_file}" ] || [ -f "${hermes_file}" ]; then
        if is_linked_to_eea "${hermes_file}"; then
            log_info "Hermes already linked to EEA harness"
            return
        fi

        if [ "${NO_BACKUP}" != true ]; then
            backup_file "${hermes_file}"
        fi

        if [ -L "${hermes_file}" ]; then
            local real_file
            real_file=$(readlink -f "${hermes_file}")
            rm -f "${hermes_file}"
            cp "${real_file}" "${hermes_file}"
        fi

        append_eea_reference_to_markdown "${hermes_file}"
        log_success "Appended EEA harness reference to ${hermes_file}"
        log_info "Your original config is backed up (see above)"
        return
    fi

    ln -sf "${HARNESS_DIR}/harness/EEA-HARNESS.md" "${hermes_file}"
    log_success "Hermes configured at ${hermes_file}"
}

# Install for Pi
install_pi() {
    log_info "Setting up Pi Agent..."

    local pi_dir="${HOME}/.pi/agent"
    local pi_file="${pi_dir}/AGENTS.md"

    mkdir -p "${pi_dir}"

    if [ -L "${pi_file}" ] || [ -f "${pi_file}" ]; then
        if is_linked_to_eea "${pi_file}"; then
            log_info "Pi already linked to EEA harness"
            return
        fi

        if [ "${NO_BACKUP}" != true ]; then
            backup_file "${pi_file}"
        fi

        if [ -L "${pi_file}" ]; then
            local real_file
            real_file=$(readlink -f "${pi_file}")
            rm -f "${pi_file}"
            cp "${real_file}" "${pi_file}"
        fi

        append_eea_reference_to_markdown "${pi_file}"
        log_success "Appended EEA harness reference to ${pi_file}"
        log_info "Your original config is backed up (see above)"
        return
    fi

    ln -sf "${HARNESS_DIR}/harness/EEA-HARNESS.md" "${pi_file}"
    log_success "Pi configured at ${pi_file}"
}

# Install for Gemini
install_gemini() {
    log_info "Setting up Gemini..."

    local gemini_dir="${HOME}/.gemini"
    local gemini_file="${gemini_dir}/GEMINI.md"

    mkdir -p "${gemini_dir}"

    if [ -L "${gemini_file}" ] || [ -f "${gemini_file}" ]; then
        if is_linked_to_eea "${gemini_file}"; then
            log_info "Gemini already linked to EEA harness"
            return
        fi

        if [ "${NO_BACKUP}" != true ]; then
            backup_file "${gemini_file}"
        fi

        if [ -L "${gemini_file}" ]; then
            local real_file
            real_file=$(readlink -f "${gemini_file}")
            rm -f "${gemini_file}"
            cp "${real_file}" "${gemini_file}"
        fi

        append_eea_reference_to_markdown "${gemini_file}"
        log_success "Appended EEA harness reference to ${gemini_file}"
        log_info "Your original config is backed up (see above)"
        return
    fi

    ln -sf "${HARNESS_DIR}/harness/EEA-HARNESS.md" "${gemini_file}"
    log_success "Gemini configured at ${gemini_file}"
}

# Install skills
install_skills() {
    log_info "Installing EEA skills..."

    local opencode_skills_dir="${HOME}/.config/opencode/skills"
    local claude_skills_dir="${HOME}/.claude/skills"
    local agents_skills_dir="${HOME}/.agents/skills"

    # Install to OpenCode skills directory
    mkdir -p "${opencode_skills_dir}"
    for skill_dir in "${HARNESS_DIR}/skills"/*; do
        if [ -d "${skill_dir}" ]; then
            local skill_name
            skill_name="$(basename "${skill_dir}")"
            local target_dir="${opencode_skills_dir}/${skill_name}"

            if [ -d "${target_dir}" ]; then
                if [ "${FORCE}" != true ]; then
                    log_warn "Skill ${skill_name} already exists, skipping (use --force to overwrite)"
                    continue
                fi
                if [ "${NO_BACKUP}" != true ]; then
                    backup_file "${target_dir}"
                fi
                rm -rf "${target_dir}"
            fi

            cp -r "${skill_dir}" "${target_dir}"
            log_success "Installed skill: ${skill_name} → ${target_dir}"
        fi
    done

    # Install to Claude skills directory
    mkdir -p "${claude_skills_dir}"
    for skill_dir in "${HARNESS_DIR}/skills"/*; do
        if [ -d "${skill_dir}" ]; then
            local skill_name
            skill_name="$(basename "${skill_dir}")"
            local target_dir="${claude_skills_dir}/${skill_name}"

            if [ -d "${target_dir}" ]; then
                if [ "${FORCE}" != true ]; then
                    continue
                fi
                if [ "${NO_BACKUP}" != true ]; then
                    backup_file "${target_dir}"
                fi
                rm -rf "${target_dir}"
            fi

            cp -r "${skill_dir}" "${target_dir}"
            log_success "Installed skill: ${skill_name} → ${target_dir}"
        fi
    done

    # Install to .agents skills directory
    mkdir -p "${agents_skills_dir}"
    for skill_dir in "${HARNESS_DIR}/skills"/*; do
        if [ -d "${skill_dir}" ]; then
            local skill_name
            skill_name="$(basename "${skill_dir}")"
            local target_dir="${agents_skills_dir}/${skill_name}"

            if [ -d "${target_dir}" ]; then
                if [ "${FORCE}" != true ]; then
                    continue
                fi
                if [ "${NO_BACKUP}" != true ]; then
                    backup_file "${target_dir}"
                fi
                rm -rf "${target_dir}"
            fi

            cp -r "${skill_dir}" "${target_dir}"
            log_success "Installed skill: ${skill_name} → ${target_dir}"
        fi
    done
}

# Helper: symlink rules to a target directory
link_rules_to_dir() {
    local target_dir="$1"
    mkdir -p "${target_dir}"

    local found=false
    for rule_file in "${HARNESS_DIR}/rules"/*.rules.md; do
        if [ -f "${rule_file}" ]; then
            found=true
            local rule_name
            rule_name="$(basename "${rule_file}")"
            ln -sf "${rule_file}" "${target_dir}/${rule_name}"
            log_success "Linked rule: ${rule_name} → ${target_dir}"
        fi
    done

    if [ "${found}" = false ]; then
        log_warn "No .rules.md files found in ${HARNESS_DIR}/rules/"
    fi
}

# Install rules
install_rules() {
    log_info "Installing EEA rules..."

    link_rules_to_dir "${HOME}/.claude/rules"
    link_rules_to_dir "${HOME}/.config/opencode/rules"
    link_rules_to_dir "${HOME}/.hermes/rules"
    link_rules_to_dir "${HOME}/.pi/agent/rules"
}

# Detect installed agents
detect_agents() {
    local agents=()

    if [ -d "${HOME}/.config/opencode" ] || command -v opencode &> /dev/null; then
        agents+=("opencode")
    fi

    if [ -d "${HOME}/.claude" ] || command -v claude &> /dev/null; then
        agents+=("claude")
    fi

    if [ -d "${HOME}/.hermes" ] || command -v hermes &> /dev/null; then
        agents+=("hermes")
    fi

    if [ -d "${HOME}/.pi/agent" ] || command -v pi &> /dev/null; then
        agents+=("pi")
    fi

    if [ -d "${HOME}/.gemini" ] || command -v gemini &> /dev/null; then
        agents+=("gemini")
    fi

    echo "${agents[@]}"
}

# Main installation
main() {
    echo "========================================"
    echo "  EEA AI Harness Installer"
    echo "========================================"
    echo ""

    install_harness_repo

    echo ""

    if [ -n "${SPECIFIC_AGENT}" ]; then
        case "${SPECIFIC_AGENT}" in
            opencode)
                install_opencode
                ;;
            claude)
                install_claude
                ;;
            hermes)
                install_hermes
                ;;
            gemini)
                install_gemini
                ;;
            pi)
                install_pi
                ;;
            *)
                log_error "Unknown agent: ${SPECIFIC_AGENT}"
                exit 1
                ;;
        esac
    else
        # Auto-detect and install for all found agents
        local detected_agents
        detected_agents=$(detect_agents)

        if [ -z "${detected_agents}" ]; then
            log_warn "No agents detected. Installing OpenCode config as default."
            install_opencode
        else
            log_info "Detected agents: ${detected_agents}"
            for agent in ${detected_agents}; do
                case "${agent}" in
                    opencode)
                        install_opencode
                        ;;
                    claude)
                        install_claude
                        ;;
                    hermes)
                        install_hermes
                        ;;
                    pi)
                        install_pi
                        ;;
                    gemini)
                        install_gemini
                        ;;
                esac
            done
        fi
    fi

    echo ""
    install_skills

    echo ""
    install_rules

    echo ""
    echo "========================================"
    log_success "EEA AI Harness installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Start your agent in an EEA project"
    echo "  2. Ask: 'What are the EEA global prohibitions?'"
    echo "  3. Create project-local AGENTS.md for your repos"
    echo ""
    echo "Documentation:"
    echo "  - Bootstrap guide: ${HARNESS_DIR}/docs/BOOTSTRAP.md"
    echo "  - Agent profiles: ${HARNESS_DIR}/agents/"
    echo "========================================"
}

main "$@"
