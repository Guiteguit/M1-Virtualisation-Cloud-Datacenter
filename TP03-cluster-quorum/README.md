# TP03 — Cluster Proxmox, Corosync, quorum & QDevice

**Durée cible : ~1 h 15 à 1 h 30**

## Contexte

Les nœuds Proxmox NovaCorp disposent maintenant :

- d’un accès Internet ;
- d’un réseau LAB inter-PVE fonctionnel ;
- d’une résolution de noms cohérente ;
- d’aucune VM ni conteneur persistant.

Votre mission consiste à les assembler en un **cluster Proxmox** et à comprendre réellement :

- ce qu’est Corosync ;
- ce qu’est `pmxcfs` ;
- comment fonctionne le quorum ;
- pourquoi un cluster 2 nœuds est particulier ;
- à quoi sert un QDevice ;
- ce qu’il se passe lorsqu’un nœud disparaît réellement.

> ⚠️ Ce TP touche au cœur du cluster.
> Ne lancez jamais une commande de contournement du quorum sans comprendre exactement ses conséquences.

---

# Architecture cible

## Groupe de 3

```text
                 CLUSTER NOVACORP

                     PVE01
                    /     \
                   /       \
               PVE02 ----- PVE03

                  3 votes
                quorum = 2
```

---

## Groupe de 2

```text
                 CLUSTER NOVACORP

               PVE01 ----- PVE02
                  \         /
                   \       /
                    QDEVICE

                  3 votes
                quorum = 2
```

Le QDevice n’héberge aucune VM.

Il fournit un vote externe permettant de départager les deux nœuds.

---

# Rappels importants

Proxmox utilise notamment :

```text
Corosync
```

pour la communication cluster.

Et :

```text
pmxcfs
```

pour distribuer la configuration présente sous :

```text
/etc/pve
```

Les nœuds d’un cluster doivent pouvoir communiquer entre eux correctement ; Proxmox exige notamment la synchronisation de l’heure, SSH entre nœuds et les ports UDP utilisés par Corosync. La documentation Proxmox indique les ports UDP `5405-5412` pour Corosync et TCP `22` pour SSH. 

---

# 🟢 GUIDÉ — Partie 1 : pré-check — aucun guest

Sur **chaque nœud** :

```bash
qm list
```

Puis :

```bash
pct list
```

Résultat attendu :

```text
aucune VM
aucun conteneur
```

### Pourquoi ?

Lorsqu’un nœud rejoint un cluster, sa configuration cluster locale est remplacée par celle du cluster.

Dans notre cours :

```text
CLUSTER D'ABORD
WORKLOADS ENSUITE
```

Si vous avez déjà créé des VM/LXC persistants, **arrêtez et prévenez le formateur**.

---

# 🟢 GUIDÉ — Partie 2 : vérifier les versions

Sur chaque nœud :

```bash
pveversion
```

Puis :

```bash
pveversion -v
```

Les nœuds doivent utiliser des versions cohérentes.

La documentation Proxmox recommande que les nœuds d’un cluster utilisent la même version.

---

# 🟢 GUIDÉ — Partie 3 : vérifier l’heure

Sur chaque nœud :

```bash
timedatectl
```

Vérifiez :

```text
System clock synchronized: yes
```

Puis :

```bash
date
```

Comparez les trois nœuds.

### Question

Pourquoi une forte dérive d’horloge est-elle problématique dans un système distribué ?

---

# 🟢 GUIDÉ — Partie 4 : vérifier l’identité de chaque nœud

Sur PVE01 :

```bash
hostname
hostname -f
```

Exemple :

```text
pve01
pve01.novacorp.lab
```

Même logique :

```text
pve02.novacorp.lab
pve03.novacorp.lab
```

---

# 🟢 GUIDÉ — Partie 5 : vérifier `/etc/hosts`

Sur **chaque PVE**, les nœuds du groupe doivent être résolus.

## Exemple recette locale

```text
192.168.56.11 pve01.novacorp.lab pve01
192.168.56.12 pve02.novacorp.lab pve02
192.168.56.13 pve03.novacorp.lab pve03
```

## Exemple cours groupe 3

