# TP02 — Réseau Proxmox, Linux Bridge & underlay

**Durée cible : ~1 h à 1 h 15 de pratique**

## Contexte

Chaque membre du groupe possède maintenant un nœud Proxmox fonctionnel.

Pour le moment, chaque PVE dispose principalement de son accès Internet via VMware NAT.

Votre mission consiste à construire le **réseau LAB inter-PVE** qui sera utilisé au TP03 pour :

- Corosync ;
- la communication entre les nœuds ;
- puis plus tard les migrations et la réplication.

Vous allez également comprendre le fonctionnement des **Linux Bridges** utilisés par Proxmox.

---

# Objectifs

À la fin du TP, vous devez être capable de :

- identifier les interfaces réseau d’un PVE ;
- distinguer NIC physique, interface VMware et Linux Bridge ;
- expliquer le rôle de `vmbr0` et `vmbr1` ;
- créer un réseau underlay inter-PVE ;
- conserver la route par défaut sur le réseau NAT ;
- vérifier la connectivité L2/L3 entre les nœuds ;
- observer ARP/ND, MAC et trafic ICMP ;
- créer un bridge local `vmbr10` ;
- diagnostiquer une panne réseau simple ;
- revenir à la configuration précédente en cas d’erreur.

---

# Architecture du TP

## Mode cours — plusieurs PC + switch manageable

```text
PC ETU1                 PC ETU2                 PC ETU3
   │                        │                       │
VMware WS                VMware WS               VMware WS
   │                        │                       │
 PVE01                    PVE02                   PVE03
   │                        │                       │
 vmbr1                    vmbr1                   vmbr1
   │                        │                       │
 NIC LAB                  NIC LAB                 NIC LAB
   │                        │                       │
   └────────────────────────┼───────────────────────┘
                            │
                    SWITCH MANAGEABLE
                            │
                    VLAN UNDERLAY DU GROUPE
```

Exemple groupe `G` :

```text
PVE01 : 10.100.G.11/24
PVE02 : 10.100.G.12/24
PVE03 : 10.100.G.13/24
```

Aucune gateway sur ce réseau.

---

## Mode recette locale — un seul PC VMware Workstation

Pour tester le cours seul, le switch physique peut être remplacé par un réseau VMware **Host-Only** commun :

```text
                  VMware Workstation
                         │
                   VMnet Host-Only
                         │
             ┌───────────┼───────────┐
             │           │           │
           PVE01       PVE02       PVE03
```

Exemple :

```text
PVE01 : 192.168.56.11/24
PVE02 : 192.168.56.12/24
PVE03 : 192.168.56.13/24
```

Le fonctionnement Proxmox reste le même.

La différence est simplement :

```text
COURS
vmbr1 -> VMware Bridged -> NIC physique -> switch

RECETTE LOCALE
vmbr1 -> VMware Host-Only -> VMnet interne
```

---

# 🟢 GUIDÉ — Partie 1 : comprendre un Linux Bridge

Proxmox utilise les Linux Bridges comme des **switches virtuels**.

Exemple :

```text
                Proxmox
                   │
              Linux Bridge
                 vmbr1
              /     |      \
             /      |       \
         Host PVE  VM100    VM101
             |
           NIC LAB
             |
        réseau physique
```

Une interface physique telle que :

```text
ens19
```

devient un **port du bridge**.

Le bridge :

```text
vmbr1
```

porte ensuite l’adresse IP du nœud.

---

## Règle importante

Lorsque :

```text
ens19
```

est membre de :

```text
vmbr1
```

l’adresse IP doit généralement être portée par :

```text
vmbr1
```

et non simultanément par :

```text
ens19
```

Architecture correcte :

```text
10.100.G.11/24
       │
     vmbr1
       │
     ens19
       │
     réseau
```

et non :

```text
10.100.G.11 -> vmbr1
10.100.G.11 -> ens19
```

---

# 🟢 GUIDÉ — Partie 2 : inventorier les interfaces

Commencez par :

```bash
ip -br link
```

Puis :

```bash
ip -br address
```

Et :

```bash
ip route
```

Vous devez identifier :

```text
NIC NAT / Internet
NIC LAB
NIC OOB éventuelle
vmbr0
```

---

# 🟢 GUIDÉ — Partie 3 : retrouver quelle NIC VMware correspond à quelle interface Linux

Dans VMware Workstation, votre VM PVE possède typiquement :

```text
Network Adapter 1 -> NAT
Network Adapter 2 -> LAB
Network Adapter 3 -> Host-Only / OOB éventuel
```

