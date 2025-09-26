---
title: Validation des composants
description: Analyse des stratégies de test et retours d'expérience
---

## Tests unitaires

### PermissionsGuard

La validation du système de permissions représente un enjeu critique pour la sécurité. Mon approche teste exhaustivement les règles d'accès selon les rôles organisationnels (member, admin, owner) et les ressources métier (workout, exercise, athlete).

La structure isole complètement la logique métier en mockant les dépendances externes (Reflector, EntityManager). Cette isolation me permet de tester précisément les algorithmes de vérification sans interférence avec la base de données.

```typescript
describe('PermissionsGuard', () => {
  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PermissionsGuard,
        { provide: Reflector, useValue: { get: jest.fn() } },
        { provide: EntityManager, useValue: { findOne: jest.fn() } },
      ],
    }).compile();
    // ... initialisation des mocks
  });

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
});
```

Les tests couvrent systématiquement permissions accordées, refusées, utilisateurs sans organisation, sessions expirées, et tentatives d'escalade de privilèges. Cette batterie de plus de 40 tests unitaires valide la robustesse du système RBAC.

### AuthGuard

L'AuthGuard gère l'intégration avec Better-Auth. Les tests vérifient la gestion des routes publiques, l'injection des données de session, et la différenciation entre utilisateurs standard et super-administrateurs.

```typescript
describe('AuthGuard', () => {
  it('should use Better Auth API in production environment', async () => {
    jest.spyOn(authService.api, 'getSession').mockResolvedValue(mockAdminSession);

    const result = await guard.canActivate(mockContext);

    expect(result).toBe(true);
    expect(authService.api.getSession).toHaveBeenCalled();
  });

  it('should inject session and user into request', async () => {
    jest.spyOn(authService.api, 'getSession').mockResolvedValue(mockAdminSession);
    await guard.canActivate(mockContext);

    expect(mockRequest.session).toBe(mockAdminSession);
    expect(mockRequest.user).toBe(mockAdminSession.user);
  });
});
```

Cette approche valide l'authentification sans dépendre du service Better-Auth réel, garantissant rapidité d'exécution et fiabilité.

## Tests d'intégration

### Workouts

Les tests d'intégration de workouts représentent le défi le plus complexe car ils orchestrent l'ensemble de la logique métier d'haltérophilie. Un workout combine exercices simples et complexes dans une structure cohérente respectant les spécificités de l'entraînement.

```typescript
const workoutResult = await workoutUseCase.createWorkout({
  title: 'Test Workout',
  workoutCategory: workoutCategory.id,
  elements: [
    {
      type: WORKOUT_ELEMENT_TYPES.COMPLEX,
      id: complex.id,
      order: 0,
      reps: 1,
      sets: 1,
      rest: 120,
      startWeight_percent: 75,
    },
    {
      type: WORKOUT_ELEMENT_TYPES.EXERCISE,
      id: exercise.id,
      order: 1,
      reps: 8,
      sets: 3,
      rest: 90,
      startWeight_percent: 70,
    },
  ],
}, testData.organization.id, testData.adminUser.id);

// Vérifications en cascade
expect(workoutResult.status).toBe(200);
expect(workout.elements).toHaveLength(2);
expect(workout.elements[0].type).toBe('complex');
expect(workout.elements[1].reps).toBe(8);
```

Cette stratégie valide l'orchestration via des programmes réalistes avec éléments mixtes. Les vérifications en cascade détectent rapidement les problèmes d'intégration entre domaines Exercise, Complex et Workout.

### Validation complète des domaines métier

Les tests d'intégration couvrent les trois domaines critiques (exercices, complexes, workouts) avec des patterns uniformes : nettoyage de base, création du contexte organisationnel via les seeders, puis validation des interactions entre modules. Cette approche garantit que les spécificités métier de l'haltérophilie sont correctement implémentées et que les relations entre entités fonctionnent de manière cohérente.

Les fonctions de recherche font l'objet de tests particuliers car elles constituent des points d'entrée critiques pour les entraîneurs lors de la conception des programmes. Cette validation me donne confiance dans la robustesse des fonctionnalités de base.

## Conclusion

Cette couverture de tests constitue un prérequis essentiel avant le déploiement en production.

L'étape suivante consiste à préparer l'infrastructure de déploiement pour mettre l'application à disposition des utilisateurs dans un environnement sécurisé.