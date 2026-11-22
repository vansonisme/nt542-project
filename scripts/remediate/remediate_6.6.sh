#!/bin/bash
# CIS 6.6 Ensure ModSecurity Is Installed and Enabled (Automated) - Remediation
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
  echo "[PASS] ModSecurity module status already compliant (Current: $RESULT | Expected: loaded)"
  exit 0
else

  # Install mod_security if not present
  if ! rpm -q mod_security &>/dev/null; then
    if ! yum install -y mod_security >/dev/null 2>&1; then
      echo "[FAIL] Failed to install mod_security (Current: not_installed | Expected: installed)"
      exit 1
    fi
  fi

  # Ensure LoadModule directive exists
  if ! httpd -M 2>/dev/null | grep -q security2_module; then
    local_conf=/etc/httpd/conf.modules.d/99-cis-modsecurity.conf
    printf '%s\n' 'LoadModule security2_module modules/mod_security2.so' > "$local_conf"
  fi

  if ! httpd -t >/dev/null 2>&1; then
    echo "[FAIL] Apache configuration syntax check failed (Current: invalid | Expected: valid)"
    exit 1
  fi
  if ! systemctl restart httpd >/dev/null 2>&1; then
    echo "[FAIL] Failed to restart httpd service (Current: restart_failed | Expected: running)"
    exit 1
  fi

  RESULT=$(get_value)
  if [ "$RESULT" = "loaded" ]; then
    echo "[REMEDIATED] ModSecurity module status (Current: $RESULT | Expected: loaded)"
    exit 0
  else
    echo "[FAIL] ModSecurity module status (Current: $RESULT | Expected: loaded)"
    exit 1
  fi
fi
