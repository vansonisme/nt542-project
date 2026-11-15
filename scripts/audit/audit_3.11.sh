#!/bin/bash
# CIS 3.11 Ensure Group Write Access for the Apache Directories and Files Is Properly Restricted (Manual)

APACHE_PREFIX=$(httpd -V 2>/dev/null | grep "HTTPD_ROOT" | awk -F'"' '{print $2}')

if [ -z "$APACHE_PREFIX" ] || [ ! -d "$APACHE_PREFIX" ]; then
  echo "[ERROR] HTTPD_ROOT directory not found (Current: invalid/missing | Expected: valid path)"
  exit 1
fi

RESULT=$(find -L "$APACHE_PREFIX" \! -type l -perm /g=w -ls 2>/dev/null)

if [ -z "$RESULT" ]; then
  echo "[PASS] Group write permissions in $APACHE_PREFIX: none (Current: none | Expected: none)"
  exit 0
else
  echo "[FAIL] Group write permissions found in $APACHE_PREFIX (Current: present | Expected: none)"
  exit 1
fi
