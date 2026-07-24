#!/bin/bash

# NetRaven Vulnerable Site Generator
# Creates test sites with different security levels for practice

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SITES_DIR="$HOME/.netraven/sites"
mkdir -p "$SITES_DIR"

site_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Vulnerable Site Generator ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Generate Low Security Site (SQLi + XSS + LFI)"
        echo -e "${CYAN}[2]${NC}  Generate Medium Security Site (Partial Protections)"
        echo -e "${CYAN}[3]${NC}  Generate High Security Site (Full Protections)"
        echo -e "${CYAN}[4]${NC}  Generate Custom Vulnerable Site"
        echo -e "${CYAN}[5]${NC}  List Generated Sites"
        echo -e "${CYAN}[6]${NC}  Start Site Locally"
        echo -e "${CYAN}[7]${NC}  Create Tunnel for Site"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) generate_low_site ;;
            2) generate_medium_site ;;
            3) generate_high_site ;;
            4) generate_custom_site ;;
            5) list_sites ;;
            6) start_site ;;
            7) create_site_tunnel ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

generate_low_site() {
    log "Generating Low Security Vulnerable Site"
    read -p "Site name: " site_name
    site_name=${site_name:-vuln_low}

    local site_dir="$SITES_DIR/$site_name"
    mkdir -p "$site_dir"

    cat > "$site_dir/index.php" << 'PHPEOF'
<?php
// LOW SECURITY - Vulnerable to SQLi, XSS, LFI, CMDi
$db = new SQLite3('/tmp/vuln.db');
$db->exec('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)');
$db->exec("INSERT OR IGNORE INTO users VALUES (1, 'admin', 'admin@example.com')");

$id = $_GET['id'] ?? '1';
$search = $_GET['q'] ?? '';
$file = $_GET['file'] ?? 'index';
$cmd = $_GET['cmd'] ?? '';
$redirect = $_GET['url'] ?? '';
$name = $_POST['name'] ?? '';
$email = $_POST['email'] ?? '';

echo "<html><head><title>Vulnerable Site</title></head><body>";
echo "<h1>Low Security Test Site</h1>";

// SQL Injection vulnerability
echo "<h2>Search Users</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='id' value='$id'>";
echo "<input type='submit' value='Search'>";
echo "</form>";
$result = $db->query("SELECT * FROM users WHERE id = $id");
if ($row = $result->fetchArray()) {
    echo "<p>User: " . $row['name'] . " - " . $row['email'] . "</p>";
} else {
    echo "<p>No user found</p>";
}

// XSS vulnerability
echo "<h2>Search</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='q' value='$search'>";
echo "<input type='submit' value='Search'>";
echo "</form>";
echo "<p>Search results for: $search</p>";

// LFI vulnerability
echo "<h2>View File</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='file' value='$file'>";
echo "<input type='submit' value='View'>";
echo "</form>";
if (file_exists($file . '.php')) {
    include($file . '.php');
} else {
    echo "<p>File not found</p>";
}

// Command Injection vulnerability
echo "<h2>Ping Tool</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='cmd' value='$cmd'>";
echo "<input type='submit' value='Ping'>";
echo "</form>";
if ($cmd) {
    echo "<pre>" . shell_exec("ping -c 1 " . $cmd) . "</pre>";
}

// Open Redirect vulnerability
echo "<h2>Redirect</h2>";
echo "<a href='$redirect'>Go to $redirect</a>";

// No CSRF protection
echo "<h2>Register</h2>";
echo "<form method='POST'>";
echo "<input type='text' name='name' placeholder='Name'>";
echo "<input type='email' name='email' placeholder='Email'>";
echo "<input type='submit' value='Register'>";
echo "</form>";

if ($name && $email) {
    $db->exec("INSERT OR IGNORE INTO users (name, email) VALUES ('$name', '$email')");
    echo "<p>Registered: $name</p>";
}

echo "</body></html>";
PHPEOF

    echo -e "${GREEN}[+] Low security site created at: $site_dir${NC}"
    echo -e "${YELLOW}[!] This site is vulnerable to SQLi, XSS, LFI, CMDi, Open Redirect, and CSRF${NC}"
}

