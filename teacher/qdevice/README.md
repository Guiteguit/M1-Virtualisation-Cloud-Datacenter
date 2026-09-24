# QNetd central — formateur

Un QNetd externe peut servir les groupes de deux nœuds.

## Debian

```bash
apt update
apt install corosync-qnetd
systemctl status corosync-qnetd
```

Le serveur doit être joignable depuis les underlays concernés.

Sur chaque PVE du groupe :

```bash
apt install corosync-qdevice
```

Puis une seule fois :

```bash
pvecm qdevice setup <IP-QNETD>
```

## Principe pédagogique

Le QNetd doit être indépendant des deux PC qui constituent le cluster deux nœuds.

Éviter :

```text
PC ETU1
 + PVE01
 + QNETD
```

car une panne du PC ferait disparaître simultanément un nœud et le témoin.
