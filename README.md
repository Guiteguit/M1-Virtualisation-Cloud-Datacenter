# M1 — Virtualisation Cloud & Datacenter avancée
## VMware (théorie) & Proxmox VE (pratique) — 12 h

Fil rouge : **NovaCorp Datacenter**.

Ce dépôt contient le parcours étudiant. Le cours se déroule en groupes de **2 à 3 étudiants** avec **un nœud Proxmox principal par étudiant**. Les nœuds sont réellement répartis sur plusieurs PC et reliés par un switch manageable.

## Organisation du cours

| Bloc | Durée | Sujet |
|---|---:|---|
| PRE-LAB | avant cours | VMware Workstation, nested virtualization, VM PVE, câblage |
| S1 | 1 h 30 | VMware vs Proxmox + découverte PVE |
| S2 | 1 h 30 | Réseau Proxmox / Linux Bridge / underlay |
| S3 | 1 h 30 | Cluster / Corosync / quorum / QDevice |
| S4 | 1 h 30 | LVM-thin / ZFS / snapshots / incident disque |
| S5 | 1 h 30 | VM / LXC / template / Cloud-Init |
| S6 | 1 h 30 | Migration / réplication ZFS / HA |
| S7 | 1 h 30 | PBS / restauration / RBAC / sécurité |
| S8 | 1 h 30 | FINAL BOSS NovaCorp |

Le ratio cible est d'environ **3 h de théorie/débrief pour 9 h de pratique**.

## Architecture du groupe

```text
                       SWITCH MANAGEABLE
                      VLAN underlay groupe
                             |
             +---------------+---------------+
             |               |               |
          PC ETU1         PC ETU2         PC ETU3
          VMware          VMware          VMware
             |               |               |
           PVE01           PVE02           PVE03
```

Groupe de deux : PVE01 + PVE02 + **QDevice externe** fourni par le formateur.

## Ressources minimales par étudiant

- Windows 10/11
- VMware Workstation Pro
- 16 Go de RAM minimum
- 8 CPU logiques minimum
- virtualisation matérielle active
- ~100 Go libres recommandés
- une NIC Ethernet dédiée au LAB recommandée
- Wi-Fi ou autre interface pour Internet

## VM Proxmox recommandée

```text
CPU      : 4 vCPU
RAM      : 6 à 7 Go
DISK0    : 64 Go système
DISK1    : 20 Go ZFS
DISK2    : 20 Go ZFS
NIC1     : VMnet8 / NAT / Internet
NIC2     : VMnet2 / Bridged vers NIC LAB
NIC3     : VMnet1 / Host-Only / OOB (optionnelle)
```

## Plan d'adressage

Pour le groupe `G` :

```text
VLAN underlay = 100 + G
Réseau        = 10.100.G.0/24

PC ETU1       = 10.100.G.101/24
PC ETU2       = 10.100.G.102/24
PC ETU3       = 10.100.G.103/24

PVE01         = 10.100.G.11/24
PVE02         = 10.100.G.12/24
PVE03         = 10.100.G.13/24
```

La NIC LAB Windows ne porte **pas de default gateway**. L'accès Internet de PVE utilise VMnet8/NAT.

## Niveaux des exercices

- 🟢 **GUIDÉ** : attendu de toute l'équipe.
- 🟠 **CHALLENGE** : objectif donné, moins d'indices.
- 🔴 **EXPERT** : problème ouvert pour les groupes rapides.

Les bonus ne bloquent jamais la progression principale.

## Git / livrables

Le dépôt doit être cloné ou distribué via GitHub Classroom. Chaque groupe conserve ses livrables dans :

```text
deliverables/
└── group-G/
    ├── TP01.md
    ├── TP02.md
    ├── TP03.md
    ├── TP04.md
    ├── TP05.md
    ├── TP06.md
    ├── TP07.md
    └── FINAL-REPORT.md
```

On ne demande **pas** une capture de chaque clic. Les preuves utiles sont : sorties de commandes, configurations, schémas, diagnostics et tests.

## Règles du LAB

1. Pas de réinstallation pour masquer un problème sans accord du formateur.
2. Pas de `pvecm expected` comme solution normale à un problème de quorum.
3. Un reboot n'est pas une analyse de cause racine.
4. Avant une modification réseau risquée : prévoir un rollback ou conserver la console VMware.
5. Aucun secret, token API ou mot de passe dans Git.
6. Ne passez pas au TP suivant avec un `[FAIL]` non compris.

## Parcours

```text
PRE-LAB
  ↓
TP01 Découverte
  ↓
TP02 Réseau
  ↓
TP03 Cluster & Quorum
  ↓
TP04 ZFS
  ↓
TP05 VM/LXC + Cloud-Init
  ↓
TP06 Migration + HA
  ↓
TP07 Backup + Sécurité
  ↓
FINAL BOSS
```

Les sujets plus longs (SDN/VXLAN, Ceph, API, Terraform, EVPN) sont conservés dans `BONUS/`.
