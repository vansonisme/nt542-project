
#!/bin/bash

APACHE_PREFIX="/etc/httpd"
CONFIG_FILE="$APACHE_PREFIX/conf/httpd.conf"
EXPECTED="strict-origin-when-cross-origin"
BACKUP_FILE="${CONFIG_FILE}.cis-5.17.bak"

# Get current Referrer-Policy value
get_value() {
    grep -iE '^[[:space:]]*Header[[:space:]]+set[[:space:]]+Referrer-Policy[[:space:]]+' "$CONFIG_FILE" |
        awk '{print $NF}' |
        tr -d '"'
}

# Check whether Apache configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file does not exist (Current: Missing | Expected: $CONFIG_FILE)"
    exit 1
fi

# Check whether configuration file is readable and writable
if [[ ! -r "$CONFIG_FILE" || ! -w "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file is not accessible (Current: Unreadable or unwritable | Expected: Readable and writable)"
    exit 1
fi

# Audit current configuration
CURRENT=$(get_value)

# Check whether configuration is already compliant
if [[ "$CURRENT" == "$EXPECTED" ]]; then
    echo "[PASS] Referrer-Policy is already configured correctly (Current: $CURRENT | Expected: $EXPECTED)"
    exit 0
fi

# Backup original configuration
if ! cp -p "$CONFIG_FILE" "$BACKUP_FILE"; then
    echo "[FAIL] Cannot create configuration backup (Current: Backup failed | Expected: Backup successful)"
    exit 1
fi

# Remove existing active Referrer-Policy directives
if ! sed -i -E '/^[[:space:]]*Header[[:space:]]+set[[:space:]]+Referrer-Policy([[:space:]]|$)/Id' "$CONFIG_FILE"; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Cannot update Referrer-Policy configuration (Current: Update failed | Expected: Update successful)"
    exit 1
fi

# Add the expected Referrer-Policy directive
if ! printf '\nHeader set Referrer-Policy "%s"\n' "$EXPECTED" >> "$CONFIG_FILE"; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Cannot add Referrer-Policy directive (Current: Write failed | Expected: Write successful)"
    exit 1
fi

# Validate Apache configuration syntax
if ! apachectl configtest >/dev/null 2>&1; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Apache configuration validation failed (Current: Invalid configuration | Expected: Valid configuration)"
    exit 1
fi

# Reload Apache if the service is running
if systemctl is-active --quiet httpd; then
    if ! systemctl reload httpd; then
        cp -p "$BACKUP_FILE" "$CONFIG_FILE"
        systemctl reload httpd >/dev/null 2>&1
        echo "[FAIL] Apache reload failed (Current: Reload failed | Expected: Reload successful)"
        exit 1
    fi
fi

# Re-audit configuration after remediation
CURRENT=$(get_value)

if [[ "$CURRENT" == "$EXPECTED" ]]; then
    echo "[REMEDIATED] Referrer-Policy has been configured successfully (Current: $CURRENT | Expected: $EXPECTED)"
    exit 0
else
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Referrer-Policy remediation failed (Current: $CURRENT | Expected: $EXPECTED)"
    exit 1
fi
