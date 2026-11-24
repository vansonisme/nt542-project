#!/bin/bash
# CIS 4.1 Restrict access to the OS root directory - Remediation

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

if [ ! -f "$CONF" ]; then
  echo "[FAIL] Apache main config not found (Current: missing | Expected: $CONF)"
  exit 1
fi

if ! RESULT=$(get_value 2>/dev/null); then
  echo "[FAIL] Could not inspect root Directory config (Current: unknown | Expected: access denied)"
  exit 1
fi

if [ "$RESULT" = compliant ]; then
  echo "[PASS] OS root directory access is already denied (Current: protected | Expected: protected)"
  exit 0
fi

BACKUP=$(mktemp) || {
  echo "[FAIL] Could not create config backup (Current: unprotected | Expected: protected)"
  exit 1
}

if ! cp -p "$CONF" "$BACKUP"; then
  rm -f "$BACKUP"
  echo "[FAIL] Could not back up Apache config (Current: unprotected | Expected: protected)"
  exit 1
fi

if ! python3 - "$CONF" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
text = path.read_text()
pattern = re.compile(
    r'(?ims)^([ \t]*<Directory[ \t]+/[ \t]*>[^\n]*\n)(.*?)(^[ \t]*</Directory>[ \t]*)'
)
matches = list(pattern.finditer(text))

if len(matches) > 1:
    raise SystemExit("Multiple root Directory blocks found")

if matches:
    match = matches[0]
    opening, body, closing = match.groups()
    kept_lines = [
        line for line in body.splitlines()
        if not re.match(r'^[ \t]*(Require|Order|Allow|Deny)[ \t]+', line, re.IGNORECASE)
    ]
    indent = re.match(r'^[ \t]*', opening).group(0) + "    "
    new_body = "".join(line + "\n" for line in kept_lines if line.strip())
    new_body += indent + "Require all denied\n"
    replacement = opening + new_body + closing
    text = text[:match.start()] + replacement + text[match.end():]
else:
    if text and not text.endswith("\n"):
        text += "\n"
    text += "\n<Directory />\n    Require all denied\n</Directory>\n"

path.write_text(text)
PY
then
  cp -p "$BACKUP" "$CONF"
  rm -f "$BACKUP"
  echo "[FAIL] Could not safely update root Directory block (Current: unchanged | Expected: protected)"
  exit 1
fi

if ! httpd -t >/dev/null 2>&1; then
  cp -p "$BACKUP" "$CONF"
  rm -f "$BACKUP"
  echo "[FAIL] Apache config validation failed; original restored (Current: unprotected | Expected: protected)"
  exit 1
fi

if ! systemctl restart httpd >/dev/null 2>&1; then
  cp -p "$BACKUP" "$CONF"
  systemctl restart httpd >/dev/null 2>&1
  rm -f "$BACKUP"
  echo "[FAIL] Apache restart failed; original restored (Current: unprotected | Expected: protected)"
  exit 1
fi

rm -f "$BACKUP"

if ! RESULT=$(get_value 2>/dev/null); then
  echo "[FAIL] Could not verify root Directory config (Current: unknown | Expected: protected)"
  exit 1
fi

if [ "$RESULT" = compliant ]; then
  echo "[REMEDIATED] OS root directory access denied and Apache restarted (Current: protected | Expected: protected)"
  exit 0
else
  echo "[FAIL] OS root directory config is still noncompliant (Current: unprotected | Expected: protected)"
  exit 1
fi
