# TP00 — Préparation du LAB

**Durée : 1 h à 1 h 30**

## Mission

Votre groupe doit construire le socle physique et VMware du futur cluster NovaCorp.

Aucun Proxmox n'est encore installé.

## Objectifs

- valider CPU/RAM/virtualisation ;
- distinguer NAT, bridged et host-only ;
- connecter les PC du groupe via le switch ;
- créer VMnet2 ;
- préparer la VM Proxmox ;
- vérifier l'isolation entre groupes.

---

## 1. Constituez le groupe

```text
2 étudiants minimum
3 étudiants maximum
```

Rôles :

```text
ETU1 -> PVE01
ETU2 -> PVE02
ETU3 -> PVE03
```

Notez votre numéro de groupe `G`.

---

## 2. Vérifiez le poste

PowerShell :

```powershell
Get-CimInstance Win32_Processor |
Select Name,NumberOfCores,NumberOfLogicalProcessors,VirtualizationFirmwareEnabled

Get-CimInstance Win32_ComputerSystem |
Select @{N="RAM_GB";E={[math]::Round($_.TotalPhysicalMemory/1GB,1)}}

Get-Volume |
Select DriveLetter,@{N="FreeGB";E={[math]::Round($_.SizeRemaining/1GB,1)}}
```

Cible :

```text
RAM >= 16 Go
CPU logiques >= 8
Espace libre >= 80 Go
Virtualisation BIOS/UEFI active
```

---

## 3. Inventoriez les interfaces

```powershell
Get-NetAdapter |
Sort ifIndex |
Format-Table ifIndex,Name,InterfaceDescription,Status,LinkSpeed
```

Identifiez :

```text
Interface Internet
Interface LAB
```

Le LAB doit idéalement utiliser une carte Ethernet dédiée ou un adaptateur USB-Ethernet.

---

## 4. Configurez le PC sur l'underlay

Pour `G=3` :

```text
VLAN 103
10.100.3.0/24
```

Adresses :

```text
ETU1 10.100.3.101/24
ETU2 10.100.3.102/24
ETU3 10.100.3.103/24
```

**Gateway : vide**

**DNS : vide**

Tests :

```powershell
ping 10.100.3.102
arp -a
Get-NetNeighbor
```

### Questions

1. Pourquoi aucune passerelle n'est nécessaire pour communiquer entre les PC ?
2. Pourquoi ne voulons-nous pas que la NIC LAB porte la route par défaut ?
3. Quelle adresse MAC correspond au PC voisin ?

---

## 5. VMware Virtual Network Editor

Créez :

```text
VMnet2
Type       : Bridged
Bridged to : <NIC LAB précise>
```

Ne laissez jamais :

```text
Automatic
```

Contrôlez également :

```text
VMnet8 = NAT
VMnet1 = Host-Only
```

---

## 6. Préparez la VM PVE

```text
4 vCPU
6144 à 7168 Mo RAM
64 Go système
20 Go disque #2
20 Go disque #3
```

Les disques sont provisionnés dynamiquement.

### Nested virtualization

Dans :

```text
VM > Settings > Processors
```

activez :

```text
Virtualize Intel VT-x/EPT or AMD-V/RVI
```

---

## 7. Ajoutez les vNIC

```text
NIC1 : NAT / VMnet8
NIC2 : Custom / VMnet2
NIC3 : Host-Only / VMnet1
```

### Question

Expliquez en une phrase le rôle de chaque vNIC.

---

## 8. Vérification VBS/Hyper-V

Exécutez :

```powershell
systeminfo
```

Si VMware refuse plus tard d'exposer VT-x/EPT au guest, documentez le message exact.

Ne désactivez pas une protection Windows sans consigne de l'enseignant.

---

# CHALLENGE

Avec :

```powershell
route print
Get-NetRoute
```

retrouvez :

- la route par défaut ;
- l'interface utilisée pour Internet ;
- la route connected de l'underlay.

---

# EXPERT — trunk expérimental

Uniquement sur un port de test donné par l'enseignant :

- envoyer une trame 802.1Q ;
- capturer la trame ;
- déterminer à quel endroit le tag est conservé ou supprimé.

Le résultat n'a aucune incidence sur la validation du TP.

---

## Livrable

Créez `docs/topologie-groupe-G.md` :

```text
Etudiants
PC
Port switch
NIC LAB
IP Windows
Nom de la future VM PVE
IP future PVE
```

---

## Validation

```powershell
.\scripts\windows\check-tp00.ps1 -Group G -Student N
```
