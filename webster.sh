#!/bin/bash

# Colors for styling
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

# ASCII Art Banner
clear

echo -e "${CYAN}"
echo "  █     █░▓█████  ▄▄▄▄     ██████ ▄▄▄█████▓▓█████  ██▀███   "
echo " ▓█░ █ ░█░▓█   ▀ ▓█████▄ ▒██    ▒ ▓  ██▒ ▓▒▓█   ▀ ▓██ ▒ ██▒ "
echo " ▒█░ █ ░█ ▒███   ▒██▒ ▄██░ ▓██▄   ▒ ▓██░ ▒░▒███   ▓██ ░▄█ ▒ "
echo " ░█░ █ ░█ ▒▓█  ▄ ▒██░█▀    ▒   ██▒░ ▓██▓ ░ ▒▓█  ▄ ▒██▀▀█▄   "
echo " ░░██▒██▓ ░▒████▒░▓█  ▀█▓▒██████▒▒  ▒██▒ ░ ░▒████▒░██▓ ▒██▒ "
echo " ░ ▓░▒ ▒  ░░ ▒░ ░░▒▓███▀▒▒ ▒▓▒ ▒ ░  ▒ ░░   ░░ ▒░ ░░ ▒▓ ░▒▓░ "
echo "   ▒ ░ ░   ░ ░  ░▒░▒   ░ ░ ░▒  ░ ░    ░     ░ ░  ░  ░▒ ░ ▒░ "
echo "   ░   ░     ░    ░    ░ ░  ░  ░    ░         ░     ░░   ░  "
echo "     ░       ░  ░ ░            ░              ░  ░   ░      "
echo "                       ░                                    "
echo -e "${RESET}"
# Ensure the script is run with a target
if [ -z "$1" ]; then
    echo "Usage: $0 <domain_or_ip>"
    exit 1
fi

TARGET=$1
RESULT_DIR="./results"
mkdir -p "$RESULT_DIR"

# Function to display time elapsed
run_with_timer() {
    local cmd="$1"
    local output_file="$2"
    local elapsed=0

    eval "$cmd > \"$output_file\" 2>&1 &"
    local pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${YELLOW}[~] Elapsed: %02d:%02d${RESET}" $((elapsed/60)) $((elapsed%60))
        sleep 1
        ((elapsed++))
    done

    wait "$pid"
    printf "\r${GREEN}[~] Elapsed: %02d:%02d${RESET}\n" $((elapsed/60)) $((elapsed%60))
    sleep 3
}

# Updater Function: Ensures all required tools are installed
updater() {
    echo -e "${CYAN}Starting dependency installation...${RESET}"
    local tools=("whatweb" "sublist3r" "nmap" "wafw00f" "sslscan" "gobuster" "cmseek")
    for tool in "${tools[@]}"; do
        echo -e "${YELLOW}[+] Installing $tool...${RESET}"
        run_with_timer "sudo apt install -y $tool" "/dev/null"
    done
    echo -e "${GREEN}All tools are installed and up-to-date!${RESET}"
}

# Check if tools are installed, run updater if missing
for tool in "whatweb" "sublist3r" "nmap" "wafw00f" "sslscan" "gobuster" "cmseek"; do
    if ! command -v "$tool" &>/dev/null; then
        echo -e "${YELLOW}Some tools are missing. Running updater.${RESET}"
        updater
        break
    fi
done

# Run the custom scans
echo -e "${CYAN}Running tests on $TARGET...${RESET}"

run_with_timer "whatweb \"$TARGET\"" "$RESULT_DIR/whatweb.txt"
echo -e "${GREEN}[+] Running WhatWeb on $TARGET completed.${RESET}"

if [[ ! "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${CYAN}[+] Running Sublist3r for domain enumeration...${RESET}"
    run_with_timer "sublist3r -d \"$TARGET\"" "$RESULT_DIR/sublist3r.txt"
fi

echo -e "${CYAN}[+] Running Nmap HTTP Server Header Check...${RESET}"
run_with_timer "nmap -p 80,443 --script http-server-header \"$TARGET\"" "$RESULT_DIR/nmap_http.txt"

echo -e "${CYAN}[+] Running Nmap Aggressive Scan...${RESET}"
run_with_timer "nmap -A \"$TARGET\"" "$RESULT_DIR/nmap_aggressive.txt"

echo -e "${CYAN}[+] Running WAFW00F for WAF Detection...${RESET}"
run_with_timer "wafw00f -a \"$TARGET\"" "$RESULT_DIR/wafw00f.txt"

echo -e "${CYAN}[+] Running SSLScan...${RESET}"
run_with_timer "sslscan \"$TARGET\"" "$RESULT_DIR/sslscan.txt"

echo -e "${CYAN}[+] Running Nmap SSL Enum Ciphers...${RESET}"
run_with_timer "nmap --script ssl-enum-ciphers -p 443 \"$TARGET\"" "$RESULT_DIR/nmap_ssl_ciphers.txt"

echo -e "${CYAN}[+] Running Directory Brute-forcing with Gobuster...${RESET}"
run_with_timer "gobuster dir -u \"$TARGET\" -w /usr/share/wordlists/dirb/common.txt" "$RESULT_DIR/gobuster.txt"

echo -e "${CYAN}[+] Running CMS Identification with CMSeek...${RESET}"
run_with_timer "cmseek -u \"$TARGET\"" "$RESULT_DIR/cmseek.txt"

echo -e "${CYAN}[+] Running Nmap Vulners Script...${RESET}"
run_with_timer "nmap -sV --script vulners \"$TARGET\"" "$RESULT_DIR/nmap_vulners.txt"

echo -e "${GREEN}All scans completed! Results saved in ${RESULT_DIR}.${RESET}"

REPORT_FILE="$RESULT_DIR/report.txt"
echo -e "${CYAN}Generating report summary at $REPORT_FILE...${RESET}"
cat "$RESULT_DIR"/*.txt > "$REPORT_FILE"
echo -e "${GREEN}Report generated: $REPORT_FILE${RESET}"
