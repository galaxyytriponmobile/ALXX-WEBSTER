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
RESULT_DIR="./results"
sudo mkdir -p "$RESULT_DIR"
sudo chmod 777 ./results
sudo chmod 777 /
# Function to display time elapsed
run_with_timer() {
    local cmd="$1"
    local output_file="$2"
    local header="$3"
    local elapsed=0

    echo -e "${header}${RESET}" > "$output_file"

    eval "$cmd >> \"$output_file\" 2>&1 &"
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

# Ensure tools are installed
REQUIRED_TOOLS=("whatweb" "sublist3r" "nmap" "wafw00f" "sslscan" "gobuster" "cmseek" "nikto")
for tool in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$tool" &>/dev/null; then
        echo -e "${YELLOW}[+] Installing missing tool: $tool...${RESET}"
        sudo apt install -y "$tool"
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
    fi
done

# Run the scans
echo -e "${CYAN}[+] Running WhatWeb to identify technologies on the target...${RESET}"
echo -e "${YELLOW}Command: whatweb \"$TARGET\"${RESET}"
run_with_timer "whatweb \"$TARGET\"" "$RESULT_DIR/whatweb.txt" "${GREEN}--- WhatWeb Results ---" "Identifying technologies and frameworks on the target website."

echo -e "${CYAN}[+] Enumerating subdomains with Sublist3r...${RESET}"
echo -e "${YELLOW}Command: sublist3r -d \"$TARGET\"${RESET}"
run_with_timer "sublist3r -d \"$TARGET\"" "$RESULT_DIR/sublist3r.txt" "${YELLOW}--- Sublist3r Results ---" "Enumerating subdomains with Sublist3r."

echo -e "${CYAN}[+] Checking HTTP server headers with Nmap...${RESET}"
echo -e "${YELLOW}Command: nmap -p 80,443 --script http-server-header \"$TARGET\"${RESET}"
run_with_timer "nmap -p 80,443 --script http-server-header \"$TARGET\"" "$RESULT_DIR/nmap_http.txt" "${CYAN}--- Nmap HTTP Server Header Check Results ---" "Checking HTTP server headers using Nmap."

echo -e "${CYAN}[+] Performing an aggressive Nmap scan...${RESET}"
echo -e "${YELLOW}Command: nmap -A \"$TARGET\"${RESET}"
run_with_timer "nmap -A \"$TARGET\"" "$RESULT_DIR/nmap_aggressive.txt" "${RED}--- Nmap Aggressive Scan Results ---" "Performing an aggressive scan with Nmap."

echo -e "${CYAN}[+] Detecting WAF presence with WAFW00F...${RESET}"
echo -e "${YELLOW}Command: wafw00f -a \"$TARGET\"${RESET}"
run_with_timer "wafw00f -a \"$TARGET\"" "$RESULT_DIR/wafw00f.txt" "${GREEN}--- WAFW00F Results ---" "Detecting the presence of a web application firewall (WAF) with WAFW00F."

echo -e "${CYAN}[+] Analyzing SSL/TLS configurations with SSLScan...${RESET}"
echo -e "${YELLOW}Command: sslscan \"$TARGET\"${RESET}"
run_with_timer "sslscan \"$TARGET\"" "$RESULT_DIR/sslscan.txt" "${CYAN}--- SSLScan Results ---" "Analyzing SSL/TLS configurations with SSLScan."

echo -e "${CYAN}[+] Enumerating SSL/TLS ciphers with Nmap...${RESET}"
echo -e "${YELLOW}Command: nmap --script ssl-enum-ciphers -p 443 \"$TARGET\"${RESET}"
run_with_timer "nmap --script ssl-enum-ciphers -p 443 \"$TARGET\"" "$RESULT_DIR/nmap_ssl_ciphers.txt" "${YELLOW}--- Nmap SSL Enum Ciphers Results ---" "Enumerating SSL/TLS ciphers with Nmap."

echo -e "${CYAN}[+] Brute-forcing directories with Gobuster...${RESET}"
echo -e "${YELLOW}Command: gobuster dir -u \"$TARGET\" -w /usr/share/wordlists/dirb/common.txt${RESET}"
run_with_timer "gobuster dir -u \"$TARGET\" -w /usr/share/wordlists/dirb/common.txt" "$RESULT_DIR/gobuster.txt" "${RED}--- Gobuster Results ---" "Brute-forcing directories with Gobuster."

echo -e "${CYAN}[+] Scanning for vulnerabilities with Nmap Vulners script...${RESET}"
echo -e "${YELLOW}Command: nmap -sV --script vulners \"$TARGET\"${RESET}"
run_with_timer "nmap -sV --script vulners \"$TARGET\"" "$RESULT_DIR/nmap_vulners.txt" "${CYAN}--- Nmap Vulners Script Results ---" "Scanning for vulnerabilities with Nmap Vulners script."

# Interactive CMSeek section
read -p "${CYAN}[?] Would you like to run CMSeek interactively? (y/n): ${RESET}" RUN_CMSEEK
if [[ "$RUN_CMSEEK" =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}[+] Running CMSeek interactively to identify CMS...${RESET}"
    echo -e "${YELLOW}Command: cmseek -u \"$TARGET\"${RESET}"
	clear
    sudo cmseek -u "$TARGET" | sudo tee "$RESULT_DIR/cmseek.txt"
    echo -e "${GREEN}[+] CMSeek completed interactively.${RESET}"
else
    echo -e "${YELLOW}[-] Skipping CMSeek interactive scan.${RESET}"
fi

# Nikto scan
echo -e "${CYAN}[+] Scanning the web server for vulnerabilities with Nikto...${RESET}"
echo -e "${YELLOW}Command: nikto -h \"$TARGET\"${RESET}"
run_with_timer "sudo nikto -h \"$TARGET\"" "$RESULT_DIR/nikto.txt" "${RED}--- Nikto Results ---" "Scanning the web server for vulnerabilities with Nikto."


# Generate a combined report
REPORT_FILE="$RESULT_DIR/report.txt"
echo -e "${CYAN}Generating report summary at $REPORT_FILE...${RESET}"
sudo cat "$RESULT_DIR"/*.txt > "$REPORT_FILE"
echo -e "${GREEN}Report generated: $REPORT_FILE${RESET}"
