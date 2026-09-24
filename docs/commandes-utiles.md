# Commandes utiles

## PVE

```bash
pveversion -v
pvesh get /nodes
systemctl --failed
```

## Réseau

```bash
ip -br a
ip route
ip neigh
bridge link
bridge fdb show
tcpdump -ni vmbr1
```

## VM / LXC

```bash
qm list
qm config <id>
pct list
pct config <id>
```

## Cluster

```bash
pvecm status
pvecm nodes
journalctl -u corosync
```

## Stockage

```bash
pvesm status
lsblk
zpool status
zfs list
zpool iostat -v
```

## Réplication / HA

```bash
pvesr status
ha-manager status
```
