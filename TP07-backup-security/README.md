# TP07 — Proxmox Backup Server, restauration & sécurité RBAC

**Durée cible : 1 h 15 à 1 h 30**

## Contexte

L’infrastructure NovaCorp est maintenant capable :

- d’exécuter des VM et des conteneurs ;
- de migrer des workloads ;
- de répliquer une VM entre plusieurs nœuds ;
- de redémarrer un workload avec HA.

Mais aucune de ces fonctions ne remplace une **sauvegarde indépendante**.

Votre dernière mission avant le Final Boss est donc double :

1. prouver que `web01` peut être **sauvegardée puis restaurée** depuis Proxmox Backup Server ;
2. arrêter d’utiliser `root@pam` pour toutes les opérations et appliquer le principe du **moindre privilège**.

---

# Objectifs

À la fin du TP, vous devez être capable de :

- distinguer snapshot, réplication, HA et backup ;
- connecter un PBS à Proxmox VE ;
- effectuer une sauvegarde de VM ;
- vérifier qu’un backup existe ;
- supprimer volontairement une VM après validation ;
- restaurer la VM depuis PBS ;
- comprendre rétention, prune, garbage collection et vérification ;
- créer un utilisateur Proxmox ;
- créer un Resource Pool ;
- créer un rôle limité ;
- appliquer une ACL ;
- prouver qu’un opérateur peut gérer l’alimentation d’une VM sans pouvoir la supprimer ;
- comprendre le rôle d’un API token et de la séparation de privilèges.

> ⚠️ Le secret PBS, les mots de passe, les API tokens et les clés privées ne doivent jamais être versionnés dans Git.

---

# Architecture cible

```text
                    CLUSTER PVE
           ┌──────────┼──────────┐
           │          │          │
         PVE01      PVE02      PVE03
           │
         web01
           │
           │ backup
           ▼
       ┌─────────┐
       │   PBS   │
       │ externe │
       └─────────┘
```

Le PBS doit idéalement être situé hors du domaine de panne du cluster qu’il sauvegarde.

---

# Important — cas du PBS partagé entre plusieurs groupes

Tous les groupes utilisent des VMID similaires :

```text
111 web01
121 app01
131 db01
```

Si plusieurs groupes utilisent le même PBS, ils ne doivent pas écrire indistinctement dans le même espace logique.

Le formateur fournira donc idéalement un **namespace par groupe** :

```text
Groupe 1 -> namespace g01
Groupe 2 -> namespace g02
Groupe 3 -> namespace g03
```

Ainsi :

```text
PBS
└── datastore-lab
    ├── g01
    │   └── vm/111
    ├── g02
    │   └── vm/111
    └── g03
        └── vm/111
```

Cela évite les collisions et clarifie la propriété des sauvegardes.

---

# 🟢 GUIDÉ — Partie 1 : pré-check avant sauvegarde

Vérifiez le cluster :

```bash
pvecm status
```

Attendu :

```text
Quorate: Yes
```

Vérifiez `web01` :

```bash
qm status 111
qm config 111
```

La VM doit exister et être fonctionnelle.

Vérifiez également :

```bash
ping <IP-web01>
```

---

# 🟢 GUIDÉ — Partie 2 : sortir temporairement web01 de HA

Dans le TP06, `web01` a pu être placée sous contrôle HA.

Avant notre exercice de suppression/restauration, nous devons éviter que HA tente de gérer la VM pendant que nous la détruisons volontairement.

Vérifiez :

```bash
ha-manager status
```

Si vous voyez :

```text
vm:111
```

retirez temporairement la VM de HA :

```bash
ha-manager remove vm:111
```

Contrôlez :

```bash
ha-manager status
```

### Question

Pourquoi ne voulons-nous pas supprimer manuellement une VM encore gérée par HA ?

---

# 🟢 GUIDÉ — Partie 3 : récupérer les informations PBS

Le formateur vous fournit :

```text
PBS server     : __________________
Datastore      : __________________
Namespace      : __________________
Authentication : __________________
Fingerprint    : __________________
```

Selon le LAB, l’authentification pourra utiliser :

```text
utilisateur PBS
```

ou :

```text
API token PBS
```

Le port PBS standard est :

```text
8007/TCP
```

---

# 🟢 GUIDÉ — Partie 4 : vérifier la connectivité PBS

Depuis un nœud PVE :

```bash
ping <IP-PBS>
```

Puis :

```bash
nc -vz <IP-PBS> 8007
```

Si `nc` n’est pas disponible :

```bash
curl -k https://<IP-PBS>:8007/
```

