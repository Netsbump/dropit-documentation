---
title: Architecture technique
description: Détails techniques d'implémentation de l'architecture DropIt - packages partagés, justifications et exemples de code
---

### Approches alternatives

Pour assurer la cohérence des types entre applications, j'ai comparé trois approches :

**Duplication des types** : Redéfinir dans chaque app - simple mais nécessite synchronisation manuelle.

**Package NPM publié** : Centralisation mais complexité de versioning/publication qui ralentit le développement.

**Monorepo avec packages internes** : Approche retenue - mutualisation sans versioning externe, propagation instantanée des modifications.

## @dropit/contract : Contrats API typés

Ce package centralise la définition de toute l'API REST sous forme de contrats typés grâce à **ts-rest**, un outil **TypeScript** qui permet de définir des APIs type-safe.

Cette approche définit une seule fois chaque endpoint avec ses schémas de validation Zod, et ce contrat devient la source de vérité partagée entre le serveur et tous les clients. Cette centralisation apporte plusieurs bénéfices comme les types TypeScript auto-générés, la validation en amont côté client avant l'appel réseau (évitant des requêtes inutiles), la détection des divergences à la compilation, ou encore l'auto-complétion IDE des paramètres disponibles.

```typescript
// Exemple de contrat pour la gestion des athlètes
export const athleteContract = {
  getAthletes: {
    method: 'GET',
    path: '/athlete',
    summary: 'Get all athletes',
    responses: {
      200: z.array(athleteDetailsSchema),
      404: z.object({ message: z.string() })
    }
  },
  createAthlete: {
    method: 'POST',
    path: '/athlete',
    body: createAthleteSchema,
    responses: {
      201: athleteSchema,
      400: z.object({ message: z.string() })
    }
  }
}
```

Toute modification du contrat se répercute automatiquement sur tous les clients, garantissant la cohérence.

## @dropit/schemas : Validation centralisée avec Zod

Les schémas de validation sont centralisés avec Zod. Au lieu de définir des validations séparées côté client et serveur, Zod permet de définir une seule fois les règles et de les réutiliser partout.

```typescript
export const createAthleteSchema = z.object({
  firstName: z.string(),
  lastName: z.string(),
  birthday: z.string().or(z.date()),
  country: z.string().optional(),
});

export const athleteDetailsSchema = z.object({
  id: z.string(),
  firstName: z.string(),
  lastName: z.string(),
  email: z.string().email(),
  personalRecords: z.object({
    snatch: z.number().optional(),
    cleanAndJerk: z.number().optional(),
  }).optional(),
});

export type AthleteDetailsDto = z.infer<typeof athleteDetailsSchema>;
```

Ces schémas servent pour la validation client ( formulaires React), serveur (NestJS) et contrats API, garantissant une cohérence complète.

## @dropit/permissions : Contrôle d'accès granulaire

Ce package implémnte un système d'autorisation centralisé avec Better Auth définissant les permissions par rôle. Les mêmes règles s'appliquent côté client (UX) et serveur (sécurité).

Côté React, les contrôles d'accès servent principalement à améliorer l'expérience utilisateur en masquant les boutons ou sections non autorisés. Côté API, les contrôles constituent une barrière de sécurité critique qui empêche l'accès non autorisé aux données, indépendamment de ce qui est affiché côté client.

```typescript
// Exemple simplifié de définition des rôles
export const member = ac.newRole({
  athlete: ["read", "create", "update"], // Peut gérer ses données
  session: ["read"], // Lecture seule des sessions
  personalRecord: ["read", "create"], // Peut créer ses records
});

export const admin = ac.newRole({
  // Permissions complètes sur toutes les ressources métier
  workout: ["read", "create", "update", "delete"],
  athlete: ["read", "create", "update", "delete"],
  trainingSession: ["read", "create", "update", "delete"],
});
```

## @dropit/i18n : Internationalisation partagée

Ce package centralise tous les textes pour la traduction multilingue et l'externalisation du contenu. Cette source de vérité unique facilitant la maintenance. Elle est structurée par domaines métier :

```typescript
// Configuration i18next partagée
export const resources = {
  fr: {
    common: frCommon,
    athletes: frAthletes,
    planning: frPlanning,
    auth: frAuth,
  },
  en: {
    common: enCommon,
    athletes: enAthletes,
    planning: enPlanning,
    auth: enAuth,
  },
};
```

Couvre tous les aspects : authentification, gestion athlètes, planification, garantissant une expérience cohérente.

## Gestion des dépendances et sécurité

L'utilisation de bibliothèques externes à travers le monorepo (frontend, backend, packages partagés) nécessite une surveillance des mises à jour et vulnérabilités de sécurité.

### Audit automatisé des vulnérabilités

J'ai mis en place un système d'audit automatique via GitHub Actions qui exécute `pnpm audit` à chaque push et de manière hebdomadaire. Cette vérification détecte les vulnérabilités connues dans l'arbre de dépendances et génère des alertes par email en cas de faille critique. GitHub Security Advisories complète ce dispositif en surveillant automatiquement le repository et en proposant des pull requests de correction pour les vulnérabilités détectées.

### Surveillance des mises à jour

Pour les bibliothèques critiques (React, NestJS, MikroORM, PostgreSQL driver), je surveille également les annonces de sécurité via leurs canaux officiels (Twitter, newsletters, GitHub releases). Cette veille proactive me permet d'anticiper les migrations importantes et de planifier les mises à jour selon leur criticité.

### Stratégie de mise à jour

Dans le contexte d'un monorepo, une vulnérabilité dans un package partagé impacte potentiellement toutes les applications. Cette centralisation présente l'avantage de pouvoir corriger une faille en un seul endroit, mais nécessite une coordination des tests sur l'ensemble de l'écosystème avant déploiement.

Cette approche préventive de la sécurité des dépendances s'inscrit dans une démarche de développement responsable, particulièrement importante dans un contexte applicatif gérant des données personnelles d'athlètes.
