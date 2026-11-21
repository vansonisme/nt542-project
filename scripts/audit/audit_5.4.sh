#!/bin/bash
# CIS 5.4 Ensure Default HTML Content Is Removed (Automated)
set -euo pipefail

file=/etc/httpd/conf.d/welcome.conf
if [ -f "$file" ]; then
    result=$(cat "$file" | grep -vE '^[[:space:]]*(#|$)' || true)
    if [ -z "$result" ]; then
        echo '[PASS] 5.4: Welcome page is disabled.'
    else
        echo "$result"
        echo '[FAIL] 5.4: Welcome page is enabled.'
        exit 1
    fi
else
    echo '[PASS] 5.4: welcome.conf is absent.'
fi
