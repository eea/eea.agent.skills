#!/usr/bin/env bash
set -euo pipefail

# EEA AI Harness Installation Script
# Usage: ./scripts/install.sh [--global] [--agent <name>]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
HARNESS_DIR="${HOME}/.eea/agent-harness"
FORCE=false
GLOBAL=false
LOCAL=false
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
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          # Full install for all detected agents"
    echo "  $0 --local                  # Install from local repo (dev mode)"
    echo "  $0 --agent opencode         # Install only for OpenCode"
    echo "  $0 --force                  # Reinstall everything"
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
    local config_file="${config_dir}/opencode.json"

    mkdir -p "${config_dir}"

    if [ -f "${config_file}" ] && [ "${FORCE}" != true ]; then
        log_warn "OpenCode config already exists at ${config_file}"
        log_info "Add this to your opencode.json instructions:"
        echo '  "https://raw.githubusercontent.com/eea/eea.agent.skills/main/harness/EEA-HARNESS.md"'
        return
    fi

    cp "${HARNESS_DIR}/docs/opencode-examples/global-opencode.json" "${config_file}"
    log_success "OpenCode configured at ${config_file}"
}

# Install for Claude Code
install_claude() {
    log_info "Setting up Claude Code..."

    local claude_dir="${HOME}/.claude"
    local claude_file="${claude_dir}/CLAUDE.md"

    mkdir -p "${claude_dir}"

    if [ -L "${claude_file}" ] || [ -f "${claude_file}" ]; then
        if [ "${FORCE}" = true ]; then
            rm -f "${claude_file}"
        else
            log_warn "Claude config already exists at ${claude_file}"
            return
        fi
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
        if [ "${FORCE}" = true ]; then
            rm -f "${hermes_file}"
        else
            log_warn "Hermes config already exists at ${hermes_file}"
            return
        fi
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
        if [ "${FORCE}" = true ]; then
            rm -f "${pi_file}"
        else
            log_warn "Pi config already exists at ${pi_file}"
            return
        fi
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
        if [ "${FORCE}" = true ]; then
            rm -f "${gemini_file}"
        else
            log_warn "Gemini config already exists at ${gemini_file}"
            return
        fi
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
            local skill_name="$(basename "${skill_dir}")"
            local target_dir="${opencode_skills_dir}/${skill_name}"

            if [ -d "${target_dir}" ] && [ "${FORCE}" != true ]; then
                log_warn "Skill ${skill_name} already exists, skipping (use --force to overwrite)"
                continue
            fi

            rm -rf "${target_dir}"
            cp -r "${skill_dir}" "${target_dir}"
            log_success "Installed skill: ${skill_name} → ${target_dir}"
        fi
    done

    # Install to Claude skills directory
    mkdir -p "${claude_skills_dir}"
    for skill_dir in "${HARNESS_DIR}/skills"/*; do
        if [ -d "${skill_dir}" ]; then
            local skill_name="$(basename "${skill_dir}")"
            local target_dir="${claude_skills_dir}/${skill_name}"

            if [ -d "${target_dir}" ] && [ "${FORCE}" != true ]; then
                continue
            fi

            rm -rf "${target_dir}"
            cp -r "${skill_dir}" "${target_dir}"
            log_success "Installed skill: ${skill_name} → ${target_dir}"
        fi
    done

    # Install to .agents skills directory
    mkdir -p "${agents_skills_dir}"
    for skill_dir in "${HARNESS_DIR}/skills"/*; do
        if [ -d "${skill_dir}" ]; then
            local skill_name="$(basename "${skill_dir}")"
            local target_dir="${agents_skills_dir}/${skill_name}"

            if [ -d "${target_dir}" ] && [ "${FORCE}" != true ]; then
                continue
            fi

            rm -rf "${target_dir}"
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
