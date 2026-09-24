# TP07 — PBS, restauration & sécurité

## Mission

Prouver qu'une sauvegarde est restaurable puis réduire les privilèges d'administration.

## Partie A — Proxmox Backup Server

Ajouter le PBS fourni par le formateur puis sauvegarder `web01`.

Après validation de la sauvegarde :

```text
STOP web01
DELETE web01
```

Restaurer et prouver que le service revient.

Définir une petite politique de rétention et expliquer RPO/RTO.

## Partie B — RBAC

Créer :

```text
ops-gG@pve
POOL-GG-APP
```

L'opérateur doit pouvoir voir/démarrer/arrêter les VMs du pool sans pouvoir supprimer une VM ni administrer le cluster.

Créer ensuite un compte/token d'automatisation à privilèges minimaux. **Le secret ne doit jamais être commité.**

## 🟠 CHALLENGE

Prouver avec une seconde session que la suppression d'une VM est refusée à l'opérateur.

## 🔴 EXPERT

Proposer une architecture d'accès administrateur réelle : comptes nominatifs, TFA, bastion/VPN, secrets, logs.

## Validation

```bash
sudo ./scripts/proxmox/check-tp07.sh G
./scripts/security/check-secrets.sh
```
