# FINAL BOSS — INC-7842 « NovaCorp indisponible »

**Durée : 1 h 30.**

08:12 : l'application NovaCorp est inaccessible après une maintenance infrastructure.

Votre groupe doit restaurer le service **sans recevoir la liste des pannes**.

## Règles

Interdit sans accord formateur :

- réinstaller PVE ;
- recréer le cluster ;
- forcer le quorum ;
- tout restaurer « au hasard » sans diagnostic.

## Méthode attendue

```text
SYMPTÔME
   ↓
HYPOTHÈSE
   ↓
TEST
   ↓
PREUVE
   ↓
CAUSE
   ↓
CORRECTION
   ↓
VALIDATION
```

## Livrable

Compléter `deliverables/group-G/FINAL-REPORT.md` avec :

1. impact ;
2. timeline ;
3. symptômes ;
4. hypothèses testées ;
5. causes racines ;
6. corrections ;
7. preuves du retour au service ;
8. deux actions préventives.

## État attendu

```text
cluster : cohérent / quorum OK
stockage : healthy
web01 : running
backup : restaurable
RBAC : cohérent
application : accessible
```
