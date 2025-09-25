---
title: Architecture technique
description: Détails techniques d'implémentation de l'architecture DropIt - packages partagés, justifications et exemples de code
---

## Packages partagés - Détails d'implémentation

Cette section présente les détails techniques d'implémentation des packages partagés mentionnés dans l'[architecture logicielle](/conception/architecture#packages-partagés).

### Justification des approches alternatives

Pour assurer la cohérence des types et de la logique métier entre les différentes applications, plusieurs approches étaient envisageables.

**Option 1 - Duplication des types** : Redéfinir les types dans chaque application (web, mobile, API). Cette approche fonctionne parfaitement pour un développeur unique qui maîtrise l'ensemble du code. L'inconvénient principal réside dans la redondance : chaque modification d'un modèle `Athlete` côté API nécessite de répliquer manuellement les changements côté web et mobile. C'est fastidieux mais gérable. Dans une équipe avec des développeurs spécialisés frontend/backend, cette approche ralentirait davantage le développement en nécessitant une coordination constante.

**Option 2 - Package NPM publié** : Publier un package `@dropit/shared-types` sur le registre NPM. Cette solution fonctionne bien pour des projets open-source mais introduit une complexité de versioning et de publication qui ralentit le développement. Chaque modification nécessite une nouvelle version, un cycle de publication, puis une mise à jour dans chaque application consommatrice.

**Option 3 - Monorepo avec packages internes** : Cette approche que j'ai retenue mutualise la logique commune via des packages partagés sans les inconvénients du versioning externe. Les modifications se propagent instantanément à toutes les applications grâce aux liens symboliques, accélérant considérablement les cycles de développement.

L'architecture monorepo résout ces problématiques en centralisant les préoccupations transversales tout en préservant l'indépendance des applications. Cette approche garantit la cohérence technique sans compromettre la vélocité de développement.

## @dropit/contract : Contrats API typés

Ce package centralise la définition de toute l'API REST sous forme de contrats typés grâce à **ts-rest**, un outil **TypeScript** qui permet de définir des APIs type-safe.

Sans cet outil, j'aurais dû maintenir manuellement la cohérence entre les endpoints NestJS côté serveur et les appels API côté clients. L'approche classique consiste à définir les types TypeScript des requêtes et réponses de chaque côté, ce qui fonctionne mais demande une synchronisation constante lors des évolutions.

ts-rest résout cette problématique en adoptant une approche "contract-first". Je définis une seule fois chaque endpoint avec ses schémas de validation Zod, et ce contrat devient la source de vérité partagée entre le serveur et tous les clients. Cette centralisation apporte plusieurs bénéfices immédiats : les types TypeScript sont générés automatiquement pour les requêtes et réponses, la validation Zod s'exécute côté client avant l'appel réseau (évitant des requêtes inutiles), toute divergence entre contrat et implémentation provoque une erreur TypeScript à la compilation, et l'IDE propose automatiquement l'auto-complétion des paramètres disponibles.

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

Cette approche élimine les divergences entre frontend et backend : toute modification du contrat se répercute automatiquement sur tous les clients, garantissant la cohérence des types et réduisant les erreurs d'intégration.

## @dropit/schemas : Validation centralisée avec Zod

L'ensemble des schémas de validation sont centralisés dans ce package grâce à Zod, une solution TypeScript de validation de données à l'exécution.

Traditionnellement, j'aurais dû définir des règles de validation séparées côté client (pour les formulaires React) et côté serveur (pour l'API NestJS), avec le risque d'incohérences entre ces validations. Zod me permet de définir une seule fois les règles de validation sous forme de schémas TypeScript, puis de les réutiliser partout où c'est nécessaire.

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

Ces schémas sont utilisés à la fois pour la validation côté client (formulaires React), la validation côté serveur (NestJS), et la définition des contrats API. Cette triple utilisation garantit une cohérence parfaite des règles de validation.

## @dropit/permissions : Contrôle d'accès granulaire

