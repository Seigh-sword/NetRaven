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

update_netraven() {
    clear
    echo -e "${CYAN}=== Update NetRaven ===${NC}"
    echo
    
    if [ ! -d "$PROJECT_ROOT/.git" ]; then
        echo -e "${RED}[!] Not a git repository. Cannot update.${NC}"
        echo -e "${YELLOW}[*] Download latest from GitHub manually${NC}"
        read -p "Press Enter to return..."
        return
    fi
    
    cd "$PROJECT_ROOT"
    
    echo -e "${YELLOW}[*] Checking for updates...${NC}"
    git fetch origin 2>/dev/null
    
    LOCAL=$(git rev-parse @ 2>/dev/null)
    REMOTE=$(git rev-parse @{u} 2>/dev/null)
    
    if [ "$LOCAL" = "$REMOTE" ]; then
        echo -e "${GREEN}[+] NetRaven is already up to date!${NC}"
        read -p "Press Enter to return..."
        return
    fi
    
    echo -e "${CYAN}[*] Updates available!${NC}"
    echo -e "${YELLOW}[*] Changes:${NC}"
    git log --oneline @{u}..HEAD 2>/dev/null || git log --oneline -5
    
    # Detect current branch
    BRANCH=$(git rev-parse --abbrev-ref @ 2>/dev/null || echo "main")
    
    read -p "Update now? (yes/no): " confirm
    if [ "$confirm" = "yes" ]; then
        echo -e "${CYAN}[*] Updating NetRaven (branch: $BRANCH)...${NC}"
        git pull origin "$BRANCH" 2>&1 | tail -n 10
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[+] Update successful!${NC}"
            echo -e "${YELLOW}[*] NetRaven will now close. Restart to auto-build.${NC}"
            read -p "Press Enter to exit..."
            exit 0
        else
            echo -e "${RED}[-] Update failed${NC}"
        fi
    fi
    
    read -p "Press Enter to return..."
}

mishvious_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}          ${CYAN}Mishvious Modules${NC}                       ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────┤${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  C++ Engine                                ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  Cloudflare Tunnels                        ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  Plugins                                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[4]${NC}  Vulnerable Site Generator                  ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[5]${NC}  Text-to-Speech (TTS)                      ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[6]${NC}  Documentation Viewer                      ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[7]${NC}  License                                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[8]${NC}  Terms of Use                              ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[9]${NC}  Environment Information                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[10]${NC} Update NetRaven                            ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Back to Main Menu                         ${PURPLE}│${NC}"
        echo -e "${PURPLE}└──────────────────────────────────────────────────┘${NC}"
        echo
        read -p "Select module: " opt

        case $opt in
            1) source src/engine/engine_menu.sh ;;
            2) source src/tunnels/tunnel_manager.sh ;;
            3) source src/core/plugin_packager.sh ;;
            4) source src/sites/site_generator.sh ;;
            5) source src/misc/tts.sh ;;
            6) view_docs ;;
            7) view_license ;;
            8) view_terms ;;
            9)
                source src/core/config.sh
                show_env_info
                ;;
            10) update_netraven ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
    done
}

mishvious_menu
