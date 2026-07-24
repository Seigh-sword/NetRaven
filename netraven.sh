#!/bin/bash

# NetRaven - Ethical Hacking Tool for Kali Linux
# Main launcher script - 3-Option Menu

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
RESULTS_DIR=""

# ==================== ANIMATION FUNCTIONS ====================

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr="|/-\\"
    while [ "$(ps a | awk '{print $1}' | grep -w "$pid")" ]; do
        local temp="${spinstr#?}"
        printf " [%c]  " "$spinstr"
        local spinstr="$temp${spinstr%$temp}"
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "${CYAN}]${NC} ${percentage}%%"
}

show_banner() {
    clear
    if [ -f "$BANNER_FILE" ]; then
        cat "$BANNER_FILE"
        echo
    fi
    echo -e "${CYAN}[*] NetRaven v1.0 - Ethical Hacking Framework${NC}"
    echo -e "${RED}[!] For educational and authorized testing only${NC}"
    echo
}

show_status_bar() {
    echo -e "${PURPLE}──────────────────────────────────────────────────${NC}"
    if [ -n "$TARGET_URL" ]; then
        echo -e "${CYAN}Target:${NC} $TARGET_URL"
    else
        echo -e "${CYAN}Target:${NC} ${YELLOW}Not set${NC}"
    fi
    if [ -f "src/engine/netraven_engine" ]; then
        echo -e "${CYAN}Engine:${NC} ${GREEN}C++${NC}"
    else
        echo -e "${CYAN}Engine:${NC} ${YELLOW}Bash${NC}"
    fi
    local plugin_count=0
    if [ -d "$HOME/.netraven/plugins" ]; then
        plugin_count=$(ls "$HOME/.netraven/plugins/"*.nrav 2>/dev/null | wc -l)
    fi
    echo -e "${CYAN}Plugins:${NC} $plugin_count"
    echo -e "${PURPLE}──────────────────────────────────────────────────${NC}"
}

# ==================== BUILD FUNCTIONS ====================

auto_build_engine() {
    local need_build=0
    local engine_src="src/engine/netraven_engine.cpp"
    local engine_bin="src/engine/netraven_engine"

    if [ ! -f "$engine_bin" ]; then
        need_build=1
    elif [ -f "$engine_src" ] && [ "$engine_src" -nt "$engine_bin" ]; then
        need_build=1
    fi

    if [ $need_build -eq 1 ]; then
        echo -e "${CYAN}[*] Building C++ Engine...${NC}"
        bash build.sh
    else
        echo -e "${GREEN}[+] Engine already built${NC}"
    fi
}

auto_install_plugins() {
    if [ ! -d "$HOME/.netraven/plugins" ]; then
        echo -e "${CYAN}[*] Installing plugins...${NC}"
        mkdir -p "$HOME/.netraven/plugins"
        cp src/plugins/*.nrav "$HOME/.netraven/plugins/" 2>/dev/null || true
        cp src/plugins/*.nrav.meta "$HOME/.netraven/plugins/" 2>/dev/null || true
        echo -e "${GREEN}[+] Plugins installed${NC}"
    else
        echo -e "${GREEN}[+] Plugins already installed${NC}"
    fi
}

prompt_target() {
    if [ -z "$TARGET_URL" ]; then
        read -p "Enter target URL (e.g., http://example.com): " TARGET_URL
        if [ -z "$TARGET_URL" ]; then
            echo -e "${RED}[!] No target provided.${NC}"
            return 1
        fi
        TARGET_DOMAIN=$(echo "$TARGET_URL" | awk -F/ '{print $3}')
        RESULTS_DIR="results/$TARGET_DOMAIN"
        mkdir -p "$RESULTS_DIR"/{recon,vulns,attacks,monitor}
        echo -e "${GREEN}[+] Target locked: $TARGET_URL${NC}"
        echo -e "${GREEN}[+] Results: $RESULTS_DIR${NC}"
    fi
    return 0
}

show_main_menu() {
    echo -e "${PURPLE}┌──────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}          ${CYAN}NetRaven Main Menu${NC}                       ${PURPLE}│${NC}"
    echo -e "${PURPLE}├──────────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  Hack                                      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  Help                                      ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  Mishvious                                 ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Exit                                      ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────┘${NC}"
    echo
}

# ==================== STARTUP ====================
show_banner
source src/core/config.sh
source src/core/utils.sh
check_tools
auto_build_engine
auto_install_plugins

echo
echo -e "${GREEN}[+] NetRaven initialized successfully${NC}"
sleep 0.5

# ==================== MAIN LOOP ====================
while true; do
    show_status_bar
    show_main_menu
    read -p "Select: " choice

    case $choice in
        1)
            prompt_target || continue
            source src/modules/hack_menu.sh
            ;;
        2)
            source src/core/help.sh
            ;;
        3)
            source src/misc/mishvious_menu.sh
            ;;
        0)
            echo -e "${GREEN}[+] Exiting NetRaven...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Invalid option${NC}"
            ;;
    esac
done
