---
title: Validation des composants
description: Analyse des stratégies de test et retours d'expérience
---

## Tests unitaires

### PermissionsGuard : validation des autorisations RBAC

La validation du système de permissions constitue un enjeu critique pour la sécurité de l'application. Mon approche de test se concentre sur la validation exhaustive des règles d'accès selon les rôles organisationnels (member, admin, owner) et les ressources métier (workout, exercise, athlete, etc.).

La structure des tests isole complètement la logique métier du PermissionsGuard en mockant les dépendances externes (Reflector, EntityManager). Cette approche me permet de tester précisément les algorithmes de vérification des permissions sans interférence avec la base de données ou d'autres composants.

```typescript
describe('PermissionsGuard', () => {
  let guard: PermissionsGuard;
  let reflector: Reflector;
  let entityManager: EntityManager;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PermissionsGuard,
        { provide: Reflector, useValue: { get: jest.fn() } },
        { provide: EntityManager, useValue: { findOne: jest.fn() } },
      ],
    }).compile();

    guard = module.get<PermissionsGuard>(PermissionsGuard);
    reflector = module.get<Reflector>(Reflector);
    entityManager = module.get<EntityManager>(EntityManager);
  });

  it('should allow access when user has required permissions', async () => {
    const mockContext = createMockExecutionContext({
      user: { id: 'user-1' },
      session: { activeOrganizationId: 'org-1' },
    });

    jest.spyOn(reflector, 'get').mockReturnValue(['read']);
    jest.spyOn(entityManager, 'findOne').mockResolvedValue({
      role: 'admin', // Admin possède les permissions de lecture
    } as Member);

    const result = await guard.canActivate(mockContext);
    expect(result).toBe(true);
  });

  it('should deny access when user lacks required permissions', async () => {
    const mockContext = createMockExecutionContext({
      user: { id: 'user-1' },
      session: { activeOrganizationId: 'org-1' },
    });

    jest.spyOn(reflector, 'get').mockReturnValue(['delete']);
    jest.spyOn(entityManager, 'findOne').mockResolvedValue({
      role: 'member', // Member n'a pas permission delete
    } as Member);

    await expect(guard.canActivate(mockContext)).rejects.toThrow();
  });
});
```

Les tests couvrent systématiquement tous les cas d'accès : permissions accordées, permissions refusées, utilisateurs sans organisation, sessions expirées, et tentatives d'escalade de privilèges. Cette batterie de plus de 40 tests unitaires me donne confiance dans la robustesse du système RBAC.

### AuthGuard : gestion des sessions Better-Auth

L'AuthGuard orchestrant l'authentification via Better-Auth fait l'objet de tests spécifiques validant l'intégration avec le système d'authentification externe. Les tests vérifient la gestion correcte des routes publiques, l'injection des données de session dans les requêtes, et la différenciation entre utilisateurs standard et super-administrateurs.

```typescript
describe('AuthGuard', () => {
  it('should use Better Auth API in production environment', async () => {
    jest.spyOn(authService.api, 'getSession').mockResolvedValue(mockAdminSession);

    const result = await guard.canActivate(mockContext);

    expect(result).toBe(true);
    expect(authService.api.getSession).toHaveBeenCalled();
  });

  it('should allow access to public routes', async () => {
    jest.spyOn(reflector, 'get').mockReturnValue('PUBLIC');

    const result = await guard.canActivate(mockContext);
    expect(result).toBe(true);
  });

  it('should inject session and user into request', async () => {
    jest.spyOn(authService.api, 'getSession').mockResolvedValue(mockAdminSession);

    await guard.canActivate(mockContext);

    expect(mockRequest.session).toBe(mockAdminSession);
    expect(mockRequest.user).toBe(mockAdminSession.user);
  });
});
```

Cette approche me permet de valider que l'authentification fonctionne correctement sans dépendre du service Better-Auth réel, garantissant la rapidité d'exécution des tests tout en conservant leur fiabilité.

## Tests d'intégration

### Création de workout : orchestration complète

Les tests d'intégration de workouts représentent le défi technique le plus complexe car ils orchestrent l'ensemble de la logique métier de l'haltérophilie. Un workout combine exercices simples et complexes dans une structure cohérente qui respecte les spécificités de l'entraînement sportif.

