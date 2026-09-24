#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
pvesm status 2>/dev/null | grep -qi 'pbs' && PASS "PBS storage detected" || WARN "No PBS storage name/type detected"
qm config 111 >/dev/null 2>&1 && PASS "VM111 exists after restore" || WARN "VM111 missing"
END