```text
10.100.3.11 pve01.novacorp.lab pve01
10.100.3.12 pve02.novacorp.lab pve02
10.100.3.13 pve03.novacorp.lab pve03
```

Testez :

```bash
getent hosts pve01.novacorp.lab
getent hosts pve02.novacorp.lab
getent hosts pve03.novacorp.lab
```

Puis :

```bash
ping -c 2 pve02.novacorp.lab
```

---

# 🟢 GUIDÉ — Partie 6 : vérifier le réseau cluster

Sur PVE01 :

```bash
ping -c 3 <IP-PVE02-LAB>
```

Puis :

```bash
ping -c 3 <IP-PVE03-LAB>
```

Sur PVE02 :

```bash
ping -c 3 <IP-PVE01-LAB>
```

---

## Vérifier SSH

Depuis PVE02 :

```bash
ssh root@pve01.novacorp.lab
```

Vous devez au minimum atteindre le service SSH.

Quittez :

```bash
exit
```

---

## Vérifier l’API Proxmox

Depuis PVE02 :

```bash
curl -k https://pve01.novacorp.lab:8006/api2/json/version
```

Vous devez obtenir une réponse JSON.

---

# 🟢 GUIDÉ — Partie 7 : vérifier le certificat avant le cluster

Sur PVE01 :

```bash
openssl s_client \
  -connect pve01.novacorp.lab:8006 \
  -servername pve01.novacorp.lab \
  </dev/null 2>/dev/null |
openssl x509 \
  -noout \
  -subject \
  -issuer \
  -ext subjectAltName
```

Vérifiez que le certificat correspond bien à l’identité du nœud.

### Pourquoi faisons-nous ce test ?

Lors de :

```bash
pvecm add
```

Proxmox contacte l’API HTTPS du nœud existant.

Une incohérence entre :

```text
IP utilisée
hostname
FQDN
certificat
```

peut produire :

```text
500 Can't connect to ...:8006
(hostname verification failed)
```

---

# 🟢 GUIDÉ — Partie 8 : choisir les adresses Corosync

Corosync utilisera notre réseau :

```text
vmbr1 / LAB
```

Exemple groupe 3 :

```text
PVE01 -> 10.100.3.11
PVE02 -> 10.100.3.12
PVE03 -> 10.100.3.13
```

Recette locale :

```text
PVE01 -> 192.168.56.11
PVE02 -> 192.168.56.12
PVE03 -> 192.168.56.13
```

Notez les trois adresses avant de continuer.

---

# 🟢 GUIDÉ — Partie 9 : créer le cluster sur PVE01

Cette commande est exécutée **uniquement sur PVE01**.

Exemple groupe 3 :

```bash
pvecm create novacorp-g03 \
  --link0 10.100.3.11
```

Recette locale :

```bash
pvecm create novacorp-g01 \
  --link0 192.168.56.11
```

Vérifiez :

```bash
pvecm status
```

Vous devriez avoir pour le moment :

```text
Nodes: 1
Quorate: Yes
```

---

# Pourquoi un cluster à un seul nœud est-il quorate ?

Avec :

```text
1 vote total
```

la majorité est :

```text
1
```

Il dispose donc de la majorité de ses votes.

---

# 🟢 GUIDÉ — Partie 10 : inspecter Corosync

```bash
cat /etc/pve/corosync.conf
```

Vous devez retrouver :

```text
cluster_name
nodelist
link0_addr
```

Puis :

```bash
corosync-cfgtool -s
```

et :

```bash
systemctl status corosync --no-pager
```

---

# 🟢 GUIDÉ — Partie 11 : ajouter PVE02

Sur PVE02 :

```bash
pvecm add pve01.novacorp.lab \
  --link0 <IP-PVE02-LAB>
```

Exemple recette locale :

```bash
pvecm add pve01.novacorp.lab \
  --link0 192.168.56.12
```

Entrez le mot de passe `root` de PVE01 lorsque demandé.

Acceptez le fingerprint **uniquement après avoir vérifié que vous contactez bien PVE01**.

---

# Pourquoi utiliser le FQDN ici ?

Nous préférons :

```bash
pvecm add pve01.novacorp.lab
```

à :

