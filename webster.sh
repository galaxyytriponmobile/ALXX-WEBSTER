#!/bin/bash

# Ensure the script is run with a target
if [ -z "$1" ]; then
    echo "Usage: $0 <domain_or_ip>"
    exit 1
fi

TARGET=$1

# Create a directory to store results
RESULT_DIR="./results"
mkdir -p "$RESULT_DIR"

# Function to run a command with a timeout
run_with_timeout() {
    local cmd="$1"
    local output_file="$2"
    eval "$cmd > \"$output_file\" 2>&1 &"
    wait $!
    local status=$?
    sleep 10  # 10-second pause between commands
    return $status
}

# Function to extract IP addresses using dig
extract_ips() {
    # Only extract IP addresses without printing extra information
    dig +short "$TARGET" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u
}

# Function to run tests
run_tests() {
    echo "Running tests on $TARGET..."
    IP_ADDRESSES=$(extract_ips)
    
    if [ -z "$IP_ADDRESSES" ]; then
        echo "No IP addresses found. Exiting."
        exit 1
    fi

    echo "Extracted IP addresses: $IP_ADDRESSES"

    for IP in $IP_ADDRESSES; do
        echo "Running tests on IP: $IP"

        echo "Running WhatWeb..."
        run_with_timeout "whatweb \"$IP\"" "$RESULT_DIR/whatweb.txt"

        echo "Running Sublist3r (only for domains)..."
        if [[ ! "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            run_with_timeout "sublist3r -d \"$TARGET\"" "$RESULT_DIR/sublist3r.txt"
        fi

        echo "Running Nmap HTTP server header..."
        run_with_timeout "nmap -p 80,443 --script http-server-header \"$IP\"" "$RESULT_DIR/nmap_http.txt"

        echo "Running Nmap Aggressive Scan..."
        run_with_timeout "nmap -A \"$IP\"" "$RESULT_DIR/nmap_aggressive.txt"

        echo "Running WAFW00F..."
        run_with_timeout "wafw00f -a \"$IP\"" "$RESULT_DIR/wafw00f.txt"

        echo "Running SSLScan..."
        run_with_timeout "sslscan \"$IP\"" "$RESULT_DIR/sslscan.txt"

        echo "Running Nmap SSL Enum Ciphers..."
        run_with_timeout "nmap --script ssl-enum-ciphers -p 443 -oX \"$RESULT_DIR/nmap_ssl_ciphers.xml\" \"$IP\"" "$RESULT_DIR/nmap_ssl_ciphers.txt"

        echo "Running directory brute-forcing with Gobuster..."
        run_with_timeout "gobuster dir -u \"$TARGET\" -w /usr/share/wordlists/dirb/common.txt" "$RESULT_DIR/gobuster.txt"

        echo "Running CMS identification with CMSeek..."
        run_with_timeout "cmseek -u \"$TARGET\"" "$RESULT_DIR/cmseek.txt"

        echo "Running Nmap Vulners script..."
        run_with_timeout "nmap -sV --script vulners \"$IP_ADDRESS\"" "$RESULT_DIR/nmap_vulners.txt"

    done

    echo "Tests completed. Results stored in the '$RESULT_DIR' directory."
}

# Function to display summary
display_summary() {
    echo "Summary of tests:"
    echo "-----------------"
    for file in "$RESULT_DIR"/*.txt; do
        echo "$(basename "$file"):"
        head -n 5 "$file"
        echo "..."
    done
    echo "End of summary."
}

# Function to launch tools
launch_tools() {
    while true; do
        echo "Select a tool or action to launch:"
        echo "1) ZAP"
        echo "2) Burp Suite"
        echo "3) Save results as report"
        echo "4) Exit"
        read -p "Enter your choice (1/2/3/4): " choice

        case $choice in
            1)
                echo "Launching ZAP..."
                /root/Desktop/ZAP/zap.sh &
                ;;
            2)
                echo "Launching Burp Suite..."
                burpsuite &
                ;;
            3)
                echo "Saving results as report..."
                cat "$RESULT_DIR"/*.txt > "$RESULT_DIR/report.txt"
                echo "Report saved as report.txt in the results directory."
                ;;
            4)
                echo "Exiting."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please enter a number from 1 to 4."
                ;;
        esac
    done
}

# Run tests, display summary, and launch tools
run_tests
display_summary
launch_tools
