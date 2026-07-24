#!/bin/bash

# NetRaven Plugin Packager
# Packages plugins into .nrava archives with full metadata

source src/core/utils.sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PLUGINS_DIR="$HOME/.netraven/plugins"
PACKAGES_DIR="$HOME/.netraven/packages"
mkdir -p "$PLUGINS_DIR" "$PACKAGES_DIR"

create_plugin_wizard() {
    clear
    echo -e "${CYAN}=== Create New Plugin ===${NC}"
    echo
    
    read -p "Plugin name (no spaces, e.g., sqli_test): " plugin_name
    if [ -z "$plugin_name" ]; then
        echo -e "${RED}[!] Plugin name required${NC}"
        return
    fi
    
    local plugin_dir="$PLUGINS_DIR/$plugin_name"
    if [ -d "$plugin_dir" ]; then
        echo -e "${RED}[!] Plugin already exists: $plugin_name${NC}"
        return
    fi
    
    mkdir -p "$plugin_dir"
    
    echo -e "${YELLOW}[*] Creating plugin structure...${NC}"
    
    # Create .nrav file
    cat > "$plugin_dir/$plugin_name.nrav" << 'EOFX'
<?xml version="1.0" encoding="UTF-8"?>
<plugin>
    <name>PLUGIN_NAME</name>
    <version>1.0</version>
    <author>Your Name</author>
    <description>Plugin description here</description>
    <category>sqli</category>
    <requires>curl,nmap</requires>
    <license>Apache-2.0</license>
    <homepage>https://example.com</homepage>
    <contact>contact@example.com</contact>
    <attack type="sqli">
        <payload>' OR '1'='1</payload>
        <detection>sql|syntax|mysql</detection>
    </attack>
</plugin>
EOFX
    
    # Create .nrav.meta
    cat > "$plugin_dir/$plugin_name.nrav.meta" << 'EOFM'
name=PLUGIN_NAME
version=1.0
author=Your Name
category=sqli
description=Plugin description here
requires=curl,nmap
license=Apache-2.0
homepage=https://example.com
contact=contact@example.com
EOFM
    
    # Replace placeholders
    sed -i "s/PLUGIN_NAME/$plugin_name/g" "$plugin_dir/$plugin_name.nrav"
    sed -i "s/PLUGIN_NAME/$plugin_name/g" "$plugin_dir/$plugin_name.nrav.meta"
    
    # Create LICENSE
    cat > "$plugin_dir/LICENSE" << 'EOF_LICENSE'
Apache License 2.0

Copyright (c) 2024

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF_LICENSE
    
    # Create README.md
    cat > "$plugin_dir/README.md" << 'EOF_README'
# PLUGIN_NAME

Plugin description here.

## Usage

Use this plugin via NetRaven Engine or Plugin Manager.

## Requirements

- curl
- nmap

## Author

Your Name

## Contact

contact@example.com

## Links

- https://example.com
EOF_README
    
    sed -i "s/PLUGIN_NAME/$plugin_name/g" "$plugin_dir/README.md"
    
    # Create TERMS.md
    cat > "$plugin_dir/TERMS.md" << 'EOF_TERMS'
Terms of Use for PLUGIN_NAME

This plugin is for authorized security testing only.
You may only use this on systems you own or have explicit permission to test.
EOF_TERMS
    
    sed -i "s/PLUGIN_NAME/$plugin_name/g" "$plugin_dir/TERMS.md"
    
    # Create CONTRIBUTING.md
    cat > "$plugin_dir/CONTRIBUTING.md" << 'EOF_CONTRIB'
# Contributing to PLUGIN_NAME

## How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## Code of Conduct

Be respectful. Only test systems you own or have permission to test.
EOF_CONTRIB
    
    sed -i "s/PLUGIN_NAME/$plugin_name/g" "$plugin_dir/CONTRIBUTING.md"
    
    # Create links.txt
    cat > "$plugin_dir/links.txt" << 'EOF_LINKS'
https://example.com
https://github.com/username/repo
https://cve.org/CVE-XXXX-XXXX
EOF_LINKS
    
    # Create contact.txt
    cat > "$plugin_dir/contact.txt" << 'EOF_CONTACT'
Author: Your Name
Email: contact@example.com
Twitter: @username
Discord: username#0000
EOF_CONTACT
    
    echo -e "${GREEN}[+] Plugin created: $plugin_dir${NC}"
    echo -e "${CYAN}[*] Files created:${NC}"
    ls -la "$plugin_dir"
    echo
    echo -e "${YELLOW}[!] Edit the files in $plugin_dir before using${NC}"
    echo -e "${YELLOW}[!] Then pack with option [2] Pack Plugin to .nrava${NC}"
}

