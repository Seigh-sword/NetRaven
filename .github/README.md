# NetRaven

NetRaven is an ethical hacking and penetration testing framework built for Kali Linux. It provides a modular, menu-driven interface for reconnaissance, vulnerability scanning, attack simulation, monitoring, and reporting.

## Features

- **Reconnaissance**: WHOIS, DNS enumeration, subdomain discovery, Nmap scanning, email harvesting, technology fingerprinting
- **Vulnerability Scanning**: Nuclei, Nikto, SQLMap, XSS detection, directory bruteforce, WAF detection, SSL audits, header checks
- **Attack Modules**: Hydra/Medusa brute force, John/Hashcat password cracking, SQLMap, XSStrike, command injection, LFI/RFI, CSRF testing, reverse shell generation
- **Monitoring**: Ping, HTTP uptime, port monitoring, DNS change detection, SSL expiry, response time analysis, TCP capture
- **Network Utilities**: Traceroute, MTR, GeoIP, ASN lookup, Masscan, Netcat, DNS zone transfer, ping sweep
- **Reporting**: Text and HTML report generation, result compression and export

## Requirements

- Kali Linux (or Debian-based distro with hacking tools)
- Bash 4+
- Root/sudo privileges recommended

## Installation

```bash
git clone https://github.com/Seigh-sword/NetRaven.git
cd netraven
chmod +x netraven.sh
sudo ./netraven.sh
```

## Usage

```bash
sudo ./netraven.sh
```

1. Select a module from the main menu
2. Enter your target URL when prompted
3. Follow the on-screen instructions

## Disclaimer

**This tool is for educational and authorized security testing only.** Unauthorized access to computer systems is illegal. The authors are not responsible for any misuse or damage caused by this program.

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
