---
title: Contribution au projet
description: Organisation du projet et méthodes de développement collaboratif
---

## Philosophie Open Source et licencing

Le projet DropIt est actuellement hébergé sur GitHub sous licence MIT, favorisant la transparence et l'apprentissage communautaire. Cette approche open source me permet de démontrer mes compétences techniques tout en contribuant à l'écosystème des outils d'haltérophilie.

J'envisage prochainement d'évoluer vers une licence plus restrictive (Free Software License) pour préserver l'usage non-commercial du projet.

## Infrastructure de développement

### Environnement containerisé avec Docker

L'environnement de développement repose entièrement sur Docker Compose, garantissant la reproductibilité entre les postes de développement. Cette approche résout les problèmes classiques des différents environnement des developpeurs et facilite significativement l'onboarding de nouveaux contributeurs.

La stack complète (PostgreSQL, PgAdmin et prochainement Redis, Typesense) s'initialise via une simple commande `docker-compose up`, créant un environnement isolé et fonctionnel en quelques minutes.

### Gestion des données avec volumes persistants

Les volumes Docker attachés aux services garantissent la persistance des données entre les redémarrages de containers. Cette configuration évite la perte frustrante des données de développement et des jeux d'essai, particulièrement précieuse lors des phases de test intensives.

Le système de seeders automatiques populate la base avec des données réalistes d'exercices d'haltérophilie, d'athlètes fictifs, et de programmes d'entraînement types. Cette initialisation automatique permet aux nouveaux développeurs de découvrir immédiatement les fonctionnalités sans configuration manuelle fastidieuse.

### Instructions d'installation standardisées

Le README du projet détaille précisément la procédure d'installation :

1. **Prérequis** : Node.js v20+, pnpm, Docker et Docker Compose
2. **Setup rapide** : Clone, `pnpm install`, `pnpm build`, configuration `.env`
3. **Démarrage** : `docker-compose up -d` puis `pnpm dev`

Cette documentation vise à permettre la mise en route en moins de 10 minutes, benchmark que j'ai testé sur plusieurs machines pour valider la simplicité d'accès.

## Méthodologie de développement

### Gestion de projet agile individuelle

Bien que travaillant seul sur ce projet, j'ai appliqué une approche Kanban via Notion pour structurer le développement. Cette méthode me permet de décomposer les fonctionnalités complexes en tâches atomiques, facilitant le suivi de progression et la priorisation des développements.

Mon expérience professionnelle en équipes agiles (2 à 5 développeurs) m'a familiarisé avec les methodes agiles Scrum et Kanban. Plus particulièrement Scrum, qui structure le développement en sprints de 2-4 semaines avec des cérémonies ritualisées (daily meetings, sprint planning, retrospectives), favorisant la collaboration et l'adaptation continue aux besoins métier.

### Outils de gestion collaborative

J'ai expérimenté différents outils de gestion de projet selon les contextes d'équipe : Jira pour les grandes organisations avec workflows complexes, ClickUp pour sa flexibilité et son interface moderne, et GitHub Projects pour l'intégration native avec le code. Cette diversité d'expérience me permet d'adapter mes méthodes selon les contraintes et préférences d'équipe.

### Workflow Git structuré

Mon flux de travail Git respecte les bonnes pratiques de développement collaboratif, même en contexte individuel, préparant l'évolution vers une équipe :

**Stratégie de branches** : Une branche par fonctionnalité (`feature/auth-better-auth`, `feature/workout-builder`) permet l'isolation des développements et facilite les revues de code futures.

**Protection des branches critiques** : Les branches `main` et `develop` sont protégées contre les push directs. Tout merge nécessite obligatoirement une Pull Request, même en tant que seul développeur du projet.

**Validation automatisée** : Chaque Pull Request vers `develop` déclenche automatiquement la suite complète de tests (unitaires, intégration, linting). Le merge n'est autorisé qu'après validation réussie de tous les checks.

**Intégration via develop** : Toutes les features mergent d'abord dans `develop` via Pull Request pour validation et tests d'intégration avant promotion vers `main`.

**Déploiement contrôlé** : Seul le merge de `develop` vers `main` (également via Pull Request) déclenche automatiquement le déploiement en production via GitHub Actions, garantissant que seul du code testé atteint l'environnement live.

Cette discipline Git, acquise en environnement d'équipe, assure la traçabilité des modifications et prépare l'évolution vers un développement collaboratif avec plusieurs contributeurs.

## Documentation technique pour développeurs

### README modulaires et organisés

La documentation technique de DropIt s'organise autour de README spécialisés selon les publics cibles. Le README principal du projet fournit une vue d'ensemble et les instructions d'installation rapide, tandis que chaque module (frontend, backend, mobile) dispose de sa propre documentation détaillée.

Cette approche modulaire me permet de maintenir une documentation pertinente sans duplication d'informations. Les développeurs frontend trouvent rapidement les informations sur la stack React/TypeScript, tandis que les contributeurs backend accèdent directement aux spécificités NestJS et MikroORM.

### Documentation API automatisée avec Swagger

L'API REST de DropIt génère automatiquement sa documentation via Swagger/OpenAPI, garantissant la synchronisation entre le code et la documentation. Cette approche élimine les risques de désynchronisation classiques entre l'implémentation et sa documentation.

La documentation Swagger couvre exhaustivement les endpoints de gestion des exercices, des programmes d'entraînement, et des données d'athlètes.

### Intégration Better-Auth documentée

Better-Auth disposant de sa propre interface Swagger, j'ai configuré un accès séparé à cette documentation spécialisée. Cette séparation clarifie la distinction entre les endpoints métier de DropIt et les fonctionnalités d'authentification, facilitant la compréhension pour les développeurs découvrant le projet.

Cette documentation détaille les flux OAuth, la gestion des sessions et les permissions RBAC informations cruciales pour comprendre l'architecture de sécurité.

## Perspectives de contribution

Cette approche combinée à la documentation technique accessible vise à réduire les barrières à la contribution, reflétant mon objectif de créer un projet maintenable et évolutif. L'expérience acquise avec ces outils et méthodologies constitue une base solide pour intégrer efficacement des équipes de développement et contribuer positivement à des projets collaboratifs. 

