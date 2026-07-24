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

WIDTH=50

header() {
    echo
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════╗${NC}"
    printf "${PURPLE}║${NC}%*s${PURPLE}║${NC}\n" $((WIDTH - 2)) "$1"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════╝${NC}"
    echo
}

progress_bar() {
    local current=$1
    local total=$2
    local width=$WIDTH
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${CYAN}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "${CYAN}]${NC} ${percentage}%%"
}

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

header "NetRaven Engine Builder"

if [ ! -f "$ENGINE_DIR/Makefile" ]; then
    echo -e "${RED}[!] Makefile not found in $ENGINE_DIR${NC}"
    exit 1
fi

# Step 1: Update package lists
header "[1/5] Updating Package Repositories"
echo -e "${CYAN}[*] Running: apt update${NC}"
start_time=$(date +%s)
sudo apt update 2>&1 | while read -r line; do
    printf "\r${CYAN}[${NC}%-50s${CYAN}]${NC} ${YELLOW}%ds${NC}" "$line" "$(($(date +%s) - start_time))"
done
printf "\r${GREEN}[+]${NC} Package repositories updated %-20s ${YELLOW}%ds${NC}\n" "" "$(($(date +%s) - start_time))"

# Step 2: Upgrade all installed packages
header "[2/5] Upgrading All Installed Packages"
echo -e "${CYAN}[*] Running: apt upgrade -y${NC}"
echo -e "${YELLOW}[!] This may take several minutes...${NC}"
start_time=$(date +%s)
sudo apt upgrade -y 2>&1 | while read -r line; do
    printf "\r${CYAN}[${NC}%-50s${CYAN}]${NC} ${YELLOW}%ds${NC}" "$line" "$(($(date +%s) - start_time))"
done
printf "\r${GREEN}[+]${NC} All packages upgraded %-30s ${YELLOW}%ds${NC}\n" "" "$(($(date +%s) - start_time))"

# Step 3: Install missing build dependencies
header "[3/5] Installing Build Dependencies"
for dep in "${BUILD_DEPS[@]}"; do
    if ! dpkg -s "$dep" &>/dev/null; then
        echo -e "${CYAN}[*] Installing $dep...${NC}"
        start_time=$(date +%s)
        sudo apt install -y "$dep" 2>&1 | while read -r line; do
            printf "\r${CYAN}[${NC}%-50s${CYAN}]${NC} ${YELLOW}%ds${NC}" "$line" "$(($(date +%s) - start_time))"
        done
        printf "\r${GREEN}[+]${NC} $dep installed %-35s ${YELLOW}%ds${NC}\n" "" "$(($(date +%s) - start_time))"
    else
        echo -e "${GREEN}[+] $dep already installed${NC}"
    fi
done

# Fallback for libcurl
if ! dpkg -s libcurl4-openssl-dev &>/dev/null; then
    echo -e "${YELLOW}[!] libcurl4-openssl-dev not available, trying libcurl-dev...${NC}"
    sudo apt install -y libcurl-dev 2>&1 | while read -r line; do
        printf "\r${CYAN}[${NC}%-50s${CYAN}]${NC}" "$line"
    done
    echo
fi

# Step 4: Install dialog for TUI
if ! command -v dialog &>/dev/null; then
    echo -e "${YELLOW}[*] Installing dialog for TUI...${NC}"
    sudo apt install -y dialog 2>&1 | while read -r line; do
        printf "\r${CYAN}[${NC}%-50s${CYAN}]${NC}" "$line"
    done
    echo
fi

# Step 5: Compile engine
header "[4/5] Compiling C++ Engine"
echo -e "${CYAN}[*] Cleaning previous build...${NC}"
cd "$ENGINE_DIR"
rm -f netraven_engine
make clean 2>/dev/null || true

echo -e "${CYAN}[*] Compiling...${NC}"
start_time=$(date +%s)
make 2>&1 | while read -r line; do
    printf "\r${CYAN}[${NC}%-50s${CYAN}]${NC} ${YELLOW}%ds${NC}" "$line" "$(($(date +%s) - start_time))"
done
echo

if [ -f "$ENGINE_DIR/netraven_engine" ]; then
    header "[5/5] Build Complete"
    echo -e "${GREEN}[+] Build successful: $ENGINE_DIR/netraven_engine${NC}"
else
    header "[5/5] Build Failed"
    echo -e "${RED}[-] Build failed${NC}"
    exit 1
fi

echo
echo -e "${GREEN}[+] NetRaven is ready!${NC}"
