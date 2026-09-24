#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
zpool status tank >/dev/null 2>&1 && PASS "pool tank présent" || FAIL "tank absent"
H=$(zpool list -H -o health tank 2>/dev/null)
[ "$H" = "ONLINE" ] && PASS "tank ONLINE" || WARN "tank état $H"
zfs get -H -o value compression tank 2>/dev/null | grep -vq '^off$' && PASS "compression active" || WARN "compression off"
pvesm status | grep -q '^zfs-lab' && PASS "zfs-lab déclaré" || FAIL "zfs-lab absent"
END
