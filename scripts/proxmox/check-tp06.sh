#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
qm config 9000 >/dev/null 2>&1 && PASS "Template candidate 9000 exists" || FAIL "VM9000 missing"
qm config 9000 2>/dev/null | grep -q 'template: 1' && PASS "VM9000 is template" || FAIL "VM9000 is not a template"
for id in 111 121 131; do
  qm config "$id" >/dev/null 2>&1 && PASS "VM$id exists" || WARN "VM$id missing"
done
END
