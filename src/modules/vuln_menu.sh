#!/bin/bash

# Vulnerability Scanning Module Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

vuln_loop() {
    while true; do
        clear
        echo -e "${CYAN}=== Vulnerability Scanning Module ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC} Nikto Web Scanner"
        echo -e "${CYAN}[2]${NC} SQL Injection Scanner"
        echo -e "${CYAN}[3]${NC} XSS Scanner"
        echo -e "${CYAN}[4]${NC} Directory Bruteforce"
        echo -e "${CYAN}[5]${NC} WAF Detection"
        echo -e "${CYAN}[6]${NC} SSL Security Check"
        echo -e "${CYAN}[7]${NC} HTTP Security Headers"
        echo -e "${CYAN}[8]${NC} CORS Configuration"
        echo -e "${CYAN}[9]${NC} Crawl & Discovery"
        echo -e "${CYAN}[0]${NC} Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) nikto_scan ;;
            2) sqli_scan ;;
            3) xss_scan ;;
            4) dir_brute ;;
            5) waf_detect ;;
            6) ssl_check ;;
            7) http_headers ;;
            8) cors_check ;;
            9) crawl_discover ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

nikto_scan() {
    log "Running Nikto Web Scanner"
    nikto -h "$TARGET_URL" -o "$RESULTS_DIR/vulns/nikto.txt"
    success "Nikto scan saved"
}

sqli_scan() {
    log "SQL Injection Scan"
    echo -e "${YELLOW}[!] This will scan for SQL injection vulnerabilities${NC}"
    read -p "Use sqlmap? (y/n): " use_sqlmap
    if [ "$use_sqlmap" = "y" ]; then
        sqlmap -u "$TARGET_URL" --batch --output-dir="$RESULTS_DIR/vulns/sqlmap"
        success "SQLMap scan saved"
    else
        echo "Manual testing recommended: ' OR '1'='1"
    fi
}

xss_scan() {
    log "XSS Scanner"
    echo -e "${YELLOW}[!] XSS scanning requires manual testing or specialized tools${NC}"
    echo "Common payloads: <script>alert(1)</script>"
    echo "Check reflection in: search, comments, profiles"
}

dir_brute() {
    log "Directory Bruteforce"
    read -p "Wordlist path (default: /usr/share/wordlists/dirb/common.txt): " wordlist
    wordlist=${wordlist:-/usr/share/wordlists/dirb/common.txt}
    dirb "$TARGET_URL" "$wordlist" -o "$RESULTS_DIR/vulns/dirb.txt"
    success "Directory scan saved"
}

waf_detect() {
    log "WAF Detection"
    wafw00f "$TARGET_URL" > "$RESULTS_DIR/vulns/waf.txt" 2>&1
    success "WAF detection saved"
    cat "$RESULTS_DIR/vulns/waf.txt"
}

ssl_check() {
    log "SSL Security Check"
    echo -e "${YELLOW}[!] Checking SSL configuration...${NC}"
    echo "SSL Labs: https://www.ssllabs.com/ssltest/analyze.html?d=$TARGET_DOMAIN"
    nmap --script ssl-enum-ciphers -p 443 "$TARGET_DOMAIN" > "$RESULTS_DIR/vulns/ssl_nmap.txt"
    success "SSL scan saved"
}

http_headers() {
    log "HTTP Security Headers Check"
    curl -sI "$TARGET_URL" > "$RESULTS_DIR/vulns/headers.txt"
    echo "Checking for security headers..."
    grep -i "strict-transport-security\|x-frame-options\|x-content-type-options\|content-security-policy" "$RESULTS_DIR/vulns/headers.txt" || echo "Missing security headers!"
    success "Headers saved"
}

cors_check() {
    log "CORS Configuration Check"
    curl -s -H "Origin: https://evil.com" "$TARGET_URL" -I > "$RESULTS_DIR/vulns/cors.txt"
    grep -i "access-control-allow-origin" "$RESULTS_DIR/vulns/cors.txt"
    success "CORS check saved"
}

crawl_discover() {
    log "Crawling and Discovery"
    echo -e "${YELLOW}[!] Basic crawl with curl${NC}"
    curl -s "$TARGET_URL" | grep -oE 'href="[^"]+"' | sed 's/href="//g' | sed 's/"$//g' > "$RESULTS_DIR/vulns/links.txt"
    success "Found $(wc -l < "$RESULTS_DIR/vulns/links.txt") links"
}

vuln_loop
