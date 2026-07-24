#!/bin/bash

# NetRaven - Ethical Hacking Tool for Kali Linux
# Main launcher script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

BANNER_FILE="src/banner.txt"
TARGET_URL=""
TARGET_DOMAIN=""

clear

if [ -f "$BANNER_FILE" ]; then
    cat "$BANNER_FILE"
    echo
fi

echo -e "${CYAN}[*] NetRaven v1.0 - Ethical Hacking Framework${NC}"
echo -e "${RED}[!] For educational and authorized testing only${NC}"
echo

read -p "Enter target URL (e.g., http://example.com): " TARGET_URL

if [ -z "$TARGET_URL" ]; then
    echo -e "${RED}[!] No target provided. Exiting.${NC}"
    exit 1
fi

TARGET_DOMAIN=$(echo "$TARGET_URL" | awk -F/ '{print $3}')

mkdir -p results/"$TARGET_DOMAIN"
RESULTS_DIR="results/$TARGET_DOMAIN"

echo
echo -e "${GREEN}[+] Target locked: $TARGET_URL${NC}"
echo -e "${GREEN}[+] Results directory: $RESULTS_DIR${NC}"
echo

# Source modules
source src/core/config.sh
source src/core/utils.sh

# TUI Loop
while true; do
    echo
    echo -e "${PURPLE}┌──────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}user@netraven${NC}:${YELLOW}~${NC}${PURPLE}                      │${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────┘${NC}"
    echo
    echo -e "${CYAN}[1]${NC} Reconnaissance & Information Gathering"
    echo -e "${CYAN}[2]${NC} Vulnerability Scanning"
    echo -e "${CYAN}[3]${NC} Attack Modules"
    echo -e "${CYAN}[4]${NC} Monitoring & Analysis"
    echo -e "${CYAN}[5]${NC} Network Utilities"
    echo -e "${CYAN}[6]${NC} Reports"
    echo -e "${CYAN}[0]${NC} Exit"
    echo
    read -p "Select module: " choice

    case $choice in
        1) source src/modules/recon_menu.sh ;;
        2) source src/modules/vuln_menu.sh ;;
        3) source src/modules/attack_menu.sh ;;
        4) source src/modules/monitor_menu.sh ;;
        5) source src/modules/network_menu.sh ;;
        6) source src/modules/reports.sh ;;
        0)
            echo -e "${GREEN}[+] Exiting NetRaven...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option${NC}"
            ;;
    esac
done
