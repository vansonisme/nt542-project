
#!/bin/bash

CONFIG_DIR="/etc/httpd"
MODULE="autoindex_module"
CONFIG_FILE="/etc/httpd/conf.modules.d/00-base.conf"
BACKUP_FILE="${CONFIG_FILE}.cis-2.5.bak"

# Check Apache configuration file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[FAIL] Module configuration file does not exist (Current: Missing | Expected: $CONFIG_FILE)"
    exit 1
fi

if [[ ! -r "$CONFIG_FILE" || ! -w "$CONFIG_FILE" ]]; then
    echo "[FAIL] Module configuration file is not accessible (Current: Unreadable or unwritable | Expected: Readable and writable)"
    exit 1
fi

# Check current module status
if ! httpd -M 2>/dev/null | grep -qE '^[[:space:]]*autoindex_module([[:space:]]|\()'; then
    echo "[PASS] Autoindex module is already disabled (Current: Not loaded | Expected: Disabled)"
    exit 0
fi

# Check LoadModule directive
if ! grep -qiE '^[[:space:]]*LoadModule[[:space:]]+autoindex_module[[:space:]]+' "$CONFIG_FILE"; then
    echo "[FAIL] Autoindex module is loaded but directive was not found (Current: Loaded | Expected: Disabled)"
    exit 1
fi

# Create backup
if ! cp -p "$CONFIG_FILE" "$BACKUP_FILE"; then
    echo "[FAIL] Cannot create configuration backup (Current: Backup failed | Expected: Backup successful)"
    exit 1
fi

# Disable autoindex module
if ! sed -i -E '/^[[:space:]]*LoadModule[[:space:]]+autoindex_module[[:space:]]+/I s/^/#/' "$CONFIG_FILE"; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Cannot disable Autoindex module (Current: Update failed | Expected: Disabled)"
    exit 1
fi

# Validate Apache configuration
if ! httpd -t >/dev/null 2>&1; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Apache configuration validation failed (Current: Invalid | Expected: Valid)"
    exit 1
fi

# Reload Apache if running
if systemctl is-active --quiet httpd; then
    if ! systemctl reload httpd >/dev/null 2>&1; then
        cp -p "$BACKUP_FILE" "$CONFIG_FILE"
        systemctl reload httpd >/dev/null 2>&1
        echo "[FAIL] Apache reload failed (Current: Reload failed | Expected: Reload successful)"
        exit 1
    fi
fi

# Verify module status
if ! httpd -M 2>/dev/null | grep -qE '^[[:space:]]*autoindex_module([[:space:]]|\()'; then
    echo "[REMEDIATED] Autoindex module has been disabled (Current: Not loaded | Expected: Disabled)"
    exit 0
else
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    systemctl reload httpd >/dev/null 2>&1
    echo "[FAIL] Autoindex module is still loaded (Current: Loaded | Expected: Disabled)"
    exit 1
fi
