#!/bin/bash
# CIS 6.6 Ensure ModSecurity Is Installed and Enabled (Automated) - Remediation
# Amazon Linux package installation.
set -euo pipefail

check_config() {
    if ! modules=$(httpd -M); then
        echo '[FAIL] 6.6: Cannot read the Apache module list.'
        return 1
    fi
    if printf '%s\n' "$modules" | grep security2_module; then
        echo '[PASS] 6.6: ModSecurity module is loaded.'
    else
        echo '[FAIL] 6.6: ModSecurity module is not loaded.'
        return 1
    fi
}


if check_config > /dev/null; then
    echo '[PASS] 6.6: ModSecurity is already loaded.'
else
    if rpm -q mod_security > /dev/null; then
        echo 'ModSecurity is installed; checking module loading.'
    else
        yum install -y mod_security
    fi

    modules=$(httpd -M)
    if printf '%s\n' "$modules" | grep -q security2_module; then
        echo 'ModSecurity LoadModule is present.'
    else
        file=/etc/httpd/conf.modules.d/99-cis-modsecurity.conf
        if [ -e "$file" ] && [ ! -e "$file.cis.bak" ]; then
            cp -p "$file" "$file.cis.bak"
        fi
        printf '%s\n' 'LoadModule security2_module modules/mod_security2.so' > "$file"
    fi
    httpd -t
    systemctl restart httpd

    if check_config > /dev/null; then
        echo '[REMEDIATED] 6.6: ModSecurity installed and loaded.'
    else
        echo '[FAIL] 6.6: ModSecurity is still not loaded.'
        exit 1
    fi
fi
