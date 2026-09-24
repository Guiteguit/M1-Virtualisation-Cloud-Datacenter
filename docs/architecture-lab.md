# Architecture du LAB NovaCorp

## Vue globale

```text
                   INTERNET
                       |
              Wi-Fi / NIC principale
                       |
       +---------------+---------------+
       |               |               |
    PC ETU1         PC ETU2         PC ETU3
    Windows         Windows         Windows
       |               |               |
 VMware WS       VMware WS       VMware WS
       |               |               |
     PVE01           PVE02           PVE03
       |               |               |
     VMnet2          VMnet2          VMnet2
       |               |               |
    NIC LAB         NIC LAB         NIC LAB
       |               |               |
       +---------------+---------------+
                       |
                SWITCH MANAGEABLE
                       |
                 VLAN UNDERLAY
```

## VMware

### NIC 1 — Internet

```text
PVE -> VMnet8 NAT -> Windows -> Internet
```

### NIC 2 — Underlay

```text
PVE -> VMnet2 -> VMware Bridge -> NIC Ethernet LAB -> Switch
```

VMnet2 doit être explicitement bridgé sur la NIC LAB et jamais laissé en « Automatic ».

### NIC 3 — OOB

```text
Windows <-> VMnet1 Host-Only <-> PVE
```

Facultative mais utile pour retrouver le nœud lorsqu'un étudiant casse la configuration underlay.

## PVE après TP02

```text
vmbr0 -> NIC NAT -> Internet / default route
vmbr1 -> NIC LAB -> 10.100.G.X/24 / cluster underlay
vmbr10 -> bridge local temporaire pour exercices guests
```

## Cluster

Groupe de 3 :

```text
PVE01 ----- PVE02
   \         /
    \       /
      PVE03
```

Groupe de 2 :

```text
PVE01 ----- PVE02
   \         /
    \       /
      QNETD
     externe
```

## Overlay au TP07

```text
              UNDERLAY 10.100.G.0/24
                 /       |       \
              PVE01    PVE02    PVE03
                 \       |       /
                  +-- VXLAN ---+
                       |
             +---------+---------+
             |                   |
           srvG                 dmzG
        10.20.G.0/24         10.30.G.0/24
```

VXLAN offre une continuité L2 aux workloads entre plusieurs PVE sans exiger un trunk VLAN physique dans Windows/Workstation.

## Limite assumée du LAB

Corosync, migration et transport VXLAN partagent initialement le même underlay physique.

C'est volontaire pour tenir avec un PC 16 Go + une seule NIC LAB dédiée.

Le débrief doit expliquer qu'en production Corosync est sensible à la latence et qu'on cherche à éviter qu'il partage un réseau fortement chargé.
