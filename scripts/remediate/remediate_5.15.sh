#!/bin/bash
# CIS 5.15 Ensure the IP Addresses for Listening for Requests Are Specified (Automated) - Remediation
# Usage: bash remediate_5.15.sh [IP_ADDRESS]
set -euo pipefail

get_value() {
  shopt -s nullglob
  local files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
  local lines
  lines=$(grep -hiE '^[[:space:]]*Listen[[:space:]]' "${files[@]}" 2>/dev/null || true)

  if [ -z "$lines" ]; then
    echo "missing"
    return
  fi

  while read -r _ address _; do
    if [[ "$address" != *:* || "$address" == 0.0.0.0:* || "$address" == \*:* || "$address" == \[::\]:* || "$address" == \[::ffff:0.0.0.0\]:* ]]; then
      echo "unrestricted"
      return
    fi
  done <<< "$lines"

  echo "restricted"
}

RESULT=$(get_value)

if [ "$RESULT" = "restricted" ]; then
  echo "[PASS] Listen directive IP binding already compliant (Current: $RESULT | Expected: restricted)"
  exit 0
else
  BIND_IP=${1:-$(hostname -I | awk '{print $1}')}

  # Validate the IP exists on the host
  if ! ip -o -4 addr show | grep -Fq " $BIND_IP/"; then
    echo "[FAIL] Listen directive IP binding (Current: $RESULT | Expected: restricted) - IP $BIND_IP not found on host"
    exit 1
  fi

  FILE=/etc/httpd/conf/httpd.conf

  if [ ! -e "$FILE.cis.bak" ]; then
    cp -p "$FILE" "$FILE.cis.bak"
  fi

  if grep -Eq '^[[:space:]]*Listen[[:space:]]' "$FILE"; then
    sed -Ei "s|^[[:space:]]*Listen[[:space:]]+.*$|Listen ${BIND_IP}:80|" "$FILE"
  else
    printf '\nListen %s:80\n' "$BIND_IP" >> "$FILE"
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
  if [ "$RESULT" = "restricted" ]; then
    echo "[REMEDIATED] Listen directive IP binding (Current: $RESULT | Expected: restricted)"
    exit 0
  else
    echo "[FAIL] Listen directive IP binding (Current: $RESULT | Expected: restricted)"
    exit 1
  fi
fi
