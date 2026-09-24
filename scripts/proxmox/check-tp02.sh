#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?group required}"; N="${2:?student required}"
ipx="10.100.${G}.$((10+N))"
ip link show vmbr1 >/dev/null 2>&1 && PASS "vmbr1 exists" || FAIL "vmbr1 missing"
ip -4 -o addr show dev vmbr1 2>/dev/null | grep -q "$ipx/" && PASS "vmbr1 has $ipx" || FAIL "Expected underlay IP missing"
ip route | grep -q '^default ' && PASS "Default route present" || WARN "No default route"
ip link show vmbr10 >/dev/null 2>&1 && PASS "vmbr10 exists" || WARN "vmbr10 local bridge not found"
END
