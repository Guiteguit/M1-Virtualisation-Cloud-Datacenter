# TP04 — Stockage avancé : ZFS, snapshots et résilience

**Durée cible : 1 h 15 à 1 h 30**

## Contexte

NovaCorp souhaite disposer d’un stockage local plus robuste pour héberger les disques des machines virtuelles et des conteneurs.

Chaque nœud Proxmox dispose de deux disques supplémentaires dédiés au LAB.

Votre mission consiste à :

- identifier correctement ces disques ;
- construire un **mirror ZFS** ;
- intégrer ce stockage à Proxmox ;
- manipuler datasets et snapshots ;
- provoquer une panne contrôlée d’un disque ;
- observer le comportement de ZFS ;
- comprendre les différences entre **RAID, snapshot, réplication et sauvegarde**.

> ⚠️ Les commandes de création de pool sont destructrices.  
> Vérifiez impérativement les disques sélectionnés avant d’exécuter `zpool create`.

---

## Architecture cible

Chaque PVE possède :

```text
PVE0X
│
├── Disque système Proxmox
│
└── Stockage LAB
      │
      └── ZFS pool : tank
             │
             └── mirror-0
                   ├── DISK1
                   └── DISK2
```

Avec deux disques de 20 Go :

```text
20 Go + 20 Go
      ↓
    MIRROR
      ↓
~20 Go utilisables
```

Les mêmes données sont écrites sur les deux membres du mirror.

---

# 🟢 GUIDÉ — Partie 1 : identifier les disques

Commencez par inventorier les disques du serveur :

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS,MODEL
```

Vous devriez retrouver une structure proche de :

```text
NAME        SIZE TYPE FSTYPE      MOUNTPOINTS
sda          64G disk
├─sda1     1007K part
├─sda2        1G part vfat        /boot/efi
└─sda3       63G part LVM2_member

sdb          20G disk
sdc          20G disk
```

Dans cet exemple :

```text
sda = disque système Proxmox

sdb = disque ZFS #1
sdc = disque ZFS #2
```

**Ne recopiez pas automatiquement ces noms.**

Votre configuration peut être différente.

Vérifiez également :

```bash
ls -l /dev/disk/by-id/
```

En production, on préfère utiliser des identifiants persistants du type :

```text
/dev/disk/by-id/...
```

plutôt que :

```text
/dev/sdb
/dev/sdc
```

car le nom `/dev/sdX` n’est pas destiné à représenter durablement l’identité physique d’un disque.

### À valider avant de continuer

Vous devez être capable de répondre :

```text
Quel est le disque système ?
Quels sont les deux disques du LAB ?
Ces deux disques contiennent-ils déjà des données ?
```

Vérifiez éventuellement :

```bash
wipefs -n /dev/sdb
wipefs -n /dev/sdc
```

`-n` signifie ici que `wipefs` **n’efface rien** : il affiche simplement les signatures trouvées.

---

# 🟢 GUIDÉ — Partie 2 : créer le mirror ZFS

Une fois les **deux bons disques identifiés**, créez le pool.

Exemple :

```bash
zpool create -f -o ashift=12 tank mirror /dev/sdb /dev/sdc
```

Ou de préférence avec les identifiants persistants :

```bash
zpool create -f -o ashift=12 tank mirror \
  /dev/disk/by-id/<DISK1> \
  /dev/disk/by-id/<DISK2>
```

Vérifiez immédiatement :

```bash
zpool status
```

Vous devez obtenir quelque chose proche de :

```text
  pool: tank
 state: ONLINE

config:

        NAME        STATE
        tank        ONLINE
          mirror-0  ONLINE
            sdb     ONLINE
            sdc     ONLINE

errors: No known data errors
```

### Question

Que signifie :

```text
state: ONLINE
```

Et surtout :

> Si l’un des deux disques tombe maintenant, combien de copies des données restera-t-il ?

---

# 🟢 GUIDÉ — Partie 3 : comprendre pool et dataset

Un **zpool** représente le pool de stockage construit à partir des disques :

```text
tank
│
└── mirror
     ├── disk1
     └── disk2
