#!/bin/bash
# CIS 6.6 Ensure ModSecurity Is Installed and Enabled (Automated)
set -euo pipefail

if httpd -M | grep security2_module; then
    echo '[PASS] 6.6: ModSecurity is loaded.'
else
    echo '[FAIL] 6.6: ModSecurity is not loaded.'
    exit 1
fi
