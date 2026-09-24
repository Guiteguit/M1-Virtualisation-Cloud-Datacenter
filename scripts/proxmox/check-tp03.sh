#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?group required}"
pvecm status >/tmp/tp03-status 2>&1 || true
grep -q "Name:.*novacorp-g${G}" /tmp/tp03-status && PASS "Cluster name OK" || WARN "Check cluster name"
grep -q "Quorate:.*Yes" /tmp/tp03-status && PASS "Cluster quorate" || FAIL "Cluster not quorate"
nodes=$(pvecm nodes 2>/dev/null | awk '/^[[:space:]]*[0-9]+/{c++} END{print c+0}')
[ "$nodes" -ge 2 ] && PASS "$nodes cluster nodes visible" || FAIL "Less than 2 nodes"
END
