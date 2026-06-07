#!/bin/bash

# Colors for styling
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RED='\033[0;31m'
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

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!] This script must be run as root (use sudo)${RESET}"
    exit 1
fi

# Ask for project name at the start
echo -ne "${CYAN}[?] Enter Project Name: ${RESET}"
read PROJECT_NAME
if [ -z "$PROJECT_NAME" ]; then
    PROJECT_NAME="scan_$(date +%Y%m%d_%H%M%S)"
fi

RESULT_DIR="./$PROJECT_NAME"
mkdir -p "$RESULT_DIR"

# Fix permissions so the non-root user can access results
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$RESULT_DIR"
fi
chmod 755 "$RESULT_DIR"

# Target reachability check
echo -e "${CYAN}[+] Checking if $TARGET is reachable...${RESET}"
if ! ping -c 1 "$(echo $TARGET | sed -E 's|https?://||; s|/.*||')" &>/dev/null; then
    echo -e "${RED}[!] Warning: Target appears to be down or blocking ICMP. Proceeding anyway...${RESET}"
else
    echo -e "${GREEN}[+] Target is up.${RESET}"
fi

# Function to display time elapsed
run_with_timer() {
    local cmd="$1"
    local output_file="$2"
    local header="$3"
    local elapsed=0
    local skipped=false

    echo -e "${header}${RESET}" > "$output_file"
    bash -c "$cmd" >> "$output_file" 2>&1 &
    local pid=$!

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${YELLOW}[~] Elapsed: %02d:%02d (Press 'x' to skip)${RESET}" $((elapsed/60)) $((elapsed%60))
        if read -t 1 -n 1 -s key && [[ "$key" == "x" ]]; then
            kill "$pid" 2>/dev/null
            echo -e "\n${RED}[!] Skipping command...${RESET}"
            echo -e "\n--SKIPPED COMMAND--" >> "$output_file"
            skipped=true
            break
        fi
        ((elapsed++))
    done

    if [ "$skipped" = false ]; then
        wait "$pid"
        printf "\r${GREEN}[~] Elapsed: %02d:%02d${RESET}\n" $((elapsed/60)) $((elapsed%60))
    fi

    # Ensure output file belongs to the user
    if [ -n "$SUDO_USER" ]; then
        chown "$SUDO_USER:$SUDO_USER" "$output_file"
    fi
    sleep 3
}

# Ensure tools are installed
REQUIRED_TOOLS=("whatweb" "sublist3r" "nmap" "wafw00f" "sslscan" "gobuster" "cmseek" "nikto")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        echo -e "${YELLOW}[+] Installing missing tool: $tool...${RESET}"
        apt update && apt install -y "$tool"
    fi
done

# Run the scans
echo -e "${CYAN}[+] Running WhatWeb...${RESET}"
run_with_timer "whatweb \"$TARGET\"" "$RESULT_DIR/whatweb.txt" "${GREEN}--- WhatWeb Results ---"

echo -e "${CYAN}[+] Enumerating subdomains...${RESET}"
run_with_timer "sublist3r -d \"$TARGET\"" "$RESULT_DIR/sublist3r.txt" "${YELLOW}--- Sublist3r Results ---"

echo -e "${CYAN}[+] Checking HTTP server headers...${RESET}"
run_with_timer "nmap -p 80,443 --script http-server-header \"$TARGET\"" "$RESULT_DIR/nmap_http.txt" "${CYAN}--- Nmap HTTP Server Header Check Results ---"

echo -e "${CYAN}[+] Performing an aggressive Nmap scan...${RESET}"
run_with_timer "nmap -A \"$TARGET\"" "$RESULT_DIR/nmap_aggressive.txt" "${RED}--- Nmap Aggressive Scan Results ---"

echo -e "${CYAN}[+] Detecting WAF presence...${RESET}"
run_with_timer "wafw00f -a \"$TARGET\"" "$RESULT_DIR/wafw00f.txt" "${GREEN}--- WAFW00F Results ---"

echo -e "${CYAN}[+] Analyzing SSL/TLS configurations...${RESET}"
run_with_timer "sslscan \"$TARGET\"" "$RESULT_DIR/sslscan.txt" "${CYAN}--- SSLScan Results ---"

echo -e "${CYAN}[+] Brute-forcing directories with Gobuster...${RESET}"
WORDLIST="/usr/share/wordlists/dirb/common.txt"
if [ -f "$WORDLIST" ]; then
    run_with_timer "gobuster dir -u \"$TARGET\" -w \"$WORDLIST\"" "$RESULT_DIR/gobuster.txt" "${RED}--- Gobuster Results ---"
else
    echo -e "${RED}[!] Wordlist missing at $WORDLIST.${RESET}"
fi

echo -e "${CYAN}[+] Scanning for vulnerabilities with Nikto...${RESET}"
run_with_timer "nikto -h \"$TARGET\"" "$RESULT_DIR/nikto.txt" "${RED}--- Nikto Results ---"

# Generate combined report and fix ownership
REPORT_FILE="$RESULT_DIR/report.txt"
echo -e "${CYAN}Generating report summary...${RESET}"
cat "$RESULT_DIR"/*.txt > "$REPORT_FILE"
if [ -n "$SUDO_USER" ]; then
    chown -R "$SUDO_USER:$SUDO_USER" "$RESULT_DIR"
fi
echo -e "${GREEN}Report generated: $REPORT_FILE${RESET}"
