#!/bin/bash
# CIS 10.4 Ensure LimitRequestBody is explicitly restricted

get_value() {
  if ! httpd -t >/dev/null 2>&1; then
    echo apache_config_invalid
    return 0
  fi

  python3 - <<'PY'
from pathlib import Path
import re

roots = [Path("/etc/httpd"), Path("/var/www")]
findings = []

for root in roots:
    if not root.exists():
        continue

    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if path.suffix.lower() != ".conf" and path.name != ".htaccess":
            continue

        try:
            lines = path.read_text(errors="replace").splitlines()
        except (PermissionError, OSError):
            continue

        for number, line in enumerate(lines, 1):
            if line.lstrip().startswith("#"):
                continue

            match = re.match(r"^\s*LimitRequestBody\s+(\S+)", line, re.IGNORECASE)
            if not match:
                continue

            try:
                value = int(match.group(1))
                compliant = 1 <= value <= 102400
            except ValueError:
                compliant = False

            findings.append(compliant)

if not findings:
    print("missing")
elif all(findings):
    print("compliant")
else:
    print("noncompliant")
PY
}

if ! command -v httpd >/dev/null 2>&1; then
  echo "[FAIL] Apache httpd is not installed (Current: missing | Expected: installed)"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[FAIL] Python 3 is not installed (Current: missing | Expected: installed)"
  exit 1
fi

if ! RESULT=$(get_value 2>/dev/null); then
  echo "[FAIL] Could not inspect LimitRequestBody (Current: unknown | Expected: 1-102400)"
  exit 1
fi

if [ "$RESULT" = compliant ]; then
  echo "[PASS] LimitRequestBody values are restricted (Current: compliant | Expected: 1-102400)"
  exit 0
else
  echo "[FAIL] LimitRequestBody check failed (Current: $RESULT | Expected: 1-102400)"
  exit 1
fi
