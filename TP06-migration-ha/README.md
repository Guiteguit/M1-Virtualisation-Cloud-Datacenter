# TP06 — Migration, réplication ZFS & haute disponibilité

**Durée cible : 1 h 15 à 1 h 30**

## Contexte

NovaCorp dispose maintenant :

- d’un cluster Proxmox fonctionnel ;
- d’un stockage local ZFS nommé `zfs-lab` sur chaque nœud ;
- d’une VM `web01` créée depuis un template Cloud-Init.

L’objectif est maintenant de comprendre ce qu’il se passe lorsqu’un workload doit :

1. changer de nœud ;
2. rester disponible pendant une maintenance ;
3. disposer d’une copie de ses données sur un autre nœud ;
4. redémarrer automatiquement après la perte de son hyperviseur.

Votre mission consiste à :

- réaliser une **migration offline** ;
- réaliser une **live migration** ;
- observer le trafic réseau généré ;
- configurer une **réplication ZFS** ;
- comprendre son caractère **asynchrone** ;
- intégrer `web01` au mécanisme **HA** ;
- provoquer une panne contrôlée ;
- mesurer le **RTO** ;
- estimer le **RPO**.

> ⚠️ Le test de panne réelle d’un nœud ne doit être réalisé qu’après validation du formateur.

---

# Architecture du TP

```text
                   CLUSTER PROXMOX

        PVE01                       PVE02
   10.100.G.11                 10.100.G.12
        │                            │
        │        vmbr1 / LAB         │
        └────────────┬───────────────┘
                     │
             Switch / VMnet LAB
```

Chaque nœud possède son propre stockage local :

```text
PVE01                           PVE02
  │                               │
tank/vmdata                   tank/vmdata
  │                               │
zfs-lab                         zfs-lab
```

Attention :

```text
même Storage ID
≠
même stockage physique
```

`zfs-lab` reste **local** à chaque nœud.

---

# 🟢 GUIDÉ — Partie 1 : pré-check cluster

Avant toute migration :

```bash
pvecm status
```

Vous devez avoir :

```text
Quorate: Yes
```

Vérifiez les nœuds :

```bash
pvecm nodes
```

Puis le stockage :

```bash
pvesm status
```

Sur PVE01 et PVE02, `zfs-lab` doit être :

```text
active
```

Vérifiez enfin la VM :

```bash
qm config 111
```

Vous devez retrouver :

```text
name: web01
```

ainsi qu’un disque situé sur :

```text
zfs-lab
```

---

# 🟢 GUIDÉ — Partie 2 : préparer le réseau de web01

Dans le TP05, `web01` pouvait être connectée à `vmbr10`.

Mais `vmbr10` est un bridge **local à chaque hyperviseur**.

Pour observer correctement une migration entre PVE01 et PVE02, la VM doit utiliser un réseau présent sur les deux nœuds.

Dans notre LAB, nous allons temporairement utiliser :

```text
vmbr1
```

qui représente le réseau LAB inter-PVE.

> ⚠️ En production, mélanger trafic VM, Corosync et migration sur le même réseau n’est pas une bonne architecture.
> Ici, c’est volontaire pour tenir avec le matériel du LAB.

Dans la GUI :

```text
web01
→ Hardware
→ Network Device
→ Bridge : vmbr1
```

Configurez ensuite une IP adaptée au réseau du groupe.

Exemple groupe `G` :

```text
PVE01 : 10.100.G.11
PVE02 : 10.100.G.12
PVE03 : 10.100.G.13

web01 : 10.100.G.51/24
```

Aucune gateway n’est nécessaire pour les tests du LAB.

Si vous utilisez Cloud-Init :

```bash
qm set 111 --ipconfig0 ip=10.100.G.51/24
qm cloudinit update 111
```

Adaptez `G` à votre groupe.

### Cas recette locale VMware Workstation

Si vous testez le LAB sur un seul PC avec un VMnet Host-Only, utilisez votre réseau réel.

Exemple :

```text
PVE01 : 192.168.56.11
PVE02 : 192.168.56.12
PVE03 : 192.168.56.13

web01 : 192.168.56.51/24
```

---

# 🟢 GUIDÉ — Partie 3 : vérifier web01 avant migration

Démarrez :

```bash
qm start 111
```

Vérifiez :

```bash
qm status 111
```

Depuis un poste ou un nœud ayant accès au réseau LAB :

```bash
ping <IP-web01>
```

Le ping doit répondre avant de continuer.

Dans la VM :

```bash
hostname
ip -br a
```

Résultat attendu :

```text
hostname = web01
IP       = adresse configurée
```

---