```bash
pvecm add 192.168.56.11
```

car l’identité utilisée pour joindre l’API doit être cohérente avec le certificat présenté.

Cela évite notamment certains cas de :

```text
hostname verification failed
```

---

# 🟢 GUIDÉ — Partie 12 : vérifier après ajout de PVE02

Sur PVE01 ou PVE02 :

```bash
pvecm status
```

Puis :

```bash
pvecm nodes
```

Vous devez maintenant voir :

```text
PVE01
PVE02
```

---

# 🟢 GUIDÉ — Partie 13 : vérifier `/etc/pve`

Sur PVE01 :

```bash
echo "NovaCorp TP03" > /etc/pve/tp03-note.txt
```

Sur PVE02 :

```bash
cat /etc/pve/tp03-note.txt
```

Résultat :

```text
NovaCorp TP03
```

### Que vient-on de démontrer ?

Le fichier écrit dans :

```text
/etc/pve
```

sur PVE01 est visible sur PVE02 grâce à :

```text
pmxcfs + Corosync
```

---

# 🟢 GUIDÉ — Partie 14 : inspecter pmxcfs

```bash
mount | grep /etc/pve
```

Puis :

```bash
ps aux | grep '[p]mxcfs'
```

Et :

```bash
ls -la /etc/pve/nodes/
```

Vous devez maintenant retrouver plusieurs dossiers :

```text
pve01
pve02
```

---

# 🟢 GUIDÉ — Partie 15 : groupe de 3 — ajouter PVE03

Sur PVE03 :

```bash
pvecm add pve01.novacorp.lab \
  --link0 <IP-PVE03-LAB>
```

Exemple recette locale :

```bash
pvecm add pve01.novacorp.lab \
  --link0 192.168.56.13
```

Puis :

```bash
pvecm status
```

---

# État attendu — groupe de 3

```text
Expected votes: 3
Total votes:    3
Quorum:         2
Quorate:        Yes
```

Et :

```bash
pvecm nodes
```

doit afficher :

```text
pve01
pve02
pve03
```

---

# 🟢 GUIDÉ — Partie 16 : comprendre le quorum

Dans un cluster 3 nœuds :

```text
PVE01 = 1 vote
PVE02 = 1 vote
PVE03 = 1 vote

TOTAL = 3
```

Pour obtenir la majorité :

```text
quorum = 2
```

Donc :

```text
3/3 -> QUORATE
2/3 -> QUORATE
1/3 -> NO QUORUM
```

Le quorum protège contre la situation où plusieurs parties isolées du cluster modifieraient simultanément l’état partagé.

---

# 🟢 GUIDÉ — Partie 17 : vraie perte de PVE03

## Recette VMware

Sur le PC hébergeant PVE03 :

```text
VMware Workstation
→ PVE03
→ Power Off
```

N’utilisez pas :

```bash
shutdown
```

dans PVE03.

Nous voulons simuler une disparition brutale.

---

## Groupe de 3

Sur PVE01 :

```bash
watch -n 1 pvecm status
```

Dans un autre terminal :

```bash
journalctl -fu corosync
```

Coupez PVE03.

Observez.

---

# Résultat attendu

Vous devriez passer de :

```text
3 votes
```

à :

```text
2 votes disponibles
```

mais conserver :

```text
Quorate: Yes
```

---

# 🟢 GUIDÉ — Partie 18 : vérifier pmxcfs pendant la panne

Pendant que PVE03 est arrêté :

```bash
touch /etc/pve/quorum-test
```

Puis :

```bash
ls -l /etc/pve/quorum-test
```

Avec PVE01 + PVE02 :

```text
2/3 votes
```

le cluster possède encore le quorum.

Les écritures restent possibles.

---

# 🟢 GUIDÉ — Partie 19 : remettre PVE03

Redémarrez PVE03.

Sur PVE01 :

```bash
watch -n 1 pvecm status
```

Puis :

```bash
pvecm nodes
```

Attendez le retour des trois membres.

---

# 🟢 GUIDÉ — Partie 20 : cas d’un groupe de 2

Avec seulement :

```text
PVE01
PVE02
```

nous avons :

```text
2 votes
```

Majorité nécessaire :

