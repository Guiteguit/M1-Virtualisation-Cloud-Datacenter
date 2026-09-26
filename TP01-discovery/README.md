# TP01 — Installation & découverte Proxmox VE

**Durée cible : ~55 min de pratique**

## Contexte

Vous rejoignez l’équipe Infrastructure de NovaCorp.

Chaque membre du groupe dispose d’un PC Windows exécutant VMware Workstation et hébergera **un nœud Proxmox VE**.

Votre première mission consiste à :

- installer ou finaliser l’installation du nœud ;
- vérifier son identité ;
- identifier ses interfaces réseau ;
- vérifier la virtualisation imbriquée ;
- vérifier les dépôts APT ;
- produire un premier inventaire technique ;
- comprendre les principaux services Proxmox ;
- préparer le nœud pour la création du cluster au TP03.

> ⚠️ À la fin de ce TP, **aucune VM ni aucun conteneur ne doit encore être créé**.
> Les nœuds doivent rester vides avant leur intégration au cluster.

---

# Architecture cible

Pour un groupe de trois étudiants :

```text
PC ETU1              PC ETU2              PC ETU3
   │                     │                     │
VMware WS             VMware WS             VMware WS
   │                     │                     │
 PVE01                 PVE02                 PVE03
```

Chaque nœud dispose de plusieurs interfaces VMware :

```text
NIC 1 -> VMnet8 / NAT
         Internet / apt

NIC 2 -> VMnet LAB
         futur réseau inter-PVE

NIC 3 -> Host-Only / OOB
         optionnelle
```

---

# 🟢 GUIDÉ — Partie 1 : vérifier l’identité du nœud

Après installation :

```bash
hostname
```

Puis :

```bash
hostname -f
```

Exemple attendu :

```text
pve01
pve01.novacorp.lab
```

Pour le groupe :

```text
ETU1 -> pve01.novacorp.lab
ETU2 -> pve02.novacorp.lab
ETU3 -> pve03.novacorp.lab
```

---

## Vérifier `/etc/hostname`

```bash
cat /etc/hostname
```

Exemple :

```text
pve01
```

---

## Vérifier `/etc/hosts`

```bash
cat /etc/hosts
```

Vous devez retrouver une entrée cohérente pour le nœud.

Exemple :

```text
127.0.0.1 localhost.localdomain localhost

192.168.56.11 pve01.novacorp.lab pve01
```

> Le réseau présenté ici est un exemple de recette locale.
> Utilisez le plan d’adressage réel fourni par le formateur.

---

## Test de résolution locale

```bash
getent hosts $(hostname -f)
```

Puis :

```bash
ping -c 2 $(hostname -f)
```

### À comprendre

Proxmox s’appuie fortement sur :

```text
hostname
FQDN
résolution de noms
certificats TLS
cluster
```

Une incohérence ici peut provoquer plus tard des erreurs lors de :

```text
pvecm add
```

ou lors de la vérification des certificats.

---

# 🟢 GUIDÉ — Partie 2 : inventorier la machine

Affichez la version Proxmox :

```bash
pveversion -v
```

Puis :

```bash
hostnamectl
```

Inventoriez les interfaces réseau :

```bash
ip -br a
```

Puis les routes :

```bash
ip route
```

