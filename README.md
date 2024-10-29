
# 🚀 Web Test Script with Enhanced Features 🚀

Welcome to the WEBSTER! This tool lets you test a target domain or IP using a range of reconnaissance and scanning tools to gather information on the web server, subdomains, IPs, SSL/TLS security, and more.

---

## 🌟 Features

1. **Initial IP Extraction**:
   - Extract IP using `dig` command to identify primary IP before further scans.

2. **Nikto Vulnerability Scan** (Optional with timeout skip):
   - `Nikto` is run in the background to check for potential vulnerabilities. You can opt to skip this scan if it takes too long.

3. **Additional Scans & Tools**:
   - `WhatWeb` to identify technologies on the IP.
   - `Sublist3r` for subdomain enumeration (only for domain targets).
   - `Nmap` scans for server headers, aggressive scans, and SSL enumeration.
   - `WAFW00F` for Web Application Firewall detection.
   - `SSLScan` to evaluate SSL/TLS settings.

4. **Customizable Timeout and Pauses**:
   - 10-second rest after each command to avoid overwhelming requests.

5. **Summary & Optional Tools**:
   - Generates a summary of results, with an option to launch tools like ZAP, Burp Suite, or save results in a report.

---

## 🚀 Getting Started

To use the script, run:
```bash
./webster.sh <target_domain_or_ip>
```

Example:
```bash
./webster.sh example.com
```

*MAKE SURE TO RUN `chmod +x webster.sh` BEFORE USE

Results are saved in the `results/` folder, with individual files for each scan.

---

## 📝 Update Log

- **v2.0**: Integrated IP extraction with `dig`, added optional Nikto timeout skip, reorganized scan order, and improved summaries.
- **v1.0**: Initial release.

---

## 👥 Contact

For feedback or issues, reach out to:

- **GitHub**: [GitHub Profile](https://github.com/galaxyytriponmobile)

Happy Scanning! 🚀
