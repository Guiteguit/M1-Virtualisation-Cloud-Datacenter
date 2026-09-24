#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?group required}"
gg=$(printf "%02d" "$G")
grep -Rqs "vxg${gg}" /etc/pve/sdn 2>/dev/null && PASS "VXLAN zone vxg${gg} found" || WARN "VXLAN zone not found"
grep -Rqs "srv${gg}" /etc/pve/sdn 2>/dev/null && PASS "VNet srv${gg} found" || WARN "server VNet not found"
pvesr status >/dev/null 2>&1 && PASS "Replication subsystem responds" || WARN "pvesr status failed"
ha-manager status >/dev/null 2>&1 && PASS "HA subsystem responds" || WARN "HA status failed"
END
