# TP05 — VM, LXC, Template & Cloud-Init

**Durée cible : 1 h 15 à 1 h 30**

## Contexte

NovaCorp souhaite industrialiser le déploiement de ses workloads.

Jusqu’à présent, chaque serveur devait être installé manuellement à partir d’un ISO. Cette méthode fonctionne, mais elle devient rapidement lente et difficile à reproduire.

Votre mission consiste à :

- créer une **VM KVM/QEMU** ;
- créer un **conteneur LXC** ;
- comparer VM et conteneur ;
- créer un **template Debian 13 Cloud** ;
- utiliser **Cloud-Init** ;
- cloner rapidement plusieurs VM ;
- injecter automatiquement :
  - hostname ;
  - utilisateur ;
  - clé SSH ;
  - configuration IP ;
- comprendre la différence entre :
  - installation manuelle ;
  - template ;
  - clone ;
  - Cloud-Init ;
  - Infrastructure as Code.

> ⚠️ Dans ce TP, `zfs-lab` est un stockage **local** à chaque nœud Proxmox.
> Le template créé sur PVE01 reste donc local à PVE01.
> Les migrations entre nœuds seront étudiées dans le TP06.

---

# Architecture cible

```text
                    PVE01
                      │
          ┌───────────┼─────────────┐
          │           │             │
        VM110       CT210        TEMPLATE
       labvm01      labct01         9000
                                    │
                                    │ clone
                         ┌──────────┼──────────┐
                         │          │          │
                       VM111      VM121      VM131
                       web01      app01       db01
```

Pour économiser les ressources du LAB, toutes les VM n’ont pas besoin d’être démarrées simultanément.

---

# 🟢 GUIDÉ — Partie 1 : vérifier le stockage et le réseau

Avant de créer des workloads :

```bash
pvesm status
```

Vous devez retrouver au minimum :

```text
local
local-lvm
zfs-lab
```

Vérifiez également les bridges :

```bash
ip -br link
```

Vous devez disposer de :

```text
vmbr0 / réseau de management ou Internet
vmbr1 / réseau LAB inter-PVE
vmbr10 / réseau local de test
```

Dans ce TP, les premiers workloads utilisent :

```text
vmbr10
```

### Question

Deux VM connectées à `vmbr10` mais situées sur deux PVE différents peuvent-elles communiquer directement ?

Justifiez.

---

# 🟢 GUIDÉ — Partie 2 : créer une VM KVM/QEMU

Nous allons créer :

```text
VM ID   : 110
Name    : labvm01
CPU     : 1 vCPU
RAM     : 1024 Mo
Disk    : 8 Go
Storage : zfs-lab
Network : vmbr10
```

Vous pouvez créer la VM depuis la GUI ou le CLI.

Exemple CLI :

```bash
qm create 110 \
  --name labvm01 \
  --cores 1 \
  --memory 1024 \
  --net0 virtio,bridge=vmbr10 \
  --scsihw virtio-scsi-single
```

Ajoutez un disque :

```bash
qm set 110 \
  --scsi0 zfs-lab:8 \
  --discard on \
  --ssd 1
```

Vérifiez :

```bash
qm config 110
```

Vous devez retrouver notamment :

```text
cores: 1
memory: 1024
name: labvm01
net0: virtio,...
scsi0: zfs-lab:...
```

---

# 🟢 GUIDÉ — Partie 3 : installer une VM Debian

Ajoutez un ISO Debian disponible dans le stockage `local`.

Vérifiez les ISO :

```bash
pvesm list local --content iso
```

Attachez ensuite l’ISO à la VM via la GUI ou le CLI.

Exemple :

```bash
qm set 110 \
  --ide2 local:iso/<DEBIAN_ISO>,media=cdrom
```

Configurez l’ordre de boot si nécessaire :

```bash
qm set 110 --boot order='ide2;scsi0'
```

Démarrez :

```bash
qm start 110
```

Vérifiez :

```bash
qm status 110
```

Installez Debian de manière minimale.

Après installation, détachez l’ISO puis placez le disque en premier dans l’ordre de boot.

---

# 🟢 GUIDÉ — Partie 4 : installer QEMU Guest Agent

Dans la VM Debian :

```bash
apt update
apt install -y qemu-guest-agent
systemctl enable --now qemu-guest-agent
```

Dans Proxmox :

```bash
qm set 110 --agent enabled=1
```

Vérifiez :

