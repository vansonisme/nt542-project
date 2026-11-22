#!/bin/bash
# CIS 5.18 Configure the Permissions-Policy header - Remediation

CONF="/etc/httpd/conf.d/cis-5-18-permissions-policy.conf"

get_value() {
  local modules response

  modules=$(httpd -M 2>/dev/null) || {
    echo apache_error
    return 0
  }

  if ! grep -Eq '^[[:space:]]*headers_module[[:space:]]+\(' <<< "$modules"; then
    echo headers_module_missing
    return 0
  fi

  response=$(curl -sS -D - -o /dev/null --max-time 10 http://127.0.0.1/ 2>/dev/null) || {
    echo request_failed
    return 0
  }

  if ! grep -Eq '^HTTP/[0-9.]+ 200([[:space:]]|$)' <<< "$response"; then
    echo http_status_not_200
    return 0
  fi

  if ! grep -Eiq '^Permissions-Policy:[[:space:]]*camera=\(\),[[:space:]]*microphone=\(\),[[:space:]]*geolocation=\(\)[[:space:]]*$' <<< "$response"; then
    echo header_missing_or_incorrect
    return 0
  fi

  echo compliant
}

if ! command -v httpd >/dev/null 2>&1; then
  echo "[FAIL] Apache httpd is not installed (Current: missing | Expected: installed)"
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "[FAIL] curl is not installed (Current: missing | Expected: installed)"
  exit 1
fi

if ! RESULT=$(get_value); then
  echo "[FAIL] Could not inspect Permissions-Policy (Current: unknown | Expected: compliant)"
  exit 1
fi

if [ "$RESULT" = compliant ]; then
  echo "[PASS] Permissions-Policy is already configured (Current: compliant | Expected: compliant)"
  exit 0
fi

if [ "$RESULT" = headers_module_missing ] || [ "$RESULT" = apache_error ]; then
  echo "[FAIL] mod_headers is unavailable (Current: $RESULT | Expected: headers_module loaded)"
  exit 1
fi

BACKUP=$(mktemp) || {
  echo "[FAIL] Could not create config backup (Current: $RESULT | Expected: compliant)"
  exit 1
}

EXISTED=0
if [ -e "$CONF" ]; then
  if ! cp -p "$CONF" "$BACKUP"; then
    rm -f "$BACKUP"
    echo "[FAIL] Could not back up Permissions-Policy config (Current: $RESULT | Expected: compliant)"
    exit 1
  fi
  EXISTED=1
fi

restore_config() {
  if [ "$EXISTED" -eq 1 ]; then
    cp -p "$BACKUP" "$CONF"
  else
    rm -f "$CONF"
  fi
}

NEW_CONF=$(mktemp "${CONF}.XXXXXX") || {
  rm -f "$BACKUP"
  echo "[FAIL] Could not create Permissions-Policy config (Current: $RESULT | Expected: compliant)"
  exit 1
}

cat > "$NEW_CONF" <<'CONFIG'
# CIS 5.18 - Restrict unnecessary browser features
Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
CONFIG

chmod 0644 "$NEW_CONF"
mv "$NEW_CONF" "$CONF"

if ! httpd -t >/dev/null 2>&1; then
  restore_config
  rm -f "$BACKUP"
  echo "[FAIL] Apache config validation failed; original restored (Current: $RESULT | Expected: compliant)"
  exit 1
fi

if ! systemctl reload httpd >/dev/null 2>&1; then
  restore_config
  systemctl reload httpd >/dev/null 2>&1
  rm -f "$BACKUP"
  echo "[FAIL] Apache reload failed; original restored (Current: $RESULT | Expected: compliant)"
  exit 1
fi

RESULT=$(get_value)

if [ "$RESULT" = compliant ]; then
  rm -f "$BACKUP"
  echo "[REMEDIATED] Permissions-Policy configured and Apache reloaded (Current: compliant | Expected: compliant)"
  exit 0
fi

restore_config
systemctl reload httpd >/dev/null 2>&1
rm -f "$BACKUP"
echo "[FAIL] Permissions-Policy verification failed (Current: $RESULT | Expected: compliant)"
exit 1
