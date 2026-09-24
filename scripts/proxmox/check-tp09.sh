#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
G="${1:?group required}"
pveum user list 2>/dev/null | grep -q "ops-g${G}@pve" && PASS "Operator user found" || WARN "Operator user missing"
pveum user list 2>/dev/null | grep -q "automation-g${G}@pve" && PASS "Automation user found" || WARN "Automation user missing"
pveum pool list 2>/dev/null | grep -q "POOL-G${G}-APP" && PASS "Resource pool found" || WARN "Resource pool missing"
END