generate_medium_site() {
    log "Generating Medium Security Site"
    read -p "Site name: " site_name
    site_name=${site_name:-vuln_medium}

    local site_dir="$SITES_DIR/$site_name"
    mkdir -p "$site_dir"

    cat > "$site_dir/index.php" << 'PHPEOF'
<?php
// MEDIUM SECURITY - Some protections but exploitable
$db = new SQLite3('/tmp/vuln_medium.db');
$db->exec('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)');
$db->exec("INSERT OR IGNORE INTO users VALUES (1, 'admin', 'admin@example.com')");

$id = $_GET['id'] ?? '1';
$search = $_GET['q'] ?? '';
$file = $_GET['file'] ?? 'index';
$cmd = $_GET['cmd'] ?? '';
$redirect = $_GET['url'] ?? '';
$name = $_POST['name'] ?? '';
$email = $_POST['email'] ?? '';
$token = $_POST['csrf_token'] ?? '';
$session_token = $_SESSION['csrf_token'] ?? '';

echo "<html><head><title>Medium Security Site</title></head><body>";
echo "<h1>Medium Security Test Site</h1>";

// Partial SQL protection (escapes but still vulnerable to certain payloads)
echo "<h2>Search Users</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='id' value='" . htmlspecialchars($id) . "'>";
echo "<input type='submit' value='Search'>";
echo "</form>";
$id_safe = $db->escapeString($id);
$result = $db->query("SELECT * FROM users WHERE id = $id_safe");
if ($row = $result->fetchArray()) {
    echo "<p>User: " . htmlspecialchars($row['name']) . " - " . htmlspecialchars($row['email']) . "</p>";
} else {
    echo "<p>No user found</p>";
}

// XSS partially protected
echo "<h2>Search</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='q' value='" . htmlspecialchars($search) . "'>";
echo "<input type='submit' value='Search'>";
echo "</form>";
echo "<p>Search results for: " . htmlspecialchars($search) . "</p>";

// LFI partially protected
echo "<h2>View File</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='file' value='" . htmlspecialchars($file) . "'>";
echo "<input type='submit' value='View'>";
echo "</form>";
$allowed = ['index', 'about', 'contact'];
if (in_array($file, $allowed)) {
    $safe_file = $file . '.php';
    if (file_exists($safe_file)) {
        include($safe_file);
    }
} else {
    echo "<p>File not allowed</p>";
}

// Command injection partially protected
echo "<h2>Ping Tool</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='cmd' value='" . htmlspecialchars($cmd) . "'>";
echo "<input type='submit' value='Ping'>";
echo "</form>";
if ($cmd && preg_match('/^[a-zA-Z0-9.-]+$/', $cmd)) {
    echo "<pre>" . shell_exec("ping -c 1 " . escapeshellarg($cmd)) . "</pre>";
} elseif ($cmd) {
    echo "<p>Invalid input</p>";
}

// Open redirect partially protected
echo "<h2>Redirect</h2>";
$allowed_redirects = ['home', 'about', 'contact'];
if (in_array($redirect, $allowed_redirects)) {
    echo "<a href='/$redirect'>Go to $redirect</a>";
} else {
    echo "<p>Invalid redirect target</p>";
}

// CSRF token present but weak
session_start();
if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(16));
}
echo "<h2>Register</h2>";
echo "<form method='POST'>";
echo "<input type='hidden' name='csrf_token' value='" . $_SESSION['csrf_token'] . "'>";
echo "<input type='text' name='name' placeholder='Name'>";
echo "<input type='email' name='email' placeholder='Email'>";
echo "<input type='submit' value='Register'>";
echo "</form>";

if ($name && $email && $token === $session_token) {
    $db->exec("INSERT OR IGNORE INTO users (name, email) VALUES ('" . $db->escapeString($name) . "', '" . $db->escapeString($email) . "')");
    echo "<p>Registered: " . htmlspecialchars($name) . "</p>";
} elseif ($name && $email) {
    echo "<p>CSRF token mismatch</p>";
}

echo "</body></html>";
PHPEOF

    echo -e "${GREEN}[+] Medium security site created at: $site_dir${NC}"
    echo -e "${YELLOW}[!] This site has partial protections - some attacks may still work${NC}"
}

