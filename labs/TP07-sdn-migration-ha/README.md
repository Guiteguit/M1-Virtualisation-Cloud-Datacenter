# TP07 — SDN/VXLAN, migration, réplication & HA

**Durée : 2 h 30 à 3 h au total**

C'est le cœur avancé du cours.

---

# PARTIE A — Construire l'overlay VXLAN

## 1. Zone

Dans :

```text
Datacenter -> SDN -> Zones
```

créez une zone VXLAN.

Pour groupe 3 :

```text
ID    : vxg03
Peers : 10.100.3.11,10.100.3.12,10.100.3.13
MTU   : 1450
```

Groupe de 2 : uniquement `.11` et `.12`.

---

## 2. VNets

Créez :

```text
VNet srv03
Zone vxg03
Tag  10003
```

et :

```text
VNet dmz03
Zone vxg03
Tag  20003
```

Adaptez `03` au groupe.

Cliquez **Apply** dans SDN.

---

## 3. Vérifiez sur chaque nœud

```bash
ip -d link | grep -A3 -i vxlan
ip link show
```

Retrouvez le VNet sous forme d'interface/bridge local.

---

## 4. Raccordez les workloads

```text
web01 -> srvG
app01 -> srvG
db01  -> srvG
```

IP :

```text
web01 10.20.G.11/24
app01 10.20.G.12/24
db01  10.20.G.13/24
```

MTU guest :

```text
1450
```

Aucune gateway n'est nécessaire pour les tests L2 du TP.

---

## 5. Test inter-PC

Depuis web01 :

```bash
ping 10.20.G.12
ping 10.20.G.13
```

Les VMs doivent communiquer même si elles sont hébergées sur des PC physiques différents.

---

## 6. Observez VXLAN

Sur le PVE source :

```bash
tcpdump -ni vmbr1 udp port 4789
```

Puis faites générer du trafic entre deux VMs.

Questions :

1. Quelles IP voyez-vous à l'extérieur ?
2. Où sont les IP 10.20.G.X ?
3. Pourquoi l'underlay n'a-t-il aucune route vers 10.20.G.0/24 ?

---

# PARTIE B — Migration

## 7. Offline migration

Arrêtez VM111 et migrez-la vers PVE02.

Vérifiez :

```bash
qm config 111
```

et l'emplacement du guest dans la GUI.

---

## 8. Live migration

Démarrez VM111.

Depuis un autre guest :

```bash
ping 10.20.G.11
```

Lancez ensuite une live migration vers un autre PVE.

Observez :

```bash
tcpdump -ni vmbr1
```

et notez le nombre de pertes ICMP.

---

# PARTIE C — Réplication ZFS

Le stockage `zfs-lab` est local.

Créez un job de réplication de VM111 vers un autre nœud :

```bash
pvesr create-local-job 111-0 <TARGET-NODE> \
  --schedule "*/5"
```

Vérifiez :

```bash
pvesr status
```

### Question

Pourquoi la réplication réduit-elle le temps d'une migration future ?

---

# PARTIE D — Haute disponibilité

## Précondition

VM111 doit disposer de ses données sur un stockage accessible/reconstructible sur le nœud cible.

Dans ce LAB, utilisez la réplication ZFS.

Ajoutez VM111 à HA via la GUI.

Vérifiez :

```bash
ha-manager status
```

---

## Incident contrôlé

Après validation enseignant :

1. assurez-vous que la réplication est à jour ;
2. notez l'heure ;
3. coupez brutalement le PVE hébergeant VM111 depuis VMware Workstation ;
4. observez le cluster depuis un autre nœud.

Mesurez :

```text
détection panne
perte de quorum éventuelle
redémarrage VM
retour du ping
```

### Groupe de 2

Ne faites le test qu'avec QDevice fonctionnel.

---

# Questions

1. Live migration = HA ?
2. Réplication = backup ?
3. Quel est le RPO potentiel d'une réplication asynchrone ?
4. Pourquoi Corosync et migration ne devraient-ils idéalement pas partager un lien saturé ?
5. Que se passe-t-il si le nœud est isolé mais continue physiquement à fonctionner ?

---

# CHALLENGE

Créez un workload DMZ sur `dmzG`.

Vérifiez qu'il ne partage pas le même domaine L2 que `srvG`.

---

# EXPERT

Étudiez l'un des sujets suivants :

```text
Dynamic Load Balancer PVE 9.2
EVPN
WireGuard SDN Fabric
second lien Corosync
Ceph
```

Produisez un mini schéma d'architecture plutôt qu'un simple copier-coller documentaire.

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp07.sh G
```
