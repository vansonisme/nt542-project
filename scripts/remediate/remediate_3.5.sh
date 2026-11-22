#!/bin/bash
# CIS 3.5 Ensure the Group Is Set Correctly on Apache Directories and Files (Automated) - Remediation
set -euo pipefail

get_value() {
  find /etc/httpd -path /etc/httpd/htdocs -prune -o \! -group root -print 2>/dev/null | wc -l | tr -d ' '
}

RESULT=$(get_value)

if [ "$RESULT" = "0" ]; then
  echo "[PASS] Apache files group ownership already compliant (Current: $RESULT | Expected: 0)"
  exit 0
else
  find /etc/httpd -path /etc/httpd/htdocs -prune -o \! -group root -exec chgrp -h root {} +

  RESULT=$(get_value)
  if [ "$RESULT" = "0" ]; then
    echo "[REMEDIATED] Apache files group ownership (Current: $RESULT | Expected: 0)"
    exit 0
  else
    echo "[FAIL] Apache files group ownership (Current: $RESULT | Expected: 0)"
    exit 1
  fi
fi
