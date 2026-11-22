#!/bin/bash
# CIS 10.4 Ensure LimitRequestBody is explicitly restricted - Remediation

CONF="/etc/httpd/conf.d/cis-10-4-limitrequestbody.conf"

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
  echo "[PASS] LimitRequestBody is already restricted (Current: compliant | Expected: 1-102400)"
  exit 0
fi

if [ "$RESULT" = apache_config_invalid ]; then
  echo "[FAIL] Apache config is invalid before remediation (Current: invalid | Expected: valid)"
  exit 1
fi

BACKUP=$(mktemp) || {
  echo "[FAIL] Could not create config backup (Current: $RESULT | Expected: 1-102400)"
  exit 1
}

EXISTED=0
if [ -e "$CONF" ]; then
  if ! cp -p "$CONF" "$BACKUP"; then
    rm -f "$BACKUP"
    echo "[FAIL] Could not back up LimitRequestBody config (Current: $RESULT | Expected: 1-102400)"
    exit 1
  fi
  EXISTED=1
fi

restore_config() {
  if [ "$EXISTED" -eq 1 ]; then
    cp -p "$BACKUP" "$CONF"
  else
    rm -f "$CONF"
  fi
}

TMP_CONF=$(mktemp) || {
  rm -f "$BACKUP"
  echo "[FAIL] Could not create LimitRequestBody config (Current: $RESULT | Expected: 1-102400)"
  exit 1
}

cat > "$TMP_CONF" <<'CONFIG'
# CIS Apache HTTP Server Benchmark 2.4 - 10.4
LimitRequestBody 102400
CONFIG

if ! install -o root -g root -m 0644 "$TMP_CONF" "$CONF"; then
  rm -f "$TMP_CONF"
  restore_config
  rm -f "$BACKUP"
  echo "[FAIL] Could not install LimitRequestBody config (Current: $RESULT | Expected: 1-102400)"
  exit 1
fi
rm -f "$TMP_CONF"

if ! httpd -t >/dev/null 2>&1; then
  restore_config
  rm -f "$BACKUP"
  echo "[FAIL] Apache config validation failed; original restored (Current: $RESULT | Expected: 1-102400)"
  exit 1
fi

if ! systemctl reload httpd >/dev/null 2>&1; then
  restore_config
  systemctl reload httpd >/dev/null 2>&1
  rm -f "$BACKUP"
  echo "[FAIL] Apache reload failed; original restored (Current: $RESULT | Expected: 1-102400)"
  exit 1
fi

RESULT=$(get_value)

if [ "$RESULT" = compliant ]; then
  rm -f "$BACKUP"
  echo "[REMEDIATED] LimitRequestBody set to 102400 and Apache reloaded (Current: compliant | Expected: 1-102400)"
  exit 0
fi

restore_config
systemctl reload httpd >/dev/null 2>&1
rm -f "$BACKUP"
echo "[FAIL] LimitRequestBody verification failed (Current: $RESULT | Expected: 1-102400)"
exit 1