# 🟢 GUIDÉ — Partie 4 : migration OFFLINE

Une migration offline signifie :

```text
VM arrêtée
    │
    ▼
copie du stockage
    │
    ▼
déplacement de la configuration
    │
    ▼
VM disponible sur le nœud cible
```

Arrêtez proprement `web01` :

```bash
qm shutdown 111
```

Vérifiez :

```bash
qm status 111
```

Résultat :

```text
status: stopped
```

---

## Méthode GUI

Dans Proxmox :

```text
web01
→ Migrate
→ Target Node : PVE02
→ Target Storage : zfs-lab
→ Migrate
```

Comme le disque est sur un stockage local, Proxmox doit **copier le disque** vers le `zfs-lab` de PVE02.

---

## Vérification

Après migration :

```bash
qm list
```

sur PVE02.

Vous devez retrouver :

```text
111 web01
```

Vérifiez également :

```bash
qm config 111
```

Puis :

```bash
zfs list | grep 111
```

Le volume doit maintenant exister sur le ZFS local du nœud cible.

---

# Question

Pourquoi la migration a-t-elle dû transférer le disque ?

Parce que :

```text
PVE01 zfs-lab
```

et :

```text
PVE02 zfs-lab
```

ont le même **nom logique dans Proxmox**, mais sont deux stockages physiques différents.

---

# 🟢 GUIDÉ — Partie 5 : revenir sur PVE01

Migrez `web01` vers PVE01.

Vous pouvez cette fois utiliser le CLI.

Exemple :

```bash
qm migrate 111 pve01 --targetstorage zfs-lab
```

La VM étant arrêtée, il s’agit d’une migration offline.

Vérifiez ensuite sa présence sur PVE01.

---

# 🟢 GUIDÉ — Partie 6 : préparer l’observation d’une live migration

Démarrez `web01` :

```bash
qm start 111
```

Dans un autre terminal :

```bash
ping <IP-web01>
```

Laissez ce ping actif.

Sur PVE01, ouvrez également :

```bash
tcpdump -ni vmbr1 host 10.100.G.12
```

ou adaptez l’adresse au nœud cible.

Vous pouvez aussi utiliser :

```bash
iftop -i vmbr1
```

si `iftop` est installé.

Objectif :

```text
observer le trafic réseau généré
pendant la migration
```

---

# 🟢 GUIDÉ — Partie 7 : live migration avec disque local

Une live migration d’une VM active doit transférer :

```text
état CPU
RAM
périphériques virtuels
ET
disque local
```

Dans notre cas, le disque est local sur ZFS.

Lancez depuis PVE01 :

```bash
qm migrate 111 pve02 \
  --online 1 \
  --with-local-disks 1 \
  --targetstorage zfs-lab
```

Pendant l’opération :

```text
ne stoppez pas le ping
ne fermez pas tcpdump
```

Observez :

- volume de trafic ;
- durée ;
- pertes ICMP ;
- moment du basculement.

Proxmox supporte la live migration avec stockage local via l’option `--with-local-disks`. Le disque doit alors être transféré vers le stockage cible. citeturn924221search0turn924221search1

---

# 🟢 GUIDÉ — Partie 8 : mesurer la migration

Notez :

```text
Heure début :
Heure fin :

Durée totale :
Nombre approximatif de ping perdus :
```

Vérifiez ensuite :

```bash
qm status 111
```

sur PVE02.

Puis dans la VM :

```bash
hostname
ip -br a
uptime
```

### Question

`uptime` a-t-il été remis à zéro ?

Si non, pourquoi est-ce important pour parler de **live migration** ?

---

# 🟢 GUIDÉ — Partie 9 : comprendre le rôle du réseau de migration

Dans notre LAB, migration et cluster utilisent :

```text
vmbr1
```

Mais Proxmox permet de définir un réseau spécifique de migration.

Exemple conceptuel :

```text
Corosync
10.10.10.0/24

Migration
10.10.20.0/24
```

Cela évite :

```text
grosse copie disque
        ↓
saturation réseau
        ↓
latence Corosync
        ↓
risque pour la stabilité cluster
```

Proxmox recommande de pouvoir utiliser un réseau dédié à la migration lorsque c’est pertinent, car le trafic de migration peut perturber le trafic cluster. citeturn379495search18

---

# 🟢 GUIDÉ — Partie 10 : comprendre la réplication ZFS

Actuellement :

```text
PVE01
web01 + disque complet
```

Si PVE01 tombe brutalement, PVE02 ne dispose pas forcément d’une copie récente du disque.

La réplication Proxmox va créer :

