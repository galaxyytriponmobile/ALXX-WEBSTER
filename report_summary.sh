#!/bin/bash

# Ensure the script is run with a target
if [ -z "$1" ]; then
    echo "Usage: $0 <domain_or_ip> (Use the same IP and/or domain you used before in webster.)"
    exit 1
fi

TARGET=$1

# Directory where results are stored
RESULT_DIR="./results"
REPORT_FILE="$RESULT_DIR/report.txt"
SUMMARY_FILE="$RESULT_DIR/vulnerability_summary.txt"

# Clear the summary file if it exists
> "$SUMMARY_FILE"

# Function to search for vulnerability indicators, subdomains, and open ports
search_vulnerabilities() {
    local file="$1"

    # Adding header to summary file
    echo "Analyzing $file for vulnerabilities and open ports..." >> "$SUMMARY_FILE"
    echo "----------------------------------------------------" >> "$SUMMARY_FILE"

    # Extract vulnerabilities or insecure findings with expanded keyword list
    grep -iE "(vulnerable|vulnerability|exploit|insecure|cve-|warning|security|WAF detected|firewall|blocking requests|signature|Cloudflare|ModSecurity|Imperva|XSS|SQLi|remote code execution|shellshock|CORS|OS detection|Apache|Nginx|nginx|version|detected|CMS|Drupal|WordPress|Joomla|Content-Type: application|OS:|server:|powered by)" "$file" \
        | grep -vi "not vulnerable" -A 1 -B 1 >> "$SUMMARY_FILE"

    # Extract subdomain enumeration results relevant to TARGET
    echo -e "\nSubdomains found for $TARGET in $file:" >> "$SUMMARY_FILE"
    grep -iE "($TARGET|subdomain|found|enumerated|discovered)" "$file" -A 1 -B 1 >> "$SUMMARY_FILE"

    # Extract open ports information
    echo -e "\nOpen Ports found in $file:" >> "$SUMMARY_FILE"
    awk '/PORTS/ {flag=1; next} /Nmap scan report|Service Info/ {flag=0} flag' "$file" >> "$SUMMARY_FILE"

    echo -e "----------------------------------------------------\n" >> "$SUMMARY_FILE"
}

# Run the analysis on report.txt only
if [[ -f "$REPORT_FILE" ]]; then
    search_vulnerabilities "$REPORT_FILE"
else
    echo "Error: $REPORT_FILE not found. Make sure the report file is generated first."
fi

echo "Vulnerability summary has been saved to $SUMMARY_FILE."