generate_high_site() {
    log "Generating High Security Site"
    read -p "Site name: " site_name
    site_name=${site_name:-secure_high}

    local site_dir="$SITES_DIR/$site_name"
    mkdir -p "$site_dir"

    cat > "$site_dir/index.php" << 'PHPEOF'
<?php
// HIGH SECURITY - Full protections
session_start();
$db = new SQLite3('/tmp/secure_high.db');
$db->exec('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, email TEXT)');
$db->exec("INSERT OR IGNORE INTO users VALUES (1, 'admin', 'admin@example.com')");

if (empty($_SESSION['csrf_token'])) {
    $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
}

$id = $_GET['id'] ?? '1';
$search = $_GET['q'] ?? '';
$file = $_GET['file'] ?? 'index';
$cmd = $_GET['cmd'] ?? '';
$redirect = $_GET['url'] ?? '';
$name = $_POST['name'] ?? '';
$email = $_POST['email'] ?? '';
$token = $_POST['csrf_token'] ?? '';

header("X-Frame-Options: DENY");
header("Content-Security-Policy: default-src 'self'; script-src 'self'");
header("X-Content-Type-Options: nosniff");
header("Strict-Transport-Security: max-age=31536000");
header("Referrer-Policy: strict-origin-when-cross-origin");
header("Permissions-Policy: camera=(), microphone=(), geolocation=()");

echo "<html><head><title>High Security Site</title></head><body>";
echo "<h1>High Security Test Site</h1>";

// SQL Injection protected with prepared statements
echo "<h2>Search Users</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='id' value='" . htmlspecialchars($id, ENT_QUOTES, 'UTF-8') . "'>";
echo "<input type='submit' value='Search'>";
echo "</form>";
$stmt = $db->prepare("SELECT * FROM users WHERE id = :id");
$stmt->bindValue(':id', $id, SQLITE3_TEXT);
$result = $stmt->execute();
if ($row = $result->fetchArray()) {
    echo "<p>User: " . htmlspecialchars($row['name'], ENT_QUOTES, 'UTF-8') . " - " . htmlspecialchars($row['email'], ENT_QUOTES, 'UTF-8') . "</p>";
} else {
    echo "<p>No user found</p>";
}

// XSS fully protected
echo "<h2>Search</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='q' value='" . htmlspecialchars($search, ENT_QUOTES, 'UTF-8') . "'>";
echo "<input type='submit' value='Search'>";
echo "</form>";
echo "<p>Search results for: " . htmlspecialchars($search, ENT_QUOTES, 'UTF-8') . "</p>";

// LFI fully protected
echo "<h2>View File</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='file' value='" . htmlspecialchars($file, ENT_QUOTES, 'UTF-8') . "'>";
echo "<input type='submit' value='View'>";
echo "</form>";
$allowed = ['index', 'about', 'contact'];
$base_dir = __DIR__ . '/pages/';
if (in_array($file, $allowed)) {
    $safe_file = realpath($base_dir . $file . '.php');
    if ($safe_file && strpos($safe_file, realpath($base_dir)) === 0 && file_exists($safe_file)) {
        include($safe_file);
    } else {
        echo "<p>File not found</p>";
    }
} else {
    echo "<p>File not allowed</p>";
}

// Command injection fully protected
echo "<h2>Ping Tool</h2>";
echo "<form method='GET'>";
echo "<input type='text' name='cmd' value='" . htmlspecialchars($cmd, ENT_QUOTES, 'UTF-8') . "'>";
echo "<input type='submit' value='Ping'>";
echo "</form>";
if ($cmd && preg_match('/^[a-zA-Z0-9.-]+$/', $cmd)) {
    echo "<pre>" . htmlspecialchars(shell_exec("ping -c 1 " . escapeshellarg($cmd)), ENT_QUOTES, 'UTF-8') . "</pre>";
} elseif ($cmd) {
    echo "<p>Invalid input</p>";
}

// Open redirect fully protected
echo "<h2>Redirect</h2>";
$allowed_redirects = ['home', 'about', 'contact'];
if (in_array($redirect, $allowed_redirects)) {
    $safe_url = '/' . $redirect;
    echo "<a href='" . htmlspecialchars($safe_url, ENT_QUOTES, 'UTF-8') . "'>Go to " . htmlspecialchars($redirect, ENT_QUOTES, 'UTF-8') . "</a>";
} else {
    echo "<p>Invalid redirect target</p>";
}

// CSRF token with SameSite cookie
echo "<h2>Register</h2>";
echo "<form method='POST'>";
echo "<input type='hidden' name='csrf_token' value='" . htmlspecialchars($_SESSION['csrf_token'], ENT_QUOTES, 'UTF-8') . "'>";
echo "<input type='text' name='name' placeholder='Name'>";
echo "<input type='email' name='email' placeholder='Email'>";
echo "<input type='submit' value='Register'>";
echo "</form>";

if ($name && $email && hash_equals($_SESSION['csrf_token'], $token)) {
    $stmt = $db->prepare("INSERT OR IGNORE INTO users (name, email) VALUES (:name, :email)");
    $stmt->bindValue(':name', $name, SQLITE3_TEXT);
    $stmt->bindValue(':email', $email, SQLITE3_TEXT);
    $stmt->execute();
    echo "<p>Registered: " . htmlspecialchars($name, ENT_QUOTES, 'UTF-8') . "</p>";
} elseif ($name && $email) {
    echo "<p>Invalid CSRF token</p>";
}

echo "</body></html>";
PHPEOF

    echo -e "${GREEN}[+] High security site created at: $site_dir${NC}"
    echo -e "${GREEN}[+] This site has full protections against SQLi, XSS, LFI, CMDi, Open Redirect, and CSRF${NC}"
}

