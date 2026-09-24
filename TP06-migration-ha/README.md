# TP06 — Migration, réplication ZFS & HA

## Mission

Déplacer un workload entre deux PC physiques puis préparer son redémarrage automatique en cas de panne.

## 🟢 GUIDÉ — migration

Effectuer une migration offline puis une migration online de `web01` vers un autre PVE.

Pendant la migration :

```bash
ping <IP-web01>
tcpdump -ni vmbr1
```

Noter les coupures et le trafic observé.

## 🟢 GUIDÉ — réplication

Créer un job de réplication ZFS de `web01` vers un autre nœud et observer :

```bash
pvesr status
```

## HA

Lorsque la réplication est à jour, ajouter `web01` à HA :

```bash
ha-manager status
```

Le test de panne réelle se fait uniquement après validation du formateur.

## 🟠 CHALLENGE

Mesurer : temps de détection de la panne, temps de redémarrage, durée totale avant retour du service.

## Questions

- migration = HA ?
- réplication = backup ?
- quel RPO peut induire une réplication asynchrone ?

## 🔴 EXPERT

Étudier un prolongement : second lien Corosync, Ceph ou Dynamic Load Balancer.

## Validation

```bash
sudo ./scripts/proxmox/check-tp06.sh
```
