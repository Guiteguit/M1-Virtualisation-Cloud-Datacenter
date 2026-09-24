# TP03 — Cluster, Corosync, quorum & QDevice

**Durée : 1 h 30 à 2 h**

## Mission

Assembler les nœuds situés sur plusieurs PC physiques en un seul cluster NovaCorp.

---

# Pré-check obligatoire

Sur TOUS les nœuds :

```bash
qm list
pct list
```

Il ne doit y avoir aucun guest.

Vérifiez aussi :

```bash
ping -c 2 10.100.G.11
ping -c 2 10.100.G.12
```

et `.13` si groupe de 3.

---

## 1. Création du cluster

Sur PVE01 uniquement :

```bash
pvecm create novacorp-gG --link0 10.100.G.11
```

Vérifiez :

```bash
pvecm status
```

---

## 2. Ajout PVE02

Sur PVE02 :

```bash
pvecm add 10.100.G.11 --link0 10.100.G.12
```

Puis :

```bash
pvecm status
pvecm nodes
```

---

## 3. Ajout PVE03

Groupe de 3 uniquement :

```bash
pvecm add 10.100.G.11 --link0 10.100.G.13
```

---

## 4. Inspectez pmxcfs

```bash
mount | grep /etc/pve
ls -la /etc/pve
cat /etc/pve/corosync.conf
```

Créez depuis PVE01 :

```bash
echo "groupe-G" > /etc/pve/lab-note.txt
```

Puis vérifiez depuis PVE02.

### Question

Que démontre ce test ?

---

# Partie quorum — groupe de 3

État normal :

```text
3 votes
quorum = 2
```

Arrêtez **PVE03 depuis VMware Workstation**.

Sur PVE01 :

```bash
pvecm status
```

Répondez :

1. Le cluster est-il quorate ?
2. Combien de votes restent ?
3. Pouvez-vous encore modifier `/etc/pve` ?

Redémarrez PVE03 avant la suite.

---

# Partie quorum — groupe de 2

Avant QDevice, observez :

```bash
pvecm status
```

Puis arrêtez PVE02.

Sur PVE01, vérifiez :

```bash
pvecm status
touch /etc/pve/test-quorum
```

Le but est d'observer le comportement, pas de le contourner.

Redémarrez PVE02.

---

# QDevice pour groupes de 2

L'enseignant fournit l'adresse d'un Debian/QNetd indépendant.

Sur le serveur externe :

```bash
apt install corosync-qnetd
```

Sur les deux PVE :

```bash
apt install corosync-qdevice
```

Depuis un PVE :

```bash
pvecm qdevice setup <IP-QNETD>
```

Vérifiez :

```bash
pvecm status
```

Vous devez maintenant comprendre le modèle :

```text
PVE01 + PVE02 + vote externe
```

---

# CHALLENGE

Avec :

```bash
journalctl -u corosync
corosync-cfgtool -s
pvecm status
```

identifiez le moment où un membre disparaît.

---

# EXPERT

Expliquez pourquoi cette « solution » est interdite comme réponse normale :

```bash
pvecm expected 1
```

Puis expliquez quand une modification temporaire des expected votes peut être dangereuse.

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp03.sh G
```
