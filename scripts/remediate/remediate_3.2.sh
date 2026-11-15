#!/bin/bash
# CIS 3.2 Ensure the Apache User Account Has an Invalid Shell (Automated) - Remediation

VALID_SHELL="/sbin/nologin"

get_shell() {
  grep "^apache:" /etc/passwd | awk -F: '{print $7}'
}

if ! grep -q "^apache:" /etc/passwd; then
  echo "[FAIL] User apache not found in /etc/passwd (Current: missing | Expected: valid user)"
  exit 1
fi

TARGET_SHELL="$(get_shell)"

if [ "$TARGET_SHELL" = "/sbin/nologin" ] || [ "$TARGET_SHELL" = "/dev/null" ]; then
  echo "[PASS] Apache user shell is already invalid (Current: $TARGET_SHELL | Expected: /sbin/nologin or /dev/null)"
  exit 0
else
  usermod -s "$VALID_SHELL" apache 2>/dev/null

  NEW_SHELL="$(get_shell)"
  if [ "$NEW_SHELL" = "/sbin/nologin" ] || [ "$NEW_SHELL" = "/dev/null" ]; then
    echo "[REMEDIATED] Updated Apache shell from $TARGET_SHELL to $NEW_SHELL (Current: $NEW_SHELL | Expected: /sbin/nologin or /dev/null)"
    exit 0
  else
    echo "[FAIL] Failed to change Apache shell (Current: $NEW_SHELL | Expected: /sbin/nologin or /dev/null)"
    exit 1
  fi
fi
