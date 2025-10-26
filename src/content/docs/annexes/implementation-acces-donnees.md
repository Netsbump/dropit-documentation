---
title: Implémentation accès aux données - Détails techniques
description: Détails techniques et exemples d'implémentation de la couche d'accès aux données avec MikroORM
---

## Comparaison des approches d'implémentation

### Database First

Cette approche aurait consisté à créer directement les tables PostgreSQL puis générer les entités TypeScript. L'avantage principal est le contrôle total sur la structure et les performances, mais elle pose des problèmes de synchronisation entre schéma de base et code applicatif, complique la maintenance des migrations et risque des divergences entre environnements.

### Schema First

Approche intermédiaire utilisant un fichier de définition central pour générer base et entités. L'avantage est la source de vérité unique, mais elle nécessite de maintenir un schéma séparé en plus des validations Zod déjà existantes dans le monorepo et limite l'utilisation native des types TypeScript dans la logique métier.

### Code First

J'ai retenu l'approche Code First qui définit les entités directement en TypeScript avec les décorateurs MikroORM. Cette approche offre une intégration native dans l'écosystème du monorepo, génère automatiquement les migrations, fournit l'auto-complétion et la vérification de types TypeScript, et assure une cohérence technique complète avec les packages partagés.

## Exemple d'entité MikroORM

### Structure type d'une entité

```typescript
@Entity()
export class Workout {
  @PrimaryKey({ type: 'uuid', defaultRaw: 'gen_random_uuid()' })
  id!: string;

  @Property()
  title!: string;

  @Property()
  description!: string;

  @ManyToOne(() => WorkoutCategory)
  category!: WorkoutCategory;

  @ManyToOne(() => User, { nullable: true })
  createdBy!: User | null;

  @OneToMany(() => WorkoutElement, (element) => element.workout)
  elements = new Collection<WorkoutElement>(this);

  @Property({ onCreate: () => new Date() })
  createdAt: Date = new Date();

  @Property({ onUpdate: () => new Date() })
  updatedAt: Date = new Date();
}
```

Cette entité `Workout` illustre plusieurs patterns adoptés systématiquement :

- **Identifiants UUID** : L'utilisation de `gen_random_uuid()` évite les conflits lors des synchronisations entre environnements
- **Relations typées** : Les décorateurs `@ManyToOne` et `@OneToMany` établissent les relations
- **Timestamps automatiques** : Les propriétés `createdAt` et `updatedAt` s'actualisent automatiquement

### Gestion des relations polymorphes

```typescript
@Entity()
@Check({
  name: 'check_one_element_type',
  expression: `
    (type = 'exercise' AND exercise_id IS NOT NULL AND complex_id IS NULL) OR
    (type = 'complex' AND complex_id IS NOT NULL AND exercise_id IS NULL)
  `,
})
export class WorkoutElement {
  @Enum({ items: () => Object.values(WORKOUT_ELEMENT_TYPES) })
  type!: WorkoutElementType;

  @ManyToOne(() => Exercise, { nullable: true })
  exercise?: Exercise;

  @ManyToOne(() => Complex, { nullable: true })
  complex?: Complex;

  @Property()
  sets!: number;

  @Property()
  reps!: number;
  
  // Autres propriétés communes...
}
```

Le décorateur `@Check` traduit la contrainte logique en contrainte PostgreSQL, garantissant l'intégrité des données même en cas d'accès direct à la base.

## Architecture en couches détaillée

### Structure du projet backend

```markdown
apps/api/src/
├── modules/                   # Modules métier organisés par domaine
│   ├── identity/              # Authentification, autorisation, organisations
│   │   ├── domain/            # Entités métier
│   │   ├── application/       # Use cases et ports/interfaces
│   │   ├── infrastructure/    # Implémentations (repositories)
│   │   └── interface/         # Controllers, DTOs, guards, Mappers, Presenters
│   ├── training/              # Gestion des entraînements et exercices
│   │   └──...
├── config/                    # Configuration centralisée
├── seeders/                   # Données de test et d'initialisation
└── main.ts                    # Point d'entrée de l'application
```