```bash
qm config 110 | grep agent
```

Puis :

```bash
qm guest cmd 110 ping
```

si la VM est démarrée et l’agent fonctionnel.

### À comprendre

QEMU Guest Agent permet à l’hyperviseur de mieux communiquer avec la VM :

```text
Proxmox
   │
   │ QEMU Guest Agent
   ▼
Guest OS
```

Il peut notamment faciliter :

- remontée d’informations ;
- arrêt propre ;
- freeze/thaw filesystem dans certains scénarios ;
- récupération d’adresses IP ;
- opérations de sauvegarde.

---

# 🟢 GUIDÉ — Partie 5 : créer un conteneur LXC

Nous allons maintenant créer :

```text
CT ID      : 210
Hostname   : labct01
CPU        : 1
RAM        : 512 Mo
RootFS     : 4 Go
Storage    : zfs-lab
Network    : vmbr10
Unprivileged : yes
```

Commencez par actualiser la liste des templates :

```bash
pveam update
```

Cherchez Debian :

```bash
pveam available | grep -i debian
```

Repérez le template Debian 13 disponible.

Téléchargez-le dans le stockage `local`.

Exemple :

```bash
pveam download local <TEMPLATE_DEBIAN_13>
```

Vérifiez :

```bash
pveam list local
```

---

# 🟢 GUIDÉ — Partie 6 : créer CT210

Exemple CLI :

```bash
pct create 210 \
  local:vztmpl/<TEMPLATE_DEBIAN_13> \
  --hostname labct01 \
  --cores 1 \
  --memory 512 \
  --rootfs zfs-lab:4 \
  --net0 name=eth0,bridge=vmbr10,ip=dhcp \
  --unprivileged 1
```

Si aucun DHCP n’existe sur `vmbr10`, configurez une IP statique adaptée à votre LAB ou laissez le réseau sans IP pour la comparaison initiale.

Démarrez le conteneur :

```bash
pct start 210
```

Vérifiez :

```bash
pct status 210
pct config 210
```

Entrez dans le conteneur :

```bash
pct enter 210
```

Puis :

```bash
hostname
uname -a
free -h
ip -br a
```

Quittez :

```bash
exit
```

---

# 🟢 GUIDÉ — Partie 7 : comparer VM et LXC

Comparez les deux workloads.

Depuis PVE :

```bash
qm status 110
qm config 110

pct status 210
pct config 210
```

Dans chaque workload :

```bash
uname -a
free -h
ps aux
```

Complétez :

| Caractéristique | VM KVM | LXC |
|---|---|---|
| Kernel propre | ? | ? |
| OS complet | ? | ? |
| Isolation | ? | ? |
| Temps de démarrage | ? | ? |
| Consommation RAM | ? | ? |
| Peut exécuter Windows | ? | ? |
| Accès matériel complexe | ? | ? |
| Densité de workloads | ? | ? |

### À comprendre

Une VM possède son propre kernel :

```text
Application
Guest OS
Guest Kernel
Virtual Hardware
KVM/QEMU
Host
```

Un conteneur partage le kernel Linux de l’hôte :

```text
Application
Userspace LXC
────────────────
Kernel Linux PVE
Host
```

---

# 🟢 GUIDÉ — Partie 8 : choix d’architecture

Pour chaque workload, choisissez **VM ou LXC** et justifiez :

```text
Active Directory
Nginx stateless
PostgreSQL critique
Runner CI
Docker host
DNS cache
Appliance propriétaire
Serveur Windows
```

> Une réponse sans justification technique n’est pas considérée comme complète.

---

# 🟢 GUIDÉ — Partie 9 : passer à l’industrialisation

L’installation manuelle de VM fonctionne, mais elle nécessite :

```text
ISO
installation
partitionnement
utilisateur
SSH
réseau
mise à jour
configuration
```

Pour chaque nouvelle VM.

Nous allons remplacer cela par :

```text
IMAGE CLOUD
     │
     ▼
 TEMPLATE
     │
     ▼
   CLONE
     │
     ▼
 CLOUD-INIT
     │
     ▼
 VM prête
```

---

# 🟢 GUIDÉ — Partie 10 : télécharger une image Debian Cloud

Sur PVE01, créez un répertoire de travail :

```bash
mkdir -p /root/cloud-images
cd /root/cloud-images
```

Téléchargez une image **Debian 13 genericcloud amd64** depuis le dépôt officiel Debian Cloud.

