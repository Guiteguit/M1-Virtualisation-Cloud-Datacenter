#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?group required}"; N="${2:?student required}"
command -v pveversion >/dev/null && PASS "PVE detected" || FAIL "PVE missing"
ipx="10.100.${G}.$((10+N))"
ip -4 -o addr show | grep -q "$ipx/" && PASS "Underlay $ipx" || WARN "Underlay not configured yet (TP02)"
egrep -q '(vmx|svm)' /proc/cpuinfo && PASS "Nested CPU flag visible" || FAIL "No VMX/SVM"
[ "$(qm list 2>/dev/null | tail -n +2 | wc -l)" -eq 0 ] && PASS "No VM guest" || FAIL "Guests exist before cluster"
[ "$(pct list 2>/dev/null | tail -n +2 | wc -l)" -eq 0 ] && PASS "No CT guest" || FAIL "Containers exist before cluster"
END
