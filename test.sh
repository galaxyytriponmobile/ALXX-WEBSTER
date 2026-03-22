#!/usr/bin/env bash

set -euo pipefail

# =========================
# CONFIG
# =========================
RESULT_DIR="./results"
LOG_FILE="$RESULT_DIR/run.log"
WORDLIST_DEFAULT="/usr/share/wordlists/dirb/common.txt"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[0;31m'
RESET='\033[0m'

# =========================
# BANNER
# =========================
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗"
    echo "  ██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║"
    echo "  ██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║"
    echo "  ██╔═══╝ ██╔══╝  ██║     ██║   ██║██║╚██╗██║"
    echo "  ██║     ███████╗╚██████╗╚██████╔╝██║ ╚████║"
    echo "  ╚═╝     ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝"
    echo -e "${RESET}"
}

# =========================
# USAGE
# =========================
usage() {
    echo "Usage: $0 -t <target> [-o output_dir] [-w wordlist] [-p parallel]"
    exit 1
}

# =========================
# ARG PARSING
# =========================
TARGET=""
PARALLEL=false
WORDLIST="$WORDLIST_DEFAULT"

while getopts "t:o:w:p" opt; do
    case $opt in
        t) TARGET="$OPTARG" ;;
        o) RESULT_DIR="$OPTARG" ;;
        w) WORDLIST="$OPTARG" ;;
        p) PARALLEL=true ;;
        *) usage ;;
    esac
done

[ -z "$TARGET" ] && usage

# =========================
# SETUP
# =========================
mkdir -p "$RESULT_DIR"
chmod 755 "$RESULT_DIR"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

print_banner

echo -e "${CYAN}[+] Target: $TARGET${RESET}"
echo -e "${CYAN}[+] Output Dir: $RESULT_DIR${RESET}"

# =========================
# AUTH CHECK
# =========================
read -p "[?] Are you authorized to scan this target? (yes/no): " confirm
[[ "$confirm" != "yes" ]] && { echo "Exiting."; exit 1; }

# =========================
# TOOL CHECK
# =========================
REQUIRED_TOOLS=(whatweb nmap wafw00f sslscan gobuster nikto)

MISSING=()
for tool in "${REQUIRED_TOOLS[@]}"; do
    command -v "$tool" >/dev/null || MISSING+=("$tool")
done

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "${YELLOW}[!] Missing tools: ${MISSING[*]}${RESET}"
    read -p "Install them? (y/n): " choice
    if [[ $choice =~ ^[Yy]$ ]]; then
        sudo apt update
        sudo apt install -y "${MISSING[@]}"
    else
        echo "Cannot continue without required tools."
        exit 1
    fi
fi

# =========================
# VALIDATE WORDLIST
# =========================
if [ ! -f "$WORDLIST" ]; then
    echo -e "${RED}[!] Wordlist not found: $WORDLIST${RESET}"
    exit 1
fi

# =========================
# TIMER FUNCTION
# =========================
run_task() {
    local name="$1"
    local outfile="$2"
    shift 2

    echo -e "${CYAN}[+] Running: $name${RESET}"

    local start=$(date +%s)

    "$@" > "$outfile" 2>&1 &
    local pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        local now=$(date +%s)
        local elapsed=$((now - start))
        printf "\r${YELLOW}[~] %s elapsed: %02d:%02d${RESET}" "$name" $((elapsed/60)) $((elapsed%60))
        sleep 1
    done

    wait "$pid"
    echo -e "\n${GREEN}[✓] Completed: $name${RESET}"
}

# =========================
# SCANS
# =========================
run_all_scans() {

    run_task "WhatWeb" "$RESULT_DIR/whatweb.txt" \
        whatweb "$TARGET" &

    run_task "Nmap Basic" "$RESULT_DIR/nmap_basic.txt" \
        nmap -p 80,443 --script http-server-header "$TARGET" &

    run_task "Nmap Aggressive" "$RESULT_DIR/nmap_aggressive.txt" \
        nmap -A "$TARGET" &

    run_task "WAF Detection" "$RESULT_DIR/waf.txt" \
        wafw00f "$TARGET" &

    run_task "SSLScan" "$RESULT_DIR/ssl.txt" \
        sslscan "$TARGET" &

    run_task "Nmap SSL Ciphers" "$RESULT_DIR/ssl_ciphers.txt" \
        nmap --script ssl-enum-ciphers -p 443 "$TARGET" &

    run_task "Gobuster" "$RESULT_DIR/gobuster.txt" \
        gobuster dir -u "$TARGET" -w "$WORDLIST" &

    run_task "Nikto" "$RESULT_DIR/nikto.txt" \
        nikto -h "$TARGET" &

    if [ "$PARALLEL" = false ]; then
        wait
    fi
}

if [ "$PARALLEL" = true ]; then
    echo -e "${YELLOW}[!] Running in PARALLEL mode${RESET}"
    run_all_scans
    wait
else
    echo -e "${YELLOW}[!] Running in SEQUENTIAL mode${RESET}"

    run_task "WhatWeb" "$RESULT_DIR/whatweb.txt" whatweb "$TARGET"
    run_task "Nmap Basic" "$RESULT_DIR/nmap_basic.txt" nmap -p 80,443 --script http-server-header "$TARGET"
    run_task "Nmap Aggressive" "$RESULT_DIR/nmap_aggressive.txt" nmap -A "$TARGET"
    run_task "WAF Detection" "$RESULT_DIR/waf.txt" wafw00f "$TARGET"
    run_task "SSLScan" "$RESULT_DIR/ssl.txt" sslscan "$TARGET"
    run_task "SSL Ciphers" "$RESULT_DIR/ssl_ciphers.txt" nmap --script ssl-enum-ciphers -p 443 "$TARGET"
    run_task "Gobuster" "$RESULT_DIR/gobuster.txt" gobuster dir -u "$TARGET" -w "$WORDLIST"
    run_task "Nikto" "$RESULT_DIR/nikto.txt" nikto -h "$TARGET"
fi

# =========================
# REPORT
# =========================
REPORT="$RESULT_DIR/report.txt"

echo -e "${CYAN}[+] Generating report...${RESET}"

{
    echo "==== SCAN REPORT ===="
    echo "Target: $TARGET"
    echo "Date: $(date)"
    echo ""

    for f in "$RESULT_DIR"/*.txt; do
        echo "===== $(basename "$f") ====="
        cat "$f"
        echo ""
    done
} > "$REPORT"

echo -e "${GREEN}[✓] Report saved: $REPORT${RESET}"
