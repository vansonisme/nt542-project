
#!/bin/bash

APACHE_PREFIX="/etc/httpd"
CONFIG_FILE="$APACHE_PREFIX/conf/httpd.conf"
EXPECTED=15

get_value() {
    grep -iE '^[[:space:]]*KeepAliveTimeout[[:space:]]+' "$CONFIG_FILE" |
        awk '{print $2}' |
        tail -n 1
}

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

CURRENT=$(get_value)

# Check whether current value is valid
if [[ -n "$CURRENT" ]] && ! [[ "$CURRENT" =~ ^[0-9]+$ ]]; then
    echo "[FAIL] KeepAliveTimeout has an invalid value (Current: $CURRENT | Expected: Integer <= $EXPECTED)"
    exit 1
fi

# Check whether KeepAliveTimeout is already compliant
if [[ -n "$CURRENT" ]] && (( CURRENT <= EXPECTED )); then
    echo "[PASS] KeepAliveTimeout is already compliant (Current: $CURRENT | Expected: <= $EXPECTED)"
    exit 0
fi

# Create backup
BACKUP_FILE="${CONFIG_FILE}.cis-9.4.bak"

if ! cp -p "$CONFIG_FILE" "$BACKUP_FILE"; then
    echo "[FAIL] Unable to create configuration backup (Current: Backup failed | Expected: Backup created)"
    exit 1
fi

# Update existing directive or append a new one
if grep -qiE '^[[:space:]]*KeepAliveTimeout[[:space:]]+' "$CONFIG_FILE"; then
    sed -i -E 's/^[[:space:]]*KeepAliveTimeout[[:space:]]+.*/KeepAliveTimeout 15/I' "$CONFIG_FILE"
else
    echo "KeepAliveTimeout 15" >> "$CONFIG_FILE"
fi

# Verify Apache configuration syntax
if ! httpd -t >/dev/null 2>&1; then
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
CURRENT=$(get_value)

if [[ "$CURRENT" =~ ^[0-9]+$ ]] && (( CURRENT <= EXPECTED )); then
    echo "[REMEDIATED] KeepAliveTimeout has been configured successfully (Current: $CURRENT | Expected: <= $EXPECTED)"
    exit 0
else
    echo "[FAIL] KeepAliveTimeout remediation failed (Current: ${CURRENT:-Not set} | Expected: <= $EXPECTED)"
    exit 1
fi