Ce package implémente un système d'autorisation centralisé qui définit précisément les permissions selon les rôles utilisateurs.

Sans centralisation, j'aurais dû gérer les autorisations séparément côté client et côté serveur, avec des enjeux différents selon le contexte. Côté React, les contrôles d'accès servent principalement à améliorer l'expérience utilisateur en masquant les boutons ou sections non autorisés. Côté API, les contrôles constituent une barrière de sécurité critique qui empêche l'accès non autorisé aux données, indépendamment de ce qui est affiché côté client.

Le package utilise Better Auth pour définir un système de permissions où chaque rôle dispose d'actions spécifiques sur des ressources métier définies. Un membre peut gérer ses propres données d'athlète mais ne peut que consulter ses séances, tandis qu'un administrateur dispose d'un contrôle complet sur toutes les ressources. Cette approche garantit que les mêmes règles s'appliquent pour l'affichage côté client et la sécurisation côté serveur. La section [Sécurité et autorisation](/securite/autorisation) détaille en profondeur ce système.

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

Ce package centralise tous les textes de l'application, répondant à un double objectif : permettre la traduction multilingue et externaliser les contenus textuels du code.

Au-delà de la simple traduction français/anglais, cette approche évite la dispersion des textes directement dans les composants React. Sans centralisation, modifier un libellé comme "Créer un programme" nécessiterait de parcourir potentiellement plusieurs fichiers pour trouver toutes ses occurrences. Le système i18n devient une source de vérité unique pour tous les contenus textuels, facilitant leur maintenance et leur évolution.

Le package structure les traductions par domaines métier :

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

Les traductions couvrent tous les aspects de l'application : authentification, gestion des athlètes, planification des séances, processus d'accueil. Cette approche centralisée facilite la maintenance des traductions et garantit une expérience utilisateur cohérente sur toutes les plateformes.

## @dropit/tsconfig : Configuration TypeScript unifiée

Ce package fournit la configuration TypeScript de base dont héritent toutes les applications du monorepo.

Sans cette centralisation, chaque application (web, mobile, API) définirait ses propres règles TypeScript, avec le risque que du code valide dans une application provoque des erreurs dans une autre. Cette situation complique le partage de code entre applications et peut créer des incohérences lors du développement.

La configuration de base définit les règles strictes communes (`strict: true`, `strictNullChecks: true`) qui garantissent un typage rigoureux à travers tout l'écosystème. Chaque application peut ensuite étendre cette base avec ses spécificités : le client web ajoute les configurations Vite pour les ES modules, l'API NestJS adapte pour CommonJS, et l'application mobile intègre les spécificités React Native.

```json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "noImplicitReturns": true,
    "forceConsistentCasingInFileNames": true,
    "skipLibCheck": true
  }
}
```

Cette approche garantit que les packages partagés respectent les mêmes standards de qualité de code tout en laissant chaque application adapter les détails techniques selon son environnement d'exécution.

## Structure complète du monorepo

L'organisation finale du projet DropIt :

