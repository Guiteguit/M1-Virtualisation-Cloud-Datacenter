#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
command -v pveversion >/dev/null && PASS "Proxmox détecté" || FAIL "pveversion absent"
egrep -q '(vmx|svm)' /proc/cpuinfo && PASS "VMX/SVM visible" || FAIL "Nested virtualization absente"
systemctl --failed --quiet && PASS "Pas d'unité systemd failed" || WARN "Unités systemd en échec"
qm list >/dev/null 2>&1 && PASS "qm répond" || FAIL "qm indisponible"
pct list >/dev/null 2>&1 && PASS "pct répond" || FAIL "pct indisponible"
END
