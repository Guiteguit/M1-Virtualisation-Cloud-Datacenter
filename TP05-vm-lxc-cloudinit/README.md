# TP05 — VM, LXC, Template & Cloud-Init

## Mission

Comparer VM et LXC puis arrêter les installations manuelles grâce à un template Cloud-Init.

## Partie A — VM vs LXC

Créer :

```text
VM 110 : labvm01, 1 vCPU, 1 Go RAM, 8 Go, vmbr10
CT 210 : labct01, 1 vCPU, 512 Mo RAM, 4 Go, vmbr10, unprivileged
```

Comparer : kernel, mémoire, démarrage, isolation, usage.

## Partie B — Template

Créer un template `9000` depuis une image cloud Debian 13 :

```bash
qm create 9000 --name debian13-cloud --memory 1024 --cores 1 --net0 virtio,bridge=vmbr10
qm importdisk 9000 <IMAGE.qcow2> zfs-lab
```

Attacher disque + Cloud-Init, configurer serial/QEMU Guest Agent, puis :

```bash
qm template 9000
```

Créer :

```text
111 web01
121 app01
131 db01
```

## 🟠 CHALLENGE

Recréer `app01` en CLI uniquement avec nom, IP et clé SSH injectés par Cloud-Init.

## 🔴 EXPERT

Expliquer full clone, linked clone, golden image, Cloud-Init et ce qu'il manque pour parler d'IaC.

## Validation

```bash
sudo ./scripts/proxmox/check-tp05.sh
```
