---
title: Plans de tests
description: Stratégie et plans de tests de l'application DropIt
---

## Stratégie de tests

J'ai structuré ma stratégie de tests selon une pyramide à trois niveaux : tests unitaires pour la logique métier critique, tests d'intégration pour les interactions entre modules, et préparation des tests E2E pour les workflows utilisateur. Cette approche me permet de détecter rapidement les régressions tout en optimisant le temps d'exécution.

L'infrastructure repose sur Jest pour l'API backend avec une base de données PostgreSQL dédiée via Docker Compose. Cette isolation garantit des tests reproductibles sans impact sur l'environnement de développement.

## Infrastructure de tests

### Base de données de test

J'ai configuré une infrastructure Docker dédiée via `docker-compose.test.yml` qui isole complètement l'environnement de test. Cette séparation utilise un port différent (5433) et un stockage en mémoire pour optimiser les performances.

L'exécution se fait via un script disponible depuis la racine du projet ainsi qu'au niveau de l'api `pnpm run test:integration:docker` qui démarre l'infrastructure, exécute les tests, puis nettoie automatiquement.

### Seeders et données de test

Le système de seeders MikroORM facilite la création de jeux de données cohérents pour les tests d'intégration :

- **OrganizationSeeder** : Clubs et structures organisationnelles
- **AthleteSeeder** : Utilisateurs avec rôles différenciés
- **ExerciseSeeder** : Catalogue d'exercices d'haltérophilie
- **WorkoutSeeder** : Programmes d'entraînement types

### Outillage qualité

Biome assure la cohérence du code en remplaçant ESLint et Prettier par une solution unifiée. Cette configuration detecte les anti-patterns TypeScript et supporte les décorateurs NestJS, simplifiant la toolchain tout en maintenant la qualité.

## Tests unitaires

J'ai priorisé les tests unitaires sur les composants de sécurité, notamment les Guards d'authentification et de permissions qui protègent l'application. Ces tests isolent la logique métier critique sans dépendances externes.

### AuthGuard

L'`AuthGuard` teste la logique d'authentification Better-Auth avec différents scénarios : routes publiques, routes optionnelles, gestion des sessions expirées, et injection des données utilisateur. Les tests vérifient aussi la différenciation entre utilisateurs standard et super-administrateurs.

### PermissionsGuard

Le `PermissionsGuard` fait l'objet d'une batterie de tests extensive validant les règles RBAC selon chaque rôle (member, admin, owner) et ressource métier (workout, exercise, athlete). J'ai testé les logiques d'accès granulaires, comme l'autorisation pour un member de gérer son profil mais l'interdiction de créer des programmes.

```typescript
it('should allow access when user has required permissions', async () => {
  const mockContext = createMockExecutionContext({
    user: { id: 'user-1' },
    session: { activeOrganizationId: 'org-1' },
  });

  jest.spyOn(reflector, 'get').mockReturnValue(['read']);
  jest.spyOn(entityManager, 'findOne').mockResolvedValue({
    role: 'admin',
  } as Member);

  const result = await guard.canActivate(mockContext);
  expect(result).toBe(true);
});
```

Cette approche couvre plus de 40 tests unitaires validant tous les cas d'usage du système de permissions. Les détails sont disponibles dans [Validation des composants](/tests/validation/).

## Tests d'intégration

Les tests d'intégration valident les interactions réelles entre modules avec une base de données PostgreSQL. J'ai concentré mes efforts sur trois domaines critiques : exercices, complexes d'exercices, et programmes d'entraînement complets.

### Tests des exercices

Les tests couvrent la création avec catégorisation selon les spécificités de l'haltérophilie, la recherche par nom, et la gestion des contraintes relationnelles lors des suppressions.

### Tests des complexes

La validation porte sur la création d'enchaînements d'exercices ordonnés, le nombre de répétitions par exercice, et la cohérence des relations entre exercices et catégories.

### Tests des workouts

