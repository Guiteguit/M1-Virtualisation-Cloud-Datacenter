#!/usr/bin/env bash
PASSN=0; WARNN=0; FAILN=0
PASS(){ echo "[PASS] $*"; PASSN=$((PASSN+1)); }
WARN(){ echo "[WARN] $*"; WARNN=$((WARNN+1)); }
FAIL(){ echo "[FAIL] $*"; FAILN=$((FAILN+1)); }
END(){ echo "PASS=$PASSN WARN=$WARNN FAIL=$FAILN"; [ "$FAILN" -eq 0 ] && exit 0 || exit 1; }
