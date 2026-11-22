#!/bin/bash
# CIS 2.8 Ensure the Info Module Is Disabled

get_value() {
  local modules
  modules=$(httpd -M 2>/dev/null) || return 2
  if grep -Eq '^[[:space:]]*info_module[[:space:]]+\(' <<< "$modules"; then
    echo enabled
  else
    echo disabled
  fi
}

if ! command -v httpd >/dev/null 2>&1; then
  echo "[FAIL] Apache httpd is not installed (Current: missing | Expected: installed)"
  exit 1
fi

if ! RESULT=$(get_value); then
  echo "[FAIL] Could not read Apache modules (Current: unknown | Expected: info_module disabled)"
  exit 1
fi

if [ "$RESULT" = disabled ]; then
  echo "[PASS] info_module is disabled (Current: disabled | Expected: disabled)"
  exit 0
else
  echo "[FAIL] info_module is enabled (Current: enabled | Expected: disabled)"
  exit 1
fi
