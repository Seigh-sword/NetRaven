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
    "openssl"
    "tcpdump"
    "tshark"
    "enum4linux"
    "smbclient"
    "nbtscan"
    "onesixtyone"
    "snmpwalk"
    "theHarvester"
    "sublist3r"
    "amass"
    "subfinder"
    "httpx"
    "nuclei"
    "zap-cli"
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

show_help() {
    clear
    echo -e "${CYAN}=== NetRaven Help ===${NC}"
    echo
    echo -e "${GREEN}NetRaven${NC} is an ethical hacking framework for Kali Linux."
    echo
    echo -e "${YELLOW}Main Menu:${NC}"
    echo "  [1] Hack      - Enter target URL, then select attack modules"
    echo "  [2] Help      - View guides and documentation"
    echo "  [3] Mishvious - Engine, tunnels, plugins, sites, TTS, docs"
    echo
    echo -e "${YELLOW}Hack Modules:${NC}"
    echo "  [1]  Reconnaissance    - WHOIS, DNS, Nmap, subdomains, tech fingerprint"
    echo "  [2]  Vulnerability     - Nikto, SQLi, XSS, dir busting, WAF, SSL"
    echo "  [3]  Attacks           - Brute force, SQLMap, XSS, CMDi, LFI/RFI, CSRF"
    echo "  [4]  Monitoring        - Ping, HTTP uptime, port, DNS, SSL expiry"
    echo "  [5]  Network           - Traceroute, GeoIP, ASN, masscan, netcat"
    echo "  [6]  Reports           - Generate and export full assessment reports"
    echo "  [7]  Exploitation      - SQLi dump/add admin/deface, CMDi shell, LFI RCE, XSS, upload shell"
    echo
    echo -e "${YELLOW}Mishvious Modules:${NC}"
    echo "  [1]  C++ Engine        - Attack simulation engine with plugin support"
    echo "  [2]  Cloudflare Tunnels - Create .trycloudflare.com tunnels for testing"
    echo "  [3]  Plugin Manager    - Manage .nrav plugin files"
    echo "  [4]  Site Generator    - Create vulnerable test sites for practice"
    echo "  [5]  TTS               - Text-to-Speech converter"
    echo "  [6]  Docs              - View documentation"
    echo "  [7]  License           - Apache 2.0 license"
    echo "  [8]  Terms             - Terms of use"
    echo "  [9]  Environment Info  - Show system details, tools, and engine status"
    echo "  [10] Update NetRaven   - Self-update from git repository"
    echo
    echo -e "${RED}[!] Only test systems you own or have explicit permission to test.${NC}"
    echo
    read -p "Press Enter to return to menu..."
}

show_env_info() {
    clear
    echo -e "${CYAN}=== Environment Information ===${NC}"
    echo
    echo -e "${CYAN}[*] Time:${NC}            $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${CYAN}[*] Working Dir:${NC}     $(pwd)"
    echo -e "${CYAN}[*] OS:${NC}              $(uname -s)"
    echo -e "${CYAN}[*] Kernel:${NC}          $(uname -r)"
    echo -e "${CYAN}[*] Architecture:${NC}    $(uname -m)"
    echo -e "${CYAN}[*] Hostname:${NC}        $(hostname)"
    echo -e "${CYAN}[*] User:${NC}            $(whoami)"
    echo -e "${CYAN}[*] Shell:${NC}           $SHELL"
    echo -e "${CYAN}[*] Bash Version:${NC}    $BASH_VERSION"
    echo
    echo -e "${CYAN}[*] CPU:${NC}             $(grep 'model name' /proc/cpuinfo 2>/dev/null | head -n1 | cut -d: -f2 | xargs)"
    echo -e "${CYAN}[*] CPU Cores:${NC}       $(nproc 2>/dev/null || echo 'unknown')"
    echo -e "${CYAN}[*] Memory Total:${NC}    $(free -h 2>/dev/null | awk '/Mem:/{print $2}' || echo 'unknown')"
    echo -e "${CYAN}[*] Memory Free:${NC}     $(free -h 2>/dev/null | awk '/Mem:/{print $4}' || echo 'unknown')"
    echo -e "${CYAN}[*] Disk Total:${NC}      $(df -h / 2>/dev/null | awk 'NR==2{print $2}' || echo 'unknown')"
    echo -e "${CYAN}[*] Disk Free:${NC}       $(df -h / 2>/dev/null | awk 'NR==2{print $4}' || echo 'unknown')"
    echo
    echo -e "${CYAN}[*] Python:${NC}          $(python3 --version 2>/dev/null || echo 'not installed')"
    echo -e "${CYAN}[*] GCC:${NC}             $(gcc --version 2>/dev/null | head -n1 || echo 'not installed')"
    echo -e "${CYAN}[*] PHP:${NC}             $(php --version 2>/dev/null | head -n1 || echo 'not installed')"
    echo -e "${CYAN}[*] Nmap:${NC}            $(nmap --version 2>/dev/null | head -n1 || echo 'not installed')"
    echo -e "${CYAN}[*] curl:${NC}            $(curl --version 2>/dev/null | head -n1 || echo 'not installed')"
    echo
    echo -e "${CYAN}[*] NetRaven Version:${NC}  1.0"
    echo -e "${CYAN}[*] Engine:${NC}          C++ (netraven_engine)"
    echo -e "${CYAN}[*] Plugin Format:${NC}    .nrav (XML-like) + .nrav.meta"
    echo -e "${CYAN}[*] Tunnel Support:${NC}    Cloudflare (.trycloudflare.com)"
    echo -e "${CYAN}[*] Site Generator:${NC}    PHP/HTML vulnerable test sites"
    echo
    echo -e "${CYAN}[*] Results Directory:${NC} results/"
    echo -e "${CYAN}[*] Plugin Directory:${NC}  ~/.netraven/plugins/"
    echo -e "${CYAN}[*] Tunnel Directory:${NC}  ~/.netraven/tunnels/"
    echo -e "${CYAN}[*] Site Directory:${NC}    ~/.netraven/sites/"
    echo
    read -p "Press Enter to return to menu..."
}
