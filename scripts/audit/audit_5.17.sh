#!/bin/bash

APACHE_PREFIX="/etc/httpd"
CONFIG_FILE="$APACHE_PREFIX/conf/httpd.conf"
EXPECTED="strict-origin-when-cross-origin"

get_value() {
    grep -iE '^[[:space:]]*Header[[:space:]]+set[[:space:]]+Referrer-Policy[[:space:]]+' "$CONFIG_FILE" |
        awk '{print $NF}' |
        tr -d '"'
}
#Check whether Apache configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
 echo "[FAIL] Apache configuration file does not exist (Current: Missing | Expected: $CONFIG_FILE)"
 exit 1
fi

#Check whether configuration file is readable
if [[ ! -r "$CONFIG_FILE" ]]; then
  echo "[FAIL] Apache configuration file is not readable (Current: Unreadable | Expected: $EXPECTED)" 
  exit 1
fi


CURRENT=$(get_value)

#Check whether Referrer-Policy is configured
if [[ -z "$CURRENT" ]]; then
  echo "[FAIL] Referrer-Policy is not configured (Current: Not set | Expected: $EXPECTED)"
  exit 1
fi

#Check configuration value

if [[ "$CURRENT" == "$EXPECTED" ]]; then
  echo "[PASS] Referrer-Policy is configured correctly (Current: $CURRENT | Expected: $EXPECTED)"
  exit 0
else
   echo "[FAIL] Referrer-Policy is not configured correctly (Current: $CURRENT | Expected: $EXPECTED)"
   exit 1
   fi
