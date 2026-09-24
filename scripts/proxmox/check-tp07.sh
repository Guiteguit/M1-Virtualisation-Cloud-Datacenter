#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?groupe}"
pvesm status | grep -qi 'pbs' && PASS "PBS détecté" || WARN "PBS non détecté par nom/type"
pveum user list 2>/dev/null | grep -q "ops-g${G}@pve" && PASS "ops-g${G}@pve existe" || WARN "compte opérateur absent"
qm config 111 >/dev/null 2>&1 && PASS "VM111 présente après restauration" || WARN "VM111 absente"
END