L’objectif n’est pas d’obtenir une page lisible dans le terminal, mais de confirmer qu’un service TLS répond sur le port PBS.

---

# 🟢 GUIDÉ — Partie 5 : ajouter PBS à Proxmox

## Méthode recommandée pour le LAB : GUI

Dans :

```text
Datacenter
→ Storage
→ Add
→ Proxmox Backup Server
```

Configurez :

```text
ID          : pbs-gG
Server      : adresse PBS
Username    : fourni par le formateur
Password    : fourni par le formateur
Datastore   : fourni par le formateur
Namespace   : gGG si utilisé
Fingerprint : fourni par le formateur
```

Exemple groupe 3 :

```text
ID        : pbs-g03
Namespace : g03
```

> Ne copiez jamais un mot de passe ou un token PBS dans le README du groupe.

---

# 🟢 GUIDÉ — Partie 6 : valider le stockage PBS

Vérifiez :

```bash
pvesm status
```

Vous devez retrouver :

```text
pbs-gGG
```

avec :

```text
Status : active
```

Exemple :

```text
pbs-g03  pbs  active
```

Vérifiez la configuration :

```bash
grep -A10 '^pbs:' /etc/pve/storage.cfg
```

ou :

```bash
cat /etc/pve/storage.cfg
```

### Attention

Le fichier de configuration contient les paramètres du stockage mais Proxmox conserve les secrets de stockage dans la partie privée de `/etc/pve`.

Ne cherchez pas à afficher ou à commiter ces secrets.

---

# 🟢 GUIDÉ — Partie 7 : première sauvegarde de web01

Nous allons sauvegarder :

```text
VM111 web01
```

La VM peut rester démarrée.

Exemple CLI :

```bash
vzdump 111 \
  --storage pbs-gGG \
  --mode snapshot
```

Adaptez :

```text
pbs-gGG
```

à votre groupe.

Exemple groupe 3 :

```bash
vzdump 111 \
  --storage pbs-g03 \
  --mode snapshot
```

Pendant la sauvegarde, observez la tâche dans la GUI Proxmox.

---

# 🟢 GUIDÉ — Partie 8 : interpréter le résultat

Une sauvegarde réussie doit terminer avec un état proche de :

```text
TASK OK
```

Mais :

```text
TASK OK
```

ne signifie pas encore :

> « J’ai prouvé que mon PRA fonctionne. »

Vérifiez que le backup est réellement visible :

```bash
pvesm list pbs-gGG --content backup
```

Vous devez retrouver une entrée correspondant à :

```text
vm/111
```

Notez :

```text
Date/heure backup :
Taille :
Durée :
```

---

# 🟢 GUIDÉ — Partie 9 : comprendre le fonctionnement PBS

PBS ne stocke pas simplement :

```text
backup1.img
backup2.img
backup3.img
```

Il travaille avec des données découpées en **chunks** et peut dédupliquer les blocs identiques.

Schéma simplifié :

```text
Backup #1
A B C D

Backup #2
A B C E

PBS stocke :

A B C D E
```

Les sauvegardes suivantes peuvent donc être beaucoup plus efficaces lorsque peu de données ont changé.

### Important

Déduplication :

```text
≠ compression
```

Compression :

```text
réduit la taille d’une donnée
```

Déduplication :

```text
évite de stocker plusieurs fois une donnée identique
```

---

# 🟢 GUIDÉ — Partie 10 : créer une modification avant un second backup

Dans `web01` :

```bash
date > /root/tp07-marker.txt
```

Puis :

```bash
cat /root/tp07-marker.txt
```

Créez éventuellement un petit volume de données :

```bash
dd if=/dev/urandom \
  of=/root/tp07-data.bin \
  bs=1M count=20
```

Relancez ensuite :

```bash
vzdump 111 \
  --storage pbs-gGG \
  --mode snapshot
```

Comparez :

```text
premier backup
deuxième backup
```

### Question

Pourquoi la seconde sauvegarde n’a-t-elle pas forcément besoin de retransférer l’intégralité du disque virtuel ?

---

# 🟢 GUIDÉ — Partie 11 : prouver qu’un backup est restaurable

Une sauvegarde intéressante est une sauvegarde que vous savez restaurer.

Avant toute suppression :

```bash
pvesm list pbs-gGG --content backup
```

Montrez le résultat au formateur.

**Ne continuez qu’après validation.**

---

# 🟢 GUIDÉ — Partie 12 : arrêter puis supprimer web01

Arrêtez proprement :

```bash
qm shutdown 111
```

Vérifiez :

```bash
qm status 111
```

Puis :

```bash
qm destroy 111 --purge 1
```

Contrôlez :

```bash
qm config 111
```

