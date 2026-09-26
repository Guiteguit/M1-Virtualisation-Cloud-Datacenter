#!/usr/bin/env bash
set -u

ROOT="${1:-.}"

echo "=============================================="
echo "        NOVACORP - SECRET CHECK"
echo "=============================================="

PATTERN='(PVEAPIToken|token[_-]?secret|api[_-]?token|password[[:space:]]*=|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY)'

MATCHES=$(grep -RniE \
  --exclude-dir=.git \
  --exclude='check-secrets.sh' \
  --exclude='*.png' \
  --exclude='*.jpg' \
  --exclude='*.jpeg' \
  --exclude='*.pdf' \
  --exclude='*.pptx' \
  "$PATTERN" "$ROOT" 2>/dev/null || true)

if [[ -n "$MATCHES" ]]; then
  echo "[WARN] Potential secret-like content detected:"
  echo "$MATCHES"
  echo ""
  echo "Review these matches manually before committing."
  exit 1
else
  echo "[PASS] No obvious secret pattern detected."
  exit 0
fi
