#!/bin/bash

# NetRaven Utility Functions

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export NC='\033[0m'

log() {
    echo -e "${CYAN}[*]${NC} $1"
}

success() {
    echo -e "${GREEN}[+]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

error() {
    echo -e "${RED}[-]${NC} $1"
}

run_cmd() {
    local desc="$1"
    shift
    local cmd="$@"
    log "$desc"
    echo -e "${PURPLE}CMD: $cmd${NC}"
    eval "$cmd" | tee -a "$RESULTS_DIR/commands.log"
}

create_results_dir() {
    mkdir -p "$RESULTS_DIR/recon"
    mkdir -p "$RESULTS_DIR/vulns"
    mkdir -p "$RESULTS_DIR/attacks"
    mkdir -p "$RESULTS_DIR/screenshots"
}

generate_report() {
    local target="$1"
    local report_file="$RESULTS_DIR/report.txt"
    echo "=== NetRaven Report ===" > "$report_file"
    echo "Target: $target" >> "$report_file"
    echo "Date: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    echo "=== Recon ===" >> "$report_file"
    cat "$RESULTS_DIR/recon/*.txt" >> "$report_file" 2>/dev/null
    echo "" >> "$report_file"
    echo "=== Vulnerabilities ===" >> "$report_file"
    cat "$RESULTS_DIR/vulns/*.txt" >> "$report_file" 2>/dev/null
    success "Report generated: $report_file"
}