```text
PVE01
   │
   │ snapshots ZFS + deltas
   ▼
PVE02
```

Après la première réplication complète, seules les différences doivent être transférées.

Proxmox utilise la réplication de stockage pour apporter de la redondance aux workloads placés sur du ZFS local et pour réduire le volume à transférer lors de migrations futures. citeturn773761search4

---

# 🟢 GUIDÉ — Partie 11 : remettre web01 sur PVE01

Pour simplifier la suite, assurez-vous que :

```text
web01
```

est hébergée sur :

```text
PVE01
```

Si nécessaire :

```bash
qm migrate 111 pve01 \
  --online 1 \
  --with-local-disks 1 \
  --targetstorage zfs-lab
```

---

# 🟢 GUIDÉ — Partie 12 : créer un job de réplication

Destination :

```text
PVE02
```

Depuis PVE01 :

```bash
pvesr create-local-job 111-0 pve02 \
  --schedule "*/5"
```

Ce job signifie :

```text
VMID      : 111
Job       : 0
Target    : pve02
Schedule  : toutes les 5 minutes
```

Vérifiez :

```bash
pvesr status
```

Vous devez retrouver le job de réplication.

---

# 🟢 GUIDÉ — Partie 13 : observer la première réplication

La première synchronisation doit transférer une copie initiale importante.

Sur PVE01 :

```bash
pvesr status
```

Sur PVE02 :

```bash
zfs list | grep 111
```

Après succès, vous devez retrouver une copie ZFS liée à la VM.

### À comprendre

Première réplication :

```text
FULL
```

Réplications suivantes :

```text
snapshots
+
deltas
```

Cela réduit fortement le trafic si peu de données ont changé.

---

# 🟢 GUIDÉ — Partie 14 : créer des changements dans web01

Dans `web01` :

```bash
dd if=/dev/urandom \
  of=/tmp/tp06-change.bin \
  bs=1M count=50
```

Puis :

```bash
sync
```

Attendez la réplication suivante.

Sur PVE01 :

```bash
pvesr status
```

Comparez :

```text
première réplication
vs
réplication incrémentale
```

---

# 🟢 GUIDÉ — Partie 15 : RPO de la réplication

Notre job s’exécute :

```text
toutes les 5 minutes
```

Imaginez :

```text
10:00 réplication OK
10:04 écriture importante
10:04:30 crash PVE01
```

La copie sur PVE02 peut ne pas contenir l’écriture de :

```text
10:04
```

C’est le principe d’une réplication :

```text
ASYNCHRONE
```

Le RPO maximal théorique dépend donc notamment de l’intervalle entre réplications et de la réussite du dernier job.

Proxmox permet HA + réplication ZFS, mais précise qu’une perte de données entre la dernière synchronisation réussie et la panne reste possible. citeturn929755search0turn773761search4

---

# Questions intermédiaires

## Réplication = backup ?

Non.

Pourquoi ?

Réfléchissez :

```text
suppression logique
ransomware
corruption applicative
erreur humaine
```

Une réplication peut reproduire un mauvais état.

---

# 🟢 GUIDÉ — Partie 16 : vérifier les prérequis HA

Avant HA :

```bash
pvecm status
pvesr status
ha-manager status
```

Vous devez avoir :

```text
cluster quorate
réplication récente
nœud cible disponible
zfs-lab actif
```

Pour un groupe de 2 :

> Le QDevice doit être opérationnel avant de tester une panne de nœud.

---

# 🟢 GUIDÉ — Partie 17 : ajouter web01 à HA

Dans la GUI :

```text
Datacenter
→ HA
→ Resources
→ Add
```

Ajoutez :

```text
VM : 111 web01
```

Vérifiez :

```bash
ha-manager status
```

Vous devez retrouver un service proche de :

```text
vm:111
```

avec un état sain.

---

# Que fait HA ?

HA ne signifie pas :

```text
VM jamais interrompue
```

Dans ce scénario, HA signifie plutôt :

```text
PVE01 tombe
     │
     ▼
cluster détecte la panne
     │
     ▼
fencing / décision HA
     │
     ▼
PVE02 possède une réplica
     │
     ▼
web01 redémarre
```

Le service subit donc une interruption.

C’est le **RTO** que nous allons mesurer.

---

# 🟢 GUIDÉ — Partie 18 : état nominal avant incident

Avant toute panne, notez :

```bash
date
pvecm status
pvesr status
ha-manager status
```

Puis vérifiez :

```bash
ping <IP-web01>
```

Notez :

```text
Nœud hébergeant web01 :
Dernière réplication réussie :
Heure du début de test :
```

---

# 🟢 GUIDÉ — Partie 19 : panne contrôlée

