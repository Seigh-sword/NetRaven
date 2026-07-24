#!/bin/bash

# Monitoring Module Menu

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

monitor_loop() {
    while true; do
        clear
        echo -e "${CYAN}=== Monitoring & Analysis Module ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC} Ping Monitoring"
        echo -e "${CYAN}[2]${NC} HTTP Uptime Monitor"
        echo -e "${CYAN}[3]${NC] Port Monitor"
        echo -e "${CYAN}[4]${NC} DNS Monitor"
        echo -e "${CYAN}[5]${NC} SSL Certificate Expiry"
        echo -e "${CYAN}[6]${NC} Traffic Analysis"
        echo -e "${CYAN}[7]${NC} Log Monitoring"
        echo -e "${CYAN}[0]${NC} Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) ping_monitor ;;
            2) http_monitor ;;
            3) port_monitor ;;
            4) dns_monitor ;;
            5) ssl_expiry ;;
            6) traffic_analysis ;;
            7) log_monitor ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

ping_monitor() {
    log "Ping Monitoring"
    read -p "Number of pings: " count
    count=${count:-10}
    ping -c "$count" "$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/ping.txt"
    success "Ping results saved"
}

http_monitor() {
    log "HTTP Uptime Monitor"
    read -p "Interval (seconds): " interval
    interval=${interval:-5}
    read -p "Duration (seconds): " duration
    duration=${duration:-60}
    log "Monitoring $TARGET_URL for $duration seconds..."
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        if curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL" | grep -q "200"; then
            echo -e "${GREEN}[$timestamp] UP${NC}"
        else
            echo -e "${RED}[$timestamp] DOWN${NC}"
        fi
        sleep "$interval"
    done | tee "$RESULTS_DIR/monitor/uptime.txt"
    success "Uptime monitor saved"
}

port_monitor() {
    log "Port Monitor"
    read -p "Ports to monitor (comma separated): " ports
    read -p "Interval (seconds): " interval
    interval=${interval:-10}
    log "Monitoring ports: $ports"
    echo "Monitoring started at $(date)" > "$RESULTS_DIR/monitor/ports.txt"
    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        for port in $(echo "$ports" | tr ',' ' '); do
            if nc -z -w 2 "$TARGET_DOMAIN" "$port" 2>/dev/null; then
                echo "[$timestamp] Port $port: OPEN" | tee -a "$RESULTS_DIR/monitor/ports.txt"
            else
                echo "[$timestamp] Port $port: CLOSED" | tee -a "$RESULTS_DIR/monitor/ports.txt"
            fi
        done
        sleep "$interval"
    done
}

dns_monitor() {
    log "DNS Monitor"
    echo "Monitoring DNS changes..."
    first_dns=$(dig +short "$TARGET_DOMAIN")
    echo "Initial IP: $first_dns" > "$RESULTS_DIR/monitor/dns.txt"
    while true; do
        current_dns=$(dig +short "$TARGET_DOMAIN")
        if [ "$current_dns" != "$first_dns" ]; then
            echo -e "${YELLOW}[!] DNS changed: $current_dns${NC}"
            echo "DNS Changed at $(date): $current_dns" >> "$RESULTS_DIR/monitor/dns.txt"
            first_dns="$current_dns"
        fi
        sleep 30
    done
}

ssl_expiry() {
    log "SSL Certificate Expiry"
    echo | openssl s_client -connect "$TARGET_DOMAIN:443" 2>/dev/null | openssl x509 -noout -dates > "$RESULTS_DIR/monitor/ssl_dates.txt"
    cat "$RESULTS_DIR/monitor/ssl_dates.txt"
}

traffic_analysis() {
    log "Traffic Analysis"
    echo -e "${YELLOW}[!] Requires tcpdump or tshark${NC}"
    read -p "Interface (default: eth0): " iface
    iface=${iface:-eth0}
    echo "Capturing traffic on $iface... Press Ctrl+C to stop"
    tcpdump -i "$iface" -w "$RESULTS_DIR/monitor/traffic.pcap" &
    TCPDUMP_PID=$!
    read -p "Press Enter to stop capture..."
    kill $TCPDUMP_PID 2>/dev/null
    success "Traffic saved to $RESULTS_DIR/monitor/traffic.pcap"
}

log_monitor() {
    log "Log Monitor"
    echo "Monitoring web server logs..."
    echo -e "${YELLOW}[!] This is a placeholder for log monitoring${NC}"
    echo "For Apache: tail -f /var/log/apache2/access.log"
    echo "For Nginx: tail -f /var/log/nginx/access.log"
}

monitor_loop
