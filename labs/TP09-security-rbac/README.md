# TP09 — RBAC, API token, firewall & exploitation

**Durée : ~1 h 30**

## Mission

Arrêter d'administrer toute la plateforme en `root@pam`.

---

# 1. Créez un opérateur

Créez :

```text
ops-gG@pve
```

Objectif :

```text
voir les VM
console
start
stop
```

Interdictions :

```text
supprimer une VM
créer un cluster
modifier stockage
modifier SDN
administrer les comptes
```

---

## 2. Rôle minimal

Inspectez les privilèges disponibles.

Créez un rôle adapté au besoin au lieu d'utiliser `Administrator`.

Testez avec une nouvelle session navigateur.

---

## 3. Resource Pool

Créez :

```text
POOL-GG-APP
```

Ajoutez les workloads du groupe.

Appliquez les permissions au pool plutôt qu'à `/` lorsque cela est possible.

---

## 4. API token

Créez un token pour un compte d'automatisation :

```text
automation-gG@pve
```

Le token doit avoir moins de privilèges que root.

Ne commitez jamais le secret dans Git.

---

## 5. Premier appel API

Utilisez `curl` ou un outil de votre choix pour lire les ressources du cluster.

Le secret doit être injecté depuis :

```text
variable d'environnement
fichier non versionné
ou secret manager
```

---

# 6. Firewall

Activez le firewall de manière progressive.

Objectif :

- ne pas vous couper de la GUI ;
- protéger un workload ;
- prouver qu'une règle bloque réellement un flux.

Avant activation, documentez :

```text
source d'administration
destination
port
rollback
```

---

# CHALLENGE

Créez un rôle permettant :

```text
VM.Audit
VM.PowerMgmt
```

et seulement les droits supplémentaires strictement nécessaires à votre scénario.

Prouvez qu'une suppression est refusée.

---

# EXPERT

Expliquez :

```text
PAM realm
PVE realm
API token privilege separation
TFA
least privilege
```

Puis proposez une architecture d'accès administrateur pour un datacenter réel.

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp09.sh G
```
