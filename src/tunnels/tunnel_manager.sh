#!/bin/bash

# NetRaven Cloudflare Tunnel Manager
# Creates .trycloudflare.com tunnels for hosting test sites

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

TUNNEL_DIR="$HOME/.netraven/tunnels"
mkdir -p "$TUNNEL_DIR"

tunnel_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Cloudflare Tunnel Manager ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Create Quick Tunnel (cloudflared)"
        echo -e "${CYAN}[2]${NC}  Create Tunnel for Local PHP Site"
        echo -e "${CYAN}[3]${NC}  Create Tunnel for Local HTML Site"
        echo -e "${CYAN}[4]${NC}  List Active Tunnels"
        echo -e "${CYAN}[5]${NC}  Stop Tunnel"
        echo -e "${CYAN}[6]${NC}  Stop All Tunnels"
        echo -e "${CYAN}[7]${NC}  Tunnel Status Dashboard"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) create_quick_tunnel ;;
            2) create_php_tunnel ;;
            3) create_html_tunnel ;;
            4) list_tunnels ;;
            5) stop_tunnel ;;
            6) stop_all_tunnels ;;
            7) tunnel_dashboard ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

create_quick_tunnel() {
    log "Creating quick Cloudflare tunnel..."
    read -p "Local port to expose (default: 8080): " port
    port=${port:-8080}

    if ! command -v cloudflared &> /dev/null; then
        echo -e "${YELLOW}[!] cloudflared not installed. Installing...${NC}"
        apt-get install -y cloudflared 2>/dev/null || wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O /usr/local/bin/cloudflared && chmod +x /usr/local/bin/cloudflared
    fi

    local tunnel_id="tunnel_$(date +%s)"
    local log_file="$TUNNEL_DIR/${tunnel_id}.log"

    cloudflared tunnel --url "http://localhost:$port" > "$log_file" 2>&1 &
    local pid=$!
    echo "$pid" > "$TUNNEL_DIR/${tunnel_id}.pid"

    sleep 4

    if grep -q "trycloudflare" "$log_file" 2>/dev/null; then
        local public_url=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' "$log_file" | head -n1)
        echo "$public_url" > "$TUNNEL_DIR/${tunnel_id}.url"
        echo "$port" > "$TUNNEL_DIR/${tunnel_id}.port"
        echo -e "${GREEN}[+] Tunnel created: $public_url${NC}"
        echo -e "${GREEN}[+] Local port: $port${NC}"
        echo -e "${YELLOW}[!] Tunnel ID: $tunnel_id${NC}"
        echo "$tunnel_id" >> "$TUNNEL_DIR/active_tunnels"
    else
        echo -e "${RED}[!] Tunnel creation failed. Check log: $log_file${NC}"
    fi
}

create_php_tunnel() {
    log "Creating tunnel for PHP site"
    read -p "Local PHP site directory: " site_dir
    read -p "Port (default: 8080): " port
    port=${port:-8080}

    if [ -z "$site_dir" ]; then
        site_dir="$HOME/.netraven/sites"
        mkdir -p "$site_dir"
    fi

    if [ ! -d "$site_dir" ]; then
        echo -e "${RED}[!] Directory not found: $site_dir${NC}"
        return
    fi

    if ! command -v php &> /dev/null; then
        echo -e "${YELLOW}[!] PHP not installed. Installing...${NC}"
        apt-get install -y php apache2-utils 2>/dev/null
    fi

    php -S "localhost:$port" -t "$site_dir" > "$TUNNEL_DIR/php_server_${port}.log" 2>&1 &
    local php_pid=$!
    echo "$php_pid" > "$TUNNEL_DIR/php_${port}.pid"

    sleep 2

    create_quick_tunnel_helper "$port"
}

create_html_tunnel() {
    log "Creating tunnel for HTML site"
    read -p "Local HTML site directory: " site_dir
    read -p "Port (default: 8080): " port
    port=${port:-8080}

    if [ -z "$site_dir" ]; then
        site_dir="$HOME/.netraven/sites"
        mkdir -p "$site_dir"
    fi

    if [ ! -d "$site_dir" ]; then
        echo -e "${RED}[!] Directory not found: $site_dir${NC}"
        return
    fi

    python3 -m http.server "$port" --directory "$site_dir" > "$TUNNEL_DIR/http_server_${port}.log" 2>&1 &
    local http_pid=$!
    echo "$http_pid" > "$TUNNEL_DIR/http_${port}.pid"

    sleep 2

    create_quick_tunnel_helper "$port"
}

