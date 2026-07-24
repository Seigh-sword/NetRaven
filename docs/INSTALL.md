# NetRaven Installation Guide

## Requirements

- Kali Linux (or Debian-based distribution)
- Bash 4.0+
- GCC/G++ (for C++ engine)
- Python 3 (for TTS and site serving)
- PHP (for vulnerable site generator)

## Quick Install

```bash
git clone https://github.com/yourusername/netraven.git
cd netraven
bash netraven.sh
```

## Tool Installation

NetRaven requires 30+ Kali tools. Install the large metapackage:

```bash
sudo apt update
sudo apt install -y kali-linux-large
```

Or install individual tools:

```bash
sudo apt install -y nmap nikto sqlmap hydra john gobuster ffuf whatweb wafw00f masscan \
    curl wget dig whois openssl tcpdump tshark enum4linux smbclient nbtscan \
    onesixtyone snmpwalk theharvester sublist3r amass subfinder httpx nuclei \
    zap-cli cloudflared php
```

## Building the C++ Engine

The engine auto-builds on first run. To build manually:

```bash
cd src/engine
make clean
make
```

## Plugin Installation

Plugins auto-copy to `~/.netraven/plugins/` on first run. To manually install:

```bash
mkdir -p ~/.netraven/plugins
cp src/plugins/*.nrav ~/.netraven/plugins/
cp src/plugins/*.nrav.meta ~/.netraven/plugins/
```

## Directory Structure

```
~/.netraven/
  plugins/    - .nrav plugin files
  tunnels/    - tunnel logs and PIDs
  sites/      - generated vulnerable sites
  tts/        - TTS MP3 files
```
