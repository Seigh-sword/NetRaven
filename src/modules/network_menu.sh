#!/bin/bash

# Network Utilities Module

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

network_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Network Utilities ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Traceroute"
        echo -e "${CYAN}[2]${NC}  MTR Network Diagnostics"
        echo -e "${CYAN}[3]${NC}  IP & DNS Information"
        echo -e "${CYAN}[4]${NC}  Reverse DNS Lookup"
        echo -e "${CYAN}[5]${NC}  ASN / BGP Lookup"
        echo -e "${CYAN}[6]${NC}  GeoIP Location Lookup"
        echo -e "${CYAN}[7]${NC}  Masscan - Fast Port Scanner"
        echo -e "${CYAN}[8]${NC}  Netcat Connection Test"
        echo -e "${CYAN}[9]${NC}  SSL Certificate Info"
        echo -e "${CYAN}[10]${NC} HTTP Response Analysis"
        echo -e "${CYAN}[11]${NC} DNS Zone Transfer Attempt"
        echo -e "${CYAN}[12]${NC} Network Range Ping Sweep"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) traceroute_test ;;
            2) mtr_analysis ;;
            3) ip_info ;;
            4) reverse_dns ;;
            5) asn_lookup ;;
            6) geoip_lookup ;;
            7) masscan_scan ;;
            8) netcat_test ;;
            9) ssl_info ;;
            10) http_analysis ;;
            11) dns_zonetransfer ;;
            12) ping_sweep ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

traceroute_test() {
    log "Traceroute to $TARGET_DOMAIN"
    traceroute -n "$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/traceroute.txt"
    success "Traceroute saved"
}

mtr_analysis() {
    log "MTR Network Diagnostics"
    mtr -n -r -c 10 "$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/mtr.txt"
    success "MTR results saved"
}

ip_info() {
    log "IP & DNS Information"
    {
        echo "=== A Records ==="
        dig "$TARGET_DOMAIN" A +short
        echo "=== IP Address ==="
        host "$TARGET_DOMAIN"
        echo "=== WHOIS IP ==="
        whois "$TARGET_DOMAIN" | grep -i "orgname\|netname\|country\|origin" | head -n 10
    } > "$RESULTS_DIR/monitor/ip_info.txt"
    success "IP info saved"
    cat "$RESULTS_DIR/monitor/ip_info.txt"
}

reverse_dns() {
    log "Reverse DNS Lookup"
    read -p "Enter IP: " ip
    dig -x "$ip" +short
}

asn_lookup() {
    log "ASN / BGP Lookup"
    whois "$TARGET_DOMAIN" | grep -i "origin\|asn\|netrange\|cidr" | head -n 10
}

geoip_lookup() {
    log "GeoIP Location Lookup"
    curl -s "https://ipinfo.io/$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/geoip.txt"
    success "GeoIP saved"
}

masscan_scan() {
    log "Masscan - Fast Port Scanner"
    read -p "Port range (e.g., 1-65535): " ports
    ports=${ports:-"1-1000"}
    masscan -p"$ports" "$TARGET_DOMAIN" --rate=1000 -oG "$RESULTS_DIR/monitor/masscan.txt" 2>/dev/null
    success "Masscan results saved"
    cat "$RESULTS_DIR/monitor/masscan.txt"
}

netcat_test() {
    log "Netcat Connection Test"
    read -p "Port: " port
    nc -zv -w 3 "$TARGET_DOMAIN" "$port"
}

ssl_info() {
    log "SSL Certificate Information"
    {
        echo "=== Certificate Text ==="
        echo | openssl s_client -connect "$TARGET_DOMAIN:443" -servername "$TARGET_DOMAIN" 2>/dev/null | openssl x509 -noout -text
        echo
        echo "=== Certificate Dates ==="
        echo | openssl s_client -connect "$TARGET_DOMAIN:443" -servername "$TARGET_DOMAIN" 2>/dev/null | openssl x509 -noout -dates
    } > "$RESULTS_DIR/monitor/ssl_full.txt"
    success "SSL info saved"
}

http_analysis() {
    log "HTTP Response Analysis"
    curl -s -D - "$TARGET_URL" -o /dev/null > "$RESULTS_DIR/monitor/http_response.txt"
    success "HTTP response saved"
    cat "$RESULTS_DIR/monitor/http_response.txt"
}

dns_zonetransfer() {
    log "DNS Zone Transfer Attempt"
    for ns in $(dig +short "$TARGET_DOMAIN" NS); do
        echo "Attempting AXFR on $ns"
        dig @"$ns" "$TARGET_DOMAIN" AXFR | tee -a "$RESULTS_DIR/monitor/zone_transfer.txt"
    done
    success "Zone transfer attempt saved"
}

ping_sweep() {
    log "Network Ping Sweep"
    read -p "Network range (e.g., 192.168.1.0/24): " range
    nmap -sn "$range" -oN "$RESULTS_DIR/monitor/ping_sweep.txt"
    success "Ping sweep saved"
}

network_menu
