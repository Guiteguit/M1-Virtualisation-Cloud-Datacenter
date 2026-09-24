# Final Boss — guide formateur

## Sélection

Injecter 3 à 5 pannes selon le groupe.

Ne pas injecter toutes les pannes disponibles.

## Catalogue

### A — Switch

Déplacer le port de PVE02 vers le VLAN d'un autre groupe.

**Effet :** PVE02 perd l'underlay, Corosync et VXLAN.

### B — VNet

Modifier le bridge réseau de VM111 pour la placer sur le mauvais VNet.

**Effet :** VM running mais service réseau inaccessible.

### C — MTU

Mettre une MTU incohérente sur un workload VXLAN.

**Effet :** petits paquets possibles, certains flux dégradés.

### D — Stockage

Laisser plusieurs snapshots et créer une pression espace raisonnable.

Ne jamais remplir volontairement le pool jusqu'à corruption.

### E — Backup/restore

Supprimer VM111 après validation d'une sauvegarde PBS.

### F — Quorum groupe 2

Rendre QNetd momentanément inaccessible puis provoquer une perte d'un membre uniquement si le scénario a été testé.

### G — RBAC

Retirer un privilège nécessaire à l'opérateur.

### H — Default route

Ajouter une route par défaut erronée sur un nœud, avec rollback préparé.

## Déroulé

### T0

Remettre l'énoncé uniquement.

### T+30

Si groupe bloqué : donner une information factuelle, jamais la cause.

### T+90

Demander un point de situation type incident manager :

```text
impact
hypothèses
preuves
actions en cours
risque
```

### Fin

Ils doivent présenter la cause racine, pas seulement montrer que le ping répond.
