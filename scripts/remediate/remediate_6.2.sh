#!/bin/bash
# CIS 6.2 Ensure a Syslog Facility Is Configured for Error Logging (Manual) - Remediation
set -euo pipefail

get_value() {
  shopt -s nullglob
  local files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
  local lines
  lines=$(grep -hiE '^[[:space:]]*ErrorLog[[:space:]]' "${files[@]}" 2>/dev/null || true)

  if [ -z "$lines" ]; then
    echo "missing"
    return
  fi

  while read -r _ value _; do
    value=${value//\"/}
    if [[ ! "$value" =~ ^syslog: ]]; then
      echo "file-based"
      return
    fi
  done <<< "$lines"

  echo "syslog"
}

RESULT=$(get_value)

if [ "$RESULT" = "syslog" ]; then
  echo "[PASS] CIS 6.2 - ErrorLog syslog configuration already compliant (Current: $RESULT | Expected: syslog)"
  exit 0
else
  echo "Remediating: setting ErrorLog to syslog:local1..." >&2
  shopt -s nullglob
  files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
  for file in "${files[@]}"; do
    if grep -Eiq '^[[:space:]]*ErrorLog[[:space:]]' "$file"; then
      if [ ! -e "$file.cis.bak" ]; then
        cp -p "$file" "$file.cis.bak"
      fi
      sed -Ei 's|^[[:space:]]*ErrorLog[[:space:]]+.*$|ErrorLog "syslog:local1"|I' "$file"
    fi
  done

  # Ensure at least one ErrorLog directive exists
  if ! grep -Eiq '^[[:space:]]*ErrorLog[[:space:]]' /etc/httpd/conf/httpd.conf; then
    if [ ! -e /etc/httpd/conf/httpd.conf.cis.bak ]; then
      cp -p /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.cis.bak
    fi
    printf '\nErrorLog "syslog:local1"\n' >> /etc/httpd/conf/httpd.conf
  fi

  httpd -t 2>&2
  systemctl restart httpd

  RESULT=$(get_value)
  if [ "$RESULT" = "syslog" ]; then
    echo "[REMEDIATED] CIS 6.2 - ErrorLog syslog configuration (Current: $RESULT | Expected: syslog)"
    exit 0
  else
    echo "[FAIL] CIS 6.2 - ErrorLog syslog configuration (Current: $RESULT | Expected: syslog)"
    exit 1
  fi
fi