Cette architecture backend s'inspire des principes du Domain-Driven Design et de l'architecture hexagonale, même si je ne les applique pas de manière puriste. Cette séparation en couches facilite l'intégration future de services externes : si demain je souhaite récupérer automatiquement les résultats de compétitions depuis le site de la fédération d'haltérophilie ou connecter des chronos physiques en salle, je peux le faire en créant de nouveaux adaptateurs dans l'Infrastructure Layer sans modifier la logique métier. Cette isolation garantit une meilleure maintenabilité à long terme pour un projet qui évoluera au-delà de ma formation.

### Interface Layer : exposition HTTP

L'Interface Layer centralise toute l'orchestration HTTP : sécurité, transformation des données et formatage des réponses. Cette couche fait le pont entre le protocole HTTP et la logique métier.

#### Controllers : orchestration et délégation

```typescript
@UseGuards(PermissionsGuard) // 1. Guard global pour l'authentification
@Controller()
export class WorkoutController {
  constructor(
    @Inject(WORKOUT_USE_CASES)
    private readonly workoutUseCases: IWorkoutUseCases
  ) {}

  @TsRestHandler(c.getWorkout) // 2. Contrat d'API type-safe
  @RequirePermissions('read')  // 3. Permission spécifique requise
  getWorkout(
    @CurrentOrganization() organizationId: string, // 4. Extraction organisation
    @CurrentUser() user: AuthenticatedUser         // 5. Extraction utilisateur
  ): ReturnType<typeof tsRestHandler<typeof c.getWorkout>> {
    return tsRestHandler(c.getWorkout, async ({ params }) => {
      try {
        // 6. Appel de la logique métier (retourne une entité Workout)
        const workout = await this.workoutUseCases.getWorkoutWithDetails(
          params.id,
          organizationId,
          user.id
        );

        // 7. Transformation en DTO pour respecter le contrat d'API
        const workoutDto = WorkoutMapper.toDto(workout);

        // 8. Formatage de la réponse HTTP
        return WorkoutPresenter.presentOne(workoutDto);
      } catch (error) {
        // 9. Gestion centralisée des erreurs
        return WorkoutPresenter.presentError(error as Error);
      }
    });
  }
}
```

Le controller orchestre plusieurs responsabilités en cascade :

- **Niveau 1 - Authentification** : `PermissionsGuard` vérifie le rôle de l'utilisateur connecté
- **Niveau 2 - Isolation organisationnelle** : `@CurrentOrganization()` extrait l'organisation du contexte
- **Niveau 3 - Permissions** : `@RequirePermissions('read')` vérifie les droits spécifiques
- **Niveau 4 - Type safety** : `@TsRestHandler()` assure la cohérence avec le contrat d'API
- **Niveau 5 - Transformation** : Le mapper convertit l'entité en DTO
- **Niveau 6 - Formatage** : Le presenter structure la réponse HTTP

#### Mappers : transformation entités → DTO

Les mappers transforment les entités de domaine en objets conformes au contrat d'API défini dans `@dropit/contract`. Ils sont organisés en objets avec des méthodes statiques :

```typescript
export const WorkoutMapper = {
  toDto(workout: Workout): WorkoutDto {
    return {
      id: workout.id,
      title: workout.title,
      workoutCategory: workout.category.name, // Simplification : nom au lieu de l'objet complet
      description: workout.description,
      elements: workout.elements.getItems().map(element => ({
        // Transformation de chaque élément (exercice ou complexe)
        id: element.id,
        type: element.type,
        sets: element.sets,
        reps: element.reps,
        // ...
      })),
    };
  },

  toDtoList(workouts: Workout[]): WorkoutDto[] {
    return workouts.map(this.toDto);
  }
}
```

