#!/bin/bash
# CIS 5.15 Ensure the IP Addresses for Listening for Requests Are Specified (Automated)
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
  echo "[PASS] CIS 5.15 - Listen directive IP binding (Current: $RESULT | Expected: restricted)"
  exit 0
else
  echo "[FAIL] CIS 5.15 - Listen directive IP binding (Current: $RESULT | Expected: restricted)"
  exit 1
fi