Le fichier doit être au format :

```text
qcow2
```

Vérifiez :

```bash
ls -lh
file *.qcow2
```

### Important

Une image Cloud n’est pas un ISO d’installation.

Elle contient déjà un système Linux prêt à démarrer et destiné à être personnalisé automatiquement.

---

# 🟢 GUIDÉ — Partie 11 : créer le squelette du template

Créez la VM 9000 :

```bash
qm create 9000 \
  --name debian13-cloud \
  --cores 1 \
  --memory 1024 \
  --net0 virtio,bridge=vmbr10 \
  --scsihw virtio-scsi-single
```

Vérifiez :

```bash
qm config 9000
```

---

# 🟢 GUIDÉ — Partie 12 : importer le disque Cloud

Importez l’image qcow2 :

```bash
qm importdisk 9000 \
  /root/cloud-images/<IMAGE_DEBIAN13.qcow2> \
  zfs-lab
```

Une fois l’import terminé :

```bash
qm config 9000
```

Vous devriez voir un disque du type :

```text
unused0: zfs-lab:vm-9000-disk-0
```

Attachez-le :

```bash
qm set 9000 \
  --scsi0 zfs-lab:vm-9000-disk-0
```

> Le nom exact du volume peut être différent.
> Utilisez celui affiché par `qm config 9000`.

---

# 🟢 GUIDÉ — Partie 13 : configurer le boot

Configurez le disque système :

```bash
qm set 9000 --boot order=scsi0
```

Ajoutez une console série :

```bash
qm set 9000 \
  --serial0 socket \
  --vga serial0
```

Pourquoi ?

Les images Cloud sont souvent prévues pour fonctionner facilement avec une console série.

---

# 🟢 GUIDÉ — Partie 14 : ajouter le disque Cloud-Init

Ajoutez :

```bash
qm set 9000 --ide2 zfs-lab:cloudinit
```

Vérifiez :

```bash
qm config 9000
```

Vous devez maintenant retrouver quelque chose comme :

```text
ide2: zfs-lab:vm-9000-cloudinit,media=cdrom
```

### À comprendre

Le disque Cloud-Init contient les données de personnalisation fournies par Proxmox :

```text
hostname
user
SSH key
IP
DNS
```

Au premier boot :

```text
Proxmox
   │
   ▼
Cloud-Init drive
   │
   ▼
Guest Linux
   │
   ▼
configuration automatique
```

---

# 🟢 GUIDÉ — Partie 15 : activer le Guest Agent

Configurez :

```bash
qm set 9000 --agent enabled=1
```

Les images Cloud Debian peuvent nécessiter l’installation du paquet `qemu-guest-agent` dans l’image ou après le premier boot.

Ce point sera vérifié sur les clones.

---

# 🟢 GUIDÉ — Partie 16 : configurer Cloud-Init

Configurez un utilisateur :

```bash
qm set 9000 --ciuser student
```

Ajoutez votre clé SSH publique.

Exemple :

```bash
qm set 9000 --sshkeys /root/.ssh/id_ed25519.pub
```

Si vous ne disposez pas encore de clé :

```bash
ssh-keygen -t ed25519
```

Puis :

```bash
qm set 9000 --sshkeys /root/.ssh/id_ed25519.pub
```

Vous pouvez également définir temporairement un mot de passe via la GUI Cloud-Init si nécessaire pour le LAB.

> En production, privilégiez l’authentification par clé SSH.

---

# 🟢 GUIDÉ — Partie 17 : configurer le réseau Cloud-Init

Si `vmbr10` dispose d’un DHCP :

```bash
qm set 9000 --ipconfig0 ip=dhcp
```

Sinon, vous pourrez définir les IP au niveau de chaque clone.

Exemple :

```bash
qm set 111 --ipconfig0 ip=10.50.0.11/24
```

Dans ce TP, aucune gateway n’est obligatoire si le réseau sert uniquement aux tests locaux.

---

# 🟢 GUIDÉ — Partie 18 : vérifier la configuration Cloud-Init

Affichez :

```bash
qm cloudinit dump 9000 user
```

Puis :

```bash
qm cloudinit dump 9000 network
```

Et :

```bash
qm cloudinit dump 9000 meta
```

### Question

À ce stade, la VM 9000 doit-elle être utilisée comme serveur de production ?

Réponse attendue :

> Non. Elle va devenir un template immuable servant de base aux clones.