La commande doit désormais échouer car VM111 n’existe plus dans la configuration active.

### Situation

```text
INCIDENT

web01 a été supprimée.
L’application NovaCorp est indisponible.
```

---

# 🟢 GUIDÉ — Partie 13 : restaurer depuis PBS

## Méthode GUI recommandée

Dans :

```text
Datacenter
→ Storage
→ pbs-gGG
→ Backups
```

Sélectionnez la sauvegarde de :

```text
VM111
```

puis :

```text
Restore
```

Cible :

```text
VM ID       : 111
Target Node : nœud choisi
Storage     : zfs-lab
```

Lancez la restauration.

---

# 🟢 GUIDÉ — Partie 14 : valider la restauration

Une fois terminée :

```bash
qm config 111
```

Puis :

```bash
qm start 111
```

Vérifiez :

```bash
qm status 111
```

Attendu :

```text
status: running
```

Testez :

```bash
ping <IP-web01>
```

Puis dans la VM :

```bash
hostname
```

Attendu :

```text
web01
```

Vérifiez également :

```bash
cat /root/tp07-marker.txt
```

si vous avez restauré la sauvegarde qui contenait ce fichier.

---

# 🟢 GUIDÉ — Partie 15 : mesurer le RTO de restauration

Notez :

```text
T0 : décision de restauration
T1 : début restore
T2 : fin restore
T3 : web01 opérationnelle
```

Calculez :

```text
RTO restauration = T3 - T0
```

### Question

Ce RTO est-il identique au RTO HA observé au TP06 ?

Pourquoi ?

---

# 🟢 GUIDÉ — Partie 16 : RPO d’un backup

Imaginez :

```text
02:00 backup PBS réussi
10:00 modification de données
14:00 suppression VM
```

Si le dernier backup est celui de :

```text
02:00
```

le RPO réel peut être :

```text
12 heures
```

La sauvegarde répond donc à une stratégie.

Elle n’invente pas des données qui n’ont jamais été sauvegardées.

---

# 🟢 GUIDÉ — Partie 17 : rétention

Une politique de sauvegarde doit déterminer combien de versions conserver.

Exemple :

```text
keep-last    : 3
keep-daily   : 7
keep-weekly  : 4
keep-monthly : 6
```

Interprétez :

```text
3 dernières sauvegardes
7 sauvegardes quotidiennes
4 hebdomadaires
6 mensuelles
```

### Question

Pourquoi :

```text
garder absolument toutes les sauvegardes
```

n’est-il pas nécessairement une bonne stratégie ?

---

# 🟢 GUIDÉ — Partie 18 : Prune, Garbage Collection et Verify

Trois opérations différentes existent dans PBS.

## Prune

Décide quelles sauvegardes ne doivent plus être conservées :

```text
politique de rétention
        ↓
snapshots anciens supprimés logiquement
```

## Garbage Collection

Nettoie les chunks qui ne sont plus référencés par aucun backup conservé :

```text
chunks inutilisés
      ↓
suppression physique
```

## Verify

Relit et vérifie les sauvegardes/chunks afin de détecter des problèmes d’intégrité.

### À retenir

```text
Prune ≠ Garbage Collection ≠ Verify
```

Et surtout :

```text
Verify réussi
≠
test complet de restauration d’une application
```

La documentation PBS distingue bien prune, garbage collection et jobs de vérification ; les politiques de rétention prennent notamment en charge `keep-last`, `keep-daily`, `keep-weekly` et `keep-monthly`.

---

# Questions obligatoires — Backup

## Question 1

Complétez :

| Mécanisme | Objectif principal |
|---|---|
| ZFS Mirror | ? |
| Snapshot | ? |
| Replication | ? |
| HA | ? |
| PBS Backup | ? |

## Question 2

Pourquoi la réplication ZFS du TP06 ne remplace-t-elle pas PBS ?

## Question 3

Pourquoi `TASK OK` ne suffit-il pas à prouver qu’un service métier est restaurable ?

## Question 4

À quoi servent :

```text
Prune
Garbage Collection
Verify
Restore Test
```

?

---

# PARTIE B — Sécurité & RBAC

Nous allons maintenant réduire l’usage de :

```text
root@pam
```

Le principe est :

> Un utilisateur ne doit disposer que des permissions nécessaires à son travail.

C’est le principe du :

```text
Least Privilege
```

---

# 🟢 GUIDÉ — Partie 19 : comprendre le modèle RBAC Proxmox

Une permission Proxmox associe :

```text
QUI
+
QUEL ROLE
+
SUR QUEL OBJET
```

Soit :

```text
User / Group / Token
        │
        ▼
       Role
        │
        ▼
       Path
```

