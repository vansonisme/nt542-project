
#!/bin/bash

APACHE_PREFIX="/etc/httpd"
CONFIG_FILE="$APACHE_PREFIX/conf/httpd.conf"
EXPECTED="off"

# Get TraceEnable value in Global Context
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

if [[ ! -r "$CONFIG_FILE" ]]; then
    echo "[FAIL] Apache configuration file is not readable (Current: Unreadable | Expected: Readable)"
    exit 1
fi

# Get current configuration
CURRENT=$(get_value)

# Check TraceEnable configuration
if [[ "$CURRENT" == "$EXPECTED" ]]; then
    echo "[PASS] TraceEnable is disabled in Global Context (Current: $CURRENT | Expected: $EXPECTED)"
    exit 0
else
    DISPLAY_CURRENT="${CURRENT:-Not set}"
    echo "[FAIL] TraceEnable is not disabled in Global Context (Current: $DISPLAY_CURRENT | Expected: $EXPECTED)"
    exit 1
fi
