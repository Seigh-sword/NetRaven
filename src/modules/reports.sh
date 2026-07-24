#!/bin/bash

# Reports Module

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

reports_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== Reports ===${NC}"
        echo
        echo -e "${CYAN}[1]${NC}  Generate Full Report (Text)"
        echo -e "${CYAN}[2]${NC}  Generate HTML Report"
        echo -e "${CYAN}[3]${NC}  View Recon Results"
        echo -e "${CYAN}[4]${NC}  View Vulnerability Results"
        echo -e "${CYAN}[5]${NC}  View Attack Results"
        echo -e "${CYAN}[6]${NC}  View Monitor Results"
        echo -e "${CYAN}[7]${NC}  Compress & Export Results"
        echo -e "${CYAN}[8]${NC}  Clean Results Directory"
        echo -e "${CYAN}[0]${NC}  Back to Main Menu"
        echo
        read -p "Select option: " opt

        case $opt in
            1) generate_text_report ;;
            2) generate_html_report ;;
            3) view_recon ;;
            4) view_vulns ;;
            5) view_attacks ;;
            6) view_monitor ;;
            7) export_results ;;
            8) clean_results ;;
            0) break ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        read -p "Press Enter to continue..."
    done
}

generate_text_report() {
    log "Generating text report..."
    local report_file="$RESULTS_DIR/full_report.txt"
    {
        echo "========================================"
        echo "  NetRaven Security Assessment Report"
        echo "========================================"
        echo "Target: $TARGET_URL"
        echo "Domain: $TARGET_DOMAIN"
        echo "Date: $(date)"
        echo "========================================"
        echo ""
        
        for dir in recon vulns attacks monitor; do
            echo "=== $dir ==="
            if [ -d "$RESULTS_DIR/$dir" ]; then
                for f in "$RESULTS_DIR/$dir"/*.txt; do
                    if [ -f "$f" ]; then
                        echo "--- $(basename "$f") ---"
                        cat "$f" 2>/dev/null
                        echo ""
                    fi
                done
            fi
        done
        
        echo "=== End of Report ==="
    } > "$report_file"
    success "Full report saved to $report_file"
}

generate_html_report() {
    log "Generating HTML report..."
    local report_file="$RESULTS_DIR/full_report.html"
    {
        echo "<!DOCTYPE html>"
        echo "<html><head><title>NetRaven Report</title>"
        echo "<style>body{font-family:Arial,sans-serif;margin:20px;} h1{color:#333;} h2{color:#666;} pre{background:#f4f4f4;padding:10px;overflow-x:auto;}</style>"
        echo "</head><body>"
        echo "<h1>NetRaven Security Assessment Report</h1>"
        echo "<p><strong>Target:</strong> $TARGET_URL</p>"
        echo "<p><strong>Date:</strong> $(date)</p><hr>"
        
        for dir in recon vulns attacks monitor; do
            echo "<h2>$dir</h2>"
            if [ -d "$RESULTS_DIR/$dir" ]; then
                for f in "$RESULTS_DIR/$dir"/*.txt; do
                    if [ -f "$f" ]; then
                        echo "<h3>$(basename "$f")</h3><pre>"
                        cat "$f" 2>/dev/null
                        echo "</pre>"
                    fi
                done
            fi
        done
        echo "</body></html>"
    } > "$report_file"
    success "HTML report saved to $report_file"
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
    log "Compressing results..."
    tar -czf "$RESULTS_DIR.tar.gz" "$RESULTS_DIR"
    success "Exported to $RESULTS_DIR.tar.gz"
}

clean_results() {
    log "Cleaning results directory..."
    rm -rf "$RESULTS_DIR"
    TARGET_URL=""
    TARGET_DOMAIN=""
    RESULTS_DIR=""
    success "Results cleaned"
}

reports_menu
