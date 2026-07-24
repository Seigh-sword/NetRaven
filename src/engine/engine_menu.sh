#!/bin/bash

# NetRaven C++ Engine Integration Menu

source src/core/utils.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ENGINE_BIN="src/engine/netraven_engine"

engine_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== C++ Engine Module ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Build Engine (compile C++ code)"
        echo -e "${CYAN}[2]${NC}  Analyze Target (full scan)"
        echo -e "${CYAN}[3]${NC}  Simulate SQL Injection"
        echo -e "${CYAN}[4]${NC}  Simulate XSS Attack"
        echo -e "${CYAN}[5]${NC}  Simulate Command Injection"
        echo -e "${CYAN}[6]${NC}  Simulate LFI Attack"
        echo -e "${CYAN}[7]${NC}  Simulate Brute Force"
        echo -e "${CYAN}[8]${NC}  Simulate Open Redirect"
        echo -e "${CYAN}[9]${NC}  Simulate CSRF Check"
        echo -e "${CYAN}[10]${NC} Simulate Clickjacking"
        echo -e "${CYAN}[11]${NC} Simulate CRLF Injection"
        echo -e "${CYAN}[12]${NC} Run Plugin Attack"
        echo -e "${CYAN}[13]${NC} Generate Engine Report"
        echo -e "${CYAN}[14]${NC} View Exploitability Score"
        echo -e "${CYAN}[15]${NC} Build & Run Full Engine Scan"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) build_engine ;;
            2) engine_analyze ;;
            3) engine_sqli ;;
            4) engine_xss ;;
            5) engine_cmdi ;;
            6) engine_lfi ;;
            7) engine_bruteforce ;;
            8) engine_open_redirect ;;
            9) engine_csrf ;;
            10) engine_clickjacking ;;
            11) engine_crlf ;;
            12) engine_plugin_attack ;;
            13) engine_report ;;
            14) engine_score ;;
            15) engine_full_scan ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

build_engine() {
    log "Building NetRaven C++ Engine..."
    if [ ! -f "src/engine/Makefile" ]; then
        echo -e "${RED}[!] Makefile not found in src/engine/${NC}"
        return
    fi
    cd src/engine && make clean 2>/dev/null && make
    cd ../..
    if [ -f "src/engine/netraven_engine" ]; then
        success "Engine built successfully"
    else
        echo -e "${YELLOW}[!] Build may have failed. Check output above.${NC}"
    fi
}

engine_analyze() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${RED}[!] Cannot run engine. Build failed.${NC}"
        return
    fi
    log "Running full target analysis..."
    "$ENGINE_BIN" analyze "$TARGET_URL" 2>/dev/null || echo -e "${YELLOW}[!] Engine analyze failed. Running fallback...${NC}"
    fallback_analyze
}

engine_sqli() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    read -p "Parameter name (default: id): " param
    param=${param:-id}
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" sqli "$TARGET_URL" "$param" 2>/dev/null || fallback_sqli "$param"
    else
        fallback_sqli "$param"
    fi
}

engine_xss() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    read -p "Parameter name (default: q): " param
    param=${param:-q}
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" xss "$TARGET_URL" "$param" 2>/dev/null || fallback_xss "$param"
    else
        fallback_xss "$param"
    fi
}

engine_cmdi() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    read -p "Parameter name (default: cmd): " param
    param=${param:-cmd}
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" cmdi "$TARGET_URL" "$param" 2>/dev/null || fallback_cmdi "$param"
    else
        fallback_cmdi "$param"
    fi
}

engine_lfi() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    read -p "Parameter name (default: file): " param
    param=${param:-file}
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" lfi "$TARGET_URL" "$param" 2>/dev/null || fallback_lfi "$param"
    else
        fallback_lfi "$param"
    fi
}

engine_bruteforce() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" bruteforce "$TARGET_URL" "http" 2>/dev/null || fallback_bruteforce
    else
        fallback_bruteforce
    fi
}

engine_open_redirect() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    read -p "Parameter name (default: url): " param
    param=${param:-url}
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" open_redirect "$TARGET_URL" "$param" 2>/dev/null || fallback_open_redirect "$param"
    else
        fallback_open_redirect "$param"
    fi
}

