# M1 — Virtualisation Cloud & Datacenter avancée
## VMware & Proxmox VE — 18 heures

**Fil rouge : NovaCorp Datacenter**

Cours destiné à des étudiants de Master 1 déjà autonomes en Linux, réseau et administration système.

## Choix pédagogiques

- VMware/vSphere : théorie, vocabulaire et comparaison d'architecture.
- Proxmox VE : cœur pratique du cours.
- 2 à 3 étudiants par groupe.
- 1 PC physique + 1 nœud PVE principal par étudiant.
- Cluster réellement distribué entre plusieurs PC via un switch manageable.
- Peu de « cliquez ici » : objectifs, indices, diagnostics et challenges.
- Trois niveaux : **GUIDÉ**, **CHALLENGE**, **EXPERT**.
- Infrastructure conservée et enrichie tout au long du cours.
- Final Boss de 3 h avec pannes multiples et restitution d'incident.

## Version de référence

Le cours cible **Proxmox VE 9.2** et **Proxmox Backup Server 4.2**.

## Prérequis poste étudiant

- Windows 10/11
- VMware Workstation Pro
- 16 Go RAM minimum
- 8 CPU logiques minimum
- VT-x/AMD-V actif
- ~100 Go libres recommandés
- Wi-Fi ou interface principale pour Internet
- Ethernet dédié au LAB, intégré ou USB-Ethernet recommandé

## VM PVE par étudiant

```text
4 vCPU
6 à 7 Go RAM
64 Go système
20 Go disque ZFS #1
20 Go disque ZFS #2

NIC1 -> VMnet8 / NAT / Internet
NIC2 -> VMnet2 / Bridged vers NIC LAB / Underlay
NIC3 -> VMnet1 / Host-Only / OOB optionnel
```

## Réseau physique

Le transport principal du cours est volontairement simple et fiable :

```text
Groupe 1 -> VLAN 101 access -> 10.100.1.0/24
Groupe 2 -> VLAN 102 access -> 10.100.2.0/24
Groupe 3 -> VLAN 103 access -> 10.100.3.0/24
...
```

Le trunk 802.1Q transparent à travers Windows + VMware Workstation n'est **pas** requis pour le parcours principal. Il reste un challenge EXPERT si le matériel a été validé au préalable.

Les réseaux applicatifs inter-nœuds seront transportés plus tard en **VXLAN via Proxmox SDN**.

## Plan d'adressage

Pour le groupe `G` :

```text
VLAN UNDERLAY : 100 + G
UNDERLAY      : 10.100.G.0/24

PC ETU1       : 10.100.G.101
PC ETU2       : 10.100.G.102
PC ETU3       : 10.100.G.103

PVE01         : 10.100.G.11
PVE02         : 10.100.G.12
PVE03         : 10.100.G.13
```

Pas de default gateway sur la NIC Windows LAB.

Le défaut route de PVE passe par VMnet8/NAT.

## Ordre du cursus

> Important : le cluster est créé **avant** les guests persistants.

| TP | Sujet | Difficulté |
|---|---|---|
| TP00 | Préparation VMware + switch + LAB | ⭐ |
| TP01 | Installation & découverte PVE | ⭐ |
| TP02 | Linux bridge & underlay | ⭐⭐ |
| TP03 | Cluster, Corosync, quorum, QDevice | ⭐⭐⭐ |
| TP04 | LVM-thin, ZFS, snapshots | ⭐⭐⭐ |
| TP05 | VM & LXC | ⭐⭐ |
| TP06 | Template & Cloud-Init | ⭐⭐⭐ |
| TP07 | SDN/VXLAN, migration, réplication, HA | ⭐⭐⭐⭐ |
| TP08 | Sauvegarde & PBS | ⭐⭐⭐ |
| TP09 | RBAC, API token, firewall | ⭐⭐⭐⭐ |
| FINAL | Incident NovaCorp | 💀 |

## Règles

1. Ne réinstallez pas un nœud pour « corriger » un TP sauf autorisation.
2. Une commande trouvée sur Internet doit pouvoir être expliquée.
3. Un reboot n'est pas une analyse de cause racine.
4. Toute modification réseau importante doit avoir un plan de rollback.
5. Avant une manipulation cluster dangereuse : vérifier le quorum.
6. `pvecm expected` n'est pas un outil de fonctionnement normal du LAB.
