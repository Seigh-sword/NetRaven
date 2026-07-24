#!/bin/bash

# Network Utilities Module Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

network_loop() {
    while true; do
        clear
        echo -e "${CYAN}=== Network Utilities ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC} Traceroute"
        echo -e "${CYAN}[2]${NC} IP Information"
        echo -e "${CYAN}[3]${NC} Reverse DNS Lookup"
        echo -e "${CYAN}[4]${NC} ASN Lookup"
        echo -e "${CYAN}[5]${NC} GeoIP Lookup"
        echo -e "${CYAN}[6]${NC} Network Range Scan"
        echo -e "${CYAN}[7]${NC} Netcat Connection Test"
        echo -e "${CYAN}[8]${NC} SSL Certificate Info"
        echo -e "${CYAN}[9]${NC} HTTP Response Analysis"
        echo -e "${CYAN}[0]${NC} Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) traceroute_test ;;
            2) ip_info ;;
            3) reverse_dns ;;
            4) asn_lookup ;;
            5) geoip_lookup ;;
            6) net_range_scan ;;
            7) netcat_test ;;
            8) ssl_info ;;
            9) http_analysis ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

traceroute_test() {
    log "Traceroute to $TARGET_DOMAIN"
    traceroute "$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/traceroute.txt"
}

ip_info() {
    log "IP Information"
    host "$TARGET_DOMAIN" > "$RESULTS_DIR/monitor/ip_info.txt"
    cat "$RESULTS_DIR/monitor/ip_info.txt"
}

reverse_dns() {
    log "Reverse DNS Lookup"
    read -p "Enter IP: " ip
    dig -x "$ip" +short
}

asn_lookup() {
    log "ASN Lookup"
    whois "$TARGET_DOMAIN" | grep -i "origin\|asn" | head -n 5
}

geoip_lookup() {
    log "GeoIP Lookup"
    curl -s "https://ipinfo.io/$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/geoip.txt"
}

net_range_scan() {
    log "Network Range Scanner"
    echo -e "${YELLOW}[!] This will scan the network range${NC}"
    masscan -p1-1000 "$TARGET_DOMAIN/24" --rate=1000 -oG "$RESULTS_DIR/monitor/masscan.txt"
    success "Masscan results saved"
}

netcat_test() {
    log "Netcat Connection Test"
    read -p "Port: " port
    nc -zv "$TARGET_DOMAIN" "$port"
}

ssl_info() {
    log "SSL Certificate Information"
    echo | openssl s_client -connect "$TARGET_DOMAIN:443" 2>/dev/null | openssl x509 -noout -text | tee "$RESULTS_DIR/monitor/ssl_full.txt"
}

http_analysis() {
    log "HTTP Response Analysis"
    curl -s -D - "$TARGET_URL" -o /dev/null | tee "$RESULTS_DIR/monitor/http_response.txt"
    cat "$RESULTS_DIR/monitor/http_response.txt"
}

network_loop