engine_csrf() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" csrf "$TARGET_URL" 2>/dev/null || fallback_csrf
    else
        fallback_csrf
    fi
}

engine_clickjacking() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" clickjacking "$TARGET_URL" 2>/dev/null || fallback_clickjacking
    else
        fallback_clickjacking
    fi
}

engine_crlf() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    read -p "Parameter name (default: input): " param
    param=${param:-input}
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" crlf "$TARGET_URL" "$param" 2>/dev/null || fallback_crlf "$param"
    else
        fallback_crlf "$param"
    fi
}

engine_plugin_attack() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    read -p "Plugin name: " plugin_name
    read -p "Target URL: " target_url
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" plugin "$plugin_name" "$target_url" 2>/dev/null || fallback_plugin "$plugin_name" "$target_url"
    else
        fallback_plugin "$plugin_name" "$target_url"
    fi
}

engine_report() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" report "$TARGET_URL" 2>/dev/null | tee "$RESULTS_DIR/engine_report.txt"
    else
        fallback_report
    fi
}

engine_score() {
    if [ ! -f "$ENGINE_BIN" ]; then
        echo -e "${YELLOW}[!] Engine not built. Building now...${NC}"
        build_engine
    fi
    if [ -f "$ENGINE_BIN" ]; then
        "$ENGINE_BIN" score "$TARGET_URL" 2>/dev/null
    else
        fallback_score
    fi
}

engine_full_scan() {
    log "Running full engine scan..."
    build_engine
    engine_analyze
    engine_sqli
    engine_xss
    engine_cmdi
    engine_lfi
    engine_bruteforce
    engine_open_redirect
    engine_csrf
    engine_clickjacking
    engine_crlf
    engine_report
    success "Full engine scan complete"
}

# Fallback bash implementations
fallback_analyze() {
    log "Running fallback analysis..."
    echo -e "${CYAN}[*] WHOIS:${NC}"
    whois "$TARGET_DOMAIN" 2>/dev/null | head -n 20
    echo
    echo -e "${CYAN}[*] DNS:${NC}"
    dig "$TARGET_DOMAIN" A +short 2>/dev/null
    echo
    echo -e "${CYAN}[*] Nmap Quick:${NC}"
    nmap -T4 -F --open "$TARGET_DOMAIN" 2>/dev/null | head -n 20
    echo
    echo -e "${CYAN}[*] Headers:${NC}"
    curl -sI "$TARGET_URL" 2>/dev/null | head -n 15
}

fallback_sqli() {
    local param=${1:-id}
    log "Fallback SQLi test on parameter: $param"
    local test_url="${TARGET_URL}/page.php?${param}=1"
    local payload="' OR '1'='1"
    local test="${test_url/$param=1/$param=$payload}"
    local response=$(curl -s "$test" 2>/dev/null)
    if echo "$response" | grep -qi "sql\|syntax\|error\|mysql"; then
        echo -e "${RED}[+] SQL Injection VULNERABLE!${NC}"
    else
        echo -e "${GREEN}[-] No SQL injection detected${NC}"
    fi
}

fallback_xss() {
    local param=${1:-q}
    log "Fallback XSS test on parameter: $param"
    local test_url="${TARGET_URL}/search.php?${param}=test"
    local payload="<script>alert(1)</script>"
    local test="${test_url/$param=test/$param=$payload}"
    local response=$(curl -s "$test" 2>/dev/null)
    if echo "$response" | grep -q "$payload"; then
        echo -e "${RED}[+] XSS VULNERABLE!${NC}"
    else
        echo -e "${GREEN}[-] No XSS detected${NC}"
    fi
}

fallback_cmdi() {
    local param=${1:-cmd}
    log "Fallback CMDi test on parameter: $param"
    local test_url="${TARGET_URL}/exec.php?${param}=whoami"
    local payload=";id"
    local test="${test_url/$param=whoami/$param=$payload}"
    local response=$(curl -s "$test" 2>/dev/null)
    if echo "$response" | grep -q "uid="; then
        echo -e "${RED}[+] Command Injection VULNERABLE!${NC}"
    else
        echo -e "${GREEN}[-] No command injection detected${NC}"
    fi
}