create_quick_tunnel_helper() {
    local port=$1
    if ! command -v cloudflared &> /dev/null; then
        echo -e "${RED}[!] cloudflared not installed${NC}"
        return
    fi

    local tunnel_id="tunnel_$(date +%s)"
    local log_file="$TUNNEL_DIR/${tunnel_id}.log"

    cloudflared tunnel --url "http://localhost:$port" > "$log_file" 2>&1 &
    local cf_pid=$!
    echo "$cf_pid" > "$TUNNEL_DIR/${tunnel_id}.pid"

    sleep 4

    if grep -q "trycloudflare" "$log_file" 2>/dev/null; then
        local public_url=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' "$log_file" | head -n1)
        echo "$public_url" > "$TUNNEL_DIR/${tunnel_id}.url"
        echo "$port" > "$TUNNEL_DIR/${tunnel_id}.port"
        echo -e "${GREEN}[+] Tunnel created: $public_url${NC}"
        echo "$tunnel_id" >> "$TUNNEL_DIR/active_tunnels"
    else
        echo -e "${RED}[!] Tunnel creation failed${NC}"
    fi
}

list_tunnels() {
    log "Active Tunnels"
    if [ -f "$TUNNEL_DIR/active_tunnels" ]; then
        while read -r tunnel_id; do
            if [ -f "$TUNNEL_DIR/${tunnel_id}.url" ]; then
                local url=$(cat "$TUNNEL_DIR/${tunnel_id}.url")
                local port=$(cat "$TUNNEL_DIR/${tunnel_id}.port" 2>/dev/null)
                local pid=$(cat "$TUNNEL_DIR/${tunnel_id}.pid" 2>/dev/null)
                if kill -0 "$pid" 2>/dev/null; then
                    echo -e "${GREEN}[ACTIVE]${NC} $tunnel_id -> $url (port $port, PID $pid)"
                else
                    echo -e "${RED}[STOPPED]${NC} $tunnel_id -> $url (port $port)"
                fi
            fi
        done < "$TUNNEL_DIR/active_tunnels"
    else
        echo -e "${YELLOW}[!] No active tunnels${NC}"
    fi
}

stop_tunnel() {
    read -p "Enter tunnel ID to stop: " tunnel_id
    if [ -f "$TUNNEL_DIR/${tunnel_id}.pid" ]; then
        local pid=$(cat "$TUNNEL_DIR/${tunnel_id}.pid")
        kill "$pid" 2>/dev/null
        pkill -f "cloudflared.*${tunnel_id}" 2>/dev/null
        rm -f "$TUNNEL_DIR/${tunnel_id}.pid" "$TUNNEL_DIR/${tunnel_id}.url" "$TUNNEL_DIR/${tunnel_id}.log"
        sed -i "/^${tunnel_id}$/d" "$TUNNEL_DIR/active_tunnels" 2>/dev/null
        echo -e "${GREEN}[+] Tunnel $tunnel_id stopped${NC}"
    else
        echo -e "${RED}[!] Tunnel not found: $tunnel_id${NC}"
    fi
}

stop_all_tunnels() {
    log "Stopping all tunnels..."
    if [ -f "$TUNNEL_DIR/active_tunnels" ]; then
        while read -r tunnel_id; do
            if [ -f "$TUNNEL_DIR/${tunnel_id}.pid" ]; then
                local pid=$(cat "$TUNNEL_DIR/${tunnel_id}.pid")
                kill "$pid" 2>/dev/null
                pkill -f "cloudflared.*${tunnel_id}" 2>/dev/null
            fi
        done < "$TUNNEL_DIR/active_tunnels"
        > "$TUNNEL_DIR/active_tunnels"
        echo -e "${GREEN}[+] All tunnels stopped${NC}"
    fi
}

tunnel_dashboard() {
    clear
    echo -e "${CYAN}=== Tunnel Dashboard ===${NC}"
    echo
    echo -e "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "Tunnel Directory: $TUNNEL_DIR"
    echo

    local count=0
    if [ -f "$TUNNEL_DIR/active_tunnels" ]; then
        while read -r tunnel_id; do
            if [ -f "$TUNNEL_DIR/${tunnel_id}.url" ]; then
                local url=$(cat "$TUNNEL_DIR/${tunnel_id}.url")
                local port=$(cat "$TUNNEL_DIR/${tunnel_id}.port" 2>/dev/null)
                local pid=$(cat "$TUNNEL_DIR/${tunnel_id}.pid" 2>/dev/null)
                if kill -0 "$pid" 2>/dev/null; then
                    echo -e "${GREEN}[ACTIVE]${NC} $tunnel_id | URL: $url | Port: $port | PID: $pid"
                else
                    echo -e "${RED}[STOPPED]${NC} $tunnel_id | URL: $url | Port: $port"
                fi
                count=$((count + 1))
            fi
        done < "$TUNNEL_DIR/active_tunnels"
    fi

    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}No tunnels active${NC}"
    fi

    echo
    echo -e "Total tunnels: $count"
}

tunnel_menu
