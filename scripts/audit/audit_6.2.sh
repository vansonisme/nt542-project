#!/bin/bash
# CIS 6.2 Ensure a Syslog Facility Is Configured for Error Logging (Manual)
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
  echo "[PASS] CIS 6.2 - ErrorLog syslog configuration (Current: $RESULT | Expected: syslog)"
  exit 0
else
  echo "[FAIL] CIS 6.2 - ErrorLog syslog configuration (Current: $RESULT | Expected: syslog)"
  exit 1
fi
