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
    local timeout="$2"
    local output_file="$3"

    # Run the command in the background
    eval "$cmd > \"$output_file\" 2>&1 &"
    local cmd_pid=$!

    # Wait for the command to finish
    wait "$cmd_pid"
    local status=$?

    return $status
}

# Function to extract IP addresses from Nikto output
extract_ips() {
    local output_file="$1"
    local ips=$(grep -oP '\d{1,3}(\.\d{1,3}){3}' "$output_file" | sort -u)
    echo "$ips"
}

# Function to run tests
run_tests() {
    echo "Running tests on $TARGET..."

    # Check if the target is an IP or domain
    if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Detected an IP address."
    else
        echo "Detected a domain."
    fi

    # Run Nikto first
    echo "Running Nikto..."
    run_with_timeout "nikto -h \"$TARGET\"" 30 "$RESULT_DIR/nikto.txt"
    sleep 10

    # Extract IP addresses from Nikto results
    IP_ADDRESSES=$(extract_ips "$RESULT_DIR/nikto.txt")
    
    if [ -z "$IP_ADDRESSES" ]; then
        echo "No IP addresses found from Nikto. Exiting."
        exit 1
    fi

    echo "Extracted IP addresses: $IP_ADDRESSES"

    # Run tests with the extracted IP addresses
    for IP in $IP_ADDRESSES; do
        echo "Running tests on IP: $IP"

        echo "Running WhatWeb..."
        run_with_timeout "whatweb \"$IP\"" 30 "$RESULT_DIR/whatweb.txt"
        sleep 10

        echo "Running Sublist3r (only for domains)..."
        if [[ ! "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            run_with_timeout "python3 Sublist3r/sublist3r.py -d \"$TARGET\"" 30 "$RESULT_DIR/sublist3r.txt"
            sleep 10
        fi

        echo "Running Nmap HTTP server header..."
        run_with_timeout "nmap -p 80,443 --script http-server-header \"$IP\"" 30 "$RESULT_DIR/nmap_http.txt"
        sleep 10

        echo "Running Nmap Aggressive Scan..."
        run_with_timeout "nmap -A \"$IP\"" 30 "$RESULT_DIR/nmap_aggressive.txt"
        sleep 10

        echo "Running WAFW00F..."
        run_with_timeout "wafw00f -a \"$IP\"" 30 "$RESULT_DIR/wafw00f.txt"
        sleep 10

        echo "Running SSLScan..."
        run_with_timeout "sslscan \"$IP\"" 30 "$RESULT_DIR/sslscan.txt"
        sleep 10

        echo "Running Nmap SSL Enum Ciphers..."
        run_with_timeout "nmap --script ssl-enum-ciphers -p 443 \"$IP\"" 30 "$RESULT_DIR/nmap_ssl_ciphers.txt"
        sleep 10
    done

    echo "Tests completed. Results stored in the '$RESULT_DIR' directory."
}

# Function to display summary
display_summary() {
    echo "Summary of tests:"
    echo "-----------------"
    for file in "$RESULT_DIR"/*.txt; do
        echo "$(basename "$file"):"
        head -n 5 "$file"  # Show first 5 lines for summary
        echo "..."
    done
    echo "End of summary."
}

# Function to launch tools
launch_tools() {
    echo "Select a tool to launch:"
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
            echo "Invalid choice."
            ;;
    esac
}

# Run tests and display summary
run_tests
display_summary
launch_tools