L'orchestration des workouts représente le défi le plus complexe car elle combine exercices simples et complexes dans une structure cohérente. Chaque test suit un pattern de vérifications en cascade : création, validation des propriétés de base, puis vérification de chaque élément selon son type avec ses métadonnées spécifiques.

Tous les tests suivent un pattern uniforme : nettoyage de base, création du contexte organisationnel via les seeders, puis exécution isolée. Les exemples détaillés sont dans [Validation des composants](/tests/validation/).

## Perspective E2E

Dans le contexte temporel du projet, j'ai élaboré une stratégie E2E pour la suite du développement. Cette approche complèterait la pyramide de tests en validant les parcours utilisateur critiques.

### Workflow prioritaire identifié

L'inscription complète d'un athlète constitue le workflow le plus critique : invitation par email, interface web d'inscription, puis accès mobile. Ce parcours traverse tous les composants de l'architecture (API, authentification, clients web/mobile).

### Approche technique envisagée

Playwright s'imposerait pour sa capacité multi-navigateurs et son intégration avec les applications Expo. L'infrastructure réutiliserait la base Docker existante, enrichie d'un service de test d'emails (MailHog) pour valider les workflows d'invitation.

Cette implémentation représenterait 1 à 2 semaines supplémentaires mais fournirait une validation complète de l'expérience utilisateur.

## Outillage et utilitaires

### Stack technique

La stack repose sur Jest pour sa maturité et son intégration NestJS. J'utilise `@nestjs/testing` pour l'injection de dépendances, Supertest pour les tests HTTP, et `@faker-js/faker` pour générer des données réalistes.

### Helpers de test

J'ai développé des utilitaires pour simplifier l'écriture des tests d'intégration. La fonction `cleanDatabase()` utilise le générateur de schéma MikroORM pour remettre à zéro la base de données entre chaque test, garantissant l'isolation. Le `TestUseCaseFactory` évite la complexité de l'injection de dépendances NestJS en instanciant directement les repositories et use cases nécessaires :

```typescript
// Helper de nettoyage de base
export async function cleanDatabase(orm: MikroORM): Promise<void> {
  const generator = orm.getSchemaGenerator();
  await generator.refreshDatabase();
}

// Factory pour instancier les use cases dans les tests
export class TestUseCaseFactory {
  constructor(private readonly orm: MikroORM) {}

  createExerciseUseCase(): ExerciseUseCase {
    const exerciseRepository = new MikroExerciseRepository(this.orm.em);
    // ... injection des dépendances nécessaires
    return new ExerciseUseCase(exerciseRepository, ...);
  }
}
```

## Intégration continue

### Workflow automatisé

L'infrastructure s'intègre dans un workflow GitHub Actions qui s'exécute automatiquement à chaque push et pull request. Ce pipeline valide systématiquement la qualité du code via Biome (linting et formatage), puis exécute la suite complète des tests avec génération des métriques de couverture.

Cette approche de **Continuous Integration** me permet de détecter immédiatement les régressions sans intervention manuelle, garantissant que seul du code validé atteint la branche principale. Les développeurs reproduisent exactement l'environnement de CI localement via `pnpm test` et `pnpm test:integration:docker`.

### Métriques actuelles

- **Sécurité** : 85% de couverture sur AuthGuard et PermissionsGuard
- **Métier** : 70% sur les domaines workout et exercise

Ces indicateurs donnent confiance dans la robustesse tout en identifiant les zones à renforcer.

## Contraintes et choix techniques

Dans le contexte temporel du projet, j'ai priorisé les composants de sécurité représentant le risque le plus élevé. Cette décision a conduit à reporter l'implémentation E2E complète au profit d'une couverture exhaustive des Guards d'authentification et de permissions.

Cette stratégie de tests me fournit une base solide pour valider la robustesse de l'application. La section suivante présente des exemples concrets d'implémentation de ces tests, illustrant comment cette approche se traduit en pratique dans le code.