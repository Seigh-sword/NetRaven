#!/bin/bash
# NetRaven Build Script - Compiles the C++ engine

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/src/engine"
BUILD_DEPS=("g++" "make" "libcurl4-openssl-dev")

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

echo -e "${PURPLE}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${PURPLE}║${NC}          ${CYAN}NetRaven Engine Builder${NC}                 ${PURPLE}║${NC}"
echo -e "${PURPLE}╚══════════════════════════════════════════════════════╝${NC}"
echo

if [ ! -f "$ENGINE_DIR/Makefile" ]; then
    echo -e "${RED}[!] Makefile not found in $ENGINE_DIR${NC}"
    exit 1
fi

# Step 1: Update package lists
echo -e "${CYAN}[*] Updating package repositories...${NC}"
sudo apt update 2>&1 | tail -n 5
echo -e "${GREEN}[+] Package repositories updated${NC}"
echo

# Step 2: Upgrade existing packages
echo -e "${CYAN}[*] Upgrading installed packages...${NC}"
sudo apt upgrade -y 2>&1 | tail -n 5
echo -e "${GREEN}[+] Packages upgraded${NC}"
echo

# Step 3: Install missing build dependencies
echo -e "${CYAN}[*] Checking build dependencies...${NC}"
for dep in "${BUILD_DEPS[@]}"; do
    if ! dpkg -s "$dep" &>/dev/null; then
        echo -e "${YELLOW}[*] Installing $dep...${NC}"
        sudo apt install -y "$dep" 2>&1 | tail -n 3
    else
        echo -e "${GREEN}[+] $dep already installed${NC}"
    fi
done

# Fallback for libcurl
if ! dpkg -s libcurl4-openssl-dev &>/dev/null; then
    echo -e "${YELLOW}[!] libcurl4-openssl-dev not available, trying libcurl-dev...${NC}"
    sudo apt install -y libcurl-dev 2>&1 | tail -n 3
fi

echo

# Step 4: Install dialog for TUI
if ! command -v dialog &>/dev/null; then
    echo -e "${YELLOW}[*] Installing dialog for TUI...${NC}"
    sudo apt install -y dialog 2>&1 | tail -n 3
fi

# Step 5: Compile engine
echo -e "${CYAN}[*] Compiling C++ Engine...${NC}"
cd "$ENGINE_DIR"
rm -f netraven_engine
make clean 2>/dev/null || true
make 2>&1

echo
if [ -f "$ENGINE_DIR/netraven_engine" ]; then
    echo -e "${GREEN}[+] Build successful: $ENGINE_DIR/netraven_engine${NC}"
else
    echo -e "${RED}[-] Build failed${NC}"
    exit 1
fi

echo
echo -e "${GREEN}[+] NetRaven is ready!${NC}"
