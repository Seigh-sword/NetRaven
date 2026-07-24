#!/bin/bash

# Vulnerability Scanning Module

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

vuln_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Vulnerability Scanning ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Nuclei - Automated Vulnerability Scanner"
        echo -e "${CYAN}[2]${NC}  Nikto Web Vulnerability Scanner"
        echo -e "${CYAN}[3]${NC}  SQL Injection Scanner (SQLMap)"
        echo -e "${CYAN}[4]${NC}  XSS Scanner (XSStrike / Manual)"
        echo -e "${CYAN}[5]${NC}  Directory/File Bruteforce (Gobuster/FFUF)"
        echo -e "${CYAN}[6]${NC}  Subdomain Takeover Check"
        echo -e "${CYAN}[7]${NC}  WAF Detection & Bypass Testing"
        echo -e "${CYAN}[8]${NC}  SSL/TLS Security Check"
        echo -e "${CYAN}[9]${NC}  HTTP Security Headers Audit"
        echo -e "${CYAN}[10]${NC} CORS Misconfiguration Check"
        echo -e "${CYAN}[11]${NC} Clickjacking Test (X-Frame-Options)"
        echo -e "${CYAN}[12]${NC} Open Redirect Tester"
        echo -e "${CYAN}[13]${NC} CRLF Injection Tester"
        echo -e "${CYAN}[14]${NC} Full Vulnerability Scan (All)"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) nuclei_scan ;;
            2) nikto_scan ;;
            3) sqli_scan ;;
            4) xss_scan ;;
            5) dir_brute ;;
            6) subdomain_takeover ;;
            7) waf_detect ;;
            8) ssl_check ;;
            9) http_headers ;;
            10) cors_check ;;
            11) clickjack_test ;;
            12) open_redirect ;;
            13) crlf_test ;;
            14) full_vuln_scan ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

nuclei_scan() {
    log "Running Nuclei Vulnerability Scanner"
    nuclei -u "$TARGET_URL" -o "$RESULTS_DIR/vulns/nuclei.txt" -severity critical,high,medium 2>/dev/null
    success "Nuclei scan saved"
    cat "$RESULTS_DIR/vulns/nuclei.txt"
}

nikto_scan() {
    log "Running Nikto Web Scanner"
    nikto -h "$TARGET_URL" -o "$RESULTS_DIR/vulns/nikto.txt" -Tuning x 2>&1
    success "Nikto scan saved"
    cat "$RESULTS_DIR/vulns/nikto.txt"
}

sqli_scan() {
    log "SQL Injection Scanner (SQLMap)"
    read -p "Parameter to test (e.g., id): " param
    read -p "Full URL with placeholder (e.g., $TARGET_URL/page.php?id=1): " url
    echo -e "${YELLOW}[*] Starting SQLMap with tamper scripts...${NC}"
    sqlmap -u "$url" --batch --risk=3 --level=5 --tamper=space2comment,between,randomcase --output-dir="$RESULTS_DIR/vulns/sqlmap" 2>&1 | tee "$RESULTS_DIR/vulns/sqlmap.log"
    success "SQLMap results saved"
}

xss_scan() {
    log "XSS Scanner"
    read -p "Parameter to test: " param
    read -p "Full URL with placeholder: " url
    payloads=(
        "<script>alert(1)</script>"
        "<img src=x onerror=alert(1)>"
        "\"><script>alert(1)</script>"
        "javascript:alert(1)"
        "<svg onload=alert(1)>"
        "'\"><script>alert(1)</script>"
    )
    echo -e "${YELLOW}[*] Testing XSS payloads...${NC}"
    for payload in "${payloads[@]}"; do
        test_url="${url/$param/$payload}"
        response=$(curl -s "$test_url")
        if echo "$response" | grep -q "$payload"; then
            echo -e "${GREEN}[+] Possible XSS: $payload${NC}"
            echo "URL: $test_url" >> "$RESULTS_DIR/vulns/xss.txt"
        fi
    done
    success "XSS scan saved"
}

dir_brute() {
    log "Directory Bruteforce"
    echo -e "${CYAN}[1]${NC} Gobuster"
    echo -e "${CYAN}[2]${NC} FFUF"
    echo -e "${CYAN}[3]${NC} Dirb"
    read -p "Select tool: " tool
    read -p "Wordlist path (default: /usr/share/wordlists/dirb/common.txt): " wordlist
    wordlist=${wordlist:-/usr/share/wordlists/dirb/common.txt}
    case $tool in
        1)
            gobuster dir -u "$TARGET_URL" -w "$wordlist" -o "$RESULTS_DIR/vulns/gobuster.txt" 2>/dev/null
            ;;
        2)
            ffuf -u "$TARGET_URL/FUZZ" -w "$wordlist" -o "$RESULTS_DIR/vulns/ffuf.json" -of json 2>/dev/null
            ;;
        3)
            dirb "$TARGET_URL" "$wordlist" -o "$RESULTS_DIR/vulns/dirb.txt" 2>/dev/null
            ;;
        *)
            gobuster dir -u "$TARGET_URL" -w "$wordlist" -o "$RESULTS_DIR/vulns/gobuster.txt" 2>/dev/null
            ;;
    esac
    success "Directory scan saved"
}

subdomain_takeover() {
    log "Subdomain Takeover Check"
    if [ -f "$RESULTS_DIR/recon/all_subdomains.txt" ]; then
        echo -e "${YELLOW}[*] Checking for subdomain takeover vulnerabilities...${NC}"
        while read -r sub; do
            result=$(curl -s -I "http://$sub" -H "Host: $sub" 2>/dev/null | grep -i "server\|x-powered-by\|x-aspnet\|nginx\|apache")
            if [ -n "$result" ]; then
                echo -e "${GREEN}[+] $sub: $result${NC}"
            fi
        done < "$RESULTS_DIR/recon/all_subdomains.txt"
        success "Subdomain takeover check saved"
    else
        warning "Run subdomain enumeration first"
    fi
}