Dans Linux, les noms peuvent être :

```text
ens18
ens19
ens20
```

ou :

```text
ens33
ens34
ens35
```

Ils ne sont pas garantis.

---

## Méthode simple

Affichez :

```bash
ip -br link
```

Puis, depuis VMware Workstation :

```text
VM Settings
→ Network Adapter LAB
→ décocher temporairement "Connected"
```

Relancez :

```bash
ip -br link
```

L’interface dont l’état change est votre NIC LAB.

Reconnectez immédiatement la carte.

---

## Méthode avec les MAC

Dans Proxmox :

```bash
ip link
```

Relevez les adresses :

```text
link/ether XX:XX:XX:XX:XX:XX
```

Puis comparez-les aux MAC affichées dans VMware Workstation.

### À retenir

Ne configurez jamais :

```text
ens19
```

simplement parce qu’un camarade possède une interface nommée :

```text
ens19
```

Identifiez votre propre matériel.

---

# 🟢 GUIDÉ — Partie 4 : vérifier l’état initial de vmbr0

Affichez :

```bash
cat /etc/network/interfaces
```

Vous devriez avoir quelque chose ressemblant à :

```text
auto lo
iface lo inet loopback

iface ens18 inet manual

auto vmbr0
iface vmbr0 inet static
    address 192.168.223.10/24
    gateway 192.168.223.2
    bridge-ports ens18
    bridge-stp off
    bridge-fd 0
```

Les valeurs dépendent de votre VMware NAT.

---

# Ce que représente vmbr0

```text
PVE
 │
vmbr0
 │
NIC NAT
 │
VMnet8
 │
VMware NAT
 │
Windows
 │
Internet
```

Pour ce TP :

> **Ne modifiez pas le rôle de vmbr0.**

Il doit continuer à fournir l’accès Internet et la route par défaut.

---

# 🟢 GUIDÉ — Partie 5 : sauvegarder la configuration

Avant toute modification :

```bash
cp /etc/network/interfaces \
   /root/interfaces.before-tp02
```

Vérifiez :

```bash
ls -l /root/interfaces.before-tp02
```

---

# Rollback

Si vous perdez le réseau :

1. ouvrez la **console VMware** ;
2. reconnectez-vous localement ;
3. restaurez :

```bash
cp /root/interfaces.before-tp02 \
   /etc/network/interfaces
```

Puis :

```bash
ifreload -a
```

### Règle

Ne travaillez jamais sur le réseau d’un hyperviseur sans prévoir comment reprendre la main si vous vous coupez l’accès.

---

# 🟢 GUIDÉ — Partie 6 : vérifier la route par défaut

Avant modification :

```bash
ip route
```

Repérez :

```text
default via ...
```

Exemple :

```text
default via 192.168.223.2 dev vmbr0
```

Cette route doit rester présente **après le TP**.

---

# 🟢 GUIDÉ — Partie 7 : configurer la NIC LAB en mode manuel

Supposons que votre interface LAB soit :

```text
ens19
```

Elle doit être configurée sans IP directe :

```text
iface ens19 inet manual
```

L’adresse sera portée par `vmbr1`.

---

# 🟢 GUIDÉ — Partie 8 : créer vmbr1

## Plan d’adressage cours

Pour un groupe `G` :

```text
PVE01 : 10.100.G.11/24
PVE02 : 10.100.G.12/24
PVE03 : 10.100.G.13/24
```

Exemple groupe 3 :

```text
PVE01 : 10.100.3.11/24
PVE02 : 10.100.3.12/24
PVE03 : 10.100.3.13/24
```

---

## Exemple `/etc/network/interfaces` sur PVE01

```text
iface ens19 inet manual

auto vmbr1
iface vmbr1 inet static
    address 10.100.3.11/24
    bridge-ports ens19
    bridge-stp off
    bridge-fd 0
```

PVE02 :

```text
address 10.100.3.12/24
```

PVE03 :

```text
address 10.100.3.13/24
```

---

## ⚠️ Pas de gateway sur vmbr1

N’ajoutez surtout pas :

```text
gateway ...
```

sur `vmbr1`.

La seule route par défaut doit rester sur le réseau Internet/NAT.

---

# 🟢 GUIDÉ — Partie 9 : cas de recette locale Host-Only

Si vous testez seul sur VMware Workstation avec :

```text
VMnet Host-Only : 192.168.56.0/24
```

utilisez :

PVE01 :