```

Les **datasets ZFS** sont créés à l’intérieur du pool :

```text
tank
├── vmdata
└── tp04-demo
```

Créez un dataset destiné à Proxmox :

```bash
zfs create tank/vmdata
```

Puis un dataset pour les expérimentations :

```bash
zfs create tank/tp04-demo
```

Listez-les :

```bash
zfs list
```

Vous devriez avoir quelque chose ressemblant à :

```text
NAME             USED  AVAIL  REFER  MOUNTPOINT
tank             ...   ...    ...    /tank
tank/tp04-demo   ...   ...    ...    /tank/tp04-demo
tank/vmdata      ...   ...    ...    /tank/vmdata
```

---

# 🟢 GUIDÉ — Partie 4 : activer la compression

Activez la compression sur le stockage des VM :

```bash
zfs set compression=lz4 tank/vmdata
```

Et sur notre dataset de test :

```bash
zfs set compression=lz4 tank/tp04-demo
```

Contrôlez :

```bash
zfs get compression tank/vmdata
```

Résultat attendu :

```text
NAME         PROPERTY     VALUE
tank/vmdata  compression  lz4
```

### À comprendre

La compression ne signifie pas :

```text
1 Go -> toujours 500 Mo
```

Le résultat dépend du contenu.

Des données texte ou système peuvent être fortement compressibles.

Des fichiers déjà compressés comme :

```text
ZIP
JPEG
MP4
```

le seront beaucoup moins.

---

# 🟢 GUIDÉ — Partie 5 : enregistrer ZFS dans Proxmox

Pour le moment :

```text
Linux/ZFS connaît tank/vmdata
```

mais nous voulons maintenant indiquer à Proxmox :

> « Ce dataset peut servir à stocker les disques VM et les rootfs LXC. »

Depuis **un seul nœud du cluster**, exécutez :

```bash
pvesm add zfspool zfs-lab \
  --pool tank/vmdata \
  --content images,rootdir \
  --sparse 1
```

Puis :

```bash
pvesm status
```

Vous devriez maintenant voir :

```text
Name       Type      Status
local      dir       active
local-lvm  lvmthin   active
zfs-lab    zfspool   active
```

### ⚠️ Dans notre cluster

La configuration des stockages Proxmox est stockée dans :

```bash
cat /etc/pve/storage.cfg
```

Elle est donc **partagée au niveau du cluster**.

Cela signifie que vous ne devez pas exécuter :

```bash
pvesm add ...
```

sur chaque PVE.

En revanche, **chaque PVE doit réellement posséder son propre** :

```text
tank/vmdata
```

local.

Architecture :

```text
                 configuration Proxmox

                     zfs-lab
                         │
           ┌─────────────┼─────────────┐
           │             │             │
         PVE01         PVE02         PVE03
           │             │             │
     tank/vmdata   tank/vmdata   tank/vmdata
           │             │             │
        LOCAL          LOCAL          LOCAL
```

Très important :

> `zfs-lab` apparaît partout, mais cela **ne signifie pas que le stockage est partagé**.

---

# 🟢 GUIDÉ — Partie 6 : premier snapshot

Nous allons maintenant utiliser :

```text
tank/tp04-demo
```

Créez un fichier :

```bash
echo "VERSION 1" > /tank/tp04-demo/demo.txt
```

Vérifiez :

```bash
cat /tank/tp04-demo/demo.txt
```

Résultat :

```text
VERSION 1
```

Créez maintenant un snapshot :

```bash
zfs snapshot tank/tp04-demo@before-change
```

Listez les snapshots :

```bash
zfs list -t snapshot
```

Vous devriez retrouver :

```text
tank/tp04-demo@before-change
```

---

# 🟢 GUIDÉ — Partie 7 : modifier puis rollback

Modifiez le fichier :

```bash
echo "VERSION 2" > /tank/tp04-demo/demo.txt
```

Vérifiez :

```bash
cat /tank/tp04-demo/demo.txt
```

Résultat :

```text
VERSION 2
```

Effectuez maintenant un rollback :

```bash
zfs rollback tank/tp04-demo@before-change
```

Puis :

```bash
cat /tank/tp04-demo/demo.txt
```

Résultat attendu :

```text
VERSION 1
```

---

# Que vient-il de se passer ?

ZFS fonctionne selon le principe de **Copy-on-Write**.

Très simplifié :

```text
AVANT