waf_detect() {
    log "WAF Detection"
    wafw00f "$TARGET_URL" > "$RESULTS_DIR/vulns/waf.txt" 2>&1
    success "WAF detection saved"
    cat "$RESULTS_DIR/vulns/waf.txt"
}

ssl_check() {
    log "SSL/TLS Security Check"
    {
        echo "=== Nmap SSL Ciphers ==="
        nmap --script ssl-enum-ciphers -p 443 "$TARGET_DOMAIN"
        echo
        echo "=== SSL Certificate Check ==="
        echo | openssl s_client -connect "$TARGET_DOMAIN:443" -servername "$TARGET_DOMAIN" 2>/dev/null | openssl x509 -noout -text
        echo
        echo "=== Heartbleed Check ==="
        nmap -p 443 --script ssl-heartbleed "$TARGET_DOMAIN"
    } > "$RESULTS_DIR/vulns/ssl_check.txt"
    success "SSL check saved"
}

http_headers() {
    log "HTTP Security Headers Audit"
    curl -sI "$TARGET_URL" > "$RESULTS_DIR/vulns/headers.txt"
    {
        echo "=== All Headers ==="
        cat "$RESULTS_DIR/vulns/headers.txt"
        echo
        echo "=== Missing Security Headers ==="
        grep -qi "strict-transport-security" "$RESULTS_DIR/vulns/headers.txt" || echo "[-] HSTS Missing"
        grep -qi "x-frame-options" "$RESULTS_DIR/vulns/headers.txt" || echo "[-] X-Frame-Options Missing"
        grep -qi "x-content-type-options" "$RESULTS_DIR/vulns/headers.txt" || echo "[-] X-Content-Type-Options Missing"
        grep -qi "content-security-policy" "$RESULTS_DIR/vulns/headers.txt" || echo "[-] CSP Missing"
        grep -qi "x-xss-protection" "$RESULTS_DIR/vulns/headers.txt" || echo "[-] X-XSS-Protection Missing"
        grep -qi "referrer-policy" "$RESULTS_DIR/vulns/headers.txt" || echo "[-] Referrer-Policy Missing"
        grep -qi "permissions-policy" "$RESULTS_DIR/vulns/headers.txt" || echo "[-] Permissions-Policy Missing"
        grep -qi "server" "$RESULTS_DIR/vulns/headers.txt" && echo "[-] Server header leaks info"
    } > "$RESULTS_DIR/vulns/headers_audit.txt"
    success "Headers audit saved"
}

cors_check() {
    log "CORS Misconfiguration Check"
    {
        echo "=== Testing with malicious origin ==="
        curl -s -H "Origin: https://evil.com" "$TARGET_URL" -I
        echo
        echo "=== Testing with null origin ==="
        curl -s -H "Origin: null" "$TARGET_URL" -I
        echo
        echo "=== Testing with reflected origin ==="
        curl -s -H "Origin: $TARGET_URL" "$TARGET_URL" -I
    } > "$RESULTS_DIR/vulns/cors.txt"
    success "CORS check saved"
    grep -i "access-control-allow-origin" "$RESULTS_DIR/vulns/cors.txt"
}

clickjack_test() {
    log "Clickjacking Test (X-Frame-Options)"
    cat > "$RESULTS_DIR/vulns/clickjack_test.html" <<EOF
<!DOCTYPE html>
<html>
<head><title>Clickjack Test</title></head>
<body>
<iframe src="$TARGET_URL" width="800" height="600" style="opacity:0.5"></iframe>
<p>If you can see the target site above, it is vulnerable to clickjacking.</p>
</body>
</html>
EOF
    success "Clickjack test HTML saved to $RESULTS_DIR/vulns/clickjack_test.html"
}

open_redirect() {
    log "Open Redirect Tester"
    read -p "Parameter to test (e.g., url, redirect, next): " param
    read -p "Base URL: " url
    payloads=(
        "https://evil.com"
        "//evil.com"
        "http://evil.com"
        "evil.com"
        "/\\evil.com"
    )
    for payload in "${payloads[@]}"; do
        test_url="${url/$param/$payload}"
        code=$(curl -s -o /dev/null -w "%{redirect_url}" "$test_url" 2>/dev/null)
        if echo "$code" | grep -qi "evil.com"; then
            echo -e "${GREEN}[+] Open Redirect: $test_url -> $code${NC}"
        fi
    done | tee "$RESULTS_DIR/vulns/open_redirect.txt"
    success "Open redirect test saved"
}

crlf_test() {
    log "CRLF Injection Tester"
    read -p "Parameter to test: " param
    read -p "Base URL: " url
    payload="%0d%0aSet-Cookie:injected=true"
    test_url="${url/$param/$payload}"
    response=$(curl -s -D - "$test_url" 2>/dev/null)
    if echo "$response" | grep -qi "injected=true"; then
        echo -e "${GREEN}[+] CRLF Injection possible!${NC}"
    else
        echo -e "${YELLOW}[-] No CRLF injection detected${NC}"
    fi
}

full_vuln_scan() {
    log "Running Full Vulnerability Scan..."
    nuclei_scan
    nikto_scan
    sqli_scan
    xss_scan
    dir_brute
    waf_detect
    ssl_check
    http_headers
    cors_check
    clickjack_test
    success "Full vulnerability scan complete"
}

vuln_menu
