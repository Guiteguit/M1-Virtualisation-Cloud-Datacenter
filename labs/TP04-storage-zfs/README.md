# TP04 — Stockage, LVM-thin & ZFS

**Durée : ~1 h 30**

## Mission

Construire un stockage ZFS local identique sur chaque nœud du cluster.

---

## 1. Inventaire

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
pvesm status
cat /etc/pve/storage.cfg
```

Retrouvez les deux disques de ~20 Go ajoutés dans VMware.

### Règle

Ne copiez jamais `/dev/sdb` depuis le PC voisin sans vérifier.

Préférez l'identification stable :

```bash
ls -l /dev/disk/by-id/
```

---

## 2. Créez le pool

Exemple :

```bash
zpool create tank mirror <DISK1> <DISK2>
```

Puis :

```bash
zpool status
zfs list
```

Activez la compression :

```bash
zfs set compression=lz4 tank
zfs get compression tank
```

---

## 3. Répétez sur chaque nœud

Tous les nœuds doivent avoir un pool local nommé :

```text
tank
```

Ce sont des pools différents qui portent le même nom.

---

## 4. Enregistrez dans Proxmox

Une fois `tank` présent partout :

```bash
pvesm add zfspool zfs-lab \
  --pool tank \
  --content images,rootdir \
  --sparse 1
```

La configuration étant cluster-wide, ne lancez cette commande qu'une fois.

Vérifiez depuis les autres nœuds :

```bash
pvesm status
```

---

## 5. Snapshot ZFS natif

```bash
zfs create tank/tp04
echo "version1" > /tank/tp04/demo.txt
zfs snapshot tank/tp04@before
echo "version2" > /tank/tp04/demo.txt
cat /tank/tp04/demo.txt
```

Rollback :

```bash
zfs rollback tank/tp04@before
cat /tank/tp04/demo.txt
```

---

## 6. Simulation d'incident

Choisissez l'un des deux disques :

```bash
zpool status
```

Puis :

```bash
zpool offline tank <DISK>
```

Observez :

```bash
zpool status
```

Le pool doit passer en état dégradé mais rester disponible.

Remettez le disque :

```bash
zpool online tank <DISK>
zpool scrub tank
zpool status
```

---

# Questions

1. RAID1/ZFS mirror est-il une sauvegarde ?
2. Snapshot est-il une sauvegarde ?
3. Pourquoi un pool plein est-il dangereux pour les guests ?
4. Pourquoi `storage.cfg` est-il visible sur tous les nœuds alors que `tank` est local ?

---

# CHALLENGE

Comparez :

```text
local
local-lvm
zfs-lab
```

en termes de :

```text
type
contenu
snapshot
thin provisioning
partagé ou local
```

---

# EXPERT

Analysez :

```bash
zpool iostat -v
zfs get all tank | grep -E 'compression|compressratio|recordsize'
```

Expliquez ARC, Copy-on-Write et scrub.

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp04.sh
```
