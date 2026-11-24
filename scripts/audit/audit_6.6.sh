#!/bin/bash
# CIS 6.6 Ensure ModSecurity Is Installed and Enabled (Automated)
set -euo pipefail

get_value() {
  if httpd -M 2>/dev/null | grep -qc security2_module; then
    echo "loaded"
  else
    echo "not_loaded"
  fi
}

RESULT=$(get_value)

if [ "$RESULT" = "loaded" ]; then
  echo "[PASS] CIS 6.6 - ModSecurity module status (Current: $RESULT | Expected: loaded)"
  exit 0
else
  echo "[FAIL] CIS 6.6 - ModSecurity module status (Current: $RESULT | Expected: loaded)"
  exit 1
fi
