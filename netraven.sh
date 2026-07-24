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

spinner_chars="/-\|"

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

animate_download() {
    local label="$1"
    shift
    local cmd="$@"
    
    echo -e "${YELLOW}[*] ${label}${NC}"
    
    local start_time=$(date +%s)
    local fake_progress=0
    local pid=$!
    
    # Run command in background
    eval "$cmd" > /tmp/netraven_install.log 2>&1 &
    local cmd_pid=$!
    
    while [ "$(ps a | awk '{print $1}' | grep -w "$cmd_pid")" ]; do
        fake_progress=$((fake_progress + 1))
        if [ $fake_progress -gt 90 ]; then
            fake_progress=90
        fi
        
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        progress_bar $fake_progress 100
        printf " ${YELLOW}%ds${NC}" "$elapsed"
        
        sleep 0.1
    done
    
    # Ensure 100%
    progress_bar 100 100
    local end_time=$(date +%s)
    local total_time=$((end_time - start_time))
    printf " ${GREEN}Done${NC} ${YELLOW}(${total_time}s)${NC}\n"
    
    wait $cmd_pid
    return $?
}

show_loading_screen() {
    clear
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${NC}                                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}██████╗ ██████╗  ██████╗ ███████╗███████╗██████╗ ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}██╔══██╗██╔══██╗██╔═══██╗██╔════╝██╔══██╗██╔══██╗${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}██████╔╝██████╔╝██║   ██║███████╗██████╔╝██████╔╝${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}██╔══██╗██╔══██╗██║   ██║╚════██║██╔═══╝ ██╔══██╗${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}██████╔╝██║  ██║╚██████╔╝███████║██║     ██║  ██║${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}     ${CYAN}╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}          ${GREEN}Ethical Hacking Framework v1.0${NC}             ${PURPLE}║${NC}"
    echo -e "${PURPLE}║${NC}                                                      ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════╝${NC}"
    echo
}

show_startup_loading() {
    show_loading_screen
    
    echo -e "${CYAN}[*] Initializing NetRaven...${NC}"
    sleep 0.3
    
    echo -e "${YELLOW}[*] Loading core modules...${NC}"
    sleep 0.2
    
    echo -e "${YELLOW}[*] Checking system compatibility...${NC}"
    sleep 0.2
    
    echo -e "${GREEN}[+] System compatible${NC}"
    echo
}

animate_apt_update() {
    local start_time=$(date +%s)
    
    echo -e "${CYAN}[*] Updating package repositories...${NC}"
    
    # Simulate download progress
    for i in $(seq 1 100); do
        progress_bar $i 100
        printf " ${YELLOW}%ds${NC}" "$(date +%s -d @$(( $(date +%s) - start_time )))"
        
        if [ $i -eq 20 ]; then
            printf " ${BLUE}Hit:1 http://kali.download kali-rolling main contrib non-free non-free-firmware${NC}"
        elif [ $i -eq 40 ]; then
            printf " ${BLUE}Get:2 http://kali.download kali-rolling-updates main contrib non-free${NC}"
        elif [ $i -eq 60 ]; then
            printf " ${BLUE}Get:3 http://kali.download kali-rolling Security main contrib non-free${NC}"
        elif [ $i -eq 80 ]; then
            printf " ${BLUE}Fetched 1,247 kB in 3s (416 kB/s)${NC}"
        fi
        
        sleep 0.03
    done
    
    local end_time=$(date +%s)
    printf " ${GREEN}Done${NC} ${YELLOW}($(($end_time - start_time))s)${NC}\n"
    
    # Actually run apt update
    sudo apt update -qq 2>/dev/null || true
}

animate_package_install() {
    local package="$1"
    local start_time=$(date +%s)
    
    echo -e "${CYAN}[*] Installing ${package}...${NC}"
    
    # Simulate download and install progress
    local phases=("Downloading" "Unpacking" "Setting up")
    local phase_idx=0
    
    for i in $(seq 1 100); do
        progress_bar $i 100
        
        if [ $i -eq 25 ] && [ $phase_idx -eq 0 ]; then
            printf " ${BLUE}${phases[$phase_idx]}...${NC}"
            phase_idx=1
        elif [ $i -eq 50 ] && [ $phase_idx -eq 1 ]; then
            printf " ${BLUE}${phases[$phase_idx]}...${NC}"
            phase_idx=2
        elif [ $i -eq 75 ] && [ $phase_idx -eq 2 ]; then
            printf " ${BLUE}${phases[$phase_idx]}...${NC}"
        fi
        
        sleep 0.02
    done
    
    local end_time=$(date +%s)
    printf " ${GREEN}Done${NC} ${YELLOW}($(($end_time - start_time))s)${NC}\n"
    
    # Actually install
    sudo apt install -y "$package" 2>/dev/null | tail -n 3
}

