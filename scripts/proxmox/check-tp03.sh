#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?groupe}"
pvecm status >/tmp/pvecm-status 2>&1 || true
grep -q "Quorate:.*Yes" /tmp/pvecm-status && PASS "cluster quorate" || FAIL "cluster non quorate"
grep -q "Name:.*novacorp-g${G}" /tmp/pvecm-status && PASS "nom cluster cohérent" || WARN "nom cluster différent"
N=$(pvecm nodes 2>/dev/null | awk '/^[[:space:]]*[0-9]+/{n++}END{print n+0}')
[ "$N" -ge 2 ] && PASS "$N nœuds visibles" || FAIL "moins de deux nœuds"
END
