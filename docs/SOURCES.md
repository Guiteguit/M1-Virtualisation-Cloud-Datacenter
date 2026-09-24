# Sources techniques de référence

Documentation à consulter / citer dans les supports de cours :

- Proxmox VE Administration Guide 9.x
- Proxmox SDN documentation (`pvesdn`)
- Proxmox Cluster Manager (`pvecm`)
- Proxmox Storage Replication (`pvesr`)
- Proxmox Backup Server documentation
- Broadcom VMware Workstation Virtual Network Editor
- Broadcom nested VT-x/EPT / VBS troubleshooting

## Décisions de conception du LAB

### Cluster avant guests

Les nœuds à joindre au cluster restent vides jusqu'au TP03.

### Underlay access

Les ports PC sont en access/untagged pour ne pas dépendre du passage 802.1Q à travers Windows + VMware Workstation.

### Overlay VXLAN

Les réseaux workload sont étendus entre PVE via VXLAN à partir du TP07.

### ZFS local

Les deux disques VMware additionnels servent à apprendre le miroir, snapshot, scrub et réplication.

Ce design est pédagogique et ne remplace pas une recommandation de sizing production.
