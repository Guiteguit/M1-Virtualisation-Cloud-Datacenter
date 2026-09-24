# TP03 — Cluster, Corosync, quorum & QDevice

## Mission

Assembler le cluster NovaCorp et provoquer une vraie perte de membre pour comprendre le quorum.

## Pré-check

```bash
qm list
pct list
```

Aucun guest persistant ne doit exister avant l'ajout des nœuds au cluster.

## 🟢 Groupe de 3

Sur PVE01 :

```bash
pvecm create novacorp-gG --link0 10.100.G.11
```

Sur PVE02 :

```bash
pvecm add 10.100.G.11 --link0 10.100.G.12
```

Puis PVE03 de la même manière.

Contrôler :

```bash
pvecm status
pvecm nodes
cat /etc/pve/corosync.conf
```

Éteindre PVE03 depuis VMware et observer le quorum.

## 🟢 Groupe de 2

Créer le cluster deux nœuds, observer le comportement lorsque l'un disparaît, puis ajouter le QDevice indiqué par le formateur :

```bash
apt install corosync-qdevice
pvecm qdevice setup <IP-QNETD>
```

## 🟠 CHALLENGE

```bash
journalctl -u corosync
corosync-cfgtool -s
```

Identifier précisément la disparition du peer.

## 🔴 EXPERT

Expliquer pourquoi `pvecm expected 1` n'est pas une solution de fonctionnement normal et quel risque il peut introduire.

## Validation

```bash
sudo ./scripts/proxmox/check-tp03.sh G
```
