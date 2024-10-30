
# 🚀 Web Test Script with Enhanced Features 🚀

Welcome to the WEBSTER! This tool lets you test a target domain or IP using a range of reconnaissance and scanning tools to gather information on the web server, subdomains, IPs, SSL/TLS security, and more.

---

## 🌟 Features

1. **Initial IP Extraction**:
   - Extract IP using `dig` command to identify primary IP before further scans.

2. **Nikto Vulnerability Scan** (Optional with timeout skip):
   - `Nikto` is run in the background to check for potential vulnerabilities. You can opt to skip this scan if it takes too long.


4. **Customizable Timeout and Pauses**:
   - 10-second rest after each command to avoid overwhelming requests.

5. **Summary & Optional Tools**:
   - Generates a summary of results, with an option to launch tools like ZAP, Burp Suite, or save results in a report.

---

## 🚀 Getting Started
To get repo, copy this code;
```bash
git clone https://github.com/galaxyytriponmobile/ALXX-WEBSTER.git
cd ALXX-WEBSTER
```

Run the updater;
**MAKE SURE TO RUN `chmod +x updater.sh` BEFORE USE**

```bash
chmod +x updater.sh
./updater.sh
```

To use the script, run:
```bash
./webster.sh <target_domain_or_ip>
```

Example:
```bash
./webster.sh example.com
```

Run report_summary.sh to parse and summarize the report.txt:
```bash
./report_summary.sh
```
This script will search for key terms like "vulnerability," "exploit," "OS", and "SSL/TLS" to generate an overview of findings.

Results are saved in the `results/` folder, with individual files for each scan.

---

## 📝 Update Log

- **v2.6**: Added even more keywords, added `updater.sh` into repo.
- **v2.5**: Added keywords for `cmseek` and `gobuster` into `report_summary.sh`
- **v2.4**: Added `cmseek` and `gobuster` to webster, adding keywords in v2.5 and in future versions i will be updating looks to make it look better.
- **v2.3**: Added `report_summary.sh` to scan and report vulnerabilities from `report.txt`.
- **v2.2**: Removed `searchsploit` because of uselessness and errors.
- **v2.1**: Fixed IP related errors, removed `nikto` because of issues, I will be adding it back.
- **v2.0**: Integrated IP extraction with `dig`, added optional Nikto timeout skip, reorganized scan order, and improved summaries.
- **v1.0**: Initial release.

---

## 👥 Contact

For feedback or issues, reach out to:

- **GitHub**: [GitHub Profile](https://github.com/galaxyytriponmobile)

Happy Scanning! 🚀
