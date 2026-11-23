
#!/bin/bash

MODULE="autoindex_module"
MODULE_FILE="/etc/httpd/conf.modules.d/00-base.conf"
AUTO_CONF="/etc/httpd/conf.d/autoindex.conf"

MODULE_BACKUP="${MODULE_FILE}.cis-2.5.bak"
AUTO_BACKUP="${AUTO_CONF}.cis-2.5.disabled"

# Check required files
if [[ ! -f "$MODULE_FILE" ]]; then
    echo "[FAIL] Module configuration file missing (Current: Missing | Expected: $MODULE_FILE)"
    exit 1
fi

# Check current module status
MODULES=$(httpd -M 2>&1)
RC=$?

if [[ $RC -ne 0 ]]; then
    echo "[FAIL] Cannot retrieve Apache modules (Current: Command failed | Expected: Module list)"
    exit 1
fi

if ! printf '%s\n' "$MODULES" | grep -qE '^[[:space:]]*autoindex_module[[:space:]]+\('; then
    if [[ -f "$AUTO_CONF" ]]; then
        echo "[FAIL] Module is unloaded but autoindex configuration is still included (Current: Config present | Expected: Disabled)"
        exit 1
    fi

    echo "[PASS] Autoindex module is already disabled (Current: Not loaded | Expected: Disabled)"
    exit 0
fi

# Check backup conflicts
if [[ -e "$AUTO_BACKUP" ]]; then
    echo "[FAIL] Autoindex backup already exists (Current: Backup conflict | Expected: No conflict)"
    exit 1
fi

# Create module backup
if ! cp -p "$MODULE_FILE" "$MODULE_BACKUP"; then
    echo "[FAIL] Cannot create module backup (Current: Failed | Expected: Successful)"
    exit 1
fi

# Disable LoadModule directive
if ! sed -i -E '/^[[:space:]]*LoadModule[[:space:]]+autoindex_module[[:space:]]+/I s/^/#/' "$MODULE_FILE"; then
    cp -p "$MODULE_BACKUP" "$MODULE_FILE"
    echo "[FAIL] Cannot disable Autoindex module (Current: Update failed | Expected: Disabled)"
    exit 1
fi

# Disable autoindex configuration file
if [[ -f "$AUTO_CONF" ]]; then
    if ! mv "$AUTO_CONF" "$AUTO_BACKUP"; then
        cp -p "$MODULE_BACKUP" "$MODULE_FILE"
        echo "[FAIL] Cannot disable autoindex.conf (Current: Rename failed | Expected: Disabled)"
        exit 1
    fi
fi

# Validate Apache configuration
if ! httpd -t >/dev/null 2>&1; then
    cp -p "$MODULE_BACKUP" "$MODULE_FILE"

    if [[ -f "$AUTO_BACKUP" ]]; then
        mv "$AUTO_BACKUP" "$AUTO_CONF"
    fi

    echo "[FAIL] Apache configuration validation failed (Current: Invalid | Expected: Valid)"
    exit 1
fi

# Reload Apache if running
if systemctl is-active --quiet httpd; then
    if ! systemctl reload httpd >/dev/null 2>&1; then
        cp -p "$MODULE_BACKUP" "$MODULE_FILE"

        if [[ -f "$AUTO_BACKUP" ]]; then
            mv "$AUTO_BACKUP" "$AUTO_CONF"
        fi

        systemctl reload httpd >/dev/null 2>&1
        echo "[FAIL] Apache reload failed (Current: Reload failed | Expected: Successful)"
        exit 1
    fi
fi

# Verify module status
MODULES=$(httpd -M 2>&1)
RC=$?

if [[ $RC -ne 0 ]] || printf '%s\n' "$MODULES" | grep -qE '^[[:space:]]*autoindex_module[[:space:]]+\('; 
then
    echo "[FAIL] Autoindex module verification failed (Current: Loaded or verification error | Expected: Disabled)"
    exit 1
fi

echo "[REMEDIATED] Autoindex module has been disabled (Current: Not loaded | Expected: Disabled)"
exit 0
