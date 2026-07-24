#!/bin/bash

# NetRaven Help System

source src/core/utils.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

help_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}          ${CYAN}Help & Documentation${NC}                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────┤${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  Quick Start Guide                     ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  Attack Explanations                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  Tool Reference                        ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[4]${NC}  Plugin Development Guide              ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[5]${NC}  Cloudflare Tunnels Guide              ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[6]${NC}  Troubleshooting                       ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[7]${NC}  FAQ                                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[8]${NC}  View Documentation                    ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Back to Main Menu                     ${PURPLE}│${NC}"
        echo -e "${PURPLE}└──────────────────────────────────────────────────┘${NC}"
        echo
        read -p "Select topic: " opt

        case $opt in
            1) quick_start ;;
            2) attack_explanations ;;
            3) tool_reference ;;
            4) plugin_guide ;;
            5) tunnel_guide ;;
            6) troubleshooting ;;
            7) faq ;;
            8)
                if [ -d "$PROJECT_ROOT/docs" ]; then
                    local files=()
                    for f in "$PROJECT_ROOT/docs"/*.md; do
                        [ -f "$f" ] && files+=("$f")
                    done
                    if [ ${#files[@]} -gt 0 ]; then
                        clear
                        echo -e "${CYAN}=== Documentation Files ===${NC}"
                        echo
                        local i=1
                        for f in "${files[@]}"; do
                            echo -e "${CYAN}[$i]${NC} $(basename "$f")"
                            i=$((i + 1))
                        done
                        echo
                        read -p "Select file (0 to back): " doc_choice
                        if [ "$doc_choice" -ge 1 ] && [ "$doc_choice" -lt "$i" ]; then
                            less "${files[$((doc_choice - 1))]}"
                        fi
                    else
                        echo -e "${YELLOW}No docs found${NC}"
                        read -p "Press Enter..."
                    fi
                else
                    echo -e "${YELLOW}No docs/ directory found${NC}"
                    read -p "Press Enter..."
                fi
                ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
    done
}

quick_start() {
    clear
    echo -e "${CYAN}=== Quick Start Guide ===${NC}"
    echo
    echo -e "${GREEN}1. Run NetRaven${NC}"
    echo "   bash netraven.sh"
    echo
    echo -e "${GREEN}2. Main Menu${NC}"
    echo "   [1] Hack     - Enter target URL, then select attack modules"
    echo "   [2] Help     - View guides and documentation"
    echo "   [3] Mishvious - Engine, tunnels, plugins, sites, TTS, docs"
    echo
    echo -e "${GREEN}3. First Time Setup${NC}"
    echo "   - Engine auto-builds on first run (requires g++, make, libcurl)"
    echo "   - Plugins auto-copy to ~/.netraven/plugins/"
    echo "   - Install missing tools: sudo apt install nmap nikto sqlmap hydra ..."
    echo
    echo -e "${GREEN}4. Generate a Test Site${NC}"
    echo "   Main -> [3] Mishvious -> [4] Vulnerable Site Generator"
    echo "   Choose low/medium/high security and start locally"
    echo
    echo -e "${GREEN}5. Create a Tunnel${NC}"
    echo "   Main -> [3] Mishvious -> [2] Cloudflare Tunnels"
    echo "   Expose local sites via .trycloudflare.com URLs"
    echo
    echo -e "${RED}[!] Only test systems you own or have explicit permission to test.${NC}"
    echo
    read -p "Press Enter to return..."
}

attack_explanations() {
    clear
    echo -e "${CYAN}=== Attack Explanations ===${NC}"
    echo
    echo -e "${YELLOW}SQL Injection (SQLi)${NC}"
    echo "  Injects SQL code into input fields to manipulate the database."
    echo "  Prevention: Prepared statements, parameterized queries, input validation."
    echo
    echo -e "${YELLOW}Cross-Site Scripting (XSS)${NC}"
    echo "  Injects malicious scripts into web pages viewed by other users."
    echo "  Prevention: Output encoding (htmlspecialchars), CSP headers."
    echo
    echo -e "${YELLOW}Command Injection (CMDi)${NC}"
    echo "  Executes arbitrary OS commands via vulnerable input fields."
    echo "  Prevention: Avoid passing user input to shells; use parameterized APIs."
    echo
    echo -e "${YELLOW}Local File Inclusion (LFI)${NC}"
    echo "  Includes local files via directory traversal (e.g., ../../etc/passwd)."
    echo "  Prevention: Validate file paths against allowlists, disable allow_url_include."
    echo
    echo -e "${YELLOW}Brute Force${NC}"
    echo "  Tries many passwords/logins against authentication endpoints."
    echo "  Prevention: Rate limiting, account lockout, MFA, strong passwords."
    echo
    echo -e "${YELLOW}Open Redirect${NC}"
    echo "  Redirects users to untrusted external domains via unvalidated URL params."
    echo "  Prevention: Validate redirect URLs against a whitelist."
    echo
    echo -e "${YELLOW}CSRF${NC}"
    echo "  Tricks authenticated users into submitting unwanted actions."
    echo "  Prevention: Anti-CSRF tokens, SameSite cookies."
    echo
    echo -e "${YELLOW}Clickjacking${NC}"
    echo "  Tricks users into clicking hidden UI elements via iframe overlays."
    echo "  Prevention: X-Frame-Options: DENY, CSP frame-ancestors."
    echo
    echo -e "${YELLOW}CRLF Injection${NC}"
    echo "  Inserts CRLF characters to split headers or inject content."
    echo "  Prevention: Strip CRLF from user input, validate headers."
    echo
    read -p "Press Enter to return..."
}

tool_reference() {
    clear
    echo -e "${CYAN}=== Tool Reference ===${NC}"
    echo
    echo -e "${YELLOW}Network Scanning${NC}"
    echo "  nmap         - Port scanning and service detection"
    echo "  masscan      - Fast port scanner"
    echo "  netcat       - Network utility (read/write across network)"
    echo
    echo -e "${YELLOW}Web Scanning${NC}"
    echo "  nikto        - Web server vulnerability scanner"
    echo "  gobuster     - Directory/file brute forcing"
    echo "  ffuf         - Fast web fuzzer"
    echo "  dirb         - Directory brute forcer"
    echo "  whatweb      - Web technology fingerprinting"
    echo "  wafw00f      - WAF detection"
    echo "  nuclei       - Vulnerability scanner (templates)"
    echo "  httpx        - HTTP probe toolkit"
    echo
    echo -e "${YELLOW}DNS/Subdomains${NC}"
    echo "  dig          - DNS lookup"
    echo "  whois        - WHOIS lookup"
    echo "  sublist3r    - Subdomain enumeration"
    echo "  amass        - Attack surface mapping"
    echo "  subfinder    - Subdomain discovery"
    echo "  theHarvester - Email/subdomain harvesting"
    echo
    echo -e "${YELLOW}Exploitation${NC}"
    echo "  sqlmap       - Automated SQL injection"
    echo "  hydra        - Network login cracker"
    echo "  john         - Password cracker"
    echo "  enum4linux   - SMB enumeration"
    echo "  smbclient    - SMB client"
    echo "  snmpwalk     - SNMP enumeration"
    echo "  onesixtyone  - SNMP scanner"
    echo
    echo -e "${YELLOW}Analysis${NC}"
    echo "  tcpdump      - Packet capture"
    echo "  tshark       - CLI Wireshark"
    echo "  openssl      - SSL/TLS toolkit"
    echo "  curl         - Data transfer utility"
    echo "  wget         - File downloader"
    echo
    echo -e "${YELLOW}Tunnels/Sites${NC}"
    echo "  cloudflared  - Cloudflare tunnel client"
    echo "  php          - PHP built-in server for test sites"
    echo
    read -p "Press Enter to return..."
}

plugin_guide() {
    clear
    echo -e "${CYAN}=== Plugin Development Guide ===${NC}"
    echo
    echo -e "${YELLOW}Plugin Format${NC}"
    echo "  Plugins use XML-like .nrav files with .nrav.meta metadata."
    echo
    echo -e "${YELLOW}Structure${NC}"
    cat << 'EXAMPLE'
<?xml version="1.0" encoding="UTF-8"?>
<plugin>
    <name>my_plugin</name>
    <version>1.0</version>
    <author>Author</author>
    <description>Description</description>
    <category>sqli</category>
    <requires>curl,nmap</requires>
    <attack type="sqli">
        <payload>' OR '1'='1</payload>
        <detection>sql|syntax|mysql</detection>
    </attack>
</plugin>
EXAMPLE
    echo
    echo -e "${YELLOW}Categories${NC}"
    echo "  sqli, xss, cmdi, lfi, bruteforce, open_redirect, csrf, clickjacking, crlf"
    echo
    echo -e "${YELLOW}Metadata File (.nrav.meta)${NC}"
    echo "  name=my_plugin"
    echo "  version=1.0"
    echo "  author=Author"
    echo "  category=sqli"
    echo "  description=Description"
    echo "  requires=curl,nmap"
    echo
    echo -e "${YELLOW}Creating Plugins${NC}"
    echo "  Main -> [3] Mishvious -> [3] Plugin Manager -> [6] Create New Plugin"
    echo
    echo -e "${YELLOW}Running Plugins${NC}"
    echo "  Main -> [3] Mishvious -> [3] Plugin Manager -> [4] Run Plugin Attack"
    echo "  Or use the C++ Engine -> [12] Run Plugin Attack"
    echo
    read -p "Press Enter to return..."
}

tunnel_guide() {
    clear
    echo -e "${CYAN}=== Cloudflare Tunnels Guide ===${NC}"
    echo
    echo -e "${YELLOW}What are tunnels?${NC}"
    echo "  Tunnels expose local servers to the internet without port forwarding."
    echo "  NetRaven uses cloudflared to create .trycloudflare.com URLs."
    echo
    echo -e "${YELLOW}Usage${NC}"
    echo "  Main -> [3] Mishvious -> [2] Cloudflare Tunnels"
    echo
    echo -e "${YELLOW}Options${NC}"
    echo "  [1] Quick Tunnel      - Expose any local port"
    echo "  [2] PHP Site Tunnel   - Start PHP server + tunnel"
    echo "  [3] HTML Site Tunnel  - Start Python HTTP server + tunnel"
    echo "  [4] List Active Tunnels"
    echo "  [5] Stop Tunnel"
    echo "  [6] Stop All Tunnels"
    echo "  [7] Tunnel Dashboard"
    echo
    echo -e "${YELLOW}Typical Workflow${NC}"
    echo "  1. Generate a vulnerable site (Mishvious -> Site Generator)"
    echo "  2. Start the site locally (Site Generator -> Start Site Locally)"
    echo "  3. Create a tunnel (Mishvious -> Tunnels -> Create Tunnel for Local PHP Site)"
    echo "  4. Share the .trycloudflare.com URL for remote testing"
    echo
    read -p "Press Enter to return..."
}

troubleshooting() {
    clear
    echo -e "${CYAN}=== Troubleshooting ===${NC}"
    echo
    echo -e "${YELLOW}Engine won't build${NC}"
    echo "  - Ensure g++ and make are installed: sudo apt install g++ make"
    echo "  - Ensure libcurl dev headers are installed: sudo apt install libcurl4-openssl-dev"
    echo "  - Check build output in /tmp/netraven_build.log"
    echo
    echo -e "${YELLOW}Tools missing${NC}"
    echo "  - Run: sudo apt install nmap nikto sqlmap hydra john gobuster ffuf ..."
    echo "  - Or install kali-linux-large metapackage"
    echo
    echo -e "${YELLOW}Tunnel creation fails${NC}"
    echo "  - Check cloudflared is installed and in PATH"
    echo "  - Ensure local port is not already in use"
    echo "  - Check logs in ~/.netraven/tunnels/"
    echo
    echo -e "${YELLOW}Site generator requires PHP${NC}"
    echo "  - Install PHP: sudo apt install php"
    echo "  - The script will attempt to install it automatically"
    echo
    echo -e "${YELLOW}TTS not working${NC}"
    echo "  - Ensure python3 is installed"
    echo "  - Install gTTS: pip3 install gtts --break-system-packages"
    echo "  - Install a player: sudo apt install mpg123"
    echo
    echo -e "${YELLOW}Plugins not loading${NC}"
    echo "  - Ensure .nrav and .nrav.meta files are both present"
    echo "  - Check plugin directory: ~/.netraven/plugins/"
    echo "  - Use Plugin Manager -> Validate Plugin to check format"
    echo
    read -p "Press Enter to return..."
}

faq() {
    clear
    echo -e "${CYAN}=== Frequently Asked Questions ===${NC}"
    echo
    echo -e "${YELLOW}Q: Is NetRaven free?${NC}"
    echo "A: Yes, NetRaven is released under the Apache 2.0 license."
    echo
    echo -e "${YELLOW}Q: Is this for illegal hacking?${NC}"
    echo "A: No. NetRaven is for educational purposes and authorized security testing only."
    echo
    echo -e "${YELLOW}Q: Does it work on Windows?${NC}"
    echo "A: No. NetRaven is designed for Kali Linux and Linux environments."
    echo
    echo -e "${YELLOW}Q: How do I add my own attack module?${NC}"
    echo "A: Create a new script in src/modules/ following the existing menu pattern,"
    echo "   then add it to hack_menu.sh."
    echo
    echo -e "${YELLOW}Q: Can I use this on production systems?${NC}"
    echo "A: Only if you have explicit written permission from the system owner."
    echo
    echo -e "${YELLOW}Q: How do I update tools?${NC}"
    echo "A: Run 'sudo apt update && sudo apt upgrade' on Kali Linux."
    echo
    read -p "Press Enter to return..."
}
