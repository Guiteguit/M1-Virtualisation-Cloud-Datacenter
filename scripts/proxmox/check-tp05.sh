#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
qm status 110 >/dev/null 2>&1 && PASS "VM110 exists" || FAIL "VM110 missing"
pct status 210 >/dev/null 2>&1 && PASS "CT210 exists" || FAIL "CT210 missing"
qm config 110 2>/dev/null | grep -q 'zfs-lab:' && PASS "VM110 uses zfs-lab" || WARN "VM110 disk not detected on zfs-lab"
pct config 210 2>/dev/null | grep -q 'zfs-lab:' && PASS "CT210 uses zfs-lab" || WARN "CT210 rootfs not detected on zfs-lab"
END
