#!/bin/bash

# NetRaven Hack Menu - Attack Modules Submenu
# Thin wrapper that sources existing module scripts

source src/core/utils.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

hack_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}          ${CYAN}Hack Modules${NC}                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────┤${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  Reconnaissance & Info Gathering     ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  Vulnerability Scanning             ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  Attack Modules                     ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[4]${NC}  Monitoring & Analysis              ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[5]${NC}  Network Utilities                  ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[6]${NC}  Reports                            ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[7]${NC}  Exploitation                       ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Back to Main Menu                  ${PURPLE}│${NC}"
        echo -e "${PURPLE}└──────────────────────────────────────────┘${NC}"
        echo
        read -p "Select module: " opt

        case $opt in
            1) source src/modules/recon_menu.sh ;;
            2) source src/modules/vuln_menu.sh ;;
            3) source src/modules/attack_menu.sh ;;
            4) source src/modules/monitor_menu.sh ;;
            5) source src/modules/network_menu.sh ;;
            6) source src/modules/reports.sh ;;
            7) source src/modules/exploit_menu.sh ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
    done
}

hack_menu