Inventoriez les disques :

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
```

Mémoire :

```bash
free -h
```

CPU :

```bash
lscpu
```

Stockages connus de Proxmox :

```bash
pvesm status
```

VM :

```bash
qm list
```

Conteneurs :

```bash
pct list
```

Services en erreur :

```bash
systemctl --failed
```

---

# 🟢 GUIDÉ — Partie 3 : comprendre le réseau actuel

Affichez :

```bash
ip -br link
ip -br address
ip route
```

Vous devez être capable d’identifier :

```text
interface NAT / Internet
interface LAB
interface OOB éventuelle
```

---

## Trouver la route par défaut

```bash
ip route | grep default
```

Exemple :

```text
default via 192.168.223.2 dev vmbr0
```

### Question

Pourquoi la route par défaut doit-elle, à ce stade, passer par le réseau :

```text
NAT / Internet
```

et non par le réseau LAB ?

---

# 🟢 GUIDÉ — Partie 4 : tester Internet et DNS

Test IP :

```bash
ping -c 3 1.1.1.1
```

Puis DNS :

```bash
ping -c 3 download.proxmox.com
```

Interprétation :

```text
1.1.1.1 OK
download.proxmox.com OK
→ Internet + DNS OK
```

```text
1.1.1.1 OK
download.proxmox.com KO
→ problème DNS probable
```

```text
1.1.1.1 KO
download.proxmox.com KO
→ problème réseau / route / NAT probable
```

---

# 🟢 GUIDÉ — Partie 5 : vérifier la nested virtualization

Proxmox est lui-même une VM VMware Workstation.

Il doit pourtant être capable d’exécuter des VM KVM.

Vérifiez :

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

Résultat attendu :

```text
> 0
```

Puis :

```bash
lsmod | grep kvm
```

Vous devriez voir quelque chose comme :

```text
kvm
kvm_intel
```

ou :

```text
kvm
kvm_amd
```

---

## Si le résultat vaut 0

Collectez :

```bash
dmesg | grep -i -E 'kvm|vmx|svm'
```

Puis vérifiez dans VMware Workstation :

```text
VM
→ Settings
→ Processors
→ Virtualize Intel VT-x/EPT or AMD-V/RVI
```

### Question

Pourquoi la nested virtualization est-elle indispensable dans notre LAB ?

---

# 🟢 GUIDÉ — Partie 6 : inspecter les services Proxmox

Listez les services :

```bash
systemctl --type=service |
grep -E 'pve|corosync'
```

Retrouvez au minimum :

```text
pveproxy
pvedaemon
pvestatd
pve-cluster
```

---

## `pveproxy`

Il fournit notamment l’accès HTTPS à l’interface web :

```text
https://<PVE>:8006
```

Vérifiez :

```bash
systemctl status pveproxy --no-pager
```

---

## `pvedaemon`

Service de gestion des tâches privilégiées exécutées par Proxmox.

```bash
systemctl status pvedaemon --no-pager
```

---

## `pvestatd`

Collecte périodiquement les informations d’état des ressources.

```bash
systemctl status pvestatd --no-pager
```

---

## `pve-cluster`

Gère notamment :

```text
pmxcfs
/etc/pve
```

Vérifiez :

```bash
systemctl status pve-cluster --no-pager
```

Puis :

```bash
mount | grep /etc/pve
```

### Important

Le service :

```text
pve-cluster
```

existe même avant la création d’un cluster multi-nœuds.

Son nom peut donc être trompeur.

---

# 🟢 GUIDÉ — Partie 7 : découvrir `/etc/pve`

Listez :

```bash
ls -la /etc/pve
```

Vous verrez notamment :

```text
storage.cfg
user.cfg
nodes/
```

Puis :

```bash
ls -la /etc/pve/nodes/
```

Vous devez retrouver votre nœud.

Exemple :

```text
pve01
```

### Question

Pourquoi `/etc/pve` est-il différent d’un répertoire classique ?

Cette notion sera approfondie au TP03 lorsque le cluster sera créé.

---

# 🟢 GUIDÉ — Partie 8 : vérifier les dépôts APT

Testez :

```bash
apt update
```

Si la commande fonctionne :

```text
Reading package lists... Done
```

continuez.

---

# ⚠️ Troubleshooting — `apt update` retourne `exit code 100`

Depuis l’interface Proxmox, vous pouvez voir :

```text
TASK ERROR: command 'apt-get update' failed: exit code 100
```

Ce message seul n’indique pas la vraie cause.

Relancez :

```bash
apt update
```

directement dans le terminal et lisez les lignes précédentes.

---

## Cas fréquent : dépôt Enterprise

Vous pouvez voir :

```text
401 Unauthorized
enterprise.proxmox.com
```

Cela signifie généralement que le dépôt :

```text
pve-enterprise
```

est actif alors que le nœud ne possède pas de souscription Enterprise.

Pour notre LAB, utilisez le dépôt :

```text
pve-no-subscription
```

---

## Inspecter les dépôts

```bash
ls -l /etc/apt/sources.list.d/
```

Puis :

```bash
grep -R "proxmox" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null
```

Sur Proxmox VE 9 / Debian 13, les dépôts utilisent généralement le format `.sources`.

---

## Désactiver Enterprise pour le LAB

Si présent :

```bash
mv /etc/apt/sources.list.d/pve-enterprise.sources \
   /etc/apt/sources.list.d/pve-enterprise.sources.disabled
```

Créez ou vérifiez :

```bash
nano /etc/apt/sources.list.d/proxmox.sources
```

avec :

```text
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
```

Puis :

```bash
apt update
```

---

## Vérifier aussi Ceph

Listez :

```bash
grep -R "enterprise.proxmox.com" \
  /etc/apt/sources.list \
  /etc/apt/sources.list.d/ 2>/dev/null
