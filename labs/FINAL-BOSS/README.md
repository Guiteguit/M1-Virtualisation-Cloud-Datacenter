# FINAL BOSS — INC-7842 « NovaCorp Datacenter Down »

**Durée : 3 h**

## Situation

08:12.

Le support indique :

```text
L'application NovaCorp est inaccessible.
Une maintenance infrastructure a eu lieu hier soir.
Aucune réinstallation n'est autorisée.
```

Votre groupe prend l'incident.

---

# Règles

Vous ne recevrez pas la liste des pannes.

Interdictions :

```text
réinstaller PVE
supprimer/recréer le cluster
forcer expected votes sans validation formateur
restaurer toute l'infra sans diagnostic
```

Vous pouvez utiliser :

```text
GUI
CLI
logs
packet capture
switch
PBS
documentation
```

---

# Méthode attendue

Pour chaque piste :

```text
SYMPTOME
   |
HYPOTHESE
   |
TEST
   |
PREUVE
   |
CAUSE
   |
CORRECTION
   |
VALIDATION
```

---

# État attendu en sortie

```text
Cluster        : QUORATE
Nœuds attendus : ONLINE ou état justifié
Storage        : HEALTHY
SDN            : APPLIED
web01          : RUNNING
app01          : RUNNING
db01           : RUNNING
Backup         : RESTORABLE
RBAC           : cohérent
```

---

# Livrable

`FINAL-REPORT.md`

Il doit contenir :

## 1. Résumé exécutif

5 à 10 lignes maximum.

## 2. Chronologie

```text
08:12 alerte
08:20 ...
```

## 3. Symptômes

## 4. Causes racines

## 5. Corrections

## 6. Preuves de rétablissement

## 7. Prévention

Exemples :

```text
monitoring
capacity
backup test
network documentation
change management
RBAC
```

---

# Bonus expert

Identifiez également une faiblesse de conception qui n'est PAS la cause immédiate de l'incident.

Exemple de catégories :

```text
SPOF
partage du réseau Corosync
RPO
gestion des secrets
surallocation
absence de supervision
```
