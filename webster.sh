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
    local cmd_pid=$!
    wait "$cmd_pid"
    local status=$?

    return $status
}

# Function to extract IP addresses using dig
extract_ip() {
    local target="$1"
    local ip=$(dig +short "$target" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')
    echo "$ip"
}

# Function to run tests
run_tests() {
    echo "Running tests on $TARGET..."

    # Check if the target is an IP or domain
    if [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Detected an IP address."
        IP_ADDRESSES="$TARGET"
    else
        echo "Detected a domain. Resolving IP..."
        IP_ADDRESSES=$(extract_ip "$TARGET")
    fi

    if [ -z "$IP_ADDRESSES" ]; then
        echo "No IP address found. Exiting."
        exit 1
    fi

    echo "Extracted IP address: $IP_ADDRESSES"

    # Run tests with the extracted IP addresses
    for IP in $IP_ADDRESSES; do
        echo "Running tests on IP: $IP"

        echo "Running WhatWeb..."
        run_with_timeout "whatweb \"$IP\"" "$RESULT_DIR/whatweb.txt"
        sleep 10

        echo "Running Sublist3r (only for domains)..."
        if [[ ! "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            run_with_timeout "python3 Sublist3r/sublist3r.py -d \"$TARGET\"" "$RESULT_DIR/sublist3r.txt"
            sleep 10
        fi

        echo "Running Nmap HTTP server header..."
        run_with_timeout "nmap -p 80,443 --script http-server-header \"$IP\"" "$RESULT_DIR/nmap_http.txt"
        sleep 10

        echo "Running Nmap Aggressive Scan..."
        run_with_timeout "nmap -A \"$IP\"" "$RESULT_DIR/nmap_aggressive.txt"
        sleep 10

        echo "Running WAFW00F..."
        run_with_timeout "wafw00f -a \"$IP\"" "$RESULT_DIR/wafw00f.txt"
        sleep 10

        echo "Running SSLScan..."
        run_with_timeout "sslscan \"$IP\"" "$RESULT_DIR/sslscan.txt"
        sleep 10

        echo "Running Nmap SSL Enum Ciphers..."
        run_with_timeout "nmap --script ssl-enum-ciphers -p 443 \"$IP\"" "$RESULT_DIR/nmap_ssl_ciphers.txt"
        sleep 10
    done

    # Run Nikto as the final test with an option to skip if it takes too long
    echo "Running Nikto..."
    run_with_timeout "nikto -h \"$TARGET\"" "$RESULT_DIR/nikto.txt" &
    local nikto_pid=$!
    sleep 30

    if ps -p $nikto_pid > /dev/null; then
        echo "Nikto scan is taking longer than expected."
        read -p "Do you want to skip Nikto? (y/n): " skip_nikto
        if [[ "$skip_nikto" == "y" ]]; then
            kill "$nikto_pid" 2>/dev/null
            echo "Nikto scan skipped."
        else
            echo "Waiting for Nikto to finish..."
            wait "$nikto_pid"
        fi
    fi

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
