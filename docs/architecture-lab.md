# Architecture du LAB

## Flux principaux

```text
Internet
   |
Windows host
   |
VMnet8 NAT ---------------- PVE : apt / dépôts / Internet

PVE vmbr1 ---------------- VMnet2 bridgé ---------------- NIC LAB
                                                        |
                                                   switch groupe
                                                        |
                                                PVE des voisins

Windows host ------------- VMnet1 Host-Only ----------- PVE OOB
```

`VMnet2` doit être bridgé **explicitement** sur la NIC LAB et non laissé en sélection automatique.

## Pourquoi un VLAN access par groupe ?

Le switch isole les groupes sans dépendre du transport de tags 802.1Q à travers Windows + VMware Workstation. Le trunk physique est donc un bonus, pas un prérequis du cours.

## Limite pédagogique assumée

Le même underlay transporte le trafic cluster et une partie du trafic de migration. En production, on cherche généralement à mieux séparer les domaines de trafic et à protéger Corosync des congestions.
