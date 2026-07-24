#!/bin/bash

# Reconnaissance Module

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

recon_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Reconnaissance & Information Gathering ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  WHOIS Lookup"
        echo -e "${CYAN}[2]${NC}  DNS Enumeration (dig + dnsenum)"
        echo -e "${CYAN}[3]${NC}  Subdomain Enumeration (Sublist3r + Amass)"
        echo -e "${CYAN}[4]${NC}  Port Scan (Nmap Quick)"
        echo -e "${CYAN}[5]${NC}  Full Port Scan + Service Detection"
        echo -e "${CYAN}[6]${NC}  OS & Service Fingerprinting (Nmap scripts)"
        echo -e "${CYAN}[7]${NC}  Email Harvesting (theHarvester)"
        echo -e "${CYAN}[8]${NC}  Technology Fingerprinting (WhatWeb + Wappalyzer)"
        echo -e "${CYAN}[9]${NC}  WAF Detection (wafw00f)"
        echo -e "${CYAN}[10]${NC} SSL/TLS Certificate Analysis"
        echo -e "${CYAN}[11]${NC} HTTP Headers & Security Analysis"
        echo -e "${CYAN}[12]${NC} Robots.txt, Sitemap & Directory Listing"
        echo -e "${CYAN}[13]${NC} SMB Enumeration (enum4linux)"
        echo -e "${CYAN}[14]${NC} SNMP Enumeration"
        echo -e "${CYAN}[15]${NC} All-in-One Recon"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) whois_lookup ;;
            2) dns_enum ;;
            3) subdomain_enum ;;
            4) nmap_quick ;;
            5) nmap_full ;;
            6) nmap_scripts ;;
            7) email_harvest ;;
            8) tech_fingerprint ;;
            9) waf_detect ;;
            10) ssl_analysis ;;
            11) http_headers ;;
            12) robots_sitemap ;;
            13) smb_enum ;;
            14) snmp_enum ;;
            15) all_recon ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

whois_lookup() {
    log "WHOIS Lookup for $TARGET_DOMAIN"
    whois "$TARGET_DOMAIN" > "$RESULTS_DIR/recon/whois.txt" 2>&1
    success "Saved to $RESULTS_DIR/recon/whois.txt"
    cat "$RESULTS_DIR/recon/whois.txt" | head -n 40
}

dns_enum() {
    log "DNS Enumeration"
    {
        echo "=== A Records ==="
        dig "$TARGET_DOMAIN" A +short
        echo "=== AAAA Records ==="
        dig "$TARGET_DOMAIN" AAAA +short
        echo "=== MX Records ==="
        dig "$TARGET_DOMAIN" MX +short
        echo "=== TXT Records ==="
        dig "$TARGET_DOMAIN" TXT +short
        echo "=== NS Records ==="
        dig "$TARGET_DOMAIN" NS +short
        echo "=== SPF Record ==="
        dig "$TARGET_DOMAIN" TXT +short | grep "v=spf"
        echo "=== DMARC Record ==="
        dig "_dmarc.$TARGET_DOMAIN" TXT +short
        echo "=== DKIM Record ==="
        dig "selector1._domainkey.$TARGET_DOMAIN" TXT +short
        echo "=== Reverse DNS ==="
        dig -x $(dig +short "$TARGET_DOMAIN" A | head -n1) +short
        echo "=== DNS Zone Transfer Attempt ==="
        for ns in $(dig +short "$TARGET_DOMAIN" NS); do
            echo "Trying $ns"
            dig @"$ns" "$TARGET_DOMAIN" AXFR +short 2>/dev/null
        done
    } > "$RESULTS_DIR/recon/dns.txt"
    success "Saved to $RESULTS_DIR/recon/dns.txt"
    cat "$RESULTS_DIR/recon/dns.txt"
}

