#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
pvesr status >/dev/null 2>&1 && PASS "subsystem réplication répond" || WARN "pvesr indisponible"
ha-manager status >/dev/null 2>&1 && PASS "HA manager répond" || WARN "HA manager indisponible"
qm config 111 >/dev/null 2>&1 && PASS "web01/111 existe" || FAIL "VM111 absente"
END
