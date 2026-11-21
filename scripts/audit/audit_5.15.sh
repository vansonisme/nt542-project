#!/bin/bash
# CIS 5.15 Ensure the IP Addresses for Listening for Requests Are Specified (Automated)
set -euo pipefail

result=$(grep -Rhi --include='*.conf' '^[[:space:]]*Listen[[:space:]]' /etc/httpd/conf /etc/httpd/conf.d || true)
echo "$result"
ss -ltnp | grep httpd || true

if [ -z "$result" ] || echo "$result" | grep -Eiq 'Listen[[:space:]]+([0-9]+([[:space:]]|$)|0\.0\.0\.0:|\[::\]:|\[::ffff:0\.0\.0\.0\]:|\*:)'; then
    echo '[FAIL] 5.15: Listen is missing or accepts all IP addresses.'
    exit 1
else
    echo '[PASS] 5.15: Listen specifies an IP address.'
fi
