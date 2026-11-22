
#!/bin/bash

MODULE="autoindex_module"
EXPECTED="Disabled"

# Check Apache binary
if ! command -v httpd >/dev/null 2>&1; then
    echo "[FAIL] Apache binary not found (Current: Missing | Expected: Available)"
    exit 1
fi

# Retrieve loaded Apache modules
MODULE_OUTPUT=$(httpd -M 2>&1)
HTTPD_STATUS=$?

# Do not interpret command failure as module disabled
if [[ $HTTPD_STATUS -ne 0 ]]; then
    echo "[FAIL] Unable to retrieve Apache modules (Current: Command failed | Expected: Module list)"
    exit 1
fi

# Check whether autoindex_module is loaded
if printf '%s\n' "$MODULE_OUTPUT" | grep -qE '^[[:space:]]*autoindex_module[[:space:]]+\('; then
    echo "[FAIL] Autoindex module is enabled (Current: Loaded | Expected: Disabled)"
    exit 1
fi

echo "[PASS] Autoindex module is disabled (Current: Not loaded | Expected: Disabled)"
exit 0
