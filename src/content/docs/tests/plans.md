---
title: Plans de tests
description: Stratégie et plans de tests de l'application DropIt
---

## Stratégie de tests

Ma stratégie de tests dans DropIt s'articule autour de trois niveaux : tests unitaires pour la logique métier isolée, tests d'intégration pour valider les interactions entre modules, et préparation des tests E2E pour les flux utilisateur critiques. Cette approche pyramidale me permet de détecter rapidement les régressions tout en maintenant une couverture adaptée aux besoins du projet.

L'infrastructure de tests repose sur Jest pour l'API backend, avec une base de données PostgreSQL dédiée orchestrée via Docker Compose. Cette séparation garantit l'isolation complète des tests sans impacter l'environnement de développement.

## Infrastructure de tests

### Base de données de test

J'ai configuré une infrastructure Docker dédiée aux tests via `docker-compose.test.yml` qui isole complètement l'environnement de test :

```yaml
# Configuration PostgreSQL optimisée pour les tests
postgres-test:
  image: postgres:16-alpine
  environment:
    POSTGRES_DB: dropit_test
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: example
  ports:
    - "5433:5432"
  tmpfs:
    - /var/lib/postgresql/data  # Performances accrues en mémoire
```

Cette approche me permet d'exécuter les tests d'intégration avec un script unique : `pnpm run test:integration:docker` qui démarre l'infrastructure, exécute les tests, puis nettoie automatiquement.

### Gestion des données avec les seeders

Comme mentionné dans la section permissions, j'utilise un système de seeders MikroORM qui facilite la création de jeux de données cohérents. Ces seeders servent à la fois pour le développement et pour initialiser les données de test :

- **OrganizationSeeder** : Création des clubs de test
- **AthleteSeeder** : Génération d'utilisateurs avec rôles
- **ExerciseSeeder** : Base d'exercices d'haltérophilie
- **WorkoutSeeder** : Programmes d'entraînement types

### Qualité de code avec Biome

Biome assure la cohérence du code et détecte les erreurs potentielles avant même l'exécution des tests. Cette configuration unified remplace ESLint et Prettier, simplifiant la toolchain :

- **Linting** : Détection des patterns anti-patterns JavaScript/TypeScript
- **Formatage** : Cohérence stylistique automatique
- **Support décorators** : Configuration spéciale pour NestJS

## Tests unitaires : focus sur la sécurité

Ma priorité s'est portée sur les tests unitaires des composants de sécurité, particulièrement les Guards d'authentification et de permissions qui constituent le cœur de la protection de l'application. Ces tests isolent la logique métier critique sans dépendances externes.

Pour l'`AuthGuard`, j'ai testé la logique d'authentification Better-Auth avec les différents cas : routes publiques, routes optionnelles, gestion des sessions expirées, et injection des données utilisateur dans les requêtes. Les tests couvrent aussi la différenciation entre utilisateurs standard et super-administrateurs.

Le `PermissionsGuard` fait l'objet d'une batterie de tests plus extensive qui valide les règles RBAC selon chaque rôle d'organisation (member, admin, owner) et chaque ressource métier (workout, exercise, athlete, complex, session, personalRecord). J'ai testé les logiques d'accès granulaires, comme l'autorisation pour un member de gérer son profil athlète mais l'interdiction de créer des programmes d'entraînement.

Voici un exemple concret du test du `PermissionsGuard` :

```typescript
it('should allow access when user has required permissions', async () => {
  const mockContext = createMockExecutionContext({
    user: { id: 'user-1' },
    session: { activeOrganizationId: 'org-1' },
  });

  jest.spyOn(reflector, 'get').mockReturnValue(['read']);
  jest.spyOn(entityManager, 'findOne').mockResolvedValue({
    role: 'admin', // Admin a les permissions de lecture
  } as Member);

  const result = await guard.canActivate(mockContext);
  expect(result).toBe(true);
});
```

Cette approche me donne confiance dans la robustesse du système de permissions, avec plus de 40 tests unitaires couvrant tous les cas d'usage possibles dans un contexte de club d'haltérophilie. Des exemples détaillés de ces tests sont disponibles dans la section [Validation des composants](/tests/validation/).

## Tests d'intégration : validation des flux métier

Les tests d'intégration me permettent de valider les interactions réelles entre modules avec une base de données PostgreSQL. J'ai concentré mes efforts sur les trois domaines les plus critiques : les **exercices**, les **complexes** (enchaînements d'exercices), et les **workouts** (programmes d'entraînement complets).

Pour les **exercices**, j'ai testé la création avec catégorisation selon les spécificités de l'haltérophilie (squat, développé, arraché), la recherche par nom, la mise à jour des propriétés (nom français, anglais, nom court), et la suppression avec vérification des contraintes relationnelles.