> ⚠️ UNIQUEMENT APRÈS VALIDATION DU FORMATEUR.

Ne faites pas :

```bash
reboot
```

dans PVE.

Nous voulons simuler une vraie disparition du serveur.

Dans VMware Workstation :

```text
PVE01
→ Power Off
```

ou, dans le LAB réel :

```text
coupure contrôlée du nœud prévue par le formateur
```

Laissez actif :

```bash
ping <IP-web01>
```

Depuis PVE02 :

```bash
ha-manager status
```

et :

```bash
pvecm status
```

Observez l’évolution.

---

# 🟢 GUIDÉ — Partie 20 : mesurer le RTO

Notez :

```text
T0 : PVE01 coupé
T1 : cluster détecte la panne
T2 : web01 démarre sur PVE02
T3 : ping/service revient
```

Calculez :

```text
RTO observé = T3 - T0
```

Ne vous attendez pas nécessairement à quelques secondes : le mécanisme HA attend et vérifie l’état du nœud avant de récupérer les workloads. La documentation Proxmox décrit un délai d’attente de l’ordre de quelques minutes dans les conditions HA par défaut avant récupération d’un guest après perte d’un nœud. citeturn929755search0

---

# 🟢 GUIDÉ — Partie 21 : vérifier web01 après failover

Sur PVE02 :

```bash
qm status 111
```

Résultat attendu :

```text
status: running
```

Dans la VM :

```bash
hostname
```

Résultat :

```text
web01
```

Vérifiez également le fichier créé avant la panne :

```bash
ls -lh /tmp/tp06-change.bin
```

### Important

Selon l’heure de la dernière réplication :

```text
le fichier peut être présent
ou
ne pas être présent
```

Ce résultat permet justement d’illustrer le RPO.

---

# 🟢 GUIDÉ — Partie 22 : remettre PVE01 en service

Redémarrez PVE01.

Attendez :

```bash
pvecm nodes
```

et :

```bash
pvecm status
```

Vérifiez également :

```bash
ha-manager status
pvesr status
```

Le but est de revenir à :

```text
cluster quorate
tous les nœuds visibles
web01 sous contrôle HA
réplication fonctionnelle
```

---

# Questions obligatoires

## Question 1 — Migration = HA ?

Expliquez la différence entre :

```text
migration planifiée
```

et :

```text
panne imprévue
```

---

## Question 2 — Live migration = zéro interruption ?

Que montrent vos pings ?

Quelle est la différence entre :

```text
zéro reboot
```

et :

```text
zéro perte réseau
```

?

---

## Question 3 — Pourquoi la live migration avec stockage local est-elle plus lourde ?

Comparez :

```text
stockage local
```

et :

```text
stockage partagé
```

Dans le premier cas, il faut transférer :

```text
RAM + état + DISQUE
```

alors qu’avec un stockage partagé, les deux nœuds accèdent déjà aux mêmes données.

---

## Question 4 — Réplication = backup ?

Justifiez avec au moins deux scénarios de perte.

---

## Question 5 — Quel RPO ?

Pour une réplication toutes les 5 minutes :

```text
quel volume de données peut théoriquement être perdu ?
```

---

## Question 6 — Quel RTO ?

Votre RTO observé correspond-il au temps :

```text
migration
```

ou au temps :

```text
détection panne
+
fencing
+
redémarrage VM
+
démarrage application
```

?

---

## Question 7 — Que se passe-t-il si PVE01 est isolé du réseau mais continue à fonctionner ?

Pourquoi le cluster doit-il éviter :

```text
web01 active sur PVE01
ET
web01 active sur PVE02
```

en même temps ?

C’est la problématique du :

```text
split-brain
```

et du fencing.

---

# 🟠 CHALLENGE — mesurer précisément la live migration

Refaites une live migration.

Utilisez simultanément :

```bash
ping <IP-web01>
```

```bash
tcpdump -ni vmbr1
```

```bash
iftop -i vmbr1
```

et :

```bash
qm status 111
```

Collectez :

| Mesure | Résultat |
|---|---|
| Durée totale migration | ? |
| Ping perdus | ? |
| Débit max observé | ? |
| Taille disque VM | ? |
| RAM VM | ? |

Expliquez quel élément semble avoir le plus influencé la durée.

---

# 🟠 CHALLENGE — effet de la réplication sur la migration

Avec `web01` correctement répliquée vers PVE02 :

1. notez l’état `pvesr status` ;
2. lancez une migration vers PVE02 ;
3. mesurez sa durée ;
4. comparez avec la migration initiale.

### Question

