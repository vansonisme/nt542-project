
#!/bin/bash
# CIS 3.6 Ensure Other Write Access on Apache Directories and Files Is Restricted (Manual | Level 1 | File Permission) - Remediation

APACHE_PREFIX="/etc/httpd"

# Get the number of Apache files/directories writable by Other
# This function must be identical to the audit script.
get_value() {
    local OUTPUT

    if ! OUTPUT=$(find -L "$APACHE_PREFIX" \! -type l -perm /o=w -ls 2>/dev/null); then
        return 1
    fi

    if [ -n "$OUTPUT" ]; then
        printf '%s\n' "$OUTPUT" | awk 'END {print NR}'
    else
        echo "0"
    fi
}

# Pre-check: Apache directory must exist
if [ ! -d "$APACHE_PREFIX" ]; then
    echo "[FAIL] Apache directory not found (Current: missing | Expected: $APACHE_PREFIX exists)"
    exit 1
fi

RESULT=$(get_value)

if [ $? -ne 0 ]; then
    echo "[FAIL] Unable to inspect Apache permissions (Current: inspection error | Expected: 0 other-writable objects)"
    exit 1
fi

# Already compliant
if [ "$RESULT" -eq 0 ]; then
    echo "[PASS] Other write access on Apache directories and files is already restricted (Current: $RESULT writable objects | Expected: 0)"
    exit 0
else
    # Remove Other write permission recursively
    if ! chmod -R o-w "$APACHE_PREFIX" 2>/dev/null; then
        echo "[FAIL] Failed to remove Other write permissions (Current: $RESULT writable objects | Expected: 0)"
        exit 1
    fi

    # Verify after remediation
    NEW_RESULT=$(get_value)

    if [ $? -ne 0 ]; then
        echo "[FAIL] Unable to verify Apache permissions after remediation (Current: verification error | Expected: 0 other-writable objects)"
        exit 1
    fi

    if [ "$NEW_RESULT" -eq 0 ]; then
        echo "[REMEDIATED] Removed Other write permissions from Apache directories and files (Current: $NEW_RESULT writable objects | Expected: 0)"
        exit 0
    else
        find -L "$APACHE_PREFIX" \! -type l -perm /o=w -ls >&2

        echo "[FAIL] Other write permissions still exist after remediation (Current: $NEW_RESULT writable objects | Expected: 0)"
        exit 1
    fi
fi
