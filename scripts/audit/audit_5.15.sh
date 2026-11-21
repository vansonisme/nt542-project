#!/bin/bash
# CIS 5.15 Ensure the IP Addresses for Listening for Requests Are Specified (Automated)
set -euo pipefail

shopt -s nullglob
files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
if [ ! -r /etc/httpd/conf/httpd.conf ]; then
    echo '[FAIL] 5.15: Cannot read httpd.conf.'
    exit 1
fi
result=$(grep -hiE '^[[:space:]]*Listen[[:space:]]' "${files[@]}" || true)
if [ -z "$result" ]; then
    echo '[FAIL] 5.15: No Listen directive found.'
    exit 1
fi

printf '%s\n' "$result"
while read -r directive address rest; do
    if [[ "$address" != *:* || "$address" == 0.0.0.0:* || "$address" == \*:* || "$address" == \[::\]:* || "$address" == \[::ffff:0.0.0.0\]:* ]]; then
        echo '[FAIL] 5.15: Listen does not specify a restricted IP address.'
        exit 1
    fi
done <<< "$result"
echo '[PASS] 5.15: Listen directives specify addresses.'