```text
iface ens19 inet manual

auto vmbr1
iface vmbr1 inet static
    address 192.168.56.11/24
    bridge-ports ens19
    bridge-stp off
    bridge-fd 0
```

PVE02 :

```text
192.168.56.12/24
```

PVE03 :

```text
192.168.56.13/24
```

Toujours :

```text
gateway : aucune
```

---

# 🟢 GUIDÉ — Partie 10 : appliquer la configuration

Avant :

```bash
cat /etc/network/interfaces
```

Relisez attentivement :

```text
IP
masque
bridge port
gateway
```

Puis :

```bash
ifreload -a
```

> `ifreload` est fourni par `ifupdown2`, utilisé par Proxmox pour appliquer les changements réseau.

---

# 🟢 GUIDÉ — Partie 11 : vérifier vmbr1

```bash
ip -br address show vmbr1
```

Vous devez voir l’adresse LAB du nœud.

Puis :

```bash
ip link show vmbr1
```

Et :

```bash
bridge link
```

Vous devez voir votre NIC LAB rattachée au bridge.

Exemple conceptuel :

```text
ens19
  master vmbr1
```

---

# 🟢 GUIDÉ — Partie 12 : vérifier le routage après modification

```bash
ip route
```

Vous devez maintenant avoir au minimum :

```text
default via <VMWARE_NAT_GATEWAY> dev vmbr0

10.100.G.0/24 dev vmbr1
```

ou en recette locale :

```text
192.168.56.0/24 dev vmbr1
```

---

## Vérification critique

Cette commande :

```bash
ip route show default
```

ne doit pas montrer une route par défaut sur :

```text
vmbr1
```

---

# 🟢 GUIDÉ — Partie 13 : vérifier qu’Internet fonctionne toujours

```bash
ping -c 3 1.1.1.1
```

Puis :

```bash
ping -c 3 download.proxmox.com
```

Si cela ne fonctionne plus juste après la création de `vmbr1`, vérifiez en priorité :

```text
gateway
route par défaut
vmbr0
```

---

# 🟢 GUIDÉ — Partie 14 : tester l’underlay inter-PVE

Depuis PVE01 :

Cours :

```bash
ping -c 3 10.100.G.12
```

Puis :

```bash
ping -c 3 10.100.G.13
```

Recette locale :

```bash
ping -c 3 192.168.56.12
ping -c 3 192.168.56.13
```

---

# Résultat attendu

```text
PVE01 ───── PVE02
  │           │
  └──────── PVE03
```

Tous les nœuds du groupe doivent se joindre sur leur adresse LAB.

---

# 🟢 GUIDÉ — Partie 15 : observer ARP / Neighbor Discovery

Après un ping :

```bash
ip neigh show dev vmbr1
```

Exemple :

```text
10.100.3.12 lladdr 00:0c:29:xx:xx:xx REACHABLE
```

Vous voyez l’association :

```text
IP
 ↓
MAC
```

### Question

À quelle couche du modèle OSI travaille principalement ARP ?

Pourquoi une résolution ARP échouée indique-t-elle souvent un problème plus bas niveau qu’un problème de routage ?

---

# 🟢 GUIDÉ — Partie 16 : observer ICMP avec tcpdump

Sur PVE01 :

```bash
tcpdump -ni vmbr1 icmp
```

Depuis PVE02 :

```bash
ping 10.100.G.11
```

ou l’adresse correspondante du LAB local.

Vous devez observer :

```text
ICMP echo request
ICMP echo reply
```

---

# 🟢 GUIDÉ — Partie 17 : observer les MAC Ethernet

Utilisez :

```bash
tcpdump -eni vmbr1 icmp
```

L’option :

```text
-e
```

affiche les informations Ethernet.

Vous pouvez maintenant voir :

```text
MAC source
MAC destination
IP source
IP destination
```

---

# 🟢 GUIDÉ — Partie 18 : examiner la FDB du bridge

```bash
bridge fdb show br vmbr1
```

La **Forwarding Database** est l’équivalent conceptuel de la table MAC d’un switch.

Un bridge apprend :

```text
MAC source observée
       ↓
port d’entrée
       ↓
entrée FDB
```

---

# 🟢 GUIDÉ — Partie 19 : créer vmbr10

Nous allons aussi créer un réseau purement local au nœud.

Ajoutez :

```text
auto vmbr10
iface vmbr10 inet manual
    bridge-ports none
    bridge-stp off
    bridge-fd 0
```

Appliquez :

```bash
ifreload -a
```

Puis :

```bash
ip link show vmbr10
```

---

