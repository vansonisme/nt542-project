#!/bin/bash
# CIS 3.11 Ensure Group Write Access for the Apache Directories and Files Is Properly Restricted (Manual) - Remediation

APACHE_PREFIX=$(httpd -V 2>/dev/null | grep "HTTPD_ROOT" | awk -F'"' '{print $2}')

get_result() {
  find -L "$APACHE_PREFIX" \! -type l -perm /g=w -ls 2>/dev/null
}

if [ -z "$APACHE_PREFIX" ] || [ ! -d "$APACHE_PREFIX" ]; then
  echo "[FAIL] HTTPD_ROOT directory not found (Current: invalid/missing | Expected: valid path)"
  exit 1
fi

RESULT=$(get_result)

if [ -z "$RESULT" ]; then
  echo "[PASS] Group write permissions in $APACHE_PREFIX: none (Current: none | Expected: none)"
  exit 0
else
  find -L "$APACHE_PREFIX" \! -type l -perm /g=w -exec chmod g-w {} + 2>/dev/null

  NEW_RESULT=$(get_result)
  if [ -z "$NEW_RESULT" ]; then
    echo "[REMEDIATED] Stripped group write permissions in $APACHE_PREFIX (Current: none | Expected: none)"
    exit 0
  else
    echo "[FAIL] Group write permissions still exist in $APACHE_PREFIX (Current: present | Expected: none)"
    exit 1
  fi
fi
