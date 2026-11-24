
#!/bin/bash

APACHE_PREFIX="/etc/httpd"
CONFIG_FILE="$APACHE_PREFIX/conf/httpd.conf"
EXPECTED_MAX=15

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

# Check whether configuration file is readable
if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file is not readable (Current: Unreadable | Expected: Readable)"
    exit 1
fi

CURRENT=$(get_value)

# Check whether KeepAliveTimeout is configured
if [[ -z "$CURRENT" ]]; then
    echo "[FAIL] KeepAliveTimeout is not explicitly configured (Current: Not set | Expected: <= $EXPECTED_MAX)"
    exit 1
fi

# Check whether value is a valid non-negative integer
if ! [[ "$CURRENT" =~ ^[0-9]+$ ]]; then
    echo "[FAIL] KeepAliveTimeout has an invalid value (Current: $CURRENT | Expected: Integer <= $EXPECTED_MAX)"
    exit 1
fi

# Check KeepAliveTimeout value
if (( CURRENT <= EXPECTED_MAX )); then
    echo "[PASS] KeepAliveTimeout is configured correctly (Current: $CURRENT | Expected: <= $EXPECTED_MAX)"
    exit 0
else
    echo "[FAIL] KeepAliveTimeout exceeds the allowed value (Current: $CURRENT | Expected: <= $EXPECTED_MAX)"
    exit 1
fi
