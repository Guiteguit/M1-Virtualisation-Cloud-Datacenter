# TP05 — VM, LXC & cycle de vie

**Durée : ~1 h 30**

## Mission

Comparer réellement KVM/QEMU et LXC.

---

## Convention des workloads

```text
VM 110 -> labvm01
CT 210 -> labct01
```

Les IDs sont cluster-wide.

---

## 1. Préparez un ISO et un template LXC

Pour le conteneur :

```bash
pveam update
pveam available | grep -i debian
```

Téléchargez un template Debian récent.

Pour la VM, utilisez un ISO Debian minimal disponible dans le LAB.

---

## 2. Créez VM110 sur PVE01

Cible :

```text
ID      110
Name    labvm01
CPU     1
RAM     1024 Mo
Disk    8 Go sur zfs-lab
NIC     vmbr10
```

Installez un Linux minimal.

Installez ensuite `qemu-guest-agent` dans la VM si disponible.

---

## 3. Créez CT210 sur PVE02

Cible :

```text
ID          210
Name        labct01
CPU         1
RAM         512 Mo
RootFS      4 Go sur zfs-lab
Network     vmbr10
Unprivileged: yes
```

---

## 4. Comparez

Depuis PVE :

```bash
qm status 110
qm config 110

pct status 210
pct config 210
```

Dans les guests :

```bash
uname -a
free -h
ps aux
```

Chronométrez grossièrement le démarrage.

---

## 5. Snapshot

Sur VM110 :

```bash
qm snapshot 110 before-change
```

Modifiez un fichier dans la VM.

Rollback via GUI ou CLI.

Même logique sur CT210.

---

## 6. Décision d'architecture

Choisissez VM ou LXC et justifiez pour :

```text
Active Directory
Nginx stateless
PostgreSQL critique
runner CI
Docker host
DNS cache
appliance propriétaire
```

Aucune réponse sans justification technique.

---

# CHALLENGE

Créez un second conteneur uniquement en CLI.

---

# EXPERT

Expliquez les implications de :

```text
conteneur privilégié
conteneur non privilégié
kernel partagé
device passthrough
```

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp05.sh
```