```typescript
// Test de création d'un workout avec éléments mixtes
const workoutResult = await workoutUseCase.createWorkout({
  title: 'Test Workout',
  workoutCategory: workoutCategory.id,
  description: 'Test workout description',
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
const workout = workoutResult.body;
expect(workout.id).toBeDefined();
expect(workout.title).toBe('Test Workout');
expect(workout.elements).toHaveLength(2);

// Validation du complex
const complexElement = workout.elements[0];
expect(complexElement.type).toBe('complex');
expect(complexElement.complex.exercises.length).toBeGreaterThan(0);

// Validation de l'exercice simple
const exerciseElement = workout.elements[1];
expect(exerciseElement.type).toBe('exercise');
expect(exerciseElement.reps).toBe(8);
expect(exerciseElement.sets).toBe(3);
expect(exerciseElement.startWeight_percent).toBe(70);
```

Ma stratégie de test valide cette orchestration en créant des programmes d'entraînement réalistes avec des éléments mixtes. Les vérifications s'effectuent en cascade pour détecter rapidement les problèmes d'intégration entre les domaines Exercise, Complex et Workout.

### Gestion des exercices : CRUD avec catégorisation

Les tests d'exercices valident la spécialisation de l'application pour l'haltérophilie en testant la création d'exercices avec leurs propriétés multilingues et leur catégorisation selon les mouvements de base.

```typescript
// Création d'exercice spécialisé haltérophilie
const exerciseResult = await exerciseUseCase.create({
  name: 'Squat Clavicule',
  description: 'Squat avec barre en position clavicule',
  exerciseCategory: exerciseCategory.id,
  englishName: 'Front Squat',
  shortName: 'FS',
}, testData.organization.id, testData.adminUser.id);

expect(exerciseResult.status).toBe(201);
const exercise = exerciseResult.body;
expect(exercise.name).toBe('Squat Clavicule');
expect(exercise.englishName).toBe('Front Squat');
expect(exercise.shortName).toBe('FS');
expect(exercise.exerciseCategory.name).toBe('Haltérophilie');

// Test de recherche multilingue
const searchResults = await exerciseUseCase.search(
  'Squat',
  testData.organization.id,
  testData.adminUser.id
);
expect(searchResults.body.length).toBeGreaterThanOrEqual(1);

// Validation de la recherche par nom court
const shortNameSearch = await exerciseUseCase.search(
  'FS',
  testData.organization.id,
  testData.adminUser.id
);
expect(shortNameSearch.body).toContainEqual(
  expect.objectContaining({ shortName: 'FS' })
);
```

### Gestion des complexes : enchaînements d'exercices

Les tests de validation des complexes vérifient la logique d'enchaînement des exercices dans l'ordre spécifié, avec gestion des répétitions et validation des relations entre exercices et catégories. Cette fonctionnalité est particulièrement importante en haltérophilie où les complexes permettent de travailler des chaînes de mouvement complètes.

```typescript
// Test de création de complexe avec exercices ordonnés
const complexResult = await complexUseCase.create({
  name: 'Complexe Arraché',
  description: 'Enchaînement technique pour l\'arraché',
  exercises: [
    {
      exerciseId: exerciseArracheTirage.id,
      order: 0,
      reps: 3,
    },
    {
      exerciseId: exerciseArrachePull.id,
      order: 1,
      reps: 2,
    },
    {
      exerciseId: exerciseArracheComplet.id,
      order: 2,
      reps: 1,
    },
  ],
}, testData.organization.id, testData.adminUser.id);

// Validation de la structure du complexe
expect(complexResult.status).toBe(201);
const complex = complexResult.body;
expect(complex.exercises).toHaveLength(3);
expect(complex.exercises[0].order).toBe(0);
expect(complex.exercises[2].reps).toBe(1);

// Vérification de l'ordre d'exécution
const orderedExercises = complex.exercises.sort((a, b) => a.order - b.order);
expect(orderedExercises[0].exercise.name).toContain('Tirage');
expect(orderedExercises[2].exercise.name).toContain('Complet');
```

Cette approche de test valide que les enchaînements d'exercices respectent la progression logique de l'apprentissage technique en haltérophilie, où l'on commence par des mouvements préparatoires pour terminer par le geste complet.

La fonction de recherche fait l'objet de tests particuliers car elle constitue un point d'entrée critique pour les entraîneurs lors de la conception des programmes. Cette validation me donne confiance dans la robustesse des fonctionnalités de base tout en m'assurant que les spécificités métier de l'haltérophilie sont correctement prises en compte.