pack_plugin() {
    clear
    echo -e "${CYAN}=== Pack Plugin to .nrava ===${NC}"
    echo
    
    if [ ! -d "$PLUGINS_DIR" ]; then
        echo -e "${RED}[!] No plugins directory found${NC}"
        return
    fi
    
    local dirs=()
    local i=1
    for d in "$PLUGINS_DIR"/*/; do
        if [ -d "$d" ]; then
            dirs+=("$d")
            echo -e "${CYAN}[$i]${NC} $(basename "$d")"
            i=$((i + 1))
        fi
    done
    
    if [ ${#dirs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No plugins found${NC}"
        return
    fi
    
    echo
    read -p "Select plugin to pack (0 to cancel): " choice
    
    if [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
        local idx=$((choice - 1))
        local plugin_dir="${dirs[$idx]}"
        local plugin_name=$(basename "$plugin_dir")
        local output="$PACKAGES_DIR/${plugin_name}.nrava"
        
        echo -e "${CYAN}[*] Packing $plugin_name...${NC}"
        
        cd "$PLUGINS_DIR"
        tar czf "$output" "$plugin_name/"
        
        if [ -f "$output" ]; then
            local size=$(du -h "$output" | cut -f1)
            echo -e "${GREEN}[+] Packed: $output ($size)${NC}"
        else
            echo -e "${RED}[-] Failed to pack${NC}"
        fi
    fi
}

unpack_plugin() {
    clear
    echo -e "${CYAN}=== Unpack .nrava Plugin ===${NC}"
    echo
    
    read -p "Path to .nrava file: " nrava_file
    
    if [ ! -f "$nrava_file" ]; then
        echo -e "${RED}[!] File not found${NC}"
        return
    fi
    
    echo -e "${CYAN}[*] Unpacking $nrava_file...${NC}"
    
    mkdir -p "$PLUGINS_DIR"
    
    tar xzf "$nrava_file" -C "$PLUGINS_DIR/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}[+] Unpacked successfully${NC}"
        ls -la "$PLUGINS_DIR"
    else
        echo -e "${RED}[-] Failed to unpack${NC}"
    fi
}

list_plugins() {
    clear
    echo -e "${CYAN}=== Installed Plugins ===${NC}"
    echo
    
    if [ ! -d "$PLUGINS_DIR" ]; then
        echo -e "${YELLOW}No plugins installed${NC}"
        return
    fi
    
    local count=0
    for d in "$PLUGINS_DIR"/*/; do
        if [ -d "$d" ]; then
            count=$((count + 1))
            local name=$(basename "$d")
            local meta="$d/$name.nrav.meta"
            local version="?"
            local author="?"
            local category="?"
            
            if [ -f "$meta" ]; then
                version=$(grep "^version=" "$meta" 2>/dev/null | cut -d= -f2 || echo "?")
                author=$(grep "^author=" "$meta" 2>/dev/null | cut -d= -f2 || echo "?")
                category=$(grep "^category=" "$meta" 2>/dev/null | cut -d= -f2 || echo "?")
            fi
            
            echo -e "${GREEN}[$count]${NC} $name"
            echo -e "     Version: $version"
            echo -e "     Author: $author"
            echo -e "     Category: $category"
            echo -e "     Files:"
            for f in "$d"*; do
                echo -e "       - $(basename "$f")"
            done
            echo
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}No plugins found${NC}"
    fi
}

