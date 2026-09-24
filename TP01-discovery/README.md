# TP01 — Installation & découverte Proxmox

**Durée cible : 55 min de pratique.**

## Mission

Installer Proxmox VE puis produire un inventaire technique du nœud sans dépendre uniquement de l'interface web.

## 🟢 GUIDÉ

Après installation :

```bash
pveversion -v
hostnamectl
ip -br a
ip route
lsblk
free -h
pvesm status
qm list
pct list
systemctl --failed
```

Vérifier la nested virtualization :

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
lsmod | grep kvm
```

Identifier les services :

```bash
systemctl --type=service | grep -E 'pve|corosync'
```

## 🟠 CHALLENGE

Sans utiliser la GUI, retrouver :

- la version PVE ;
- les stockages ;
- les VMs/LXC ;
- l'adresse de la route par défaut ;
- les ressources CPU/RAM.

## 🔴 EXPERT

Construire un petit script `inventory.sh` qui affiche ces informations proprement.

## Livrable

`deliverables/group-G/TP01.md` : inventaire, deux services PVE expliqués, résultat du check.

## Validation

```bash
sudo ./scripts/proxmox/check-tp01.sh
```
