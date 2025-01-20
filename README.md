
# WEBSTER - Automated Reconnaissance Tool 🕵️‍♂️

Welcome to **WEBSTER**! Your go-to automated reconnaissance tool for gathering information about a target domain or IP. This tool runs various scans and saves the results in individual files for easy review, as well as a consolidated report!

## Features 🚀

- **Dependency Check**: Automatically verifies if required tools are installed, updating as necessary.
- **Custom Scans**:
  - WhatWeb: Identifies the underlying technologies of websites.
  - Sublist3r: Enumerates subdomains of the target domain.
  - Nmap: Runs different types of scans to gather details about the target.
  - WAFW00F: Detects Web Application Firewalls (WAFs).
  - SSLScan: Assesses SSL/TLS protocols.
  - Gobuster: Brute-forces directories to discover hidden paths.
  - CMSeek: CMS detection and vulnerability scanning.
- **Report Generation**: Combines individual scan results into a single report.

## Usage 🛠️
Installing;

```bash
sudo git clone https://github.com/galaxyytriponmobile/ALXX-WEBSTER.git
cd ALXX-WEBSTER
```

Running;

```bash
sudo chmod +x webster.sh
```
```bash
./webster.sh <domain_or_ip>
```
Example:
```bash
./webster.sh example.com
```

## Output Files 📄

- Each tool’s output is saved in the **results/** directory.
- Individual files include:
  - `whatweb.txt`
  - `sublist3r.txt`
  - `nmap_http.txt`, `nmap_aggressive.txt`, `nmap_ssl_ciphers.txt`, `nmap_vulners.txt`
  - `wafw00f.txt`
  - `sslscan.txt`
  - `gobuster.txt`
  - `cmseek.txt`
- Consolidated report is saved as `report.txt`.

 ## 📝 Update Log

-**v3.1**: Added some more tweaks because of errors encountered.

-**v3.0**: Added back `nikto` and `cmseek`, this wil probably be the last update.

-**v2.9**: Added sufficient permissions for `webster.sh`, because before this update, you could have only used it as root.

 -**v2.8**: Removed `report_summary.sh` because of uselessness, and added colored headers to `report.txt`, making it more readable.

 -**v2.7**: Fused `updater.sh` into `webster.sh` and updated the looks, looks amazing now.

 -**v2.6**: Added even more keywords, added `updater.sh` into repo.

 -**v2.5**: Added keywords for cmseek and gobuster into `report_summary.sh`.

 -**v2.4**: Added `cmseek` and `gobuster` to webster, adding keywords in v2.5 and in future versions i will be updating looks to make it look better.

 -**v2.3**: Added `report_summary.sh` to scan and report vulnerabilities from report.txt.

 -**v2.2**: Removed `searchsploit` because of uselessness and errors.

 -**v2.1**: Fixed IP related errors, removed `nikto` because of issues, I will be adding it back.

 -**v2.0**: Integrated IP extraction with `dig`, added optional `Nikto` timeout skip, reorganized scan order, and improved summaries.

 -**v1.0**: Initial release.


## Notes 📝

This script is intended for ethical hacking and penetration testing purposes **only**. Use responsibly! 💡

---

Made with AI (chatgpt), i think this script is fullproof, still expect errors.

**Happy Scanning!** 🎉

