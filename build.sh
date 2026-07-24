#!/bin/bash
# NetRaven Build Script - Compiles the C++ engine

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/src/engine"

echo -e "${CYAN}[*] Building NetRaven C++ Engine...${NC}"

if [ ! -f "$ENGINE_DIR/Makefile" ]; then
    echo -e "${RED}[!] Makefile not found in $ENGINE_DIR${NC}"
    exit 1
fi

if ! dpkg -s libcurl4-openssl-dev &>/dev/null; then
    echo -e "${YELLOW}[!] libcurl development headers not found. Installing...${NC}"
    sudo apt update -qq 2>/dev/null || true
    sudo apt install -y libcurl4-openssl-dev 2>&1 | tail -n 5
fi

if ! dpkg -s libcurl4-openssl-dev &>/dev/null; then
    echo -e "${YELLOW}[!] libcurl4-openssl-dev not available, trying libcurl-dev...${NC}"
    sudo apt install -y libcurl-dev 2>&1 | tail -n 5
fi

cd "$ENGINE_DIR"
make clean 2>/dev/null || true
make

if [ -f "$ENGINE_DIR/netraven_engine" ]; then
    echo -e "${GREEN}[+] Build successful: $ENGINE_DIR/netraven_engine${NC}"
else
    echo -e "${RED}[-] Build failed${NC}"
    exit 1
fi
