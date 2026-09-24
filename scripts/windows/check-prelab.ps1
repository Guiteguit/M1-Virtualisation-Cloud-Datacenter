$ErrorActionPreference="SilentlyContinue"
$fail=0
function OK($m){Write-Host "[PASS] $m" -ForegroundColor Green}
function KO($m){$script:fail++;Write-Host "[FAIL] $m" -ForegroundColor Red}
function WRN($m){Write-Host "[WARN] $m" -ForegroundColor Yellow}
$cs=Get-CimInstance Win32_ComputerSystem
$cpu=Get-CimInstance Win32_Processor|Select-Object -First 1
$ram=[math]::Round($cs.TotalPhysicalMemory/1GB,1)
if($ram -ge 15.5){OK "RAM: $ram GB"}else{KO "RAM < 16 GB: $ram GB"}
if($cpu.NumberOfLogicalProcessors -ge 8){OK "CPU logiques: $($cpu.NumberOfLogicalProcessors)"}else{KO "CPU logiques < 8"}
if($cpu.VirtualizationFirmwareEnabled){OK "Virtualisation firmware active"}else{WRN "Virtualisation firmware non confirmée"}
if(Get-Command vmware.exe -ErrorAction SilentlyContinue){OK "VMware Workstation détecté dans PATH"}else{WRN "vmware.exe non trouvé dans PATH — vérifier installation"}
if($fail -gt 0){exit 1}else{exit 0}