subdomain_enum() {
    log "Subdomain Enumeration"
    mkdir -p "$RESULTS_DIR/recon/subdomains"
    
    echo -e "${YELLOW}[*] Running Sublist3r...${NC}"
    sublist3r -d "$TARGET_DOMAIN" -o "$RESULTS_DIR/recon/subdomains/sublist3r.txt" 2>/dev/null || echo "Sublist3r failed or not installed"
    
    echo -e "${YELLOW}[*] Running Amass...${NC}"
    amass enum -d "$TARGET_DOMAIN" -o "$RESULTS_DIR/recon/subdomains/amass.txt" 2>/dev/null || echo "Amass failed or not installed"
    
    echo -e "${YELLOW}[*] Running Subfinder...${NC}"
    subfinder -d "$TARGET_DOMAIN" -o "$RESULTS_DIR/recon/subdomains/subfinder.txt" 2>/dev/null || echo "Subfinder failed or not installed"
    
    echo -e "${YELLOW}[*] Certificate Transparency search...${NC}"
    curl -s "https://crt.sh/?q=%.$TARGET_DOMAIN&output=json" | grep -o '"name_value":"[^"]*"' | sed 's/"name_value":"//g' | sed 's/"//g' | sort -u > "$RESULTS_DIR/recon/subdomains/crtsh.txt" 2>/dev/null
    
    cat "$RESULTS_DIR/recon/subdomains/"*.txt 2>/dev/null | sort -u > "$RESULTS_DIR/recon/all_subdomains.txt"
    local count=$(wc -l < "$RESULTS_DIR/recon/all_subdomains.txt")
    success "Found $count unique subdomains"
    cat "$RESULTS_DIR/recon/all_subdomains.txt"
}

nmap_quick() {
    log "Quick Nmap Scan"
    nmap -T4 -F --open "$TARGET_DOMAIN" -oN "$RESULTS_DIR/recon/nmap_quick.txt"
    success "Saved to $RESULTS_DIR/recon/nmap_quick.txt"
    cat "$RESULTS_DIR/recon/nmap_quick.txt"
}

nmap_full() {
    log "Full Nmap Port Scan"
    nmap -p- -T4 --open --min-rate=1000 "$TARGET_DOMAIN" -oN "$RESULTS_DIR/recon/nmap_full.txt"
    success "Saved to $RESULTS_DIR/recon/nmap_full.txt"
    cat "$RESULTS_DIR/recon/nmap_full.txt"
}

nmap_scripts() {
    log "Nmap Service Detection + Default Scripts"
    nmap -sV -sC -T4 "$TARGET_DOMAIN" -oA "$RESULTS_DIR/recon/nmap_scripts"
    success "Saved to $RESULTS_DIR/recon/nmap_scripts.*"
    cat "$RESULTS_DIR/recon/nmap_scripts.nmap"
}

email_harvest() {
    log "Email Harvesting with theHarvester"
    read -p "Limit results (default 500): " limit
    limit=${limit:-500}
    theHarvester -d "$TARGET_DOMAIN" -l "$limit" -b all > "$RESULTS_DIR/recon/emails.txt" 2>&1
    success "Emails saved to $RESULTS_DIR/recon/emails.txt"
    grep -i "@$TARGET_DOMAIN" "$RESULTS_DIR/recon/emails.txt" || cat "$RESULTS_DIR/recon/emails.txt"
}

tech_fingerprint() {
    log "Technology Fingerprinting"
    {
        echo "=== WhatWeb ==="
        whatweb -v "$TARGET_URL" 2>/dev/null || echo "WhatWeb not installed"
        echo
        echo "=== Wappalyzer (curl + regex) ==="
        curl -s "$TARGET_URL" | grep -oE '(wordpress|joomla|drupal|react|angular|vue|jquery|bootstrap|laravel|django|flask|rails|express|asp\.net|php|java|python|ruby|go|node\.js)' | sort -u || echo "No frameworks detected"
        echo
        echo "=== Server Headers ==="
        curl -sI "$TARGET_URL" | grep -i "server\|x-powered-by\|x-aspnet|x-generator"
    } > "$RESULTS_DIR/recon/tech.txt"
    success "Technology fingerprint saved"
    cat "$RESULTS_DIR/recon/tech.txt"
}

waf_detect() {
    log "WAF Detection"
    wafw00f "$TARGET_URL" > "$RESULTS_DIR/recon/waf.txt" 2>&1
    success "WAF detection saved"
    cat "$RESULTS_DIR/recon/waf.txt"
}

ssl_analysis() {
    log "SSL/TLS Certificate Analysis"
    {
        echo "=== Certificate Details ==="
        echo | openssl s_client -connect "$TARGET_DOMAIN:443" -servername "$TARGET_DOMAIN" 2>/dev/null | openssl x509 -noout -text
        echo
        echo "=== Certificate Dates ==="
        echo | openssl s_client -connect "$TARGET_DOMAIN:443" -servername "$TARGET_DOMAIN" 2>/dev/null | openssl x509 -noout -dates
        echo
        echo "=== SSL Labs Check ==="
        echo "Manual check: https://www.ssllabs.com/ssltest/analyze.html?d=$TARGET_DOMAIN"
        echo
        echo "=== Nmap SSL Ciphers ==="
        nmap --script ssl-enum-ciphers -p 443 "$TARGET_DOMAIN" 2>/dev/null
    } > "$RESULTS_DIR/recon/ssl.txt"
    success "SSL analysis saved"
    cat "$RESULTS_DIR/recon/ssl.txt"
}

