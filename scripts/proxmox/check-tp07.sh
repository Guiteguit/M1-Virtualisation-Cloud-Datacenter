#!/usr/bin/env bash
set -u

G="${1:-}"

if [[ -z "$G" ]] || ! [[ "$G" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <group-number>"
  exit 2
fi

GG=$(printf "%02d" "$G")
PBS="pbs-g${GG}"
POOL="POOL-G${GG}-APP"
USER="ops-g${GG}@pve"
ROLE="NovaVMOperator"

PASS=0
WARN=0
FAIL=0

pass(){ echo "[PASS] $*"; PASS=$((PASS+1)); }
warn(){ echo "[WARN] $*"; WARN=$((WARN+1)); }
fail(){ echo "[FAIL] $*"; FAIL=$((FAIL+1)); }

echo "=============================================="
echo "       NOVACORP - TP07 VALIDATOR"
echo "=============================================="
echo "Group: $G"
echo ""

if pvesm status 2>/dev/null | awk '{print $1}' | grep -qx "$PBS"; then
  if pvesm status 2>/dev/null | grep "^${PBS}[[:space:]]" | grep -q "active"; then
    pass "PBS storage ${PBS} detected and active"
  else
    warn "PBS storage ${PBS} exists but is not reported active"
  fi
else
  fail "PBS storage ${PBS} not found"
fi

if pvesm list "$PBS" --content backup 2>/dev/null | grep -Eq 'vm/111|vm-111|/111/'; then
  pass "Backup for VM111 detected on ${PBS}"
else
  warn "No VM111 backup detected automatically on ${PBS}"
fi

if qm config 111 >/dev/null 2>&1; then
  pass "VM111 exists after restore"
  NAME=$(qm config 111 2>/dev/null | awk '/^name:/{print $2}')
  if [[ "$NAME" == "web01" ]]; then
    pass "VM111 is named web01"
  else
    warn "VM111 exists but name is '${NAME:-unknown}'"
  fi
else
  fail "VM111 does not exist"
fi

if pveum pool list 2>/dev/null | awk '{print $1}' | grep -qx "$POOL"; then
  pass "Resource pool ${POOL} exists"
else
  fail "Resource pool ${POOL} not found"
fi

if pveum user list 2>/dev/null | awk '{print $1}' | grep -qx "$USER"; then
  pass "Operator user ${USER} exists"
else
  fail "Operator user ${USER} not found"
fi

if pveum role list 2>/dev/null | awk '{print $1}' | grep -qx "$ROLE"; then
  pass "Role ${ROLE} exists"
else
  fail "Role ${ROLE} not found"
fi

PERMS=$(pveum user permissions "$USER" 2>/dev/null || true)
if echo "$PERMS" | grep -q 'VM.PowerMgmt'; then
  pass "Operator has VM.PowerMgmt"
else
  warn "VM.PowerMgmt not detected for ${USER}"
fi

if echo "$PERMS" | grep -q 'VM.Audit'; then
  pass "Operator has VM.Audit"
else
  warn "VM.Audit not detected for ${USER}"
fi

echo ""
echo "----------------------------------------------"
echo "PASS : $PASS"
echo "WARN : $WARN"
echo "FAIL : $FAIL"

if [[ "$FAIL" -eq 0 ]]; then
  echo "STATUS: READY FOR FINAL BOSS"
  exit 0
else
  echo "STATUS: FIX REQUIRED"
  exit 1
fi
