#!/bin/bash

# Reconnaissance Module Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

recon_loop() {
    while true; do
        clear
        echo -e "${CYAN}=== Reconnaissance Module ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC} WHOIS Lookup"
        echo -e "${CYAN}[2]${NC} DNS Enumeration"
        echo -e "${CYAN}[3]${NC} Port Scan (Nmap)"
        echo -e "${CYAN}[4]${NC} Service Detection"
        echo -e "${CYAN}[5]${NC} Subdomain Enumeration"
        echo -e "${CYAN}[6]${NC} Technology Fingerprinting"
        echo -e "${CYAN}[7]${NC} SSL/TLS Analysis"
        echo -e "${CYAN}[8]${NC} Headers & Metadata"
        echo -e "${CYAN}[9]${NC} Robots.txt & Sitemap"
        echo -e "${CYAN}[0]${NC} Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) whois_lookup ;;
            2) dns_enum ;;
            3) port_scan ;;
            4) service_detect ;;
            5) subdomain_enum ;;
            6) tech_fingerprint ;;
            7) ssl_analysis ;;
            8) headers_meta ;;
            9) robots_sitemap ;;
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
    cat "$RESULTS_DIR/recon/whois.txt" | head -n 30
}

dns_enum() {
    log "DNS Enumeration"
    {
        echo "=== A Records ==="
        dig "$TARGET_DOMAIN" A +short
        echo "=== MX Records ==="
        dig "$TARGET_DOMAIN" MX +short
        echo "=== TXT Records ==="
        dig "$TARGET_DOMAIN" TXT +short
        echo "=== NS Records ==="
        dig "$TARGET_DOMAIN" NS +short
    } > "$RESULTS_DIR/recon/dns.txt"
    success "Saved to $RESULTS_DIR/recon/dns.txt"
    cat "$RESULTS_DIR/recon/dns.txt"
}

port_scan() {
    log "Port Scan with Nmap"
    read -p "Scan type (quick/full/custom): " scantype
    case $scantype in
        quick) nmap -T4 -F "$TARGET_DOMAIN" -oN "$RESULTS_DIR/recon/nmap_quick.txt" ;;
        full) nmap -p- -T4 "$TARGET_DOMAIN" -oN "$RESULTS_DIR/recon/nmap_full.txt" ;;
        custom)
            read -p "Enter ports: " ports
            nmap -p "$ports" "$TARGET_DOMAIN" -oN "$RESULTS_DIR/recon/nmap_custom.txt"
            ;;
        *) nmap -T4 -F "$TARGET_DOMAIN" -oN "$RESULTS_DIR/recon/nmap_quick.txt" ;;
    esac
    success "Nmap scan complete"
}

service_detect() {
    log "Service Detection"
    nmap -sV -sC "$TARGET_DOMAIN" -oN "$RESULTS_DIR/recon/services.txt"
    success "Service detection saved"
}

subdomain_enum() {
    log "Subdomain Enumeration"
    echo -e "${YELLOW}[!] Checking common subdomains...${NC}"
    for sub in www mail ftp admin test dev staging api cdn docs blog shop app; do
        host="$sub.$TARGET_DOMAIN"
        if dig +short "$host" &>/dev/null; then
            echo -e "${GREEN}[+] Found: $host${NC}"
            echo "$host" >> "$RESULTS_DIR/recon/subdomains.txt"
        fi
    done
    success "Subdomain enumeration saved"
}

tech_fingerprint() {
    log "Technology Fingerprinting"
    whatweb "$TARGET_URL" > "$RESULTS_DIR/recon/tech.txt" 2>&1
    success "Technology fingerprint saved"
    cat "$RESULTS_DIR/recon/tech.txt"
}

ssl_analysis() {
    log "SSL/TLS Analysis"
    echo | openssl s_client -connect "$TARGET_DOMAIN:443" 2>/dev/null | openssl x509 -noout -text > "$RESULTS_DIR/recon/ssl.txt" 2>&1
    success "SSL analysis saved"
}

headers_meta() {
    log "Headers and Metadata"
    curl -s -D - "$TARGET_URL" -o /dev/null > "$RESULTS_DIR/recon/headers.txt" 2>&1
    success "Headers saved"
    cat "$RESULTS_DIR/recon/headers.txt"
}

robots_sitemap() {
    log "Robots.txt and Sitemap"
    {
        echo "=== Robots.txt ==="
        curl -s "$TARGET_URL/robots.txt"
        echo
        echo "=== Sitemap ==="
        curl -s "$TARGET_URL/sitemap.xml"
    } > "$RESULTS_DIR/recon/robots_sitemap.txt"
    success "Saved"
}

recon_loop