http_headers() {
    log "HTTP Headers & Security Analysis"
    curl -s -D - "$TARGET_URL" -o /dev/null > "$RESULTS_DIR/recon/headers.txt" 2>&1
    {
        echo "=== All Headers ==="
        cat "$RESULTS_DIR/recon/headers.txt"
        echo
        echo "=== Security Headers Check ==="
        grep -i "strict-transport-security" "$RESULTS_DIR/recon/headers.txt" && echo "[+] HSTS Present" || echo "[-] HSTS Missing"
        grep -i "x-frame-options" "$RESULTS_DIR/recon/headers.txt" && echo "[+] X-Frame-Options Present" || echo "[-] X-Frame-Options Missing"
        grep -i "x-content-type-options" "$RESULTS_DIR/recon/headers.txt" && echo "[+] X-Content-Type-Options Present" || echo "[-] X-Content-Type-Options Missing"
        grep -i "content-security-policy" "$RESULTS_DIR/recon/headers.txt" && echo "[+] CSP Present" || echo "[-] CSP Missing"
        grep -i "x-xss-protection" "$RESULTS_DIR/recon/headers.txt" && echo "[+] X-XSS-Protection Present" || echo "[-] X-XSS-Protection Missing"
        grep -i "referrer-policy" "$RESULTS_DIR/recon/headers.txt" && echo "[+] Referrer-Policy Present" || echo "[-] Referrer-Policy Missing"
        grep -i "permissions-policy" "$RESULTS_DIR/recon/headers.txt" && echo "[+] Permissions-Policy Present" || echo "[-] Permissions-Policy Missing"
    } > "$RESULTS_DIR/recon/security_headers.txt"
    success "Headers saved"
    cat "$RESULTS_DIR/recon/security_headers.txt"
}

robots_sitemap() {
    log "Robots.txt, Sitemap & Directory Listing"
    {
        echo "=== Robots.txt ==="
        curl -s "$TARGET_URL/robots.txt"
        echo
        echo "=== Sitemap.xml ==="
        curl -s "$TARGET_URL/sitemap.xml"
        echo
        echo "=== Sitemap Index ==="
        curl -s "$TARGET_URL/sitemap_index.xml"
        echo
        echo "=== .git/HEAD Check ==="
        curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL/.git/HEAD"
        echo
        echo "=== Directory Listing Check ==="
        curl -s "$TARGET_URL/" | grep -i "index of" && echo "Directory listing enabled!" || echo "No directory listing detected"
    } > "$RESULTS_DIR/recon/robots_sitemap.txt"
    success "Saved"
    cat "$RESULTS_DIR/recon/robots_sitemap.txt"
}

smb_enum() {
    log "SMB Enumeration"
    read -p "Target IP for SMB: " smb_ip
    if [ -n "$smb_ip" ]; then
        echo "=== enum4linux ===" > "$RESULTS_DIR/recon/smb.txt"
        enum4linux -a "$smb_ip" >> "$RESULTS_DIR/recon/smb.txt" 2>&1
        echo "=== smbclient ===" >> "$RESULTS_DIR/recon/smb.txt"
        smbclient -L "//$smb_ip" -N >> "$RESULTS_DIR/recon/smb.txt" 2>&1
        success "SMB enumeration saved"
    else
        warning "No IP provided"
    fi
}

snmp_enum() {
    log "SNMP Enumeration"
    read -p "Target IP for SNMP: " snmp_ip
    read -p "Community string (default: public): " community
    community=${community:-public}
    if [ -n "$snmp_ip" ]; then
        echo "=== SNMP Walk ===" > "$RESULTS_DIR/recon/snmp.txt"
        snmpwalk -c "$community" -v1 "$snmp_ip" >> "$RESULTS_DIR/recon/snmp.txt" 2>&1
        echo "=== onesixtyone ===" >> "$RESULTS_DIR/recon/snmp.txt"
        onesixtyone -c /usr/share/doc/onesixtyone/dict.txt "$snmp_ip" >> "$RESULTS_DIR/recon/snmp.txt" 2>&1
        success "SNMP enumeration saved"
    else
        warning "No IP provided"
    fi
}

all_recon() {
    log "Running All Reconnaissance..."
    whois_lookup
    dns_enum
    subdomain_enum
    nmap_quick
    nmap_scripts
    email_harvest
    tech_fingerprint
    waf_detect
    ssl_analysis
    http_headers
    robots_sitemap
    success "Full reconnaissance complete"
}

recon_menu