**Rôles du mapper** :
- **Protection de la structure interne** : N'expose pas directement les entités MikroORM
- **Respect du contrat d'API** : Structure exactement conforme au schéma Zod défini dans `@dropit/contract`
- **Simplification** : Aplatit les relations complexes (ex: ne retourne que le nom de la catégorie)

#### Presenters : formatage des réponses HTTP

Les presenters normalisent le format des réponses HTTP avec les codes de statut appropriés :

```typescript
export const WorkoutPresenter = {
  presentOne(workout: WorkoutDto) {
    return { status: 200 as const, body: workout };
  },

  presentList(workouts: WorkoutDto[]) {
    return { status: 200 as const, body: workouts };
  },

  presentSuccess(message: string) {
    return { status: 200 as const, body: { message } };
  },

  presentError(error: Error) {
    // Gestion des exceptions métier
    if (error instanceof WorkoutException) {
      return {
        status: error.statusCode as 400 | 403 | 404 | 500,
        body: { message: error.message }
      };
    }

    // Masquage des erreurs techniques
    console.error('Unexpected error:', error);
    return {
      status: 500 as const,
      body: { message: 'An error occurred while processing the request' }
    };
  }
}
```

**Rôles du presenter** :
- **Normalisation des codes HTTP** : Assure la cohérence (200, 404, 500, etc.)
- **Sécurisation** : Masque les détails techniques des erreurs internes
- **Centralisation** : Format uniforme pour toute l'API

### Application Layer : orchestration métier

L'Application Layer contient les Use Cases qui concentrent la logique métier pure, sans aucune dépendance à NestJS ou au protocole HTTP. Les use cases retournent des entités de domaine et lancent des exceptions métier en cas d'erreur.

#### Exemple de Use Case

```typescript
export class WorkoutUseCases implements IWorkoutUseCases {
  constructor(
    private readonly workoutRepository: IWorkoutRepository,
    private readonly workoutCategoryRepository: IWorkoutCategoryRepository,
    private readonly exerciseRepository: IExerciseRepository,
    private readonly complexRepository: IComplexRepository,
    private readonly memberUseCases: IMemberUseCases
  ) {}

  async createWorkout(data: CreateWorkout, organizationId: string, userId: string): Promise<Workout> {
    // 1. Vérification des autorisations
    const isCoach = await this.memberUseCases.isUserCoachInOrganization(userId, organizationId);
    if (!isCoach) {
      throw new WorkoutAccessDeniedException('User is not coach of this organization');
    }

    // 2. Vérification de l'existence des ressources référencées
    const coachFilterConditions = await this.memberUseCases.getCoachFilterConditions(organizationId);

    const category = await this.workoutCategoryRepository.getOne(
      data.workoutCategory,
      coachFilterConditions
    );
    if (!category) {
      throw new WorkoutCategoryNotFoundException('Workout category not found or access denied');
    }

    // 3. Vérification des exercices/complexes référencés
    for (const element of data.elements) {
      const resource = element.type === 'exercise'
        ? await this.exerciseRepository.getOne(element.id, coachFilterConditions)
        : await this.complexRepository.getOne(element.id, coachFilterConditions);

      if (!resource) {
        throw new WorkoutValidationException(`${element.type} not found or access denied`);
      }
    }

    // 4. Création du workout
    const createdWorkout = await this.workoutRepository.save(/* ... */);

    // Retour de l'entité (la transformation en DTO se fera dans le Controller)
    return createdWorkout;
  }
}
```

**Caractéristiques des Use Cases** :
- **Pur TypeScript** : Aucune dépendance à NestJS ou au framework web
- **Logique métier** : Valide les règles business (autorisations, intégrité des données)
- **Exceptions métier** : Lance des exceptions typées (`WorkoutNotFoundException`, etc.)
- **Retour d'entités** : Retourne des entités de domaine, pas des DTO
- **Orchestration** : Coordonne plusieurs repositories et use cases

### Domain Layer : modèle métier

#### Entités avec décorateurs MikroORM