# À quoi sert vmbr10 ?

```text
        PVE01
          │
        vmbr10
        /    \
      VM1    VM2
```

`vmbr10` n’a aucun port physique :

```text
bridge-ports none
```

Donc :

```text
VM1 sur PVE01
```

peut communiquer avec :

```text
VM2 sur PVE01
```

si leur configuration IP le permet.

Mais :

```text
VM1 sur PVE01
```

ne peut pas automatiquement communiquer avec :

```text
VM3 sur PVE02
```

via `vmbr10`.

---

# Question importante

Pourquoi deux bridges portant tous les deux le nom :

```text
vmbr10
```

sur PVE01 et PVE02 ne constituent-ils pas automatiquement le même réseau ?

Réponse attendue :

> Parce qu’un Linux Bridge local n’est pas un réseau distribué à lui seul.

Cette limitation prépare les notions de :

```text
VLAN
VXLAN
SDN
```

qui pourront être étudiées plus tard.

---

# ⚠️ TROUBLESHOOTING — vmbr1 est DOWN

Vérifiez :

```bash
ip link show vmbr1
```

Puis :

```bash
ip link show <NIC-LAB>
```

Si la NIC physique/virtuelle est :

```text
DOWN
```

vérifiez VMware :

```text
Network Adapter LAB
☑ Connected
☑ Connect at power on
```

---

# ⚠️ TROUBLESHOOTING — PVE01 ne ping pas PVE02

Commencez par :

```bash
ip -br a
ip route
bridge link
```

Puis :

```bash
ip neigh show dev vmbr1
```

---

## Si vous voyez :

```text
192.168.x.x INCOMPLETE
```

ou :

```text
FAILED
```

le problème est probablement L2.

Vérifiez :

### Recette locale

```text
PVE01 Network Adapter LAB -> même VMnet Host-Only
PVE02 Network Adapter LAB -> même VMnet Host-Only
PVE03 Network Adapter LAB -> même VMnet Host-Only
```

### Cours avec switch

Vérifiez :

```text
VMnet2 bien bridgé sur NIC Ethernet LAB
NIC Windows branchée au bon port switch
ports du groupe dans le bon VLAN access
```

---

# ⚠️ TROUBLESHOOTING — Internet a disparu

Vérifiez :

```bash
ip route
```

Cherchez :

```text
deux routes par défaut
```

ou :

```text
route par défaut via vmbr1
```

Dans notre design, ce serait une erreur.

La gateway doit rester portée par :

```text
vmbr0 / NAT
```

---

# ⚠️ TROUBLESHOOTING — GUI inaccessible

Si vous avez modifié par erreur `vmbr0` :

```text
SSH peut être perdu
GUI peut être perdue
```

Utilisez :

```text
console VMware
```

Puis :

```bash
cp /root/interfaces.before-tp02 \
   /etc/network/interfaces

ifreload -a
```

---

# 🟠 CHALLENGE — simuler la perte du réseau LAB

## En salle

Un membre du groupe débranche temporairement :

```text
le câble Ethernet LAB
```

## En recette locale VMware

Décochez temporairement :

```text
Network Adapter LAB
→ Connected
```

---

## Avant la panne

Lancez :

```bash
ping <PAIR-LAB>
```

et :

```bash
ping 1.1.1.1
```

---

## Pendant la panne

Déterminez ce qui fonctionne encore :

| Fonction | Fonctionne ? | Pourquoi ? |
|---|---:|---|
| Internet PVE | ? | ? |
| `apt update` | ? | ? |
| GUI via réseau NAT | ? | ? |
| ping PVE voisin via vmbr1 | ? | ? |
| vmbr10 local | ? | ? |

### Objectif

Comprendre qu’une panne :

```text
LAB
```

n’implique pas forcément une panne :

```text
Internet
```

car les chemins réseau sont différents.

---

# 🟠 CHALLENGE — diagnostic sans regarder VMware

Le formateur provoque une panne simple.

À l’aide uniquement de :

```bash
ip -br a
ip route
ip neigh
bridge link
bridge fdb show
ping
tcpdump
```

vous devez déterminer si le problème se situe :

```text
L1 / lien
L2 / bridge-MAC
L3 / adressage-route
```

---

# 🔴 EXPERT — comment un bridge apprend-il les MAC ?

Sur PVE01 :

```bash
bridge fdb show br vmbr1
```

Lancez ensuite du trafic vers PVE02 :

```bash
ping <IP-PVE02>
```

Puis relancez :

```bash
bridge fdb show br vmbr1
```

