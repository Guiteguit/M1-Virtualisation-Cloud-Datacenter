#!/usr/bin/env bash

PASS=0
WARN=0
FAIL=0

pass() { echo "[PASS] $1"; PASS=$((PASS+1)); }
warn() { echo "[WARN] $1"; WARN=$((WARN+1)); }
fail() { echo "[FAIL] $1"; FAIL=$((FAIL+1)); }

echo "=============================================="
echo "     NOVACORP - TP06 VALIDATOR"
echo "=============================================="

if pvecm status 2>/dev/null | grep -q "Quorate:.*Yes"; then
    pass "Cluster is quorate"
else
    fail "Cluster is not quorate"
fi

if qm config 111 >/dev/null 2>&1; then
    pass "VM111 web01 exists"
else
    fail "VM111 web01 does not exist"
fi

if qm config 111 2>/dev/null | grep -q "zfs-lab:"; then
    pass "web01 uses zfs-lab"
else
    warn "web01 does not appear to use zfs-lab"
fi

if pvesr status >/dev/null 2>&1; then
    pass "Replication subsystem responds"
else
    fail "Replication subsystem does not respond"
fi

if pvesr status 2>/dev/null | grep -qE '(^|[[:space:]])111-'; then
    pass "Replication job for VM111 exists"
else
    warn "No replication job detected for VM111"
fi

if ha-manager status >/dev/null 2>&1; then
    pass "HA subsystem responds"
else
    fail "HA subsystem does not respond"
fi

if ha-manager status 2>/dev/null | grep -q "vm:111"; then
    pass "VM111 is managed by HA"
else
    warn "VM111 is not currently managed by HA"
fi

echo "----------------------------------------------"
echo "PASS : $PASS"
echo "WARN : $WARN"
echo "FAIL : $FAIL"

if [ "$FAIL" -eq 0 ]; then
    echo "STATUS: READY FOR TP07"
    exit 0
else
    echo "STATUS: FIX REQUIRED"
    exit 1
fi
