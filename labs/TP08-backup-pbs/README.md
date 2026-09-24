# TP08 — Backup, restauration & Proxmox Backup Server

**Durée : ~1 h 30**

## Mission

Prouver qu'une sauvegarde est restaurable.

---

## 1. Rappels

Expliquez :

```text
RPO
RTO
backup
snapshot
replication
HA
```

Ils ne sont pas interchangeables.

---

## 2. PBS

L'enseignant vous fournit :

```text
Adresse PBS
Datastore
Utilisateur/token
Fingerprint si nécessaire
```

Ajoutez le stockage PBS au cluster.

Vérifiez :

```bash
pvesm status
```

---

## 3. Sauvegardez VM111

Lancez un backup de `web01`.

Observez :

```text
task log
durée
volume transféré
état final
```

---

## 4. Incident

L'enseignant valide la sauvegarde.

Ensuite :

```text
STOP VM111
SUPPRESSION VM111
```

Vous devez maintenant restaurer le service.

---

## 5. Restauration

Restaurez VM111.

Vérifiez :

```bash
qm config 111
qm status 111
```

Puis :

```text
IP correcte
VNet correct
service accessible
```

---

## 6. Rétention

Proposez une politique :

```text
keep-last
keep-daily
keep-weekly
keep-monthly
```

Justifiez-la pour :

```text
petite PME
service critique
budget stockage limité
```

---

# CHALLENGE

Effectuez une seconde sauvegarde après modification de la VM.

Comparez avec la première.

Expliquez déduplication et incrémental côté PBS.

---

# EXPERT

Dessinez une stratégie 3-2-1 réaliste incluant :

```text
cluster PVE
PBS local
copie hors site
```

---

## Validation

```bash
sudo ./scripts/proxmox/check-tp08.sh
```
