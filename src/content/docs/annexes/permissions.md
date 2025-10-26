---
title: Annexe Permissions
description: Détails techniques du système de permissions
---

## Modèle Logique de Données RBAC

Bien que Better-Auth génère automatiquement les structures du plugin Organization, cette modélisation MLD démontre ma compréhension des patterns RBAC et ma capacité à analyser un système de permissions complexe.

Résolution des associations many-to-many par des tables intermédiaires :

![Modèle Logique de Données](../../../assets/mld-autorization.png)

**Analyse des relations RBAC :**
- **User** appartient à une **Organization** (1,n)
- **User** peut avoir plusieurs **Roles** via la table **Member** (n,n)
- **Role** dispose de plusieurs **Permissions** (n,n)

Les tables `Member` et `RolePermission` matérialisent les associations many-to-many avec index composites sur (`userId`, `organizationId`) et (`roleId`, `permissionId`) pour optimiser les vérifications de permissions.
