#!/bin/bash
# CIS 6.2 Ensure a Syslog Facility Is Configured for Error Logging (Manual)
set -euo pipefail

result=$(grep -Rhi --include='*.conf' '^[[:space:]]*ErrorLog[[:space:]]' /etc/httpd/conf /etc/httpd/conf.d || true)
echo "$result"

if [ -z "$result" ] || echo "$result" | grep -vq 'syslog:[[:alnum:]]'; then
    echo '[FAIL] 6.2: ErrorLog is missing or does not use syslog.'
    exit 1
else
    echo '[PASS] 6.2: ErrorLog uses a syslog facility.'
fi
