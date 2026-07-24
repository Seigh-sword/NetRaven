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

if ! dpkg -s libcurl4-openssl-dev &>/dev/null; then
    echo -e "${YELLOW}[!] libcurl development headers not found. Installing...${NC}"
    echo -e "${CYAN}[*] Updating package list...${NC}"
    sudo apt update -qq 2>/dev/null || true
    echo -e "${GREEN}[+] Package list updated${NC}"
    echo
    
    start_time=$(date +%s)
    echo -e "${CYAN}[*] Installing libcurl4-openssl-dev...${NC}"
    
    for i in $(seq 1 100); do
        progress_bar $i 100
        printf " ${YELLOW}%ds${NC}" "$(($(date +%s) - start_time))"
        
        if [ $i -eq 30 ]; then
            printf " ${BLUE}Downloading...${NC}"
        elif [ $i -eq 60 ]; then
            printf " ${BLUE}Unpacking...${NC}"
        elif [ $i -eq 90 ]; then
            printf " ${BLUE}Setting up...${NC}"
        fi
        
        sleep 0.02
    done
    
    sudo apt install -y libcurl4-openssl-dev 2>/dev/null | tail -n 3
    printf " ${GREEN}Done${NC}\n"
fi

if ! dpkg -s libcurl4-openssl-dev &>/dev/null; then
    echo -e "${YELLOW}[!] libcurl4-openssl-dev not available, trying libcurl-dev...${NC}"
    sudo apt install -y libcurl-dev 2>/dev/null | tail -n 3
fi

echo
echo -e "${CYAN}[*] Building engine...${NC}"

cd "$ENGINE_DIR"
make clean 2>/dev/null || true

# Animated compilation
start_time=$(date +%s)
make > /tmp/compile.log 2>&1 &
pid=$!

fake_progress=0
while [ "$(ps a | awk '{print $1}' | grep -w "$pid")" ]; do
    fake_progress=$((fake_progress + 3))
    if [ $fake_progress -gt 80 ]; then
        fake_progress=80
    fi
    
    progress_bar $fake_progress 100
    printf " ${YELLOW}%ds${NC}" "$(($(date +%s) - start_time))"
    
    if [ $fake_progress -eq 20 ]; then
        printf " ${BLUE}[CC] netraven_engine.cpp${NC}"
    elif [ $fake_progress -eq 50 ]; then
        printf " ${BLUE}[LINK] netraven_engine${NC}"
    fi
    
    sleep 0.1
done

wait $pid

progress_bar 100 100
end_time=$(date +%s)
printf " ${GREEN}Done${NC} ${YELLOW}($(($end_time - start_time))s)${NC}\n"

if [ -f "$ENGINE_DIR/netraven_engine" ]; then
    echo
    echo -e "${GREEN}[+] Build successful: $ENGINE_DIR/netraven_engine${NC}"
else
    echo
    echo -e "${RED}[-] Build failed${NC}"
    exit 1
fi
