#!/usr/bin/env bash
pass=0; warn=0; fail=0
PASS(){ echo "[PASS] $*"; pass=$((pass+1)); }
WARN(){ echo "[WARN] $*"; warn=$((warn+1)); }
FAIL(){ echo "[FAIL] $*"; fail=$((fail+1)); }
END(){
  echo "--------------------------------"
  echo "PASS=$pass WARN=$warn FAIL=$fail"
  if [ "$fail" -eq 0 ]; then echo "STATUS: READY"; exit 0; else echo "STATUS: FIX REQUIRED"; exit 1; fi
}
