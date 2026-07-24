#!/bin/bash

# Reports Module

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

show_reports() {
    clear
    echo -e "${CYAN}=== Reports Module ===${NC}"
    echo
    if [ ! -d "$RESULTS_DIR" ]; then
        echo -e "${RED}[!] No results directory found${NC}"
        return
    fi

    echo -e "${CYAN}[1]${NC} Generate Full Report"
    echo -e "${CYAN}[2]${NC} View Recon Results"
    echo -e "${CYAN}[3]${NC} View Vulnerability Results"
    echo -e "${CYAN}[4]${NC} View Attack Results"
    echo -e "${CYAN}[5]${NC} View Monitor Results"
    echo -e "${CYAN}[6]${NC} Export Results"
    echo -e "${CYAN}[0]${NC} Back to Main Menu"
    echo
    read -p "Select option: " opt

    case $opt in
        1) generate_full_report ;;
        2) view_recon ;;
        3) view_vulns ;;
        4) view_attacks ;;
        5) view_monitor ;;
        6) export_results ;;
        0) return ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
    read -p "Press Enter to continue..."
}

generate_full_report() {
    log "Generating full report..."
    local report_file="$RESULTS_DIR/full_report.txt"
    echo "========================================" > "$report_file"
    echo "  NetRaven Security Assessment Report" >> "$report_file"
    echo "========================================" >> "$report_file"
    echo "Target: $TARGET_URL" >> "$report_file"
    echo "Date: $(date)" >> "$report_file"
    echo "========================================" >> "$report_file"
    echo >> "$report_file"

    for dir in recon vulns attacks monitor; do
        echo "=== $dir ===" >> "$report_file"
        if [ -d "$RESULTS_DIR/$dir" ]; then
            for f in "$RESULTS_DIR/$dir"/*.txt; do
                if [ -f "$f" ]; then
                    echo "--- $(basename "$f") ---" >> "$report_file"
                    cat "$f" >> "$report_file" 2>/dev/null
                    echo >> "$report_file"
                fi
            done
        fi
    done

    success "Full report saved to $report_file"
}

view_recon() {
    echo -e "${CYAN}=== Recon Results ===${NC}"
    ls -la "$RESULTS_DIR/recon/" 2>/dev/null || echo "No recon results"
}

view_vulns() {
    echo -e "${CYAN}=== Vulnerability Results ===${NC}"
    ls -la "$RESULTS_DIR/vulns/" 2>/dev/null || echo "No vulnerability results"
}

view_attacks() {
    echo -e "${CYAN}=== Attack Results ===${NC}"
    ls -la "$RESULTS_DIR/attacks/" 2>/dev/null || echo "No attack results"
}

view_monitor() {
    echo -e "${CYAN}=== Monitor Results ===${NC}"
    ls -la "$RESULTS_DIR/monitor/" 2>/dev/null || echo "No monitor results"
}

export_results() {
    log "Exporting results..."
    tar -czf "$RESULTS_DIR.tar.gz" "$RESULTS_DIR"
    success "Exported to $RESULTS_DIR.tar.gz"
}

show_reports
