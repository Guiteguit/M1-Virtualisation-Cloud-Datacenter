#!/usr/bin/env bash
set -u

PASS=0
WARN=0
FAIL=0

pass(){ echo "[PASS] $*"; PASS=$((PASS+1)); }
warn(){ echo "[WARN] $*"; WARN=$((WARN+1)); }
fail(){ echo "[FAIL] $*"; FAIL=$((FAIL+1)); }

echo "=============================================="
echo "       NOVACORP - TP01 VALIDATOR"
echo "=============================================="

if command -v pveversion >/dev/null 2>&1; then
  pass "Proxmox VE detected: $(pveversion | head -n1)"
else
  fail "pveversion command not found"
fi

HOST="$(hostname 2>/dev/null || true)"
FQDN="$(hostname -f 2>/dev/null || true)"

if [[ -n "$HOST" && "$HOST" != "localhost" ]]; then
  pass "Hostname configured: $HOST"
else
  fail "Invalid hostname"
fi

if [[ -n "$FQDN" && "$FQDN" == *.* ]]; then
  pass "FQDN detected: $FQDN"
else
  warn "FQDN does not look complete: ${FQDN:-unknown}"
fi

if [[ -n "$FQDN" ]] && getent hosts "$FQDN" >/dev/null 2>&1; then
  pass "FQDN resolves locally"
else
  fail "FQDN resolution failed"
fi

if ip route | grep -q '^default '; then
  pass "Default route detected"
else
  fail "No default route detected"
fi

if ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
  pass "Internet connectivity OK"
else
  warn "Cannot reach 1.1.1.1"
fi

if getent hosts download.proxmox.com >/dev/null 2>&1; then
  pass "DNS resolution OK"
else
  warn "DNS resolution failed for download.proxmox.com"
fi

VIRTCOUNT="$(grep -E -c '(vmx|svm)' /proc/cpuinfo 2>/dev/null || true)"
if [[ "${VIRTCOUNT:-0}" -gt 0 ]]; then
  pass "Nested virtualization CPU flag visible: $VIRTCOUNT"
else
  fail "No VMX/SVM flag visible"
fi

if lsmod | grep -q '^kvm'; then
  pass "KVM module loaded"
else
  fail "KVM module not loaded"
fi

if pvesm status >/dev/null 2>&1; then
  pass "Proxmox storage subsystem responds"
else
  fail "pvesm status failed"
fi

VMCOUNT="$(qm list 2>/dev/null | awk 'NR>1 {c++} END{print c+0}')"
if [[ "$VMCOUNT" -eq 0 ]]; then
  pass "No VM exists"
else
  fail "$VMCOUNT VM(s) already exist before cluster creation"
fi

CTCOUNT="$(pct list 2>/dev/null | awk 'NR>1 {c++} END{print c+0}')"
if [[ "$CTCOUNT" -eq 0 ]]; then
  pass "No LXC exists"
else
  fail "$CTCOUNT container(s) already exist before cluster creation"
fi

FAILED="$(systemctl --failed --no-legend 2>/dev/null | sed '/^[[:space:]]*$/d' | wc -l)"
if [[ "$FAILED" -eq 0 ]]; then
  pass "No failed systemd units"
else
  warn "$FAILED failed systemd unit(s)"
fi

for svc in pveproxy pvedaemon pvestatd pve-cluster; do
  if systemctl is-active --quiet "$svc"; then
    pass "$svc is active"
  else
    fail "$svc is not active"
  fi
done

if apt-get update -qq >/dev/null 2>&1; then
  pass "APT repositories update successfully"
else
  warn "APT update failed - run 'apt update' manually to inspect the error"
fi

echo ""
echo "----------------------------------------------"
echo "PASS : $PASS"
echo "WARN : $WARN"
echo "FAIL : $FAIL"

if [[ "$FAIL" -eq 0 ]]; then
  echo "STATUS: READY FOR TP02"
  exit 0
else
  echo "STATUS: FIX REQUIRED"
  exit 1
fi
