#!/usr/bin/env bash
set -u

G="${1:-}"
EXPECTED_NODES="${2:-}"

if [[ -z "$G" || -z "$EXPECTED_NODES" ]]; then
  echo "Usage: $0 <group> <expected-pve-nodes:2|3>"
  exit 2
fi

if ! [[ "$G" =~ ^[0-9]+$ ]] || ! [[ "$EXPECTED_NODES" =~ ^[23]$ ]]; then
  echo "Invalid arguments."
  exit 2
fi

GG=$(printf "%02d" "$G")
EXPECTED_CLUSTER="novacorp-g${GG}"

PASS=0
WARN=0
FAIL=0

pass(){ echo "[PASS] $*"; PASS=$((PASS+1)); }
warn(){ echo "[WARN] $*"; WARN=$((WARN+1)); }
fail(){ echo "[FAIL] $*"; FAIL=$((FAIL+1)); }

echo "=============================================="
echo "       NOVACORP - TP03 VALIDATOR"
echo "=============================================="
echo "Group          : $G"
echo "Expected nodes : $EXPECTED_NODES"
echo ""

STATUS="$(pvecm status 2>/dev/null || true)"

if [[ -n "$STATUS" ]]; then
  pass "Cluster detected"
else
  fail "pvecm status failed - cluster not detected"
fi

CLUSTER_NAME="$(echo "$STATUS" | awk -F: '/^[[:space:]]*Name:/{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2; exit}')"

if [[ "$CLUSTER_NAME" == "$EXPECTED_CLUSTER" ]]; then
  pass "Cluster name is ${EXPECTED_CLUSTER}"
elif [[ -n "$CLUSTER_NAME" ]]; then
  warn "Cluster name is '${CLUSTER_NAME}', expected '${EXPECTED_CLUSTER}'"
else
  warn "Could not determine cluster name"
fi

if echo "$STATUS" | grep -qE 'Quorate:[[:space:]]+Yes'; then
  pass "Cluster is quorate"
else
  fail "Cluster is not quorate"
fi

NODE_COUNT="$(pvecm nodes 2>/dev/null | awk '/^[[:space:]]*[0-9]+[[:space:]]+[0-9]+/ {c++} END{print c+0}')"

if [[ "$NODE_COUNT" -eq "$EXPECTED_NODES" ]]; then
  pass "${NODE_COUNT} PVE nodes detected"
else
  fail "Detected ${NODE_COUNT} PVE node(s), expected ${EXPECTED_NODES}"
fi

if [[ -f /etc/pve/corosync.conf ]]; then
  pass "Corosync configuration exists"
else
  fail "/etc/pve/corosync.conf missing"
fi

if systemctl is-active --quiet corosync; then
  pass "Corosync service active"
else
  fail "Corosync service not active"
fi

if mountpoint -q /etc/pve; then
  pass "pmxcfs mounted on /etc/pve"
else
  fail "/etc/pve is not a mountpoint"
fi

if pgrep -x pmxcfs >/dev/null 2>&1; then
  pass "pmxcfs process running"
else
  fail "pmxcfs process not detected"
fi

if [[ "$EXPECTED_NODES" -eq 2 ]]; then
  if echo "$STATUS" | grep -qi 'Qdevice'; then
    pass "QDevice detected"
  else
    fail "QDevice not detected for 2-node cluster"
  fi

  EXPECTED_VOTES="$(echo "$STATUS" | awk -F: '/Expected votes:/{gsub(/[ \t]/,"",$2); print $2; exit}')"
  TOTAL_VOTES="$(echo "$STATUS" | awk -F: '/Total votes:/{gsub(/[ \t]/,"",$2); print $2; exit}')"

  if [[ "${EXPECTED_VOTES:-0}" =~ ^[0-9]+$ ]] && [[ "$EXPECTED_VOTES" -ge 3 ]]; then
    pass "Expected votes >= 3 (${EXPECTED_VOTES})"
  else
    warn "Expected votes appears to be ${EXPECTED_VOTES:-unknown}"
  fi

  if [[ "${TOTAL_VOTES:-0}" =~ ^[0-9]+$ ]] && [[ "$TOTAL_VOTES" -ge 3 ]]; then
    pass "Total votes >= 3 (${TOTAL_VOTES})"
  else
    warn "Total votes appears to be ${TOTAL_VOTES:-unknown}"
  fi
fi

if [[ -r /etc/pve/.members ]]; then
  pass "pmxcfs membership data readable"
else
  warn "/etc/pve/.members not readable"
fi

FAILED_LINKS="$(corosync-cfgtool -s 2>/dev/null | grep -ciE 'disconnected|faulty' || true)"
if [[ "$FAILED_LINKS" -eq 0 ]]; then
  pass "No disconnected/faulty Corosync link reported"
else
  warn "${FAILED_LINKS} Corosync link warning(s) reported"
fi

echo ""
echo "----------------------------------------------"
echo "PASS : $PASS"
echo "WARN : $WARN"
echo "FAIL : $FAIL"

if [[ "$FAIL" -eq 0 ]]; then
  echo "STATUS: READY FOR TP04"
  exit 0
else
  echo "STATUS: FIX REQUIRED"
  exit 1
fi