```typescript
@Entity() // Décorateur qui marque cette classe comme une entité de base de données
@Check({
  name: 'check_one_element_type',
  expression: `(type = 'exercise' AND exercise_id IS NOT NULL) OR (type = 'complex' AND complex_id IS NOT NULL)`
})
export class WorkoutElement {
  @PrimaryKey({ type: 'uuid', defaultRaw: 'gen_random_uuid()' })
  id!: string;

  @Enum({ items: () => Object.values(WORKOUT_ELEMENT_TYPES) })
  type!: WorkoutElementType; // Enum contraint à 'exercise' ou 'complex'
  
  @ManyToOne(() => Exercise, { nullable: true })
  exercise?: Exercise; // Relation optionnelle vers un exercice
  
  @ManyToOne(() => Complex, { nullable: true })
  complex?: Complex; // Relation optionnelle vers un complexe
  
  @Property()
  sets!: number; // Nombre de séries
  
  @Property()
  reps!: number; // Nombre de répétitions
  
  @Property({ onCreate: () => new Date() })
  createdAt: Date = new Date(); // Timestamp automatique
}
```

Chaque décorateur MikroORM a un rôle spécifique :
- `@Entity()` : Indique que cette classe correspond à une table en base de données
- `@Property()` : Mappe les propriétés simples vers des colonnes de base de données
- `@ManyToOne()` : Établit les associations entre entités et génère les clés étrangères
- `@Check()` : Traduit une règle métier en contrainte PostgreSQL
- `@Property({ onCreate: () => new Date() })` : Configure des comportements de lifecycle

**Note** : Dans une architecture hexagonale pure, ces entités devraient être découplées de MikroORM avec des entités domaine séparées et un système de mapping. Cette séparation constitue un objectif d'évolution future pour renforcer l'indépendance de la couche métier vis-à-vis des détails d'infrastructure.

### Infrastructure Layer : accès aux données

#### Repository personnalisé

```typescript
@Injectable()
export class MikroWorkoutRepository extends EntityRepository<Workout> implements IWorkoutRepository {
  constructor(public readonly em: EntityManager) {
    super(em, Workout);
  }

  // Méthode spécialisée avec populate profond et filtrage organisationnel
  async getOneWithDetails(id: string, coachFilterConditions: CoachFilterConditions): Promise<Workout | null> {
    return await this.em.findOne(
      Workout,
      { id, $or: coachFilterConditions.$or },
      {
        populate: [
          'category',
          'elements',
          'elements.exercise',
          'elements.exercise.exerciseCategory',
          'elements.complex',
          'elements.complex.complexCategory',
          'elements.complex.exercises',
          'elements.complex.exercises.exercise',
          'elements.complex.exercises.exercise.exerciseCategory',
          'createdBy'
        ],
      }
    );
  }
}
```

Cette approche hybride donne le meilleur des deux mondes : l'héritage d'`EntityRepository<Workout>` conserve l'accès aux méthodes MikroORM optimisées, tandis que l'implémentation de `IWorkoutRepository` garantit le respect du contrat métier.


## Gestion des migrations en production

Lorsqu'un développeur modifie une entité, il génère la migration correspondante via `pnpm db:migration:create`. MikroORM analyse automatiquement les changements et produit le script SQL nécessaire.

### Exemple de migration générée

```typescript
import { Migration } from '@mikro-orm/migrations';

export class Migration20240115000000 extends Migration {

  async up(): Promise<void> {
    this.addSql('alter table "workout" add column "difficulty_level" int null;');
    this.addSql('alter table "workout" add constraint "workout_difficulty_level_check" check ("difficulty_level" >= 1 and "difficulty_level" <= 5);');
  }

  async down(): Promise<void> {
    this.addSql('alter table "workout" drop constraint "workout_difficulty_level_check";');
    this.addSql('alter table "workout" drop column "difficulty_level";');
  }
}
```

Lors du processus de mise en production, la CI vérifie l'application de ces migrations avant le déploiement complet par mesure de sécurité.