---

# 🟢 GUIDÉ — Partie 19 : transformer la VM en template

Vérifiez une dernière fois :

```bash
qm config 9000
```

Puis :

```bash
qm template 9000
```

Contrôlez :

```bash
qm config 9000 | grep template
```

Résultat attendu :

```text
template: 1
```

Dans la GUI, l’icône de VM doit également changer.

---

# 🟢 GUIDÉ — Partie 20 : créer web01

Clonez le template :

```bash
qm clone 9000 111 \
  --name web01 \
  --full 1 \
  --storage zfs-lab
```

Pourquoi :

```text
--full 1
```

?

Parce que nous souhaitons ici un **full clone indépendant**.

Configurez :

```bash
qm set 111 --ciuser student
```

Ajoutez la clé SSH :

```bash
qm set 111 --sshkeys /root/.ssh/id_ed25519.pub
```

Configurez son réseau.

DHCP :

```bash
qm set 111 --ipconfig0 ip=dhcp
```

ou statique :

```bash
qm set 111 --ipconfig0 ip=10.50.0.11/24
```

---

# 🟢 GUIDÉ — Partie 21 : créer app01 et db01

Créez :

```text
VM121 -> app01
VM131 -> db01
```

Exemple :

```bash
qm clone 9000 121 \
  --name app01 \
  --full 1 \
  --storage zfs-lab
```

Puis :

```bash
qm clone 9000 131 \
  --name db01 \
  --full 1 \
  --storage zfs-lab
```

Configurez éventuellement :

```text
web01 -> 10.50.0.11
app01 -> 10.50.0.12
db01  -> 10.50.0.13
```

---

# 🟢 GUIDÉ — Partie 22 : démarrer un clone

Pour limiter la RAM du LAB, commencez uniquement par :

```bash
qm start 111
```

Puis :

```bash
qm status 111
```

Attendez le premier boot Cloud-Init.

Consultez la console.

Dans la VM :

```bash
cloud-init status --wait
```

Puis :

```bash
hostname
ip -br a
```

Vous devez retrouver :

```text
hostname : web01
IP       : celle injectée
```

---

# 🟢 GUIDÉ — Partie 23 : tester SSH

Depuis une machine ayant accès au réseau de `web01` :

```bash
ssh student@<IP_WEB01>
```

Vous devez vous connecter à l’aide de votre clé.

Vérifiez :

```bash
hostname
whoami
ip -br a
```

---

# 🟢 GUIDÉ — Partie 24 : mesurer le gain

Comparez les deux processus.

## Installation traditionnelle

```text
Créer VM
ISO
boot
installation
partitionnement
création utilisateur
SSH
réseau
mise à jour
configuration
```

## Cloud-Init

```text
clone template
     │
     ▼
injecter paramètres
     │
     ▼
start
     │
     ▼
VM prête
```

Chronométrez grossièrement :

```text
Installation VM110 : ______ minutes
Création web01      : ______ minutes
```

---

# Questions obligatoires

## Question 1 — VM ou LXC ?

Pourquoi utiliser une VM pour certains workloads et un LXC pour d’autres ?

---

## Question 2 — Template vs snapshot

Quelle est la différence entre :

```text
snapshot
template
```

?

---

## Question 3 — Template vs clone

Expliquez :

```text
Template
   │
   ├── Clone 1
   ├── Clone 2
   └── Clone 3
```

---

## Question 4 — Cloud-Init

Cloud-Init installe-t-il Debian ?

Expliquez précisément son rôle.

---

## Question 5 — Pourquoi une clé SSH ?

Pourquoi préférer :

```text
clé SSH
```

à :

```text
mot de passe root identique partout
```

?

---

## Question 6 — Stockage local

Le template `9000` existe sur PVE01.

Peut-on immédiatement exécuter :

```text
clone 9000 sur PVE02
```

avec notre `zfs-lab` actuel ?

Expliquez.

---

# 🟠 CHALLENGE — recréer app01 uniquement en CLI

Supprimez :

```text
VM121 app01
```

Puis recréez-la **sans utiliser la GUI**.

Objectif final :

```text
VM ID      : 121
Name       : app01
CPU        : 1
RAM        : 1024 Mo
Storage    : zfs-lab
User       : student
SSH        : clé publique
IP         : 10.50.0.12/24
```

Vous devrez utiliser notamment :

```text
qm clone
qm set
qm start
```