A ─ B ─ C
```

Création du snapshot :

```text
Snapshot
   └── A ─ B ─ C
```

Vous modifiez `B`.

ZFS ne détruit pas immédiatement l’ancienne donnée :

```text
Snapshot
   └── ancien B

Dataset actuel
   └── nouveau B
```

C’est notamment pour cela qu’un snapshot peut être créé très rapidement.

---

# 🟢 GUIDÉ — Partie 8 : simuler la perte d’un disque

Avant l’incident :

```bash
zpool status tank
```

Vous devez avoir :

```text
tank
  mirror-0
    DISK1 ONLINE
    DISK2 ONLINE

state: ONLINE
```

Choisissez **l’un des deux membres du mirror**.

Puis :

```bash
zpool offline tank <DISK>
```

Exemple :

```bash
zpool offline tank /dev/sdc
```

Vérifiez :

```bash
zpool status tank
```

Vous devriez maintenant voir :

```text
  pool: tank
 state: DEGRADED

        NAME        STATE
        tank        DEGRADED
          mirror-0  DEGRADED
            sdb     ONLINE
            sdc     OFFLINE
```

### Testez les données

```bash
cat /tank/tp04-demo/demo.txt
```

Les données doivent toujours être disponibles.

---

# Pourquoi cela fonctionne-t-il ?

Avant :

```text
             tank
              │
           mirror
          /      \
       DISK1    DISK2
        ✅        ✅
```

Après panne :

```text
             tank
              │
           mirror
          /      \
       DISK1    DISK2
        ✅        ❌

        DEGRADED
           mais
       fonctionnel
```

Vous avez perdu la **redondance**, pas encore les données.

---

# 🟢 GUIDÉ — Partie 9 : remettre le disque

Remettez le disque ONLINE :

```bash
zpool online tank <DISK>
```

Puis :

```bash
zpool status tank
```

Le pool doit revenir à :

```text
ONLINE
```

---

# 🟢 GUIDÉ — Partie 10 : scrub

Lancez :

```bash
zpool scrub tank
```

Puis :

```bash
zpool status tank
```

Le scrub demande à ZFS de parcourir les données et de vérifier leur intégrité à l’aide des checksums.

Schématiquement :

```text
bloc
 │
 ▼
lecture
 │
 ▼
checksum calculé
 │
 ├── correspond -> OK
 │
 └── différent  -> corruption détectée
```

Avec un mirror, si une copie est incorrecte mais que l’autre est valide :

```text
DISK1
corrompu ❌

DISK2
valide ✅
```

ZFS peut utiliser la copie correcte pour réparer.

---

# Questions obligatoires

## Question 1 — Mirror/RAID = Backup ?

Répondez et justifiez.

Pensez notamment aux situations suivantes :

```text
panne d'un disque
rm -rf
ransomware
suppression VM
vol du serveur
incendie
```

## Question 2 — Snapshot = Backup ?

Que se passe-t-il si `tank` est totalement perdu ? Où se trouve le snapshot ?

## Question 3 — Pourquoi un pool presque plein est-il dangereux ?

Réfléchissez notamment à :

```text
Copy-on-Write
snapshots
fragmentation
nouvelles écritures
```

## Question 4 — Local ou partagé ?

Nous avons `zfs-lab` visible depuis tout le cluster.

Cela signifie-t-il qu’une VM sur PVE01 peut immédiatement démarrer sur PVE02 avec le même disque ? Expliquez.

---

# 🟠 CHALLENGE — Comparer les stockages Proxmox

Analysez :

```bash
pvesm status
cat /etc/pve/storage.cfg
```

Comparez :

```text
local
local-lvm
zfs-lab
```

Complétez le tableau suivant :

| Caractéristique | local | local-lvm | zfs-lab |
|---|---|---|---|
| Technologie | ? | ? | ? |
| VM disks | ? | ? | ? |
| LXC | ? | ? | ? |
| ISO | ? | ? | ? |
| Backup | ? | ? | ? |
| Snapshot | ? | ? | ? |
| Thin provisioning | ? | ? | ? |
| Shared entre PVE | ? | ? | ? |

Ne vous contentez pas de `oui / non`. Vous devez être capable d’expliquer **pourquoi**.

---

# 🟠 CHALLENGE — Observer l’espace réellement utilisé

Créez un fichier fortement compressible :

```bash
dd if=/dev/zero \
   of=/tank/tp04-demo/zero-file \
   bs=1M count=500
