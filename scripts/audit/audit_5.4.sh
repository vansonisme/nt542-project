#!/bin/bash
# CIS 5.4 Ensure Default HTML Content Is Removed (Automated)
set -euo pipefail

file=/etc/httpd/conf.d/welcome.conf
if [ ! -d /etc/httpd ]; then
    echo '[FAIL] 5.4: Apache directory is missing.'
    exit 1
fi
if [ ! -e "$file" ]; then
    echo '[PASS] 5.4: welcome.conf is absent.'
    exit 0
fi
result=$(grep -nEv '^[[:space:]]*(#|$)' "$file" || true)
if [ -z "$result" ]; then
    echo '[PASS] 5.4: welcome.conf is disabled.'
else
    echo '[FAIL] 5.4: Active welcome.conf directives:'
    printf '%s\n' "$result"
    exit 1
fi