```text
2
```

Si un membre disparaît :

```text
1/2
```

le nœud restant ne possède plus la majorité.

---

# 🟢 GUIDÉ — Partie 21 : observer un cluster 2 nœuds sans QDevice

Avant QDevice :

```bash
pvecm status
```

Arrêtez PVE02 après validation du formateur.

Sur PVE01 :

```bash
pvecm status
```

Puis essayez :

```bash
touch /etc/pve/no-quorum-test
```

L’opération doit révéler le comportement en absence de quorum.

### Important

Le but n’est pas de contourner le problème.

Le but est de comprendre **pourquoi** le cluster se protège.

Redémarrez PVE02 avant de continuer.

---

# 🟢 GUIDÉ — Partie 22 : installer le support QDevice

Pour un cluster **2 nœuds uniquement**.

Sur PVE01 **et** PVE02 :

```bash
apt update
apt install -y corosync-qdevice
```

Le serveur QNetd externe est fourni par le formateur.

Il héberge :

```text
corosync-qnetd
```

Proxmox recommande le QDevice pour les clusters comportant un nombre pair de nœuds, notamment un cluster à 2 nœuds qui doit offrir davantage de disponibilité. 

---

# 🟢 GUIDÉ — Partie 23 : vérifier le QNetd

Le formateur fournit :

```text
QNETD IP/FQDN : __________________
```

Depuis PVE01 :

```bash
ping -c 2 <QNETD>
```

Puis :

```bash
ssh root@<QNETD>
```

si demandé par la procédure du LAB.

Quittez :

```bash
exit
```

---

# 🟢 GUIDÉ — Partie 24 : configurer le QDevice

Tous les nœuds du cluster doivent être en ligne.

Depuis **un seul PVE** :

```bash
pvecm qdevice setup <QNETD-IP>
```

La commande configure le QDevice pour le cluster.

La procédure Proxmox s’appuie sur `corosync-qnetd` côté serveur externe et `corosync-qdevice` sur les nœuds PVE. 

---

# 🟢 GUIDÉ — Partie 25 : vérifier le QDevice

```bash
pvecm status
```

Vous devez retrouver quelque chose indiquant :

```text
Expected votes: 3
Total votes:    3
Quorum:         2
Flags:          Quorate Qdevice
```

Le principe devient :

```text
PVE01   = 1 vote
PVE02   = 1 vote
QDevice = 1 vote
```

---

# 🟢 GUIDÉ — Partie 26 : retester une panne à 2 nœuds

Après validation du formateur :

```text
PVE01 + PVE02 + QDevice
```

Coupez PVE02.

Sur PVE01 :

```bash
pvecm status
```

Le nœud restant peut conserver le quorum grâce au vote externe du QDevice.

---

# Pourquoi le QDevice doit-il être externe ?

Mauvaise architecture :

```text
PC ETU1
├── PVE01
└── QDevice
```

Si PC ETU1 tombe :

```text
PVE01 perdu
+
QDevice perdu
```

Le témoin doit donc être placé dans un **domaine de panne différent**.

---

# ⚠️ TROUBLESHOOTING — `hostname verification failed`

Symptôme possible :

```text
500 Can't connect to <IP>:8006
(hostname verification failed)
```

Vérifiez sur PVE01 :

```bash
hostname
hostname -f
```

Puis sur PVE02 :

```bash
getent hosts pve01.novacorp.lab
```

Vérifiez ensuite le certificat :

```bash
openssl s_client \
  -connect pve01.novacorp.lab:8006 \
  -servername pve01.novacorp.lab \
  </dev/null 2>/dev/null |
openssl x509 -noout -subject -ext subjectAltName
```

Puis utilisez :

```bash
pvecm add pve01.novacorp.lab \
  --link0 <IP-PVE02-LAB>
```

plutôt que l’adresse IP brute.

### Règle

Ne contournez pas une erreur de certificat sans avoir d’abord compris :

```text
quel nœud vous contactez
quelle identité présente le certificat
quelle résolution de nom est utilisée
```

---

# ⚠️ TROUBLESHOOTING — PVE02 ne rejoint pas le cluster

Contrôlez dans cet ordre :