Exemple :

```text
ops-g03@pve
     │
NovaVMOperator
     │
/pool/POOL-G03-APP
```

Un **Role** est un ensemble de privilèges.

Une **ACL** associe ce rôle à un utilisateur sur un chemin précis.

---

# 🟢 GUIDÉ — Partie 20 : créer un Resource Pool

Pour le groupe `GG`, créez :

```text
POOL-GGG-APP
```

Exemple groupe 3 :

```text
POOL-G03-APP
```

Dans :

```text
Datacenter
→ Permissions
→ Pools
```

Ajoutez ensuite :

```text
VM111 web01
```

au Resource Pool.

### Pourquoi un pool ?

Au lieu d’appliquer :

```text
permissions sur chaque VM individuellement
```

on peut appliquer :

```text
permission sur un ensemble logique de ressources
```

---

# 🟢 GUIDÉ — Partie 21 : créer un rôle opérateur

Objectif :

```text
VOIR web01
OUVRIR LA CONSOLE
DÉMARRER web01
ARRÊTER web01
```

mais pas :

```text
SUPPRIMER VM
MODIFIER CPU/RAM
MODIFIER RÉSEAU
ADMINISTRER CLUSTER
MODIFIER STORAGE
GÉRER UTILISATEURS
```

Créez un rôle :

```text
NovaVMOperator
```

avec les privilèges :

```text
VM.Audit
VM.Console
VM.PowerMgmt
```

CLI possible :

```bash
pveum role add NovaVMOperator \
  --privs "VM.Audit VM.Console VM.PowerMgmt"
```

Vérifiez :

```bash
pveum role list
```

---

# 🟢 GUIDÉ — Partie 22 : créer l’utilisateur opérateur

Créez :

```text
ops-gGG@pve
```

Exemple :

```text
ops-g03@pve
```

CLI :

```bash
pveum user add ops-g03@pve
```

Définissez son mot de passe :

```bash
pveum passwd ops-g03@pve
```

> Ne mettez pas le mot de passe dans Git.

---

# 🟢 GUIDÉ — Partie 23 : appliquer l’ACL

Exemple groupe 3 :

```bash
pveum acl modify /pool/POOL-G03-APP \
  -user ops-g03@pve \
  -role NovaVMOperator
```

Vérifiez les permissions :

```bash
pveum user permissions ops-g03@pve
```

Le modèle RBAC Proxmox repose précisément sur des ACL liant utilisateur/groupe/token, rôle et chemin de ressource.

---

# 🟢 GUIDÉ — Partie 24 : test opérateur

Ouvrez :

```text
une fenêtre privée / incognito
```

Connectez-vous en :

```text
ops-gGG@pve
```

Testez :

```text
Voir web01              → doit fonctionner
Console web01           → doit fonctionner
Stop web01              → doit fonctionner
Start web01             → doit fonctionner
```

Puis essayez :

```text
Supprimer web01
Modifier son CPU
Modifier son réseau
Créer un cluster
Modifier un storage
```

Ces opérations doivent être refusées ou non proposées.

---

# 🟢 GUIDÉ — Partie 25 : observer le refus

Le but du RBAC n’est pas simplement :

```text
faire disparaître des boutons
```

mais :

```text
faire refuser l’action par l’API
```

Une GUI cachée n’est pas un contrôle de sécurité.

### Question

Pourquoi est-il important de tester les droits avec un second compte au lieu de simplement regarder la configuration depuis `root@pam` ?

---

# 🟠 CHALLENGE — API token d’automatisation

Créez :

```text
automation-gGG@pve
```

Puis un token séparé :

```text
tp07
```

Exemple :

```bash
pveum user add automation-g03@pve
```

Puis :

```bash
pveum user token add automation-g03@pve tp07 -privsep 1
```

> ⚠️ Le secret du token n’est affiché qu’au moment de sa création.
> Ne le copiez jamais dans Git.

Avec `privsep=1`, les permissions du token peuvent être **plus restrictives** que celles de son utilisateur parent ; elles ne peuvent pas dépasser les droits du compte parent.

---

# 🟠 CHALLENGE — token en lecture seule

Donnez au token uniquement un rôle de lecture sur le pool.

Exemple :

```bash
pveum acl modify /pool/POOL-G03-APP \
  -token 'automation-g03@pve!tp07' \
  -role PVEAuditor
```

Puis vérifiez :

```bash
pveum user token permissions automation-g03@pve tp07
```

Le token doit pouvoir lire les informations autorisées sans pouvoir démarrer ou supprimer une VM.

---

# 🟠 CHALLENGE — appel API

