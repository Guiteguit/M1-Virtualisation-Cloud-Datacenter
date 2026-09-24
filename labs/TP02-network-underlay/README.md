# TP02 — Réseau Proxmox & underlay

**Durée : ~1 h 30**

## Mission

Créer le vrai réseau inter-PC du cluster sans casser l'accès Internet.

À la fin :

```text
vmbr0 -> NAT VMware -> Internet
vmbr1 -> NIC LAB -> underlay du groupe
```

---

## 1. Cartographiez les interfaces

```bash
ip -br link
ip -br a
ip route
```

Débranchez/rebranchez temporairement le câble LAB si nécessaire pour identifier la bonne interface.

Ne modifiez rien avant d'avoir noté :

```text
NIC NAT = ?
NIC LAB = ?
NIC OOB = ?
```

---

## 2. Comprenez le bridge Linux

Inspectez :

```bash
cat /etc/network/interfaces
bridge link
ip -d link show type bridge
```

Question :

> En quoi `vmbr0` ressemble-t-il à un vSwitch VMware ?

---

## 3. Configurez vmbr1

Pour PVE01 groupe 3 :

```text
vmbr1
Address : 10.100.3.11/24
Bridge port : NIC LAB
Gateway : aucune
STP : off
Forward delay : 0
```

PVE02 :

```text
10.100.3.12/24
```

PVE03 :

```text
10.100.3.13/24
```

Effectuez la modification via la GUI ou `/etc/network/interfaces`.

Avant application :

```bash
cp /etc/network/interfaces /root/interfaces.tp02.bak
```

Si modification manuelle :

```bash
ifreload -a
```

---

## 4. Vérifiez le routage

```bash
ip route
```

Vous devez conserver :

```text
default via <VMware NAT>
10.100.G.0/24 dev vmbr1
```

Il ne doit y avoir **qu'une route par défaut utile**.

---

## 5. Tests inter-nœuds

PVE01 :

```bash
ping -c 3 10.100.G.12
ping -c 3 10.100.G.13
```

PVE02 :

```bash
ping -c 3 10.100.G.11
```

Puis :

```bash
ip neigh show dev vmbr1
```

---

## 6. Capture

Sur PVE01 :

```bash
tcpdump -ni vmbr1 icmp
```

Pendant que PVE02 ping PVE01.

Repérez :

```text
source
destination
ICMP request
ICMP reply
```

---

## 7. Bridge local de test

Créez :

```text
vmbr10
Bridge ports : none
IPv4         : none
```

Ce bridge sera utilisé temporairement pour les premiers guests.

### Question

Pourquoi deux VM sur deux PVE différents et attachées chacune à `vmbr10` ne pourraient-elles pas communiquer ?

---

# CHALLENGE

L'un des étudiants coupe temporairement son câble LAB.

Les autres doivent décrire précisément ce qui est perdu et ce qui reste disponible :

```text
Internet PVE ?
GUI locale ?
underlay ?
```

---

# EXPERT

À partir de :

```bash
ip -d link
bridge fdb show
tcpdump -e
```

expliquez comment le bridge apprend les MAC.

---

## Rollback

Si vmbr1 est cassé :

```bash
cp /root/interfaces.tp02.bak /etc/network/interfaces
ifreload -a
```

ou utilisez la console VMware si SSH n'est plus possible.

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp02.sh G N
```
