# Switch — préparation formateur

## Principe

Chaque groupe dispose d'un VLAN access dédié.

Exemple :

```text
G1 -> VLAN101 -> ports 1-3
G2 -> VLAN102 -> ports 4-6
G3 -> VLAN103 -> ports 7-9
```

## Pseudo-config Cisco

```text
vlan 101
 name G01-UNDERLAY

interface range Gi1/0/1-3
 description G01-PROXMOX
 switchport mode access
 switchport access vlan 101
 spanning-tree portfast
```

Adapter au constructeur.

## Pré-check

- 3 PC du même groupe : communication OK
- groupes différents : isolation OK
- pas de port-security limité à une seule MAC
- STP edge/portfast
- vitesse/duplex cohérents
- aucun DHCP parasite sur l'underlay

## Pannes Final Boss possibles

- un port déplacé vers le VLAN voisin ;
- port administrativement down ;
- un seul étudiant isolé ;
- ajout d'une restriction MAC si le switch permet un rollback immédiat.

Ne jamais injecter une panne dont le rollback n'est pas documenté.
