#!/bin/bash
# CIS 5.4 Ensure Default HTML Content Is Removed (Automated) - Remediation
set -euo pipefail

get_value() {
  local file="/etc/httpd/conf.d/welcome.conf"
  if [ ! -f "$file" ]; then
    echo "absent"
  elif grep -qE '^[[:space:]]*[^#[:space:]]' "$file" 2>/dev/null; then
    echo "enabled"
  else
    echo "disabled"
  fi
}

RESULT=$(get_value)

if [[ "$RESULT" == "disabled" || "$RESULT" == "absent" ]]; then
  echo "[PASS] Default HTML content (welcome.conf) already compliant (Current: $RESULT | Expected: disabled or absent)"
  exit 0
else
  sed -i '/^[[:space:]]*[^#[:space:]]/s/^/# /' /etc/httpd/conf.d/welcome.conf

  RESULT=$(get_value)
  if [[ "$RESULT" == "disabled" || "$RESULT" == "absent" ]]; then
    echo "[REMEDIATED] Default HTML content (welcome.conf) (Current: $RESULT | Expected: disabled or absent)"
    exit 0
  else
    echo "[FAIL] Default HTML content (welcome.conf) (Current: $RESULT | Expected: disabled or absent)"
    exit 1
  fi
fi
