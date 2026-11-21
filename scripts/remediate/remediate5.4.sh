#!/bin/bash
# CIS 5.4 Ensure Default HTML Content Is Removed (Automated) - Remediation
set -euo pipefail

file=/etc/httpd/conf.d/welcome.conf
check_config() {
    file=/etc/httpd/conf.d/welcome.conf
    if [ ! -d /etc/httpd ]; then
        echo '[FAIL] 5.4: Apache directory is missing.'
        return 1
    fi
    if [ ! -e "$file" ]; then
        echo '[PASS] 5.4: welcome.conf is absent.'
        return 0
    fi
    result=$(grep -nEv '^[[:space:]]*(#|$)' "$file" || true)
    if [ -z "$result" ]; then
        echo '[PASS] 5.4: welcome.conf is disabled.'
    else
        echo '[FAIL] 5.4: Active welcome.conf directives:'
        printf '%s\n' "$result"
        return 1
    fi
}


if check_config > /dev/null; then
    echo '[PASS] 5.4: Welcome page is already disabled or absent.'
else
    if [ ! -e "$file.cis.bak" ]; then
        cp -p "$file" "$file.cis.bak"
    fi
    sed -i '/^[[:space:]]*[^#[:space:]]/s/^/# /' "$file"
    httpd -t
    systemctl restart httpd

    if check_config > /dev/null; then
        echo '[REMEDIATED] 5.4: Welcome page disabled.'
    else
        echo '[FAIL] 5.4: Welcome page configuration is still active.'
        exit 1
    fi
fi