fallback_lfi() {
    local param=${1:-file}
    log "Fallback LFI test on parameter: $param"
    local test_url="${TARGET_URL}/view.php?${param}=index"
    local payload="../../../../etc/passwd"
    local test="${test_url/$param=index/$param=$payload}"
    local response=$(curl -s "$test" 2>/dev/null)
    if echo "$response" | grep -q "root:x"; then
        echo -e "${RED}[+] LFI VULNERABLE!${NC}"
    else
        echo -e "${GREEN}[-] No LFI detected${NC}"
    fi
}

fallback_bruteforce() {
    log "Fallback brute force simulation"
    echo -e "${YELLOW}[*] Simulating brute force attack...${NC}"
    echo -e "${YELLOW}[*] Target: $TARGET_URL${NC}"
    echo -e "${YELLOW}[*] Security level affects success rate${NC}"
    echo -e "${YELLOW}[*] Use Hydra for real brute force attacks${NC}"
}

fallback_open_redirect() {
    local param=${1:-url}
    log "Fallback Open Redirect test on parameter: $param"
    local test_url="${TARGET_URL}/redirect.php?${param}=home"
    local payload="https://evil.com"
    local test="${test_url/$param=home/$param=$payload}"
    local redirect=$(curl -s -o /dev/null -w "%{redirect_url}" "$test" 2>/dev/null)
    if echo "$redirect" | grep -q "evil.com"; then
        echo -e "${RED}[+] Open Redirect VULNERABLE!${NC}"
    else
        echo -e "${GREEN}[-] No open redirect detected${NC}"
    fi
}

fallback_csrf() {
    log "Fallback CSRF check"
    local response=$(curl -s "$TARGET_URL" 2>/dev/null)
    if echo "$response" | grep -qi "csrf\|token\|_token\|nonce"; then
        echo -e "${GREEN}[+] CSRF protection detected${NC}"
    else
        echo -e "${RED}[+] No CSRF tokens found - potential vulnerability${NC}"
    fi
}

fallback_clickjacking() {
    log "Fallback Clickjacking check"
    local response=$(curl -sI "$TARGET_URL" 2>/dev/null)
    if echo "$response" | grep -qi "x-frame-options\|frame-ancestors"; then
        echo -e "${GREEN}[+] Clickjacking protection detected${NC}"
    else
        echo -e "${RED}[+] Missing X-Frame-Options - vulnerable to clickjacking${NC}"
    fi
}

fallback_crlf() {
    local param=${1:-input}
    log "Fallback CRLF test on parameter: $param"
    local test_url="${TARGET_URL}/redirect.php?${param}=test"
    local payload="%0d%0aSet-Cookie:injected=true"
    local test="${test_url/$param=test/$param=$payload}"
    local response=$(curl -s -D - "$test" 2>/dev/null)
    if echo "$response" | grep -qi "injected=true"; then
        echo -e "${RED}[+] CRLF Injection VULNERABLE!${NC}"
    else
        echo -e "${GREEN}[-] No CRLF injection detected${NC}"
    fi
}

fallback_plugin() {
    local plugin_name=$1
    local target_url=$2
    log "Fallback plugin attack: $plugin_name on $target_url"
    echo -e "${YELLOW}[!] Plugin system requires the C++ engine to be built${NC}"
    echo -e "${YELLOW}[!] Run option [1] to build the engine first${NC}"
}

fallback_report() {
    log "Generating fallback report..."
    fallback_analyze > "$RESULTS_DIR/engine_report.txt" 2>&1
    success "Report saved to $RESULTS_DIR/engine_report.txt"
}

fallback_score() {
    log "Calculating exploitability score..."
    local score=50
    echo -e "${CYAN}Exploitability Score: $score/100${NC}"
    echo -e "${YELLOW}[!] Install the C++ engine for accurate scoring${NC}"
}

engine_menu