delete_plugin() {
    clear
    echo -e "${CYAN}=== Delete Plugin ===${NC}"
    echo
    
    if [ ! -d "$PLUGINS_DIR" ]; then
        echo -e "${YELLOW}No plugins installed${NC}"
        return
    fi
    
    local dirs=()
    local i=1
    for d in "$PLUGINS_DIR"/*/; do
        if [ -d "$d" ]; then
            dirs+=("$d")
            echo -e "${CYAN}[$i]${NC} $(basename "$d")"
            i=$((i + 1))
        fi
    done
    
    if [ ${#dirs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No plugins found${NC}"
        return
    fi
    
    echo
    read -p "Select plugin to delete (0 to cancel): " choice
    
    if [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
        local idx=$((choice - 1))
        local plugin_dir="${dirs[$idx]}"
        local plugin_name=$(basename "$plugin_dir")
        
        read -p "Delete $plugin_name permanently? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            rm -rf "$plugin_dir"
            echo -e "${GREEN}[+] Deleted: $plugin_name${NC}"
        fi
    fi
}

validate_plugin() {
    clear
    echo -e "${CYAN}=== Validate Plugin ===${NC}"
    echo
    
    if [ ! -d "$PLUGINS_DIR" ]; then
        echo -e "${YELLOW}No plugins installed${NC}"
        return
    fi
    
    local dirs=()
    local i=1
    for d in "$PLUGINS_DIR"/*/; do
        if [ -d "$d" ]; then
            dirs+=("$d")
            echo -e "${CYAN}[$i]${NC} $(basename "$d")"
            i=$((i + 1))
        fi
    done
    
    if [ ${#dirs[@]} -eq 0 ]; then
        echo -e "${YELLOW}No plugins found${NC}"
        return
    fi
    
    echo
    read -p "Select plugin to validate (0 to cancel): " choice
    
    if [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
        local idx=$((choice - 1))
        local plugin_dir="${dirs[$idx]}"
        local plugin_name=$(basename "$plugin_dir")
        
        echo -e "${CYAN}[*] Validating $plugin_name...${NC}"
        
        local errors=0
        
        # Check .nrav file
        if [ ! -f "$plugin_dir/$plugin_name.nrav" ]; then
            echo -e "${RED}[-] Missing: $plugin_name.nrav${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}[+] Found: $plugin_name.nrav${NC}"
        fi
        
        # Check .nrav.meta
        if [ ! -f "$plugin_dir/$plugin_name.nrav.meta" ]; then
            echo -e "${RED}[-] Missing: $plugin_name.nrav.meta${NC}"
            errors=$((errors + 1))
        else
            echo -e "${GREEN}[+] Found: $plugin_name.nrav.meta${NC}"
            
            # Check required fields
            for field in name version author category description requires; do
                if ! grep -q "^$field=" "$plugin_dir/$plugin_name.nrav.meta"; then
                    echo -e "${RED}[-] Missing field in meta: $field${NC}"
                    errors=$((errors + 1))
                fi
            done
        fi
        
        # Check LICENSE
        if [ ! -f "$plugin_dir/LICENSE" ]; then
            echo -e "${YELLOW}[!] Missing LICENSE (recommended)${NC}"
        else
            echo -e "${GREEN}[+] Found: LICENSE${NC}"
        fi
        
        # Check README
        if [ ! -f "$plugin_dir/README.md" ]; then
            echo -e "${YELLOW}[!] Missing README.md (recommended)${NC}"
        else
            echo -e "${GREEN}[+] Found: README.md${NC}"
        fi
        
        echo
        if [ $errors -eq 0 ]; then
            echo -e "${GREEN}[+] Plugin is valid!${NC}"
        else
            echo -e "${RED}[-] Plugin has $errors error(s)${NC}"
        fi
    fi
}

plugin_menu() {
    while true; do
        clear
        echo -e "${PURPLE}┌──────────────────────────────────────────────────┐${NC}"
        echo -e "${PURPLE}│${NC}          ${CYAN}Plugin Manager${NC}                       ${PURPLE}│${NC}"
        echo -e "${PURPLE}├──────────────────────────────────────────────────┤${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[1]${NC}  Create New Plugin                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[2]${NC}  Pack Plugin to .nrava                ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[3]${NC}  Unpack .nrava Plugin                 ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[4]${NC}  List Installed Plugins              ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[5]${NC}  Delete Plugin                       ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[6]${NC}  Validate Plugin                     ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[7]${NC}  Export All Plugins                  ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[8]${NC}  Bulk Import Plugins                 ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} ${CYAN}[0]${NC}  Back to Main Menu                   ${PURPLE}│${NC}"
        echo -e "${PURPLE}└──────────────────────────────────────────────────┘${NC}"
        echo
        read -p "Select option: " opt
        
        case $opt in
            1) create_plugin_wizard ;;
            2) pack_plugin ;;
            3) unpack_plugin ;;
            4) list_plugins ;;
            5) delete_plugin ;;
            6) validate_plugin ;;
            7)
                echo -e "${CYAN}[*] Exporting all plugins...${NC}"
                mkdir -p "$PACKAGES_DIR"
                for d in "$PLUGINS_DIR"/*/; do
                    if [ -d "$d" ]; then
                        local name=$(basename "$d")
                        tar czf "$PACKAGES_DIR/${name}.nrava" -C "$PLUGINS_DIR" "$name"
                        echo -e "${GREEN}[+] Packed: $name.nrava${NC}"
                    fi
                done
                echo -e "${GREEN}[+] All plugins exported to $PACKAGES_DIR${NC}"
                ;;
            8)
                echo -e "${CYAN}[*] Bulk import from $PACKAGES_DIR...${NC}"
                for f in "$PACKAGES_DIR"/*.nrava; do
                    if [ -f "$f" ]; then
                        tar xzf "$f" -C "$PLUGINS_DIR/"
                        echo -e "${GREEN}[+] Imported: $(basename "$f")${NC}"
                    fi
                done
                ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}
