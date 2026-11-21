#!/bin/bash
# CIS 6.2 Ensure a Syslog Facility Is Configured for Error Logging (Manual) - Remediation
# Replace active ErrorLog directives in httpd.conf and conf.d/*.conf.
set -euo pipefail

check_config() {
    shopt -s nullglob
    files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
    if [ ! -r /etc/httpd/conf/httpd.conf ]; then
        echo '[FAIL] 6.2: Cannot read httpd.conf.'
        return 1
    fi
    result=$(grep -hiE '^[[:space:]]*ErrorLog[[:space:]]' "${files[@]}" || true)
    if [ -z "$result" ]; then
        echo '[FAIL] 6.2: No ErrorLog directive found.'
        return 1
    fi

    printf '%s\n' "$result"
    while read -r directive value rest; do
        value=${value//\"/}
        if [[ "$value" =~ ^syslog:(auth|authpriv|cron|daemon|ftp|kern|lpr|mail|news|syslog|user|uucp|local[0-7])(:[^[:space:]]+)?$ ]]; then
            continue
        else
            echo '[FAIL] 6.2: ErrorLog does not use a syslog facility.'
            return 1
        fi
    done <<< "$result"
    echo '[PASS] 6.2: ErrorLog directives use syslog facilities.'
}


if check_config > /dev/null; then
    echo '[PASS] 6.2: ErrorLog already uses syslog.'
else
    shopt -s nullglob
    files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
    for file in "${files[@]}"; do
        if grep -Eiq '^[[:space:]]*ErrorLog[[:space:]]' "$file"; then
            if [ ! -e "$file.cis.bak" ]; then
                cp -p "$file" "$file.cis.bak"
            fi
            sed -Ei 's|^[[:space:]]*[Ee][Rr][Rr][Oo][Rr][Ll][Oo][Gg][[:space:]]+.*$|ErrorLog "syslog:local1"|' "$file"
        fi
    done
    file=/etc/httpd/conf/httpd.conf
    if ! grep -Eiq '^[[:space:]]*ErrorLog[[:space:]]' "$file"; then
        if [ ! -e "$file.cis.bak" ]; then
            cp -p "$file" "$file.cis.bak"
        fi
        printf '\nErrorLog "syslog:local1"\n' >> "$file"
    fi
    httpd -t
    systemctl restart httpd

    if check_config > /dev/null; then
        echo '[REMEDIATED] 6.2: ErrorLog configured to syslog:local1.'
    else
        echo '[FAIL] 6.2: ErrorLog still does not use syslog.'
        exit 1
    fi
fi