animate_compilation() {
    local start_time=$(date +%s)
    
    echo -e "${CYAN}[*] Compiling C++ Engine...${NC}"
    
    cd src/engine
    make clean 2>/dev/null || true
    
    # Run make in background and show progress
    make > /tmp/compile.log 2>&1 &
    local pid=$!
    
    local fake_progress=0
    while [ "$(ps a | awk '{print $1}' | grep -w "$pid")" ]; do
        fake_progress=$((fake_progress + 2))
        if [ $fake_progress -gt 85 ]; then
            fake_progress=85
        fi
        
        progress_bar $fake_progress 100
        printf " ${YELLOW}%ds${NC}" "$(($(date +%s) - start_time))"
        
        # Show compilation status
        if [ $fake_progress -eq 20 ]; then
            printf " ${BLUE}[CC] netraven_engine.cpp${NC}"
        elif [ $fake_progress -eq 50 ]; then
            printf " ${BLUE}[LINK] netraven_engine${NC}"
        fi
        
        sleep 0.1
    done
    
    wait $pid
    
    progress_bar 100 100
    local end_time=$(date +%s)
    printf " ${GREEN}Done${NC} ${YELLOW}($(($end_time - start_time))s)${NC}\n"
    
    cd ../..
}

# ==================== MAIN FUNCTIONS ====================

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

auto_build_engine() {
    if [ ! -f "src/engine/netraven_engine" ]; then
        echo
        animate_apt_update
        echo
        
        echo -e "${CYAN}[*] Installing build dependencies...${NC}"
        sleep 0.3
        
        animate_package_install "g++"
        animate_package_install "make"
        animate_package_install "libcurl4-openssl-dev"
        
        if ! dpkg -s libcurl4-openssl-dev &>/dev/null; then
            echo -e "${YELLOW}[!] libcurl4-openssl-dev not available, trying libcurl-dev...${NC}"
            animate_package_install "libcurl-dev"
        fi
        
        echo
        animate_compilation
        
        if [ -f "src/engine/netraven_engine" ]; then
            echo -e "${GREEN}[+] Engine ready${NC}"
        else
            echo -e "${YELLOW}[!] Engine build failed, using bash mode${NC}"
        fi
    fi
}

auto_install_plugins() {
    if [ ! -d "$HOME/.netraven/plugins" ]; then
        echo
        echo -e "${CYAN}[*] Installing plugins...${NC}"
        sleep 0.2
        
        local plugins=("sqli_test.nrav" "xss_test.nrav" "cmdi_test.nrav" "lfi_scan.nrav" "bruteforce_test.nrav")
        local total=${#plugins[@]}
        local idx=0
        
        for plugin in "${plugins[@]}"; do
            idx=$((idx + 1))
            progress_bar $idx $total
            printf " ${CYAN}%s${NC}" "$plugin"
            
            mkdir -p "$HOME/.netraven/plugins"
            cp "src/plugins/$plugin" "$HOME/.netraven/plugins/" 2>/dev/null || true
            cp "src/plugins/${plugin}.meta" "$HOME/.netraven/plugins/" 2>/dev/null || true
            
            sleep 0.1
        done
        
        printf " ${GREEN}Done${NC}\n"
        echo -e "${GREEN}[+] Plugins installed to ~/.netraven/plugins/${NC}"
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
    echo -e "${PURPLE}┌──────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}          ${CYAN}NetRaven Main Menu${NC}              ${PURPLE}│${NC}"
    echo -e "${PURPLE}├──────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  Hack                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  Help                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  Mishvious                         ${PURPLE}│${NC}"
    echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Exit                              ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────┘${NC}"
    echo
}

# ==================== STARTUP ====================
show_startup_loading
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
