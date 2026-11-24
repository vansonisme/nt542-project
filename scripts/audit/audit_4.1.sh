#!/bin/bash
# CIS 4.1 Restrict access to the OS root directory

CONF="/etc/httpd/conf/httpd.conf"

get_value() {
  python3 - "$CONF" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
pattern = re.compile(
    r'(?ims)^[ \t]*<Directory[ \t]+/[ \t]*>[^\n]*\n.*?^[ \t]*</Directory>[ \t]*'
)
blocks = pattern.findall(text)

if len(blocks) != 1:
    print("noncompliant")
    raise SystemExit(0)

block = blocks[0]
has_denied = re.search(
    r'(?m)^[ \t]*Require[ \t]+all[ \t]+denied[ \t]*$', block
)
has_unsafe = re.search(
    r'(?m)^[ \t]*(Require[ \t]+all[ \t]+granted|Order[ \t]+|Allow[ \t]+|Deny[ \t]+)',
    block
)

print("compliant" if has_denied and not has_unsafe else "noncompliant")
PY
}

if ! command -v httpd >/dev/null 2>&1; then
  echo "[FAIL] Apache httpd is not installed (Current: missing | Expected: installed)"
  exit 1
fi

if [ ! -r "$CONF" ]; then
  echo "[FAIL] Apache main config cannot be read (Current: unavailable | Expected: readable)"
  exit 1
fi

if ! RESULT=$(get_value 2>/dev/null); then
  echo "[FAIL] Could not inspect root Directory config (Current: unknown | Expected: access denied)"
  exit 1
fi

if [ "$RESULT" = compliant ]; then
  echo "[PASS] OS root directory access is denied (Current: protected | Expected: protected)"
  exit 0
else
  echo "[FAIL] OS root directory config requires remediation (Current: unprotected | Expected: protected)"
  exit 1
fi
