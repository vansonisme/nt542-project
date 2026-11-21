#!/bin/bash
# CIS 3.5 Ensure the Group Is Set Correctly on Apache Directories and Files (Automated)
set -euo pipefail

APACHE_PREFIX=/etc/httpd
if ! result=$(find "$APACHE_PREFIX" -path "$APACHE_PREFIX/htdocs" -prune -o \! -group root -ls); then
    echo '[FAIL] 3.5: Cannot inspect Apache directories.'
    exit 1
fi
if [ -z "$result" ]; then
    echo '[PASS] 3.5: No non-root group found under /etc/httpd.'
else
    echo '[FAIL] 3.5: Non-root groups found:'
    printf '%s\n' "$result"
    exit 1
fi