À la fin :

```bash
qm config 121
```

doit permettre de retrouver votre configuration.

---

# 🟠 CHALLENGE — modifier Cloud-Init après clonage

Changez l’adresse IP de `app01`.

Puis :

```bash
qm cloudinit update 121
```

Redémarrez la VM si nécessaire.

Vérifiez que la nouvelle configuration est effectivement appliquée.

### Question

Pourquoi une modification Cloud-Init n’est-elle pas forcément équivalente à une modification réseau classique dans l’OS après plusieurs boots ?

---

# 🔴 EXPERT — Full clone vs Linked clone

Expliquez :

## Full clone

```text
Template
   │
   ├── copie complète
   │
   ▼
Clone indépendant
```

Avantages :

```text
indépendance
mobilité
moins de dépendance à la source
```

Inconvénient :

```text
plus d'espace
copie plus longue
```

## Linked clone

```text
Template
   │
   ├── base commune
   │
   └── différences du clone
```

Avantages :

```text
rapide
économie d'espace
```

Inconvénients :

```text
dépendance
contraintes de stockage
gestion plus complexe
```

### Question

Quel modèle choisiriez-vous pour :

```text
VDI éphémère
serveur de production
LAB étudiant
```

et pourquoi ?

---

# 🔴 EXPERT — Golden Image

Expliquez ce qu’est une :

```text
Golden Image
```

et proposez son cycle de vie :

```text
Debian Cloud
     │
     ▼
patch
     │
     ▼
packages communs
     │
     ▼
hardening
     │
     ▼
validation
     │
     ▼
template
```

### Question

Pourquoi une Golden Image vieille de 18 mois représente-t-elle un risque ?

---

# 🔴 EXPERT — Sommes-nous déjà en Infrastructure as Code ?

Nous avons :

```text
template
Cloud-Init
CLI qm
```

Est-ce suffisant pour parler d’Infrastructure as Code ?

Identifiez ce qu’il manque éventuellement :

```text
déclaration versionnée
Git
Terraform/OpenTofu
Ansible
pipeline
validation
secrets
idempotence
review
```

Proposez une évolution :

```text
Git
 │
 ▼
Terraform / OpenTofu
 │
 ▼
API Proxmox
 │
 ▼
VM clone
 │
 ▼
Cloud-Init
 │
 ▼
Ansible
 │
 ▼
Application prête
```

---

# 🔴 EXPERT — Inspecter Cloud-Init dans la VM

Dans `web01` :

```bash
cloud-init status
```

Puis :

```bash
ls -la /var/lib/cloud/
```

Consultez :

```bash
journalctl -u cloud-init
```

ou :

```bash
cat /var/log/cloud-init.log
```

Retrouvez les informations provenant de Proxmox.

---

# Validation TP05

Le nœud doit disposer au minimum de :

```text
VM110 labvm01
CT210 labct01
Template 9000 debian13-cloud
VM111 web01
VM121 app01
VM131 db01
```

> Les trois clones n’ont pas besoin d’être démarrés simultanément.

Vérifiez :

```bash
qm list
```

Puis :

```bash
pct list
```

Vérifiez le template :

```bash
qm config 9000 | grep template
```

Résultat attendu :

```text
template: 1
```

Vérifiez Cloud-Init sur web01 :

```bash
qm cloudinit dump 111 user
qm cloudinit dump 111 network
```

Puis lancez :

```bash
sudo ./scripts/proxmox/check-tp05.sh
```

Résultat attendu :

```text
[PASS] VM110 labvm01 exists
[PASS] CT210 labct01 exists
[PASS] Template 9000 exists
[PASS] VM9000 is a template
[PASS] VM111 web01 exists
[PASS] VM121 app01 exists
[PASS] VM131 db01 exists
[PASS] web01 uses Cloud-Init
[PASS] Workloads use zfs-lab

STATUS: READY FOR TP06
```

---

# Ce qu’il faut retenir

À la fin du TP, vous devez pouvoir expliquer cette évolution :

```text
MANUEL

ISO
 ↓
installation
 ↓
configuration
 ↓
serveur
```

vers :

```text
INDUSTRIALISÉ

Cloud Image
    ↓
Template
    ↓
Clone
    ↓
Cloud-Init
    ↓
VM configurée
```

Et comprendre que Cloud-Init n’est pas encore, à lui seul, une chaîne complète d’Infrastructure as Code.
