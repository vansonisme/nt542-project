
#!/bin/bash

APACHE_PREFIX="/etc/httpd"
CONFIG_FILE="$APACHE_PREFIX/conf/httpd.conf"
APACHE_BIN="httpd"
MODULE="autoindex_module"

# Check whether Apache binary exists
if ! command -v "$APACHE_BIN" >/dev/null 2>&1; then
    echo "[FAIL] Apache binary does not exist (Current: Missing | Expected: $APACHE_BIN)"
    exit 1
fi

# Check whether configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file does not exist (Current: Missing | Expected: $CONFIG_FILE)"
    exit 1
fi

# Check whether configuration file is readable and writable
if [[ ! -r "$CONFIG_FILE" || ! -w "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file is not accessible (Current: Read/write unavailable | Expected: Read/write available)"
    exit 1
fi

# Check whether Autoindex module is loaded
MODULES=$("$APACHE_BIN" -M 2>/dev/null)

if [[ $? -ne 0 ]]; then
    echo "[FAIL] Unable to retrieve Apache modules (Current: Command failed | Expected: Module list)"
    exit 1
fi

if ! echo "$MODULES" | grep -qE '^[[:space:]]*autoindex_module([[:space:]]|\()'; then
    echo "[PASS] Autoindex module is already disabled (Current: Not loaded | Expected: Disabled)"
    exit 0
fi

# Check whether Autoindex is dynamically loaded
if ! grep -qiE '^[[:space:]]*LoadModule[[:space:]]+autoindex_module[[:space:]]+' "$CONFIG_FILE"; then
    echo "[FAIL] Autoindex module is loaded but LoadModule directive was not found (Current: Loaded | Expected: Disabled)"
    exit 1
fi

# Create backup
BACKUP_FILE="${CONFIG_FILE}.cis-2.5.bak"

if ! cp -p "$CONFIG_FILE" "$BACKUP_FILE"; then
    echo "[FAIL] Unable to create configuration backup (Current: Backup failed | Expected: Backup created)"
    exit 1
fi

# Disable Autoindex module
if ! sed -i -E '/^[[:space:]]*LoadModule[[:space:]]+autoindex_module[[:space:]]+/s/^([[:space:]]*)LoadModule/\1#LoadModule/' "$CONFIG_FILE"; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Unable to disable Autoindex module (Current: Configuration update failed | Expected: Disabled)"
    exit 1
fi

# Verify Apache configuration syntax
if ! "$APACHE_BIN" -t >/dev/null 2>&1; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Apache configuration test failed (Current: Invalid configuration | Expected: Valid configuration)"
    exit 1
fi

# Reload Apache if service is running
if systemctl is-active --quiet httpd; then
    if ! systemctl reload httpd >/dev/null 2>&1; then
        cp -p "$BACKUP_FILE" "$CONFIG_FILE"
        systemctl reload httpd >/dev/null 2>&1
        echo "[FAIL] Unable to reload Apache (Current: Reload failed | Expected: Reload successful)"
        exit 1
    fi
fi

# Re-audit
MODULES=$("$APACHE_BIN" -M 2>/dev/null)

if [[ $? -eq 0 ]] && ! echo "$MODULES" | grep -qE '^[[:space:]]*autoindex_module([[:space:]]|\()'; then
    echo "[REMEDIATED] Autoindex module has been disabled (Current: Not loaded | Expected: Disabled)"
    exit 0
else
    echo "[FAIL] Autoindex module is still enabled (Current: Loaded | Expected: Disabled)"
    exit 1
fi