```

Vérifiez :

```bash
ls -lh /tank/tp04-demo/zero-file
zfs list tank/tp04-demo
zfs get compressratio tank/tp04-demo
```

Comparez :

```text
taille logique du fichier
vs
espace réellement consommé
```

Expliquez le résultat.

---

# 🔴 EXPERT — Observer les I/O ZFS

Lancez :

```bash
zpool iostat -v
```

Puis générez quelques écritures dans `/tank/tp04-demo`.

Observez :

```text
capacity
operations
bandwidth
```

Puis essayez :

```bash
zpool iostat -v 2
```

Que représente le `2` ?

---

# 🔴 EXPERT — Propriétés importantes

Exécutez :

```bash
zfs get compression,compressratio,recordsize tank/tp04-demo
```

Vous pourriez obtenir :

```text
PROPERTY       VALUE
compression    lz4
compressratio  1.45x
recordsize     128K
```

Expliquez `compression`, `compressratio` et `recordsize`.

Répondez :

> Pourquoi un serveur de fichiers séquentiel et une base de données réalisant de nombreuses petites I/O pourraient-ils ne pas avoir les mêmes besoins ?

---

# 🔴 EXPERT — ARC

Observez :

```bash
free -h
```

Puis :

```bash
arc_summary
```

si l’outil est disponible.

Recherchez notamment :

```text
ARC size
hits
misses
```

ARC signifie **Adaptive Replacement Cache** : il s’agit du cache RAM utilisé par ZFS.

```text
Application
     │
     ▼
    ARC
    RAM
     │
   HIT ?
   /   \
 YES   NO
 │      │
 RAM   DISK
```

### Question

Un serveur ZFS qui utilise beaucoup de RAM est-il forcément en manque de mémoire ? Justifiez.

---

# 🔴 EXPERT — Synthèse stockage

Associez chaque mécanisme à son objectif principal :

```text
MIRROR
SNAPSHOT
REPLICATION
BACKUP
HA
```

avec :

```text
A. Revenir rapidement à un état précédent
B. Continuer à disposer des données malgré la panne d'un disque
C. Disposer d'une copie des données sur un autre nœud
D. Restaurer depuis une copie indépendante
E. Remettre automatiquement le workload en service après une panne
```

---

# Validation TP04

Le résultat final doit être :

```text
tank
└── mirror
    ├── DISK1 ONLINE
    └── DISK2 ONLINE
```

Et :

```bash
zpool status tank
```

doit afficher :

```text
state: ONLINE
```

Les datasets doivent exister :

```bash
zfs list
```

avec au minimum :

```text
tank/vmdata
tank/tp04-demo
```

Et Proxmox doit connaître :

```bash
pvesm status
```

avec :

```text
zfs-lab
```

Le script peut ensuite être lancé :

```bash
sudo ./scripts/proxmox/check-tp04.sh
```

Résultat attendu :

```text
[PASS] ZFS pool tank exists
[PASS] tank is ONLINE
[PASS] mirror detected
[PASS] tank/vmdata exists
[PASS] compression enabled
[PASS] zfs-lab registered in Proxmox

STATUS: READY
```
