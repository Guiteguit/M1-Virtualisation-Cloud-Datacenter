#!/usr/bin/env bash
set -u

G="${1:-}"
N="${2:-}"
CUSTOM_IP="${3:-}"

if [[ -z "$G" || -z "$N" ]]; then
  echo "Usage: $0 <group> <student:1-3> [expected-lab-ip]"
  exit 2
fi

if ! [[ "$G" =~ ^[0-9]+$ ]] || ! [[ "$N" =~ ^[1-3]$ ]]; then
  echo "Invalid group or student number."
  exit 2
fi

EXPECTED_IP="${CUSTOM_IP:-10.100.${G}.$((10+N))}"

PASS=0
WARN=0
FAIL=0

pass(){ echo "[PASS] $*"; PASS=$((PASS+1)); }
warn(){ echo "[WARN] $*"; WARN=$((WARN+1)); }
fail(){ echo "[FAIL] $*"; FAIL=$((FAIL+1)); }

echo "=============================================="
echo "       NOVACORP - TP02 VALIDATOR"
echo "=============================================="
echo "Expected LAB IP: ${EXPECTED_IP}"
echo ""

if ip link show vmbr0 >/dev/null 2>&1; then
  pass "vmbr0 exists"
else
  fail "vmbr0 missing"
fi

DEFAULTS="$(ip -4 route show default 2>/dev/null || true)"
if [[ -n "$DEFAULTS" ]]; then
  pass "Default route detected"
  if echo "$DEFAULTS" | grep -q 'dev vmbr1'; then
    fail "Default route is configured on vmbr1"
  else
    pass "Default route is not on vmbr1"
  fi
else
  fail "No IPv4 default route"
fi

if ip link show vmbr1 >/dev/null 2>&1; then
  pass "vmbr1 exists"
else
  fail "vmbr1 missing"
fi

if ip -4 -o addr show dev vmbr1 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | grep -qx "$EXPECTED_IP"; then
  pass "Expected LAB IP found on vmbr1: ${EXPECTED_IP}"
else
  fail "Expected LAB IP not found on vmbr1: ${EXPECTED_IP}"
fi

if [[ -d /sys/class/net/vmbr1/brif ]]; then
  PORT_COUNT="$(find /sys/class/net/vmbr1/brif -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
  if [[ "$PORT_COUNT" -ge 1 ]]; then
    PORTS="$(basename -a /sys/class/net/vmbr1/brif/* 2>/dev/null | tr '\n' ' ')"
    pass "vmbr1 has ${PORT_COUNT} bridge port(s): ${PORTS}"
  else
    fail "vmbr1 has no bridge port"
  fi
else
  fail "vmbr1 is not detected as a Linux bridge"
fi

if ip link show vmbr1 2>/dev/null | grep -q 'state UP'; then
  pass "vmbr1 is UP"
else
  warn "vmbr1 is not reported UP"
fi

if ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
  pass "Internet connectivity OK"
else
  warn "Cannot reach 1.1.1.1"
fi

if ip link show vmbr10 >/dev/null 2>&1; then
  pass "vmbr10 exists"

  if [[ -d /sys/class/net/vmbr10/brif ]]; then
    VM10_PORT_COUNT="$(find /sys/class/net/vmbr10/brif -mindepth 1 -maxdepth 1 2>/dev/null | wc -l)"
  else
    VM10_PORT_COUNT=0
  fi

  if [[ "$VM10_PORT_COUNT" -eq 0 ]]; then
    pass "vmbr10 has no physical bridge port"
  else
    warn "vmbr10 currently has ${VM10_PORT_COUNT} bridge port(s)"
  fi
else
  fail "vmbr10 missing"
fi

LAB_ROUTE="$(ip -4 route show dev vmbr1 2>/dev/null | head -n1 || true)"
if [[ -n "$LAB_ROUTE" ]]; then
  pass "Connected LAB route detected: ${LAB_ROUTE}"
else
  warn "No connected IPv4 route detected on vmbr1"
fi

echo ""
echo "----------------------------------------------"
echo "PASS : $PASS"
echo "WARN : $WARN"
echo "FAIL : $FAIL"

if [[ "$FAIL" -eq 0 ]]; then
  echo "STATUS: READY FOR TP03"
  exit 0
else
  echo "STATUS: FIX REQUIRED"
  exit 1
fi
