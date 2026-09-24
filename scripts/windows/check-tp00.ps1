param(
  [Parameter(Mandatory=$true)][int]$Group,
  [Parameter(Mandatory=$true)][ValidateRange(1,3)][int]$Student
)
$ErrorActionPreference="SilentlyContinue"
$pass=0;$warn=0;$fail=0
function R($s,$m){
  if($s-eq"PASS"){$script:pass++;Write-Host "[PASS] $m" -ForegroundColor Green}
  elseif($s-eq"WARN"){$script:warn++;Write-Host "[WARN] $m" -ForegroundColor Yellow}
  else{$script:fail++;Write-Host "[FAIL] $m" -ForegroundColor Red}
}
$cs=Get-CimInstance Win32_ComputerSystem
$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1
$ram=[math]::Round($cs.TotalPhysicalMemory/1GB,1)
if($ram-ge15.5){R PASS "RAM $ram GB"}else{R FAIL "RAM $ram GB"}
if($cpu.NumberOfLogicalProcessors-ge8){R PASS "CPU logical: $($cpu.NumberOfLogicalProcessors)"}else{R FAIL "CPU logical < 8"}
if($cpu.VirtualizationFirmwareEnabled){R PASS "Virtualization firmware enabled"}else{R WARN "Virtualization firmware not reported as enabled"}
$expected="10.100.$Group.$(100+$Student)"
$ip=Get-NetIPAddress -AddressFamily IPv4|Where-Object IPAddress -eq $expected
if($ip){
 R PASS "LAB IP $expected/$($ip.PrefixLength)"
 $def=Get-NetRoute -InterfaceIndex $ip.InterfaceIndex -DestinationPrefix "0.0.0.0/0"
 if($def){R FAIL "Default route detected on LAB NIC"}else{R PASS "No default route on LAB NIC"}
}else{R FAIL "Expected LAB IP missing: $expected"}
Write-Host "PASS=$pass WARN=$warn FAIL=$fail"
if($fail){exit 1}else{exit 0}
