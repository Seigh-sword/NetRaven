# NetRaven Troubleshooting Guide

## Engine Build Issues

### g++ or make not found
```bash
sudo apt install g++ make
```

### libcurl headers missing
```bash
sudo apt install libcurl4-openssl-dev
```

### Build fails silently
Check `/tmp/netraven_build.log` for compiler errors.

## Missing Tools

Run the tool checker from the main menu or manually install:
```bash
sudo apt install kali-linux-large
```

## Tunnel Issues

### cloudflared not installed
```bash
sudo apt install cloudflared
# Or download from https://github.com/cloudflare/cloudflared/releases
```

### Tunnel creation fails
- Check if port is already in use: `sudo ss -tlnp | grep <port>`
- Check logs in `~/.netraven/tunnels/`
- Ensure outbound HTTPS (port 443) is not blocked

## PHP / Site Generator

### PHP not installed
```bash
sudo apt install php
```

### PHP server won't start
- Ensure the site directory exists
- Check if port is already in use
- Verify PHP is installed: `php -v`

## TTS Issues

### gTTS not installed
```bash
pip3 install gtts --break-system-packages
```

### No audio playback
```bash
sudo apt install mpg123
# Or install ffplay from ffmpeg
```

## Plugin Issues

### Plugins not loading
- Ensure `.nrav` and `.nrav.meta` files are both present in `~/.netraven/plugins/`
- Use Plugin Manager -> Validate Plugin to check format
- Ensure plugin category is valid

### Plugin directory missing
```bash
mkdir -p ~/.netraven/plugins
cp src/plugins/*.nrav ~/.netraven/plugins/
cp src/plugins/*.nrav.meta ~/.netraven/plugins/
```