```bash
ping <IP-PVE01-LAB>
```

```bash
getent hosts pve01.novacorp.lab
```

```bash
ssh root@pve01.novacorp.lab
```

```bash
curl -k https://pve01.novacorp.lab:8006/api2/json/version
```

Puis :

```bash
journalctl -u corosync --since "-10 min"
```

---

# ⚠️ TROUBLESHOOTING — les nœuds sont visibles mais Corosync est instable

Vérifiez :

```bash
corosync-cfgtool -s
```

Puis :

```bash
journalctl -u corosync
```

Et :

```bash
ping <PAIR-LAB>
```

En salle :

```text
câble
switch
VLAN groupe
NIC VMware bridgée
```

En recette locale :

```text
toutes les NIC LAB sur le même VMnet Host-Only
```

---

# ⚠️ TROUBLESHOOTING — `/etc/pve` devient read-only

Commencez par :

```bash
pvecm status
```

Si :

```text
Quorate: No
```

alors le comportement est volontaire.

`pmxcfs` protège la configuration partagée contre les écritures lorsqu’il n’existe plus de majorité.

---

# ⚠️ TROUBLESHOOTING — `Host key verification failed` pendant QDevice

Commencez par vérifier :

```bash
ssh root@<QNETD>
```

et la résolution/clé SSH du serveur externe.

La documentation Proxmox indique également qu’un :

```bash
pvecm updatecerts
```

peut corriger certains cas de clés/certificats devenus incohérents.

N’exécutez cependant pas cette commande au hasard : vérifiez d’abord l’identité des machines.

---

# 🟠 CHALLENGE — trouver précisément la disparition d’un peer

Avant de couper un nœud :

```bash
journalctl -fu corosync
```

et :

```bash
corosync-cfgtool -s
```

Coupez PVE03.

Identifiez :

```text
heure de disparition
peer concerné
état du lien
état du quorum
```

Produisez une mini timeline :

```text
T0 : PVE03 coupé
T1 : événement Corosync
T2 : membership mis à jour
T3 : quorum recalculé
```

---

# 🟠 CHALLENGE — vérifier les ports

Proxmox requiert entre les nœuds notamment :

```text
UDP 5405-5412 : Corosync
TCP 22        : SSH
```

À l’aide de :

```bash
ss -lunp
ss -lntp
```

retrouvez les services concernés.

Puis expliquez pourquoi :

```text
ping OK
```

ne suffit pas à prouver que :

```text
cluster OK
```

.

---

# 🟠 CHALLENGE — casser uniquement Corosync

Le formateur peut provoquer une situation où :

```text
Internet = OK
SSH      = OK
GUI      = OK
Corosync = KO
```

Votre mission :

```text
identifier que le problème ne concerne pas toute la connectivité
```

mais spécifiquement le chemin/service Corosync.

Outils :

```bash
pvecm status
corosync-cfgtool -s
journalctl -u corosync
ss -lunp
tcpdump
```

---

# 🔴 EXPERT — pourquoi `pvecm expected 1` n’est pas une solution normale

Vous pouvez rencontrer :

```bash
pvecm expected 1
```

Cette commande modifie temporairement le nombre de votes attendus.

Elle peut permettre certaines opérations d’urgence.

Mais si vous l’utilisez simplement pour :

> « faire disparaître l’erreur de quorum »

vous supprimez précisément la protection que le quorum devait fournir.

---

# Scénario dangereux

Imaginez :

```text
PVE01 --------X-------- PVE02
```

Les deux nœuds sont toujours actifs mais ne se voient plus.

Si chacun décide :

```text
je suis le cluster
```

vous pouvez arriver à :

```text
deux modifications concurrentes
deux copies divergentes
double démarrage d’un workload
corruption
split-brain
```

Le quorum existe précisément pour éviter cette situation.

---

# 🔴 EXPERT — second lien Corosync

Proposez une architecture :

```text
PVE01 ================= PVE02
  |                       |
  | link0                 | link0
  |                       |
Switch A                Switch A

  |                       |
  | link1                 | link1
  |                       |
Switch B                Switch B
```

Questions :

