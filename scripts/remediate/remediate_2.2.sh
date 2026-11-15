#!/bin/bash
# CIS 2.2 Ensure the Log Config Module Is Enabled (Automated)
# Remediation: dynamically loaded module -> LoadModule directive present and not commented out

DIRECTIVE="LoadModule log_config_module modules/mod_log_config.so"
DEFAULT_FILE="/etc/httpd/conf.modules.d/00-base.conf"
CONF_FILES="/etc/httpd/conf/httpd.conf /etc/httpd/conf.modules.d/*.conf"

check_module() {
  httpd -M 2>/dev/null | grep -q "log_config_module"
}

# Audit
if check_module; then
  echo "[PASS] log_config_module is already loaded (Current: loaded | Expected: loaded)"
  exit 0
fi

# Đảm bảo có dòng LoadModule không bị comment
ACTIVE=$(grep -lE "^[[:space:]]*LoadModule[[:space:]]+log_config_module" $CONF_FILES 2>/dev/null)

if [ -z "$ACTIVE" ]; then
  COMMENTED=$(grep -lE "^[[:space:]]*#[[:space:]]*LoadModule[[:space:]]+log_config_module" $CONF_FILES 2>/dev/null | head -n 1)

  if [ -n "$COMMENTED" ]; then
    sed -i "s|^[[:space:]]*#[[:space:]]*LoadModule[[:space:]]\+log_config_module.*|$DIRECTIVE|" "$COMMENTED"
  else
    echo "$DIRECTIVE" >> "$DEFAULT_FILE"
  fi
fi

# Áp dụng
if ! systemctl restart httpd 2>/dev/null; then
  echo "[FAIL] Failed to restart httpd service (Check root privileges or httpd config syntax)"
  exit 1
fi

# Xác minh
if check_module; then
  echo "[REMEDIATED] log_config_module directive enabled and httpd restarted (Current: loaded | Expected: loaded)"
  exit 0
else
  echo "[FAIL] log_config_module is still not loaded after remediation (Current: not loaded | Expected: loaded)"
  exit 1
fi