generate_custom_site() {
    log "Generate Custom Vulnerable Site"
    read -p "Site name: " site_name
    read -p "Vulnerabilities (comma separated: sqli,xss,lfi,cmdi,open_redirect,csrf,clickjacking,crlf): " vulns

    local site_dir="$SITES_DIR/${site_name}_custom"
    mkdir -p "$site_dir"

    cat > "$site_dir/index.php" << PHPEOF
<?php
// Custom Vulnerable Site: $site_name
// Vulnerabilities: $vulns
$db = new SQLite3('/tmp/${site_name}.db');
\$id = \$_GET['id'] ?? '1';
\$search = \$_GET['q'] ?? '';
\$file = \$_GET['file'] ?? 'index';
\$cmd = \$_GET['cmd'] ?? '';
\$redirect = \$_GET['url'] ?? '';

echo "<html><body>";
echo "<h1>Custom Vulnerable Site</h1>";
echo "<p>Vulnerabilities enabled: $vulns</p>";

if (strpos('$vulns', 'sqli') !== false) {
    echo "<h2>Search</h2><form method='GET'><input name='id' value='\$id'><input type='submit'></form>";
    \$result = \$db->query("SELECT * FROM users WHERE id = \$id");
}
if (strpos('$vulns', 'xss') !== false) {
    echo "<h2>Search</h2><form method='GET'><input name='q' value='\$search'><input type='submit'></form>";
    echo "<p>\$search</p>";
}
if (strpos('$vulns', 'lfi') !== false) {
    echo "<h2>File</h2><form method='GET'><input name='file' value='\$file'><input type='submit'></form>";
    @include(\$file . '.php');
}
if (strpos('$vulns', 'cmdi') !== false) {
    echo "<h2>Ping</h2><form method='GET'><input name='cmd' value='\$cmd'><input type='submit'></form>";
    if (\$cmd) echo "<pre>" . shell_exec("ping -c 1 " . \$cmd) . "</pre>";
}
if (strpos('$vulns', 'open_redirect') !== false) {
    echo "<h2>Redirect</h2><a href='\$redirect'>Go</a>";
}
echo "</body></html>";
PHPEOF

    echo -e "${GREEN}[+] Custom site created at: $site_dir${NC}"
}

list_sites() {
    log "Generated Sites"
    if [ -d "$SITES_DIR" ]; then
        for dir in "$SITES_DIR"/*; do
            if [ -d "$dir" ]; then
                local name=$(basename "$dir")
                local count=$(find "$dir" -type f | wc -l)
                echo -e "${CYAN}$name${NC} - $count files"
            fi
        done
    else
        echo -e "${YELLOW}No sites generated yet${NC}"
    fi
}

start_site() {
    log "Start Site Locally"
    read -p "Site name: " site_name
    local site_dir="$SITES_DIR/$site_name"

    if [ ! -d "$site_dir" ]; then
        echo -e "${RED}[!] Site not found: $site_name${NC}"
        return
    fi

    read -p "Port (default: 8080): " port
    port=${port:-8080}

    echo -e "${GREEN}[+] Starting PHP server on port $port...${NC}"
    echo -e "${YELLOW}[!] URL: http://localhost:$port${NC}"
    php -S "localhost:$port" -t "$site_dir"
}

create_site_tunnel() {
    log "Create Tunnel for Site"
    read -p "Site name: " site_name
    local site_dir="$SITES_DIR/$site_name"

    if [ ! -d "$site_dir" ]; then
        echo -e "${RED}[!] Site not found: $site_name${NC}"
        return
    fi

    read -p "Port (default: 8080): " port
    port=${port:-8080}

    php -S "localhost:$port" -t "$site_dir" > /dev/null 2>&1 &
    sleep 1

    if ! command -v cloudflared &> /dev/null; then
        echo -e "${YELLOW}[!] cloudflared not installed${NC}"
        return
    fi

    local tunnel_id="site_$(date +%s)"
    local log_file="$TUNNEL_DIR/${tunnel_id}.log"

    cloudflared tunnel --url "http://localhost:$port" > "$log_file" 2>&1 &
    sleep 4

    if grep -q "trycloudflare" "$log_file" 2>/dev/null; then
        local public_url=$(grep -oP 'https://[a-z0-9-]+\.trycloudflare\.com' "$log_file" | head -n1)
        echo -e "${GREEN}[+] Tunnel created: $public_url${NC}"
        echo -e "${YELLOW}[!] Use this URL for testing${NC}"
    else
        echo -e "${RED}[!] Tunnel creation failed${NC}"
    fi
}

site_menu
