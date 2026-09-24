#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
zpool status tank >/dev/null 2>&1 && PASS "ZFS pool tank exists" || FAIL "tank missing"
state=$(zpool list -H -o health tank 2>/dev/null)
[ "$state" = "ONLINE" ] && PASS "tank ONLINE" || WARN "tank state: ${state:-unknown}"
zfs get -H -o value compression tank 2>/dev/null | grep -vq '^off$' && PASS "Compression enabled" || WARN "Compression off"
pvesm status 2>/dev/null | grep -q '^zfs-lab' && PASS "zfs-lab registered" || FAIL "zfs-lab missing"
END
