#!/bin/bash

# Monitoring Module

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

monitor_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Monitoring & Analysis ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Ping Monitoring"
        echo -e "${CYAN}[2]${NC}  HTTP Uptime Monitor"
        echo -e "${CYAN}[3]${NC}  Port Monitor (Netcat)"
        echo -e "${CYAN}[4]${NC}  DNS Change Monitor"
        echo -e "${CYAN}[5]${NC}  SSL Certificate Expiry Check"
        echo -e "${CYAN}[6]${NC}  HTTP Response Time Monitor"
        echo -e "${CYAN}[7]${NC}  Traceroute Analysis"
        echo -e "${CYAN}[8]${NC}  MTR - Network Diagnostics"
        echo -e "${CYAN}[9]${NC}  TCP Dump Capture"
        echo -e "${CYAN}[10]${NC} Live Log Tailing (Apache/Nginx)"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) ping_monitor ;;
            2) http_monitor ;;
            3) port_monitor ;;
            4) dns_monitor ;;
            5) ssl_expiry ;;
            6) http_time_monitor ;;
            7) traceroute_analysis ;;
            8) mtr_analysis ;;
            9) tcpdump_capture ;;
            10) log_tail ;;
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
    read -p "Interval in seconds: " interval
    interval=${interval:-5}
    read -p "Duration in seconds: " duration
    duration=${duration:-60}
    log "Monitoring $TARGET_URL every $interval seconds for $duration seconds..."
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        code=$(curl -s -o /dev/null -w "%{http_code}" "$TARGET_URL")
        if [ "$code" = "200" ]; then
            echo -e "${GREEN}[$timestamp] UP (HTTP $code)${NC}"
        else
            echo -e "${RED}[$timestamp] DOWN (HTTP $code)${NC}"
        fi
        sleep "$interval"
    done | tee "$RESULTS_DIR/monitor/uptime.txt"
    success "Uptime monitor saved"
}

port_monitor() {
    log "Port Monitor"
    read -p "Ports to monitor (comma separated): " ports
    read -p "Interval in seconds: " interval
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
    log "DNS Change Monitor"
    echo "Monitoring DNS changes... Press Ctrl+C to stop"
    first_dns=$(dig +short "$TARGET_DOMAIN" A | head -n1)
    echo "Initial IP: $first_dns" > "$RESULTS_DIR/monitor/dns.txt"
    while true; do
        current_dns=$(dig +short "$TARGET_DOMAIN" A | head -n1)
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
    echo "=== Certificate Dates ===" > "$RESULTS_DIR/monitor/ssl_dates.txt"
    echo | openssl s_client -connect "$TARGET_DOMAIN:443" -servername "$TARGET_DOMAIN" 2>/dev/null | openssl x509 -noout -dates >> "$RESULTS_DIR/monitor/ssl_dates.txt"
    cat "$RESULTS_DIR/monitor/ssl_dates.txt"
}

http_time_monitor() {
    log "HTTP Response Time Monitor"
    read -p "Interval in seconds: " interval
    interval=${interval:-5}
    read -p "Duration in seconds: " duration
    duration=${duration:-60}
    log "Monitoring response time for $duration seconds..."
    end=$((SECONDS + duration))
    while [ $SECONDS -lt $end ]; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        time=$(curl -s -o /dev/null -w "%{time_total}" "$TARGET_URL")
        size=$(curl -s -o /dev/null -w "%{size_download}" "$TARGET_URL")
        echo "[$timestamp] Response: ${time}s | Size: ${size} bytes" | tee "$RESULTS_DIR/monitor/http_times.txt"
        sleep "$interval"
    done
}

traceroute_analysis() {
    log "Traceroute Analysis"
    traceroute -n "$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/traceroute.txt"
    success "Traceroute saved"
}

mtr_analysis() {
    log "MTR Network Diagnostics"
    mtr -n -r -c 10 "$TARGET_DOMAIN" | tee "$RESULTS_DIR/monitor/mtr.txt"
    success "MTR results saved"
}

tcpdump_capture() {
    log "TCP Dump Capture"
    read -p "Interface (default: eth0): " iface
    iface=${iface:-eth0}
    read -p "Filter (e.g., host $TARGET_DOMAIN, port 80): " filter
    filter=${filter:-"host $TARGET_DOMAIN"}
    echo "Capturing traffic... Press Ctrl+C to stop"
    tcpdump -i "$iface" -w "$RESULTS_DIR/monitor/traffic.pcap" "$filter" 2>&1 | tee "$RESULTS_DIR/monitor/tcpdump.log"
    success "Traffic saved to $RESULTS_DIR/monitor/traffic.pcap"
}

log_tail() {
    log "Live Log Tailing"
    echo -e "${CYAN}[1]${NC} Apache"
    echo -e "${CYAN}[2]${NC} Nginx"
    read -p "Select web server: " ws
    case $ws in
        1) echo "Tailing Apache access log..."; tail -f /var/log/apache2/access.log 2>/dev/null || echo "Apache log not found" ;;
        2) echo "Tailing Nginx access log..."; tail -f /var/log/nginx/access.log 2>/dev/null || echo "Nginx log not found" ;;
        *) warning "Invalid selection" ;;
    esac
}

monitor_menu
