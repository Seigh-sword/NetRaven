# NetRaven Plugin Development Guide

## Plugin Format

Plugins are XML-like `.nrav` files paired with `.nrav.meta` metadata files.

## Directory

Plugins are stored in `~/.netraven/plugins/`. The `src/plugins/` directory contains example plugins.

## Creating a Plugin

### Method 1: Plugin Manager

1. Run NetRaven
2. Main -> [3] Mishvious -> [3] Plugin Manager
3. Select [6] Create New Plugin
4. Fill in name, version, author, category, description, required tools

### Method 2: Manual

Create two files:

**my_plugin.nrav:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plugin>
    <name>my_plugin</name>
    <version>1.0</version>
    <author>Your Name</author>
    <description>Description</description>
    <category>sqli</category>
    <requires>curl,nmap</requires>
    <attack type="sqli">
        <payload>' OR '1'='1</payload>
        <detection>sql|syntax|mysql</detection>
    </attack>
</plugin>
```

**my_plugin.nrav.meta:**
```
name=my_plugin
version=1.0
author=Your Name
category=sqli
description=Description
requires=curl,nmap
```

## Categories

- `sqli` - SQL Injection
- `xss` - Cross-Site Scripting
- `cmdi` - Command Injection
- `lfi` - Local File Inclusion
- `bruteforce` - Brute Force
- `open_redirect` - Open Redirect
- `csrf` - CSRF
- `clickjacking` - Clickjacking
- `crlf` - CRLF Injection

## Running Plugins

### Via Plugin Manager
Main -> [3] Mishvious -> [3] Plugin Manager -> [4] Run Plugin Attack

### Via C++ Engine
Main -> [3] Mishvious -> [1] C++ Engine -> [12] Run Plugin Attack

## Validation

Use Plugin Manager -> [5] Validate Plugin to check:
- `<plugin>` root element
- `<name>` element
- `<attack>` element
- `.nrav.meta` fields (name, version, category, description, requires)

## Best Practices

- Keep plugins focused on a single attack type
- Document required tools in the `requires` field
- Use realistic but safe payloads for simulation
- Test against the vulnerable site generator before using on real targets
