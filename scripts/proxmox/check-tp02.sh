#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?groupe}"; N="${2:?étudiant 1-3}"
IP="10.100.${G}.$((10+N))"
ip link show vmbr1 >/dev/null 2>&1 && PASS "vmbr1 présent" || FAIL "vmbr1 absent"
ip -4 -o addr show dev vmbr1 2>/dev/null | grep -q "$IP/" && PASS "$IP présent" || FAIL "$IP absent de vmbr1"
ip route | grep -q '^default ' && PASS "default route présente" || WARN "pas de default route"
ip link show vmbr10 >/dev/null 2>&1 && PASS "vmbr10 présent" || WARN "vmbr10 absent"
END
