#!/bin/bash
# CIS 7.1 Ensure mod_ssl and/or mod_nss Is Installed (Automated) - Remediation

DIRECTIVE="LoadModule ssl_module modules/mod_ssl.so"
DEFAULT_FILE="/etc/httpd/conf.modules.d/00-ssl.conf"
CONF_FILES="/etc/httpd/conf/httpd.conf /etc/httpd/conf.modules.d/*.conf"

get_module() {
  httpd -M 2>/dev/null | grep -E 'ssl_module|nss_module' | awk '{print $1}' | head -n 1
}

RESULT=$(get_module)

if [ "$RESULT" = "ssl_module" ] || [ "$RESULT" = "nss_module" ]; then
  echo "[PASS] Active encryption module is already $RESULT (Current: $RESULT | Expected: ssl_module or nss_module)"
  exit 0
else
  if ! rpm -q mod_ssl >/dev/null 2>&1; then
    if ! dnf install -y mod_ssl >/dev/null 2>&1; then
      echo "[FAIL] Failed to install mod_ssl (Current: none | Expected: ssl_module or nss_module)"
      exit 1
    fi
  fi

  ACTIVE=$(grep -lE "^[[:space:]]*LoadModule[[:space:]]+ssl_module" $CONF_FILES 2>/dev/null)

  if [ -z "$ACTIVE" ]; then
    COMMENTED=$(grep -lE "^[[:space:]]*#[[:space:]]*LoadModule[[:space:]]+ssl_module" $CONF_FILES 2>/dev/null | head -n 1)

    if [ -n "$COMMENTED" ]; then
      sed -i "s|^[[:space:]]*#[[:space:]]*LoadModule[[:space:]]\+ssl_module.*|$DIRECTIVE|" "$COMMENTED"
    else
      echo "$DIRECTIVE" >> "$DEFAULT_FILE"
    fi
  fi

  if ! systemctl restart httpd 2>/dev/null; then
    echo "[FAIL] Failed to restart httpd service (Current: none | Expected: ssl_module or nss_module)"
    exit 1
  fi

  NEW_RESULT=$(get_module)
  if [ "$NEW_RESULT" = "ssl_module" ] || [ "$NEW_RESULT" = "nss_module" ]; then
    echo "[REMEDIATED] Installed and enabled $NEW_RESULT (Current: $NEW_RESULT | Expected: ssl_module or nss_module)"
    exit 0
  else
    echo "[FAIL] Encryption module is still not loaded after remediation (Current: none | Expected: ssl_module or nss_module)"
    exit 1
  fi
fi
