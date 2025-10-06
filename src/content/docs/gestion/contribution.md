---
title: Contribution au projet
description: Organisation du projet et méthodes de développement collaboratif
---

## Philosophie Free Software

Le projet DropIt est hébergé sur GitHub sous licence AGPL-3.0, favorisant la transparence et l'apprentissage communautaire tout en protégeant contre l'appropriation commerciale.

Cette licence copyleft garantit que toute modification reste open source, même pour les déploiements sur serveur web.

## Infrastructure de développement

### Environnement Docker

L'environnement repose entièrement sur Docker Compose, garantissant la reproductibilité entre postes. Cette approche résout les problèmes classiques de différences d'environnement et facilite l'onboarding des contributeurs.

La stack complète (PostgreSQL, PgAdmin, Redis, Typesense) s'initialise via `docker-compose up`, créant un environnement isolé et fonctionnel en quelques minutes.

### Données et seeders

Les volumes Docker garantissent la persistance des données entre redémarrages, évitant la perte des données de développement lors des phases de test.

Le système de seeders automatiques peuple la base avec des données réalistes : exercices d'haltérophilie, athlètes fictifs, programmes d'entraînement types. Cette initialisation permet aux nouveaux développeurs de découvrir immédiatement les fonctionnalités.

### Installation standardisée

Le README détaille la procédure d'installation :

1. **Prérequis** : Node.js v20+, pnpm, Docker
2. **Setup** : Clone, `pnpm install`, `pnpm build`, configuration `.env`
3. **Démarrage** : `docker-compose up -d` puis `pnpm dev`

Cette documentation vise une mise en route en moins de 10 minutes, benchmark testé sur plusieurs machines.

## Méthodologie de développement

### Approche agile individuelle

Bien que travaillant seul, j'ai appliqué une approche Kanban via Notion pour structurer le développement. Cette méthode me permet de décomposer les fonctionnalités complexes en tâches atomiques, facilitant le suivi et la priorisation.

Mon expérience en équipes agiles m'a familiarisé avec Scrum et Kanban. J'ai expérimenté différents outils selon les contextes : Jira pour les grandes organisations, ClickUp pour sa flexibilité, GitHub Projects pour l'intégration native avec le code.

### Workflow Git structuré

Mon flux Git respecte les bonnes pratiques collaboratives, préparant l'évolution vers une équipe :

**Stratégie de branches** : Une branche par fonctionnalité (`feature/auth-better-auth`) isole les développements et facilite les futures revues.

**Protection des branches** : `main` et `develop` sont protégées contre les push directs. Tout merge nécessite une Pull Request.

**Validation automatisée** : Chaque PR vers `develop` déclenche la suite complète de tests. Le merge n'est autorisé qu'après validation réussie.

**Déploiement contrôlé** : Seul le merge `develop` → `main` déclenche le déploiement production via GitHub Actions.

Cette discipline assure la traçabilité et prépare l'évolution collaborative.

## Documentation technique

### README modulaires

La documentation s'organise autour de README spécialisés par public. Le README principal fournit vue d'ensemble et installation rapide, chaque module (frontend, backend, mobile) dispose de sa documentation détaillée.

Cette approche modulaire maintient une documentation pertinente sans duplication. Les développeurs frontend trouvent rapidement les informations React/TypeScript, les contributeurs backend accèdent aux spécificités NestJS et MikroORM.

### Documentation API Swagger

L'API REST génère automatiquement sa documentation via Swagger/OpenAPI, garantissant la synchronisation code-documentation. Cette approche élimine les risques de désynchronisation classiques.

Better-Auth dispose de sa propre interface Swagger séparée, clarifiant la distinction entre endpoints métier DropIt et fonctionnalités d'authentification.

## Perspectives

Cette approche vise à réduire les barrières à la contribution, reflétant mon objectif de créer un projet maintenable et évolutif. L'expérience acquise constitue une base solide pour intégrer des équipes et contribuer positivement à des projets collaboratifs.

L'infrastructure technique étant en place, la section suivante aborde les aspects de documentation utilisateur et de support, éléments essentiels pour l'adoption par les clubs d'haltérophilie. 

