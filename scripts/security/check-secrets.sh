#!/usr/bin/env bash
set -euo pipefail
PATTERN='(PVEAPIToken|token[[:space:]]*=|secret[[:space:]]*=|password[[:space:]]*=|BEGIN (RSA |OPENSSH )?PRIVATE KEY)'
if git grep -nEi "$PATTERN" -- ':!scripts/security/check-secrets.sh' 2>/dev/null; then
  echo "[FAIL] Motif potentiellement sensible détecté dans les fichiers suivis par Git."
  exit 1
fi
echo "[PASS] Aucun motif sensible évident détecté."
