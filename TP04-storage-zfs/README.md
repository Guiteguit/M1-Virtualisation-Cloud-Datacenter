# TP04 — Stockage, LVM-thin & ZFS

## Mission

Construire un miroir ZFS local, provoquer une dégradation contrôlée et distinguer snapshot, réplication et sauvegarde.

## 🟢 GUIDÉ

Identifier les deux disques :

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
ls -l /dev/disk/by-id/
```

Créer `tank` en mirror avec les deux bons disques :

```bash
zpool create tank mirror <DISK1> <DISK2>
zfs set compression=lz4 tank
zpool status
zfs list
```

Enregistrer `zfs-lab` dans Proxmox.

Tester snapshot / rollback sur un dataset de test.

Incident disque :

```bash
zpool offline tank <DISK>
zpool status
zpool online tank <DISK>
zpool scrub tank
```

## Questions

- RAID = backup ?
- snapshot = backup ?
- pourquoi un pool presque plein est-il problématique ?

## 🟠 CHALLENGE

Comparer `local`, `local-lvm`, `zfs-lab`.

## 🔴 EXPERT

```bash
zpool iostat -v
zfs get compression,compressratio,recordsize tank
```

Expliquer CoW, ARC et scrub.

## Validation

```bash
sudo ./scripts/proxmox/check-tp04.sh
```
