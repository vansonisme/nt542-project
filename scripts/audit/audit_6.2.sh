#!/bin/bash
# CIS 6.2 Ensure a Syslog Facility Is Configured for Error Logging (Manual)
set -euo pipefail

shopt -s nullglob
files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
if [ ! -r /etc/httpd/conf/httpd.conf ]; then
    echo '[FAIL] 6.2: Cannot read httpd.conf.'
    exit 1
fi
result=$(grep -hiE '^[[:space:]]*ErrorLog[[:space:]]' "${files[@]}" || true)
if [ -z "$result" ]; then
    echo '[FAIL] 6.2: No ErrorLog directive found.'
    exit 1
fi

printf '%s\n' "$result"
while read -r directive value rest; do
    value=${value//\"/}
    if [[ "$value" =~ ^syslog:(auth|authpriv|cron|daemon|ftp|kern|lpr|mail|news|syslog|user|uucp|local[0-7])(:[^[:space:]]+)?$ ]]; then
        continue
    else
        echo '[FAIL] 6.2: ErrorLog does not use a syslog facility.'
        exit 1
    fi
done <<< "$result"
echo '[PASS] 6.2: ErrorLog directives use syslog facilities.'
