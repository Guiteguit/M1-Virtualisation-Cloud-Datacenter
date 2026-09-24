# PRE-LAB — À faire avant la première séance

Objectif : arriver en cours avec la VM Proxmox **prête à installer**, afin de ne pas utiliser une séance sur l'installation de VMware et les téléchargements.

## 1. Vérification du PC

PowerShell :

```powershell
Get-CimInstance Win32_Processor |
Select Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled

Get-CimInstance Win32_ComputerSystem |
Select @{N="RAM_GB";E={[math]::Round($_.TotalPhysicalMemory/1GB,1)}}
```

Cible : 16 Go RAM, 8 CPU logiques, virtualisation active.

## 2. VMware Workstation

Créer `VMnet2` dans **Virtual Network Editor** :

```text
Type       : Bridged
Bridged to : NIC Ethernet LAB exacte
```

Ne pas choisir `Automatic`.

Vérifier également :

```text
VMnet8 = NAT
VMnet1 = Host-Only
```

## 3. VM PVE

```text
4 vCPU
6-7 Go RAM
64 Go disque système
20 Go disque #2
20 Go disque #3
```

Activer :

```text
Virtualize Intel VT-x/EPT or AMD-V/RVI
```

NIC : NAT + VMnet2 + Host-Only facultatif.

## 4. Livrable PRE-LAB

Aucun rapport long. Le jour du cours, le script suivant doit être exécutable :

```powershell
.\scripts\windows\check-prelab.ps1
```
