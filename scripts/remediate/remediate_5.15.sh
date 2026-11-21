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
  echo "[PASS] CIS 5.15 - Listen directive IP binding already compliant (Current: $RESULT | Expected: restricted)"
  exit 0
else
  BIND_IP=${1:-$(hostname -I | awk '{print $1}')}
  echo "Using bind IP: $BIND_IP" >&2

  # Validate the IP exists on the host
  if ! ip -o -4 addr show | grep -Fq " $BIND_IP/"; then
    echo "[FAIL] CIS 5.15 - Listen directive IP binding (Current: $RESULT | Expected: restricted) - IP $BIND_IP not found on host"
    exit 1
  fi

  FILE=/etc/httpd/conf/httpd.conf
  echo "Remediating: binding Listen to $BIND_IP in $FILE..." >&2

  if [ ! -e "$FILE.cis.bak" ]; then
    cp -p "$FILE" "$FILE.cis.bak"
  fi

  if grep -Eq '^[[:space:]]*Listen[[:space:]]' "$FILE"; then
    sed -Ei "s|^[[:space:]]*Listen[[:space:]]+.*$|Listen ${BIND_IP}:80|" "$FILE"
  else
    printf '\nListen %s:80\n' "$BIND_IP" >> "$FILE"
  fi

  httpd -t 2>&2
  systemctl restart httpd

  RESULT=$(get_value)
  if [ "$RESULT" = "restricted" ]; then
    echo "[REMEDIATED] CIS 5.15 - Listen directive IP binding (Current: $RESULT | Expected: restricted)"
    exit 0
  else
    echo "[FAIL] CIS 5.15 - Listen directive IP binding (Current: $RESULT | Expected: restricted)"
    exit 1
  fi
fi
