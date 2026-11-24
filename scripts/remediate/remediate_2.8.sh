#!/bin/bash
# CIS 2.8 Ensure the Info Module Is Disabled - Remediation

CONF="/etc/httpd/conf.modules.d/00-base.conf"

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
  echo "[PASS] info_module is already disabled (Current: disabled | Expected: disabled)"
  exit 0
fi

if [ ! -f "$CONF" ]; then
  echo "[FAIL] Apache module config not found (Current: missing | Expected: $CONF)"
  exit 1
fi

BACKUP=$(mktemp) || {
  echo "[FAIL] Could not create config backup (Current: enabled | Expected: disabled)"
  exit 1
}

if ! cp -p "$CONF" "$BACKUP"; then
  rm -f "$BACKUP"
  echo "[FAIL] Could not back up Apache config (Current: enabled | Expected: disabled)"
  exit 1
fi

sed -i -E \
  '/^[[:space:]]*LoadModule[[:space:]]+info_module[[:space:]]+modules\/mod_info\.so([[:space:]]|$)/s/^([[:space:]]*)LoadModule/#\1LoadModule/' \
  "$CONF"

if cmp -s "$BACKUP" "$CONF"; then
  rm -f "$BACKUP"
  echo "[FAIL] Active info_module directive not found in $CONF (Current: enabled | Expected: disabled)"
  exit 1
fi

if ! httpd -t >/dev/null 2>&1; then
  cp -p "$BACKUP" "$CONF"
  rm -f "$BACKUP"
  echo "[FAIL] Apache config invalid; original restored (Current: enabled | Expected: disabled)"
  exit 1
fi

if ! systemctl restart httpd >/dev/null 2>&1; then
  cp -p "$BACKUP" "$CONF"
  systemctl restart httpd >/dev/null 2>&1
  rm -f "$BACKUP"
  echo "[FAIL] Apache restart failed; original restored (Current: enabled | Expected: disabled)"
  exit 1
fi

rm -f "$BACKUP"

if ! RESULT=$(get_value); then
  echo "[FAIL] Could not verify Apache modules (Current: unknown | Expected: disabled)"
  exit 1
fi

if [ "$RESULT" = disabled ]; then
  echo "[REMEDIATED] info_module disabled and Apache restarted (Current: disabled | Expected: disabled)"
  exit 0
else
  echo "[FAIL] info_module is still enabled (Current: enabled | Expected: disabled)"
  exit 1
fi
