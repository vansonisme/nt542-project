#!/bin/bash
# CIS 3.2 Ensure the Apache User Account Has an Invalid Shell (Automated)

VALID_SHELL="/sbin/nologin"
TARGET_SHELL="$(grep "^apache:" /etc/passwd | awk -F: '{print $7}')"

if [ -z "$TARGET_SHELL" ]; then
  echo "[FAIL] User apache not found in /etc/passwd (Current: missing | Expected: valid user)"
  exit 1
fi

if [ "$TARGET_SHELL" = "/sbin/nologin" ] || [ "$TARGET_SHELL" = "/dev/null" ]; then
  echo "[PASS] Apache user shell is already invalid (Current: $TARGET_SHELL | Expected: /sbin/nologin or /dev/null)"
  exit 0
else
  if ! command -v chsh >/dev/null 2>&1; then
    echo "[INFO] Installing package util-linux-user..."
    if ! dnf install -y util-linux-user >/dev/null 2>&1; then
      echo "[FAIL] Failed to install util-linux-user (Check root privileges or network)"
      exit 1
    fi
  fi

  if chsh -s "$VALID_SHELL" apache 2>/dev/null; then
    NEW_SHELL="$(grep "^apache:" /etc/passwd | awk -F: '{print $7}')"
    if [ "$NEW_SHELL" = "/sbin/nologin" ] || [ "$NEW_SHELL" = "/dev/null" ]; then
      echo "[REMEDIATED] Updated Apache shell from $TARGET_SHELL to $NEW_SHELL (Current: $NEW_SHELL | Expected: /sbin/nologin or /dev/null)"
      exit 0
    else
      echo "[FAIL] Apache shell verification failed (Current: $NEW_SHELL | Expected: $VALID_SHELL)"
      exit 1
    fi
  else
    echo "[FAIL] Failed to change Apache shell (Root privileges required)"
    exit 1
  fi
fi