```
dropit/
├── apps/                          # Applications principales
│   ├── web/                       # Interface web React/TypeScript
│   │   ├── src/
│   │   │   ├── features/          # Modules métier (athletes, exercises, workout, planning)
│   │   │   ├── shared/            # Composants UI, hooks et utilitaires partagés
│   │   │   ├── lib/               # Configuration des clients (API, auth)
│   │   │   └── routes/            # Structure de routage Tanstack Router
│   │   ├── package.json           # Dépendances spécifiques au web
│   │   ├── vite.config.ts         # Configuration Vite
│   │   └── tailwind.config.js     # Configuration Tailwind CSS
│   ├── mobile/                    # Application mobile React Native/Expo
│   │   ├── src/
│   │   │   ├── components/        # Composants React Native
│   │   │   └── lib/               # Configuration clients mobiles
│   │   ├── assets/                # Ressources natives (icônes, splash screens)
│   │   ├── app.json               # Configuration Expo
│   │   ├── App.tsx                # Point d'entrée mobile
│   │   └── package.json           # Dépendances React Native/Expo
│   └── api/                       # Backend NestJS
│       ├── src/
│       │   ├── modules/           # Modules métier NestJS
│       │   ├── common/            # Utilitaires et middlewares partagés
│       │   └── config/            # Configuration application
│       ├── package.json           # Dépendances backend
│       └── nest-cli.json          # Configuration NestJS CLI
├── packages/                      # Packages partagés entre applications
│   ├── contract/                  # Contrats d'API typés avec ts-rest
│   │   ├── src/api/               # Définitions des endpoints
│   │   ├── index.ts               # Export principal des contrats
│   │   └── package.json           # Configuration du package
│   ├── schemas/                   # Schémas de validation Zod
│   │   ├── src/                   # Schémas métier (User, Workout, Exercise)
│   │   ├── index.ts               # Export des schémas
│   │   └── package.json           # Configuration Zod
│   ├── permissions/               # Système de rôles et permissions
│   │   ├── src/                   # Définition des rôles et contrôles d'accès
│   │   ├── index.ts               # Export des permissions
│   │   └── package.json           # Configuration des permissions
│   ├── i18n/                      # Internationalisation partagée
│   │   ├── locales/               # Fichiers de traduction (fr, en)
│   │   ├── index.ts               # Configuration i18next
│   │   └── package.json           # Configuration i18n
│   └── tsconfig/                  # Configurations TypeScript partagées
│       ├── base.json              # Configuration TypeScript de base
│       ├── nextjs.json            # Config spécifique React
│       ├── react-native.json      # Config spécifique React Native
│       └── package.json           # Configuration du package
├── package.json                   # Configuration racine du monorepo
├── pnpm-workspace.yaml           # Définition des workspaces pnpm
├── pnpm-lock.yaml                # Verrouillage des dépendances
├── biome.json                     # Configuration du linter/formatter
├── docker-compose.yml            # Services de développement (PostgreSQL, Redis, MinIO)
└── README.md                     # Documentation du projet
```

Cette architecture monorepo centralise la logique commune et garantit la cohérence des types à travers l'ensemble des applications.

## Gestion des dépendances et sécurité

L'utilisation de bibliothèques externes à travers le monorepo (frontend, backend, packages partagés) nécessite une surveillance des mises à jour et vulnérabilités de sécurité.

### Audit automatisé des vulnérabilités

J'ai mis en place un système d'audit automatique via GitHub Actions qui exécute `pnpm audit` à chaque push et de manière hebdomadaire. Cette vérification détecte les vulnérabilités connues dans l'arbre de dépendances et génère des alertes par email en cas de faille critique. GitHub Security Advisories complète ce dispositif en surveillant automatiquement le repository et en proposant des pull requests de correction pour les vulnérabilités détectées.

### Surveillance des mises à jour

Pour rester informé des évolutions importantes, j'ai configuré Dependabot sur le repository GitHub qui propose automatiquement des pull requests pour les mises à jour de dépendances. Cette approche me permet de tester et valider chaque mise à jour dans un environnement contrôlé avant déploiement.

Pour les bibliothèques critiques (React, NestJS, MikroORM, PostgreSQL driver), je surveille également les annonces de sécurité via leurs canaux officiels (Twitter, newsletters, GitHub releases). Cette veille proactive me permet d'anticiper les migrations importantes et de planifier les mises à jour selon leur criticité.

### Stratégie de mise à jour

Dans le contexte d'un monorepo, une vulnérabilité dans un package partagé impacte potentiellement toutes les applications. Cette centralisation présente l'avantage de pouvoir corriger une faille en un seul endroit, mais nécessite une coordination des tests sur l'ensemble de l'écosystème avant déploiement.

Cette approche préventive de la sécurité des dépendances s'inscrit dans une démarche de développement responsable, particulièrement importante dans un contexte applicatif gérant des données personnelles d'athlètes.