Les tests de **complexes** valident la création d'enchaînements d'exercices avec leur ordre d'exécution, le nombre de répétitions par exercice, et la cohérence des relations entre exercices et catégories. J'ai aussi testé les mises à jour d'ordre et la suppression cascade.

L'intégration des **workouts** représente le test le plus complexe car elle orchestre exercices simples et complexes dans un programme structuré. Chaque test de création de workout suit un pattern de vérifications en cascade : d'abord la création avec validation du statut de retour, puis la vérification de l'existence et des propriétés de base (ID, titre, nombre d'éléments), ensuite la validation de chaque élément selon son type (complex ou exercise) avec ses métadonnées spécifiques (ordre, répétitions, séries, temps de repos, pourcentage de poids de départ), et enfin la cohérence des relations entre les éléments et leurs entités référencées (exercices du complexe, propriétés de l'exercice simple).

Ces tests d'intégration suivent tous le même pattern de setup avec nettoyage complet de la base et création d'un contexte organisationnel via les seeders, garantissant l'isolation entre chaque série de tests. La section [Validation des composants](/tests/validation/) présente des exemples concrets de ces implémentations.

## Perspective E2E : workflows utilisateur complets

Bien que contrainte par le temps imparti au projet, j'ai élaboré une stratégie complète pour l'implémentation des tests E2E qui constituerait la prochaine étape logique de ma démarche qualité.

### Plan d'implémentation prioritaire

Mon analyse identifie un workflow critique qui mériterait une automatisation E2E :

**Inscription complète d'un athlète** - Depuis l'invitation par email jusqu'à l'accès aux fonctionnalités via l'application mobile. Ce parcours traverse l'API d'invitation, le système d'email, l'interface web d'inscription, et l'authentification mobile.


### Stratégie technique envisagée

J'opterais pour Playwright plutôt que Cypress en raison de sa capacité native à gérer les tests multi-navigateurs et son intégration facilitée avec les applications mobiles via Expo. Cette approche permettrait de valider l'expérience utilisateur sur les différents supports (web desktop, web mobile, application native).

L'infrastructure s'appuierait sur la même base Docker que les tests d'intégration, enrichie d'un service de test d'emails (MailHog) pour valider les workflows d'invitation. Cette continuité technique garantirait la cohérence de l'environnement de tests.

Cette approche représenterait un investissement de 1 à 2 semaines supplémentaires mais fournirait une validation complète de l'expérience utilisateur, complétant ainsi la pyramide de tests initiée avec les tests unitaires et d'intégration.

## Utilitaires et outillage

Ma stack de tests s'appuie sur Jest pour sa maturité et son intégration native avec NestJS. J'utilise `@nestjs/testing` qui me permet de créer des modules de test avec injection de dépendances, Supertest pour les tests HTTP directs sur l'API, et `@faker-js/faker` pour générer des données d'athlètes et d'exercices réalistes.

J'ai développé quelques utilitaires custom qui simplifient significativement l'écriture des tests. Le `TestUseCaseFactory` me permet d'éviter la complexité de l'injection de dépendances NestJS dans les tests en instanciant directement les repositories MikroORM. Les fonctions `cleanDatabase()` et `createTestOrganization()` standardisent la préparation des données de test et garantissent un état cohérent entre chaque test.

## Intégration continue et métriques automatisées

Cette infrastructure de tests s'intègre dans un workflow de CI/CD via GitHub Actions qui automatise l'exécution à chaque commit. Le workflow valide systématiquement la qualité du code via Biome, puis exécute la suite complète des tests (unitaires et d'intégration) avec génération automatique des métriques de couverture.

Cette approche me permet de détecter immédiatement les régressions sans intervention manuelle, garantissant que seul du code validé atteint la branche principale. Les développeurs peuvent également exécuter localement ces tests via les scripts `pnpm test` et `pnpm test:integration:docker`, reproduisant exactement l'environnement de CI.

Les métriques actuelles attestent d'une couverture de 85% sur les modules de sécurité critiques (AuthGuard, PermissionsGuard) et de 70% sur la logique métier des domaines workout et exercise. Ces indicateurs me donnent confiance dans la robustesse de l'application tout en identifiant les zones nécessitant un renforcement des tests.

## Contraintes et compromis techniques

Dans le contexte de ce projet académique, j'ai dû faire des choix pragmatiques face aux contraintes temporelles. Ma priorité s'est naturellement portée sur les composants de sécurité car ils représentent le risque le plus élevé en cas de dysfonctionnement. Cette décision m'a amené à reporter l'implémentation complète des tests E2E au profit d'une couverture exhaustive des Guards d'authentification et de permissions.