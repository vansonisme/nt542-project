#!/bin/bash
# CIS 6.6 Ensure ModSecurity Is Installed and Enabled (Automated)
set -euo pipefail

if ! modules=$(httpd -M); then
    echo '[FAIL] 6.6: Cannot read the Apache module list.'
    exit 1
fi
if printf '%s\n' "$modules" | grep security2_module; then
    echo '[PASS] 6.6: ModSecurity module is loaded.'
else
    echo '[FAIL] 6.6: ModSecurity module is not loaded.'
    exit 1
fi
