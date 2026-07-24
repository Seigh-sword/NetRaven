#!/bin/bash

# NetRaven Mishvious Menu - Utilities Submenu
# Engine, Tunnels, Plugins, Sites, TTS, Docs, License, Terms, Env

source src/core/utils.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

view_docs() {
    clear
    echo -e "${CYAN}=== Documentation ===${NC}"
    echo
    if [ -d "$PROJECT_ROOT/docs" ]; then
        local i=1
        local files=()
        for f in "$PROJECT_ROOT/docs"/*.md; do
            if [ -f "$f" ]; then
                files+=("$f")
                echo -e "${CYAN}[$i]${NC} $(basename "$f")"
                i=$((i + 1))
            fi
        done
        if [ ${#files[@]} -eq 0 ]; then
            echo -e "${YELLOW}No documentation files found${NC}"
            read -p "Press Enter to return..."
            return
        fi
        echo
        read -p "Select file to view (0 to back): " doc_choice
        if [ "$doc_choice" -ge 1 ] && [ "$doc_choice" -lt "$i" ]; then
            local idx=$((doc_choice - 1))
            if [ -f "${files[$idx]}" ]; then
                less "${files[$idx]}"
            fi
        fi
    else
        echo -e "${YELLOW}No docs/ directory found${NC}"
        read -p "Press Enter to return..."
    fi
}

view_license() {
    clear
    echo -e "${CYAN}=== License (Apache 2.0) ===${NC}"
    echo
    if [ -f "$PROJECT_ROOT/.github/LICENSE" ]; then
        less "$PROJECT_ROOT/.github/LICENSE"
    else
        echo -e "${YELLOW}License file not found${NC}"
        read -p "Press Enter to return..."
    fi
}

view_terms() {
    clear
    echo -e "${CYAN}=== Terms of Use ===${NC}"
    echo
    if [ -f "$PROJECT_ROOT/.github/terms.txt" ]; then
        less "$PROJECT_ROOT/.github/terms.txt"
    else
        echo -e "${YELLOW}Terms file not found${NC}"
        read -p "Press Enter to return..."
    fi
}

mishvious_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}          ${CYAN}Mishvious Modules${NC}              ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────┤${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  C++ Engine                        ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  Cloudflare Tunnels                ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  Plugin Manager                    ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[4]${NC}  Vulnerable Site Generator          ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[5]${NC}  Text-to-Speech (TTS)              ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[6]${NC}  Documentation Viewer              ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[7]${NC}  License                           ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[8]${NC}  Terms of Use                      ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[9]${NC}  Environment Information            ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Back to Main Menu                 ${PURPLE}│${NC}"
        echo -e "${PURPLE}└──────────────────────────────────────────┘${NC}"
        echo
        read -p "Select module: " opt

        case $opt in
            1) source src/engine/engine_menu.sh ;;
            2) source src/tunnels/tunnel_manager.sh ;;
            3) source src/core/plugin_loader.sh ;;
            4) source src/sites/site_generator.sh ;;
            5) source src/misc/tts.sh ;;
            6) view_docs ;;
            7) view_license ;;
            8) view_terms ;;
            9)
                source src/core/config.sh
                show_env_info
                ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
    done
}

mishvious_menu