1. Pourquoi deux liens Corosync peuvent-ils être utiles ?
2. Pourquoi les deux liens ne devraient-ils pas partager exactement le même domaine de panne ?
3. Un second lien connecté au même switch apporte-t-il la même résilience ?

---

# 🔴 EXPERT — pourquoi Corosync aime un réseau stable

Comparez :

```text
Corosync
→ messages courts
→ besoin de latence stable
```

avec :

```text
Migration VM
→ gros débit
→ copie RAM/disques
```

Question :

> Pourquoi saturer le réseau Corosync avec une migration peut-il être problématique ?

Cette réflexion prépare le TP06.

---

# Questions obligatoires

## Question 1

Quelle est la différence entre :

```text
Corosync
```

et :

```text
pmxcfs
```

?

---

## Question 2

Dans un cluster de 3 nœuds :

```text
combien de nœuds peuvent disparaître
sans perdre le quorum ?
```

---

## Question 3

Pourquoi un cluster de 2 nœuds sans QDevice pose-t-il problème lorsqu’un nœud disparaît ?

---

## Question 4

Le QDevice héberge-t-il les VM ?

---

## Question 5

Pourquoi le QDevice doit-il être indépendant des deux PVE ?

---

## Question 6

Pourquoi :

```text
ping OK
```

ne garantit-il pas que :

```text
Corosync fonctionne
```

?

---

## Question 7

Pourquoi le cluster refuse-t-il certaines écritures lorsqu’il n’a plus le quorum ?

---

# Livrable

Complétez :

```text
deliverables/group-G/TP03.md
```

avec :

## 1. Cluster

```text
Cluster name :
PVE01 :
PVE02 :
PVE03 :
```

ou :

```text
PVE01 :
PVE02 :
QDevice :
```

---

## 2. État nominal

Copiez :

```bash
pvecm status
```

et :

```bash
pvecm nodes
```

---

## 3. Corosync

Copiez les parties pertinentes de :

```bash
cat /etc/pve/corosync.conf
```

---

## 4. Test pmxcfs

Décrivez le test :

```text
PVE01 écrit un fichier dans /etc/pve
PVE02 le lit
```

et expliquez ce que cela prouve.

---

## 5. Incident

Décrivez :

```text
nœud coupé
votes avant
votes après
quorum avant
quorum après
écriture /etc/pve possible ?
```

---

## 6. Groupe de 2 uniquement

Ajoutez :

```text
QDevice IP/FQDN
Expected votes
Total votes
Quorum
Flags
```

---

# Validation TP03

## Groupe de 3

```bash
sudo ./scripts/proxmox/check-tp03.sh G 3
```

Exemple :

```bash
sudo ./scripts/proxmox/check-tp03.sh 3 3
```

---

## Groupe de 2

```bash
sudo ./scripts/proxmox/check-tp03.sh G 2
```

Le script vérifiera alors également la présence d’un QDevice.

---

# Résultat attendu — groupe de 3

```text
[PASS] Cluster detected
[PASS] Cluster name is novacorp-g03
[PASS] Cluster is quorate
[PASS] 3 cluster nodes detected
[PASS] Corosync configuration exists
[PASS] Corosync service active
[PASS] pmxcfs mounted on /etc/pve

STATUS: READY FOR TP04
```

---

# Résultat attendu — groupe de 2

```text
[PASS] Cluster detected
[PASS] Cluster is quorate
[PASS] 2 PVE nodes detected
[PASS] QDevice detected
[PASS] Expected votes >= 3
[PASS] Corosync configuration exists

STATUS: READY FOR TP04
```

---

# Ce qu’il faut retenir

```text
COROSYNC
    │
    └── communication / membership cluster

PMXCFS
    │
    └── configuration distribuée sous /etc/pve

QUORUM
    │
    └── majorité permettant de modifier l’état partagé

QDEVICE
    │
    └── vote externe pour certains clusters pairs
```

Et surtout :

```text
Perdre un nœud
≠
perdre automatiquement le cluster
```

Ce qui compte est :

```text
combien de votes sont encore disponibles
par rapport au quorum requis
```

Le TP04 utilisera ensuite ce cluster pour ajouter un stockage ZFS local cohérent sur chaque nœud.
