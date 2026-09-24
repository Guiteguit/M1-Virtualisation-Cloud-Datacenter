# TP02 — Réseau Proxmox, Linux Bridge & underlay

## Mission

Créer le réseau réellement utilisé entre les nœuds situés sur plusieurs PC.

## 🟢 GUIDÉ

Identifier les NIC :

```bash
ip -br link
ip -br a
ip route
```

Sauvegarder :

```bash
cp /etc/network/interfaces /root/interfaces.before-tp02
```

Créer `vmbr1` sur la NIC LAB :

```text
PVE01 : 10.100.G.11/24
PVE02 : 10.100.G.12/24
PVE03 : 10.100.G.13/24
Gateway : aucune
```

Conserver la default route via la NIC NAT.

Tester :

```bash
ping -c 3 10.100.G.12
ip neigh show dev vmbr1
tcpdump -ni vmbr1 icmp
```

Créer aussi `vmbr10`, bridge local sans port, pour les premières VMs.

## 🟠 CHALLENGE

Un membre du groupe débranche son câble LAB. Décrire ce qui fonctionne encore : Internet, GUI, underlay, voisins.

## 🔴 EXPERT

Utiliser :

```bash
bridge fdb show
ip -d link
tcpdump -e
```

et expliquer comment un bridge apprend les MAC.

## Validation

```bash
sudo ./scripts/proxmox/check-tp02.sh G N
```
