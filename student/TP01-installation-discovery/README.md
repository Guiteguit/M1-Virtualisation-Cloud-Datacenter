# TP01 — Installation & découverte Proxmox VE

**Durée : ~1 h 30**

## Mission

Installer un seul nœud PVE par étudiant et préparer sa double connectivité :

```text
Internet -> VMnet8
Cluster  -> VMnet2
```

Le cluster n'est PAS encore créé.

---

## 1. Nom des nœuds

Pour G=3 :

```text
pve01-g3.novacorp.lab
pve02-g3.novacorp.lab
pve03-g3.novacorp.lab
```

---

## 2. Installation

Installez Proxmox VE 9.2.

Utilisez d'abord l'interface NAT pour disposer d'un chemin Internet.

Le sous-réseau VMnet8 est propre à chaque PC ; il n'a pas besoin d'être identique entre étudiants.

---

## 3. Premier inventaire

```bash
pveversion -v
hostnamectl
ip -br link
ip -br address
ip route
lsblk
df -h
free -h
pvesm status
qm list
pct list
systemctl --failed
```

Identifiez les interfaces correspondant aux trois vNIC VMware.

---

## 4. Vérifiez la nested virtualization

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
lsmod | grep kvm
```

Le premier résultat doit être supérieur à zéro.

Sinon :

```bash
dmesg | grep -i -E 'kvm|vmx|svm'
```

---

## 5. Mettez le nœud à jour

```bash
apt update
```

N'effectuez un upgrade complet que si l'enseignant le demande, afin que toute la promotion garde une version cohérente.

---

## 6. Services Proxmox

Explorez :

```bash
systemctl --type=service |
grep -E 'pve|corosync'
```

Retrouvez au moins :

```text
pveproxy
pvedaemon
pvestatd
pve-cluster
```

Expliquez le rôle de deux d'entre eux.

---

## 7. CLI

Sans GUI :

```bash
pvesh get /nodes
pvesm status
qm list
pct list
```

---

# CHALLENGE

Construisez une commande qui affiche :

```text
HOSTNAME
PVE VERSION
CPU
RAM
DISQUES
IP
ROUTE PAR DEFAUT
```

---

# EXPERT

Explorez l'API avec `pvesh` et retrouvez l'état du nœud sans consulter de tutoriel.

---

## Important pour TP03

À la fin du TP01 :

```text
qm list  -> aucun guest
pct list -> aucun guest
```

Un nœud qui doit rejoindre le cluster doit rester vide.

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp01.sh G N
```