Expliquez le mécanisme :

```text
Frame reçue
   │
   ▼
MAC source observée
   │
   ▼
Association MAC -> port
   │
   ▼
FDB
```

---

# 🔴 EXPERT — flooding

Supposons qu’un bridge reçoive une frame destinée à une MAC inconnue.

Que doit-il faire ?

Expliquez :

```text
Unknown Unicast Flooding
```

Puis comparez avec :

```text
Broadcast
Known Unicast
```

---

# 🔴 EXPERT — STP

Notre LAB utilise :

```text
bridge-stp off
```

Pourquoi est-ce acceptable dans notre topologie simple ?

Imaginez maintenant :

```text
deux liens physiques
entre deux switches
```

sans mécanisme de prévention de boucle.

Que pourrait-il arriver ?

Expliquez :

```text
boucle L2
broadcast storm
MAC flapping
STP
```

---

# Questions obligatoires

## Question 1

Quelle est la différence entre :

```text
NIC physique
Linux Bridge
interface IP
```

?

---

## Question 2

Pourquoi l’adresse IP du PVE est-elle placée sur :

```text
vmbr1
```

et non sur la NIC membre du bridge ?

---

## Question 3

Pourquoi `vmbr1` n’a-t-il pas de gateway ?

---

## Question 4

Pourquoi :

```text
vmbr10 sur PVE01
```

et :

```text
vmbr10 sur PVE02
```

ne sont-ils pas automatiquement reliés ?

---

## Question 5

Quelle commande utilisez-vous pour observer :

```text
table MAC du bridge
```

?

---

## Question 6

Quelle est la différence entre :

```text
ip neigh
```

et :

```text
bridge fdb
```

?

Indice :

```text
IP <-> MAC
```

contre :

```text
MAC <-> port
```

---

# Livrable

Complétez :

```text
deliverables/group-G/TP02.md
```

avec :

## 1. Mapping interfaces

```text
NIC NAT :
NIC LAB :
NIC OOB :
vmbr0 :
vmbr1 :
```

## 2. Plan d’adressage

```text
PVE01 :
PVE02 :
PVE03 :
```

## 3. Routage

Copiez :

```bash
ip route
```

Expliquez la route par défaut.

## 4. Bridge

Copiez :

```bash
bridge link
bridge fdb show br vmbr1
```

## 5. Capture

Ajoutez quelques lignes pertinentes issues de :

```bash
tcpdump -eni vmbr1 icmp
```

## 6. Troubleshooting

Décrivez le résultat du test de panne LAB.

---

# Validation TP02

Vérifiez :

```bash
ip -br address
```

Puis :

```bash
ip route
```

Puis :

```bash
bridge link
```

Le nœud doit avoir :

```text
vmbr0
→ Internet / default route

vmbr1
→ IP LAB
→ aucune gateway
→ NIC LAB attachée

vmbr10
→ bridge local
→ aucun port physique
```

---

## Script

Mode cours :

```bash
sudo ./scripts/proxmox/check-tp02.sh G N
```

Exemple :

```bash
sudo ./scripts/proxmox/check-tp02.sh 3 1
```

Le script attend alors :

```text
10.100.3.11
```

---

## Recette locale avec une IP personnalisée

Vous pouvez fournir explicitement l’IP attendue :

```bash
sudo ./scripts/proxmox/check-tp02.sh 1 1 192.168.56.11
```

Le troisième argument remplace le plan d’adressage standard uniquement pour la recette.

---

# Résultat attendu

```text
[PASS] vmbr0 exists
[PASS] Default route exists and is not on vmbr1
[PASS] vmbr1 exists
[PASS] Expected LAB IP found on vmbr1
[PASS] vmbr1 has a bridge port
[PASS] Internet connectivity OK
[PASS] vmbr10 exists
[PASS] vmbr10 has no physical bridge port

STATUS: READY FOR TP03
```

---

# Ce qu’il faut retenir

Le chemin Internet :

```text
PVE
 │
vmbr0
 │
NIC NAT
 │
VMnet8
 │
Internet
```

est différent du chemin LAB :

```text
PVE
 │
vmbr1
 │
NIC LAB
 │
VMware
 │
Switch / Host-Only
 │
autres PVE
```

Et un Linux Bridge est fondamentalement :

```text
un switch L2 logiciel
```

sur lequel peuvent être connectés :

```text
NIC physique
VM
conteneurs
interfaces du host
```

Le TP03 utilisera `vmbr1` pour construire le cluster Proxmox et Corosync.
