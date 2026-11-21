#!/bin/bash
# CIS 3.5 Ensure the Group Is Set Correctly on Apache Directories and Files (Automated) - Remediation
set -euo pipefail

APACHE_PREFIX=/etc/httpd
check_config() {
    APACHE_PREFIX=/etc/httpd
    if ! result=$(find "$APACHE_PREFIX" -path "$APACHE_PREFIX/htdocs" -prune -o \! -group root -ls); then
        echo '[FAIL] 3.5: Cannot inspect Apache directories.'
        return 1
    fi
    if [ -z "$result" ]; then
        echo '[PASS] 3.5: No non-root group found under /etc/httpd.'
    else
        echo '[FAIL] 3.5: Non-root groups found:'
        printf '%s\n' "$result"
        return 1
    fi
}


if check_config > /dev/null; then
    echo '[PASS] 3.5: Apache groups are already root.'
else
    find "$APACHE_PREFIX" -path "$APACHE_PREFIX/htdocs" -prune -o \! -group root -exec chgrp -h root {} +

    if check_config > /dev/null; then
        echo '[REMEDIATED] 3.5: Apache groups changed to root.'
    else
        echo '[FAIL] 3.5: Non-root groups still exist.'
        exit 1
    fi
fi