Stockez temporairement le secret dans une variable d’environnement :

```bash
export PVE_TOKEN_SECRET='...'
```

Ne faites jamais :

```text
echo TOKEN_SECRET > token.txt
git add token.txt
```

Exemple d’appel :

```bash
curl -k \
  -H "Authorization: PVEAPIToken=automation-g03@pve!tp07=${PVE_TOKEN_SECRET}" \
  https://<PVE>:8006/api2/json/cluster/resources
```

### Question

Pourquoi un token est-il préférable au mot de passe personnel d’un administrateur pour une application d’automatisation ?

---

# 🟠 CHALLENGE — vérifier qu’aucun secret n’est versionné

Depuis votre dépôt :

```bash
./scripts/security/check-secrets.sh
```

Inspectez également :

```bash
git status
```

et :

```bash
git diff --cached
```

avant chaque commit contenant des fichiers de configuration.

---

# 🔴 EXPERT — architecture d’administration réelle

Proposez une architecture intégrant :

```text
comptes nominatifs
MFA / TFA
VPN
bastion
RBAC
API tokens
secret manager
logs d’administration
réseau management
```

Exemple de réflexion :

```text
ADMIN
  │
 MFA
  │
 VPN
  │
BASTION
  │
  └──── réseau management
          │
          └──── PVE Cluster
```

Expliquez ce qui est amélioré par rapport à :

```text
root@pam
+
mot de passe partagé
+
GUI exposée partout
```

---

# 🔴 EXPERT — permissions par groupe

Imaginez :

```text
Equipe APP
Equipe INFRA
Equipe BACKUP
Auditeurs
```

Proposez un modèle RBAC :

```text
Group
Role
Path
```

pour chacun.

Aucun groupe ne doit recevoir :

```text
Administrator /
```

sans justification.

---

# 🔴 EXPERT — stratégie PBS réelle

Concevez une politique comprenant :

```text
backup quotidien
rétention
prune
garbage collection
verify
test de restauration
copie hors site
```

Puis proposez :

```text
RPO cible
RTO cible
```

pour :

```text
web01
app01
db01
```

Les valeurs ne doivent pas être choisies au hasard : justifiez-les selon la criticité.

---

# Questions finales

## 1 — Quel mécanisme protège contre quoi ?

Complétez :

```text
Disque physique HS      → ?
Suppression fichier     → ?
Nœud PVE HS             → ?
VM supprimée            → ?
Site complet perdu      → ?
Compte admin compromis  → ?
```

---

## 2 — Une sauvegarde dans le même datacenter suffit-elle ?

Discutez :

```text
incendie
vol
ransomware
erreur administrative
compromission PBS
```

---

## 3 — Pourquoi éviter un compte partagé ?

Discutez :

```text
traçabilité
révocation
MFA
audit
responsabilité
```

---

# Validation TP07

À la fin du TP :

## Backup

Le stockage PBS doit être actif :

```bash
pvesm status
```

Une sauvegarde de VM111 doit exister :

```bash
pvesm list pbs-gGG --content backup
```

Et :

```text
web01
```

doit avoir été restaurée et être de nouveau fonctionnelle :

```bash
qm status 111
```

---

## RBAC

Vous devez disposer de :

```text
Resource Pool : POOL-GGG-APP
User          : ops-gGG@pve
Role          : NovaVMOperator
```

L’opérateur doit pouvoir :

```text
voir
console
start
stop
```

mais pas :

```text
delete
modify hardware
admin cluster
admin storage
admin users
```

---

# Script de validation

Lancez :

```bash
sudo ./scripts/proxmox/check-tp07.sh G
```

Exemple groupe 3 :

```bash
sudo ./scripts/proxmox/check-tp07.sh 3
```

Puis :

```bash
./scripts/security/check-secrets.sh
```

Résultat attendu :

```text
[PASS] PBS storage detected
[PASS] Backup for VM111 detected
[PASS] VM111 web01 exists after restore
[PASS] Resource pool exists
[PASS] Operator user exists
[PASS] NovaVMOperator role exists

STATUS: READY FOR FINAL BOSS
```

---

# Ce qu’il faut retenir

```text
SNAPSHOT
   │
   └── retour rapide dans le même stockage

REPLICATION
   │
   └── copie asynchrone sur un autre nœud

HA
   │
   └── redémarrage automatique après panne

PBS
   │
   └── sauvegarde indépendante + restauration

RBAC
   │
   └── limiter qui peut faire quoi et où
```

Le principe final est :

```text
DISPONIBILITÉ ≠ SAUVEGARDE ≠ SÉCURITÉ
```

Une infrastructure mature doit traiter les trois.
