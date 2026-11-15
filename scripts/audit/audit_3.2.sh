#!/bin/bash
# CIS 3.2 Ensure the Apache User Account Has an Invalid Shell (Automated)

get_shell() {
  grep "^apache:" /etc/passwd | awk -F: '{print $7}'
}

if ! grep -q "^apache:" /etc/passwd; then
  echo "[FAIL] User apache not found in /etc/passwd (Current: missing | Expected: valid user)"
  exit 1
fi

TARGET_SHELL="$(get_shell)"

if [ "$TARGET_SHELL" = "/sbin/nologin" ] || [ "$TARGET_SHELL" = "/dev/null" ]; then
  echo "[PASS] Apache user shell is invalid (Current: $TARGET_SHELL | Expected: /sbin/nologin or /dev/null)"
  exit 0
else
  echo "[FAIL] Apache user shell is valid (Current: $TARGET_SHELL | Expected: /sbin/nologin or /dev/null)"
  exit 1
fi