```

Si un dépôt Enterprise Ceph est actif alors que Ceph n’est pas utilisé dans le LAB, signalez-le au formateur.

Ne modifiez pas plusieurs dépôts au hasard.

---

# 🟢 GUIDÉ — Partie 9 : ne pas upgrader n’importe comment

Pendant le cours :

```bash
apt update
```

est demandé.

En revanche :

```bash
apt full-upgrade
```

ne doit être lancé que si le formateur le demande.

### Pourquoi ?

Nous voulons que les trois nœuds du groupe restent :

```text
sur des versions cohérentes
```

pendant les TP cluster.

---

# 🟢 GUIDÉ — Partie 10 : utiliser la CLI Proxmox

Sans utiliser l’interface graphique, retrouvez :

## Liste des nodes

```bash
pvesh get /nodes
```

## Stockages

```bash
pvesm status
```

## VM

```bash
qm list
```

## LXC

```bash
pct list
```

## Version

```bash
pveversion
```

---

# 🟢 GUIDÉ — Partie 11 : vérifier que le nœud est vide

Avant TP03 :

```bash
qm list
```

et :

```bash
pct list
```

ne doivent afficher aucun guest.

### Pourquoi ?

Nous allons bientôt joindre plusieurs nœuds au même cluster.

Le cours impose donc :

```text
cluster d'abord
workloads ensuite
```

---

# Questions obligatoires

## Question 1

Quelle est la différence entre :

```text
hostname
```

et :

```text
hostname -f
```

?

---

## Question 2

Pourquoi `/etc/hosts` est-il important dans un cluster Proxmox ?

---

## Question 3

Que représente :

```text
default via ...
```

dans :

```bash
ip route
```

?

---

## Question 4

Que signifie :

```text
vmx
```

ou :

```text
svm
```

dans `/proc/cpuinfo` ?

---

## Question 5

À quoi servent :

```text
pveproxy
pvedaemon
pvestatd
pve-cluster
```

?

---

## Question 6

Pourquoi l’erreur :

```text
apt-get update failed: exit code 100
```

ne suffit-elle pas pour diagnostiquer le problème ?

---

# 🟠 CHALLENGE — Inventaire sans GUI

Sans consulter l’interface web, produisez :

```text
Hostname
FQDN
Version PVE
Version Debian
CPU
RAM
Disques
Interfaces
IP
Route par défaut
Stockages
VM
LXC
Services en erreur
```

Toutes les informations doivent provenir du CLI.

---

# 🟠 CHALLENGE — vérifier le certificat Web

Affichez le certificat présenté sur le port Proxmox :

```bash
openssl s_client \
  -connect 127.0.0.1:8006 \
  -servername "$(hostname -f)" \
  </dev/null 2>/dev/null |
openssl x509 -noout -subject -issuer -dates -ext subjectAltName
```

### Question

Retrouvez-vous :

```text
hostname
FQDN
```

dans le certificat ?

Pourquoi cela pourrait-il devenir important lorsqu’un autre nœud tente de joindre le cluster ?

---

# 🔴 EXPERT — `inventory.sh`

Créez :

```text
inventory.sh
```

Le script doit afficher proprement :

```text
====================================
 NOVACORP PVE INVENTORY
====================================

Hostname :
FQDN :
PVE version :
Kernel :
CPU :
RAM :
Default route :
Interfaces :
Storage :
Nested virtualization :
Failed services :
```

Contraintes :

- Bash ;
- aucune valeur codée en dur ;
- script lisible ;
- sortie compréhensible ;
- code retour `0` si les contrôles essentiels sont corrects.

Exemple de lancement :

```bash
chmod +x inventory.sh
./inventory.sh
```

---

# Livrable

Complétez :

```text
deliverables/group-G/TP01.md
```

Le document doit contenir :

## 1. Identité

```text
Hostname :
FQDN :
IP management/NAT :
```

## 2. Inventaire

```text
PVE :
Kernel :
CPU :
RAM :
Disques :
Stockages :
```

## 3. Réseau

```text
Route par défaut :
NIC Internet :
NIC LAB :
```

## 4. Services

Expliquez le rôle de deux services Proxmox.

## 5. Validation

Collez la sortie de :

```bash
sudo ./scripts/proxmox/check-tp01.sh
```

---

# Validation TP01

Avant validation :

```bash
hostname
hostname -f
ip -br a
ip route
pveversion
pvesm status
qm list
pct list
```

Le nœud doit :

```text
avoir un hostname/FQDN cohérent
avoir Internet
avoir DNS
voir VMX/SVM
avoir KVM chargé
avoir les services PVE actifs
ne contenir aucune VM
ne contenir aucun LXC
```

Lancez :

```bash
sudo ./scripts/proxmox/check-tp01.sh
```

Résultat attendu :

```text
[PASS] Proxmox VE detected
[PASS] Hostname configured
[PASS] FQDN resolves
[PASS] Default route detected
[PASS] Internet connectivity
[PASS] DNS resolution
[PASS] Nested virtualization flag visible
[PASS] KVM module loaded
[PASS] Proxmox storage subsystem responds
[PASS] No VM exists
[PASS] No LXC exists

STATUS: READY FOR TP02
```

---

# Ce qu’il faut retenir

À la fin du TP01, vous devez être capable de regarder un nœud Proxmox inconnu et de répondre rapidement :

```text
Qui suis-je ?
Quelle version tourne ?
Quels CPU/RAM/disques ?
Quelles interfaces ?
Quelle route Internet ?
Quels stockages ?
La nested virtualization fonctionne-t-elle ?
Les services PVE fonctionnent-ils ?
Les dépôts APT fonctionnent-ils ?
Le nœud est-il prêt à rejoindre le futur cluster ?
```

Le TP02 utilisera ensuite ce nœud pour construire le réseau LAB inter-PVE.
