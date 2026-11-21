#!/bin/bash
# CIS 5.15 Ensure the IP Addresses for Listening for Requests Are Specified (Automated) - Remediation
# Usage: sudo bash scripts/remediate/remediate5.15.sh 10.0.2.10
set -euo pipefail

worker_ip=${1:-$(hostname -I | awk '{print $1}')}
if ! ip -o -4 addr show | grep -Fq " $worker_ip/"; then
    echo 'ERROR: The supplied IP is not assigned to this worker.'
    exit 1
fi
file=/etc/httpd/conf/httpd.conf
check_config() {
    shopt -s nullglob
    files=(/etc/httpd/conf/httpd.conf /etc/httpd/conf.d/*.conf)
    if [ ! -r /etc/httpd/conf/httpd.conf ]; then
        echo '[FAIL] 5.15: Cannot read httpd.conf.'
        return 1
    fi
    result=$(grep -hiE '^[[:space:]]*Listen[[:space:]]' "${files[@]}" || true)
    if [ -z "$result" ]; then
        echo '[FAIL] 5.15: No Listen directive found.'
        return 1
    fi

    printf '%s\n' "$result"
    while read -r directive address rest; do
        if [[ "$address" != *:* || "$address" == 0.0.0.0:* || "$address" == \*:* || "$address" == \[::\]:* || "$address" == \[::ffff:0.0.0.0\]:* ]]; then
            echo '[FAIL] 5.15: Listen does not specify a restricted IP address.'
            return 1
        fi
    done <<< "$result"
    echo '[PASS] 5.15: Listen directives specify addresses.'
}


if check_config > /dev/null; then
    echo '[PASS] 5.15: Listen addresses are already specified.'
else
    if [ ! -e "$file.cis.bak" ]; then
        cp -p "$file" "$file.cis.bak"
    fi
    if grep -Eq '^[[:space:]]*[Ll][Ii][Ss][Tt][Ee][Nn][[:space:]]+([^[:space:]]+:)?80([[:space:]]|$)' "$file"; then
        sed -Ei "s|^[[:space:]]*[Ll][Ii][Ss][Tt][Ee][Nn][[:space:]]+([^[:space:]]+:)?80([[:space:]].*)?$|Listen $worker_ip:80|" "$file"
    else
        printf '\nListen %s:80\n' "$worker_ip" >> "$file"
    fi
    httpd -t
    systemctl stop httpd
    systemctl start httpd

    if check_config > /dev/null; then
        echo "[REMEDIATED] 5.15: Listen configured to $worker_ip:80."
    else
        echo '[FAIL] 5.15: Unrestricted Listen directives still exist.'
        exit 1
    fi
fi
