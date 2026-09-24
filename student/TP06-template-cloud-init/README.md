# TP06 — Templates & Cloud-Init

**Durée : ~1 h 30**

## Mission

Passer d'une installation manuelle à un provisioning reproductible.

---

## Architecture cible

```text
Template 9000
   |
   +-- VM111 web01
   +-- VM121 app01
   +-- VM131 db01
```

Les groupes de 2 hébergent plusieurs workloads sur PVE02 si nécessaire.

---

## 1. Récupérez une image cloud

Téléchargez l'image **Debian 13 genericcloud amd64** depuis la source officielle fournie par l'enseignant.

Placez-la sur PVE01.

---

## 2. Créez le squelette

Exemple :

```bash
qm create 9000 \
  --name debian13-cloud \
  --memory 1024 \
  --cores 1 \
  --net0 virtio,bridge=vmbr10
```

Importez le disque :

```bash
qm importdisk 9000 <IMAGE.qcow2> zfs-lab
```

Repérez le disque importé :

```bash
qm config 9000
```

Attachez-le comme disque SCSI via GUI ou CLI.

Ajoutez également un disque Cloud-Init.

---

## 3. Options recommandées

Configurez :

```text
SCSI controller
boot disk
serial console
QEMU guest agent
Cloud-Init drive
```

Puis :

```bash
qm template 9000
```

Vérifiez :

```bash
qm config 9000
```

---

## 4. Clonez

Créez :

```text
111 web01
121 app01
131 db01
```

Répartition :

```text
PVE01 -> web01
PVE02 -> app01
PVE03 -> db01
```

groupe de 2 :

```text
PVE01 -> web01
PVE02 -> app01 + db01
```

---

## 5. Cloud-Init

Configurez au minimum :

```text
username
SSH public key
hostname
IP
```

Pour le moment, les VMs peuvent rester sur `vmbr10`.

Le vrai réseau distribué arrive au TP07.

---

## 6. Test d'idempotence humaine

Supprimez VM121.

Recréez-la depuis le template.

Comparez le temps avec une réinstallation ISO traditionnelle.

---

# CHALLENGE

Recréez VM121 en CLI uniquement.

---

# EXPERT

Expliquez les différences entre :

```text
full clone
linked clone
template
cloud-init
golden image
```

Puis listez ce qui manque encore pour parler de véritable Infrastructure as Code.

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp06.sh
```
