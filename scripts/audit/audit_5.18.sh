#!/bin/bash
# CIS 5.18 Configure the Permissions-Policy header

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

  if ! grep -RIEq '^[[:space:]]*Header[[:space:]]+always[[:space:]]+set[[:space:]]+Permissions-Policy[[:space:]].*camera=\(\),[[:space:]]*microphone=\(\),[[:space:]]*geolocation=\(\)' /etc/httpd/conf /etc/httpd/conf.d 2>/dev/null; then
    echo local_directive_missing
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

RESULT=$(get_value)

if [ "$RESULT" = compliant ]; then
  echo "[PASS] Permissions-Policy header is configured (Current: compliant | Expected: compliant)"
  exit 0
else
  echo "[FAIL] Permissions-Policy check failed (Current: $RESULT | Expected: compliant)"
  exit 1
fi
