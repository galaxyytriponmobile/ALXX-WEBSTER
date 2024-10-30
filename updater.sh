#!/bin/bash

echo "Starting installation of required tools..."

# Install each tool with apt
sudo apt update

# Install dig (part of dnsutils package)
sudo apt install -y dnsutils

# Install WhatWeb for web server and tech identification
sudo apt install -y whatweb

# Install Sublist3r for subdomain enumeration
sudo apt install -y sublist3r

# Install Nmap for network scanning and scripting
sudo apt install -y nmap

# Install Nikto for vulnerability scanning
sudo apt install -y nikto

# Install WAFW00F for Web Application Firewall detection
sudo apt install -y wafw00f

# Install SSLScan for SSL/TLS security analysis
sudo apt install -y sslscan

# Install Gobuster for directory and subdomain brute-forcing
sudo apt install -y gobuster

# Install CMSeeK for CMS detection and vulnerability scanning
sudo apt install -y cmseek

# Install SearchSploit for CVE and exploit searching
sudo apt install -y exploitdb

echo "All required tools have been installed."
