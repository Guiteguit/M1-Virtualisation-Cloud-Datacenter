#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
qm config 110 >/dev/null 2>&1 && PASS "VM110 existe" || WARN "VM110 absente"
pct config 210 >/dev/null 2>&1 && PASS "CT210 existe" || WARN "CT210 absent"
qm config 9000 2>/dev/null | grep -q 'template: 1' && PASS "template 9000 OK" || FAIL "template 9000 absent"
for id in 111 121 131; do qm config "$id" >/dev/null 2>&1 && PASS "VM$id existe" || WARN "VM$id absente"; done
END