Pourquoi le volume à transférer peut-il être beaucoup plus faible ?

La réplication permet de prépositionner les données sur le nœud cible. Seules les différences récentes doivent alors être synchronisées. citeturn773761search4

---

# 🟠 CHALLENGE — LXC

Essayez de raisonner sur :

```text
CT210 labct01
```

Proxmox permet la migration d’un conteneur arrêté.

Une migration avec restart est également possible.

Mais un conteneur LXC ne possède pas la même live migration transparente qu’une VM KVM classique. citeturn379495search1

### Question

Pourquoi le modèle de virtualisation LXC rend-il cette problématique différente ?

---

# 🔴 EXPERT — réseau dédié de migration

Notre architecture actuelle :

```text
Corosync
Migration
VM traffic

        ↓

      vmbr1
```

n’est pas idéale.

Concevez :

```text
NIC / réseau 1
→ management

NIC / réseau 2
→ Corosync

NIC / réseau 3
→ migration

NIC / réseau 4
→ stockage / workloads
```

Proposez :

```text
subnets
VLAN
MTU
débit
redondance
```

Puis expliquez comment Proxmox peut sélectionner un `migration_network`.

---

# 🔴 EXPERT — second lien Corosync

Étudiez :

```text
Corosync link0
Corosync link1
```

Répondez :

- quel problème cherche-t-on à éviter ?
- les deux liens doivent-ils traverser le même switch ?
- que se passe-t-il si les deux liens partagent le même domaine de panne ?

---

# 🔴 EXPERT — Ceph vs ZFS Replication

Comparez :

| | ZFS + Replication | Ceph |
|---|---|---|
| Stockage | local répliqué | distribué |
| Réplication | asynchrone | intégrée au cluster stockage |
| HA | possible | possible |
| RPO | potentiellement > 0 | dépend architecture/écriture |
| Complexité | modérée | plus élevée |
| Besoin réseau | raisonnable | important |
| Petit LAB | adapté | souvent trop lourd |

Expliquez dans quel contexte vous choisiriez chaque solution.

---

# 🔴 EXPERT — Dynamic Load Balancer / Cluster Resource Scheduling

Étudiez le mécanisme actuel de planification des ressources HA dans Proxmox.

Questions :

```text
HA choisit-il toujours le nœud ayant le moins de VM ?
```

```text
CPU et RAM sont-ils les seuls critères possibles ?
```

```text
Comment éviter qu’une VM critique et sa dépendance
soient placées sur le même nœud ?
```

Produisez un mini schéma d’architecture.

---

# 🔴 EXPERT — scénario de panne complexe

Imaginez :

```text
10:00 réplication web01 vers PVE02 OK
10:02 utilisateur modifie des données
10:04 PVE01 tombe
10:06 web01 redémarre sur PVE02
```

Répondez :

```text
RPO ?
RTO ?
Données potentiellement perdues ?
Service restauré ?
Backup nécessaire ?
```

Expliquez pourquoi :

```text
HA
```

et :

```text
Backup
```

répondent à deux besoins différents.

---

# Validation TP06

À la fin du TP :

```text
Cluster
└── Quorate
```

`web01` doit être :

```text
présente
fonctionnelle
sur zfs-lab
```

Un job de réplication doit exister :

```bash
pvesr status
```

Le statut HA doit répondre :

```bash
ha-manager status
```

La VM doit être visible comme ressource HA si cette partie a été réalisée.

Vérifiez :

```bash
qm config 111
```

Puis lancez :

```bash
sudo ./scripts/proxmox/check-tp06.sh
```

Résultat attendu :

```text
[PASS] Cluster is quorate
[PASS] VM111 web01 exists
[PASS] web01 uses zfs-lab
[PASS] Replication job for VM111 exists
[PASS] Replication subsystem responds
[PASS] HA subsystem responds
[PASS] VM111 is managed by HA

STATUS: READY FOR TP07
```

---

# Ce qu’il faut retenir

## Migration

```text
maintenance planifiée
        ↓
déplacer un workload
```

## Réplication

```text
copie asynchrone
des données
vers un autre nœud
```

## HA

```text
détecter une panne
        ↓
fencer / sécuriser
        ↓
redémarrer le workload ailleurs
```

## Backup

```text
copie indépendante
        ↓
restauration
```

Le modèle complet devient :

```text
                 DISPONIBILITÉ

Disque HS
   │
   ▼
ZFS Mirror

Maintenance
   │
   ▼
Migration

Nœud HS
   │
   ├── Réplication
   │
   └── HA
         │
         ▼
    redémarrage

Erreur / perte logique
   │
   ▼
Backup / Restore
```
