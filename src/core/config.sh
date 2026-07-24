#!/bin/bash

# NetRaven Configuration

export TOOLS_DIR="/usr/share"
export WORDLISTS_DIR="/usr/share/wordlists"
export RESULTS_DIR=""

export TOOLS=(
    "nmap"
    "nikto"
    "sqlmap"
    "hydra"
    "john"
    "dirb"
    "gobuster"
    "ffuf"
    "whatweb"
    "wafw00f"
    "masscan"
    "netcat"
    "curl"
    "wget"
    "dig"
    "whois"
)

check_tools() {
    echo -e "${CYAN}[*] Checking installed tools...${NC}"
    local missing=0
    for tool in "${TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo -e "${YELLOW}[!] Missing: $tool${NC}"
            missing=$((missing + 1))
        fi
    done
    if [ $missing -eq 0 ]; then
        echo -e "${GREEN}[+] All tools available${NC}"
    else
        echo -e "${YELLOW}[*] $missing tool(s) missing. Install with: apt install ${TOOLS[*]}${NC}"
    fi
}
