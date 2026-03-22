import sys
import subprocess
import threading
import json
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QPushButton, QTextEdit,
    QLabel, QLineEdit, QCheckBox, QFileDialog, QProgressBar
)
from PyQt5.QtCore import pyqtSignal, QObject

# =========================
# Worker with signals
# =========================
class WorkerSignals(QObject):
    log = pyqtSignal(str)
    progress = pyqtSignal(int)
    finished = pyqtSignal()


class ScanWorker(threading.Thread):
    def __init__(self, target, use_sqlmap, use_zap, signals):
        super().__init__()
        self.target = target
        self.use_sqlmap = use_sqlmap
        self.use_zap = use_zap
        self.signals = signals
        self.results = {}

    def run_command(self, command, name):
        self.signals.log.emit(f"[+] Running {name}...")
        output = []
        try:
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True
            )

            for line in process.stdout:
                output.append(line.strip())
                self.signals.log.emit(line.strip())

            process.wait()
            self.signals.log.emit(f"[✓] {name} finished\n")
        except Exception as e:
            self.signals.log.emit(f"[!] Error in {name}: {e}")

        return output

    def run(self):
        steps = 1 + int(self.use_sqlmap) + int(self.use_zap)
        completed = 0

        # WhatWeb
        self.results["whatweb"] = self.run_command(["whatweb", self.target], "WhatWeb")
        completed += 1
        self.signals.progress.emit(int((completed / steps) * 100))

        # SQLMap
        if self.use_sqlmap:
            self.results["sqlmap"] = self.run_command([
                "sqlmap", "-u", self.target, "--batch", "--level", "2", "--risk", "1"
            ], "SQLMap")
            completed += 1
            self.signals.progress.emit(int((completed / steps) * 100))

        # ZAP
        if self.use_zap:
            zap_steps = [
                ["zap-cli", "start"],
                ["zap-cli", "open-url", self.target],
                ["zap-cli", "spider", self.target],
                ["zap-cli", "active-scan", self.target],
                ["zap-cli", "report", "-o", "zap_report.html", "-f", "html"],
                ["zap-cli", "shutdown"]
            ]
            zap_output = []
            for step in zap_steps:
                zap_output += self.run_command(step, "ZAP")

            self.results["zap"] = zap_output
            completed += 1
            self.signals.progress.emit(int((completed / steps) * 100))

        self.signals.finished.emit()


# =========================
# GUI
# =========================
class PentestGUI(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Pentest Toolkit PRO")
        self.resize(900, 650)

        layout = QVBoxLayout()

        self.target_input = QLineEdit()
        self.target_input.setPlaceholderText("Enter target URL (e.g. http://example.com)")
        layout.addWidget(self.target_input)

        self.sqlmap_checkbox = QCheckBox("Enable SQLMap Scan")
        layout.addWidget(self.sqlmap_checkbox)

        self.zap_checkbox = QCheckBox("Enable OWASP ZAP Scan")
        layout.addWidget(self.zap_checkbox)

        self.progress_bar = QProgressBar()
        layout.addWidget(self.progress_bar)

        self.start_button = QPushButton("Start Scan")
        self.start_button.clicked.connect(self.start_scan)
        layout.addWidget(self.start_button)

        self.save_button = QPushButton("Save JSON Report")
        self.save_button.clicked.connect(self.save_output)
        layout.addWidget(self.save_button)

        self.output = QTextEdit()
        self.output.setReadOnly(True)
        layout.addWidget(self.output)

        self.setLayout(layout)

        self.results = {}

    def log(self, message):
        self.output.append(message)

    def update_progress(self, value):
        self.progress_bar.setValue(value)

    def scan_finished(self):
        self.log("[✓] All scans completed")

    def start_scan(self):
        target = self.target_input.text().strip()

        if not target:
            self.log("[!] Please enter a target")
            return

        self.log(f"[+] Starting scan for: {target}\n")

        # Authorization check
        confirm = input("Are you authorized to scan this target? (yes/no): ")
        if confirm != "yes":
            self.log("[!] Authorization denied")
            return

        self.signals = WorkerSignals()
        self.signals.log.connect(self.log)
        self.signals.progress.connect(self.update_progress)
        self.signals.finished.connect(self.scan_finished)

        self.worker = ScanWorker(
            target,
            self.sqlmap_checkbox.isChecked(),
            self.zap_checkbox.isChecked(),
            self.signals
        )

        self.worker.start()
        self.results = self.worker.results

    def save_output(self):
        path, _ = QFileDialog.getSaveFileName(self, "Save Report", "report.json")
        if path:
            with open(path, "w") as f:
                json.dump(self.worker.results, f, indent=4)
            self.log(f"[+] JSON report saved to {path}")


# =========================
# MAIN
# =========================
if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = PentestGUI()
    window.show()
    sys.exit(app.exec_())
