#!/bin/bash
# CIS 7.1 Ensure mod_ssl and/or mod_nss Is Installed (Automated)

RESULT=$(httpd -M 2>/dev/null | egrep 'ssl_module|nss_module' | awk '{print $1}' | head -n 1)

if [ "$RESULT" = "ssl_module" ] || [ "$RESULT" = "nss_module" ]; then
  echo "[PASS] Active encryption module is $RESULT (Current: $RESULT | Expected: ssl_module or nss_module)"
  exit 0
else
  echo "[FAIL] Active encryption module is missing (Current: none | Expected: ssl_module or nss_module)"
  exit 1
fi
