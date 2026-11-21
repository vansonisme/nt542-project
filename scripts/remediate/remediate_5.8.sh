
#!/bin/bash

APACHE_PREFIX="/etc/httpd"
CONFIG_FILE="$APACHE_PREFIX/conf/httpd.conf"
EXPECTED="off"
BACKUP_FILE="${CONFIG_FILE}.cis-5.8.bak"

get_value() {
    awk '
    BEGIN {
        depth = 0
        found = ""
    }

    {
        line = $0
        sub(/[[:space:]]*#.*/, "", line)

        if (line ~ /^[[:space:]]*$/) {
            next
        }

        if (line ~ /^[[:space:]]*<\//) {
            if (depth > 0) {
                depth--
            }
            next
        }

        if (depth == 0 &&
            tolower(line) ~ /^[[:space:]]*traceenable[[:space:]]+/) {
            n = split(line, fields, /[[:space:]]+/)
            found = tolower(fields[2])
        }

        if (line ~ /^[[:space:]]*<[^/]/) {
            depth++
        }
    }

    END {
        print found
    }
    ' "$CONFIG_FILE"
}

# Check configuration file
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file does not exist (Current: Missing | Expected: $CONFIG_FILE)"
    exit 1
fi

if [[ ! -r "$CONFIG_FILE" || ! -w "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file is not accessible (Current: Unreadable or unwritable | Expected: Readable and writable)"
    exit 1
fi

# Audit current configuration
CURRENT=$(get_value)

if [[ "$CURRENT" == "$EXPECTED" ]]; then
    echo "[PASS] TraceEnable is already disabled in Global Context (Current: $CURRENT | Expected: $EXPECTED)"
    exit 0
fi

# Backup configuration
if ! cp -p "$CONFIG_FILE" "$BACKUP_FILE"; then
    echo "[FAIL] Cannot create configuration backup (Current: Backup failed | Expected: Backup successful)"
    exit 1
fi

# Remove TraceEnable directives in Global Context
if ! awk '
BEGIN {
    depth = 0
}

{
    line = $0
    check = line
    sub(/[[:space:]]*#.*/, "", check)

    if (check ~ /^[[:space:]]*<\//) {
        if (depth > 0) depth--
        print
        next
    }

    if (depth == 0 &&
        tolower(check) ~ /^[[:space:]]*traceenable[[:space:]]+/) {
        next
    }

    print

    if (check ~ /^[[:space:]]*<[^/]/) {
        depth++
    }
}
' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    rm -f "${CONFIG_FILE}.tmp"
    echo "[FAIL] Cannot update Apache configuration (Current: Update failed | Expected: Update successful)"
    exit 1
fi

if ! mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Cannot replace Apache configuration (Current: Replace failed | Expected: Replace successful)"
    exit 1
fi

# Add directive in Global Context at the beginning
if ! sed -i '1i TraceEnable off' "$CONFIG_FILE"; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Cannot add TraceEnable directive (Current: Write failed | Expected: TraceEnable off)"
    exit 1
fi

# Validate Apache configuration
if ! httpd -t >/dev/null 2>&1; then
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] Apache configuration validation failed (Current: Invalid configuration | Expected: Valid configuration)"
    exit 1
fi

# Reload Apache if running
if systemctl is-active --quiet httpd; then
    if ! systemctl reload httpd; then
        cp -p "$BACKUP_FILE" "$CONFIG_FILE"
        systemctl reload httpd >/dev/null 2>&1
        echo "[FAIL] Apache reload failed (Current: Reload failed | Expected: Reload successful)"
        exit 1
    fi
fi

# Re-audit
CURRENT=$(get_value)

if [[ "$CURRENT" == "$EXPECTED" ]]; then
    echo "[REMEDIATED] TraceEnable has been disabled in Global Context (Current: $CURRENT | Expected: $EXPECTED)"
    exit 0
else
    cp -p "$BACKUP_FILE" "$CONFIG_FILE"
    echo "[FAIL] TraceEnable remediation failed (Current: $CURRENT | Expected: $EXPECTED)"
    exit 1
fi
