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
  echo "[PASS] CIS 6.6 - ModSecurity module status already compliant (Current: $RESULT | Expected: loaded)"
  exit 0
else
  echo "Remediating: installing and enabling ModSecurity..." >&2

  # Install mod_security if not present
  if ! rpm -q mod_security &>/dev/null; then
    echo "Installing mod_security package..." >&2
    yum install -y mod_security >&2
  fi

  # Ensure LoadModule directive exists
  if ! httpd -M 2>/dev/null | grep -q security2_module; then
    echo "Adding LoadModule for security2_module..." >&2
    local_conf=/etc/httpd/conf.modules.d/99-cis-modsecurity.conf
    printf '%s\n' 'LoadModule security2_module modules/mod_security2.so' > "$local_conf"
  fi

  httpd -t 2>&2
  systemctl restart httpd

  RESULT=$(get_value)
  if [ "$RESULT" = "loaded" ]; then
    echo "[REMEDIATED] CIS 6.6 - ModSecurity module status (Current: $RESULT | Expected: loaded)"
    exit 0
  else
    echo "[FAIL] CIS 6.6 - ModSecurity module status (Current: $RESULT | Expected: loaded)"
    exit 1
  fi
fi
