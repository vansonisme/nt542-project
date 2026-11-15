#!/bin/bash
# CIS 2.2 Ensure the Log Config Module Is Enabled (Automated)

RESULT=$(httpd -M 2>/dev/null | grep "log_config_module" | awk '{print $1}')

if [ "$RESULT" = "log_config_module" ]; then
  echo "[PASS] log_config_module is loaded (Current: loaded | Expected: loaded)"
  exit 0
else
  echo "[FAIL] log_config_module is not loaded (Current: not loaded | Expected: loaded)"
  exit 1
fi
