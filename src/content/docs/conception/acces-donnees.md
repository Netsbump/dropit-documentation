---
title: Accès aux données
description: Implémentation de la couche d'accès aux données
---

## Approche générale

Pour implémenter l'accès aux données, j'utilise MikroORM comme ORM (Object-Relational Mapping). Ce choix, comme expliqué dans la section architecture, permet de bénéficier du pattern Unit of Work et d'un typage fort avec TypeScript.

## Entités et Repositories

### Structure des entités

Les entités représentent la traduction en code des tables définies dans le [modèle de données](/conception/base-donnees). Voici un exemple simplifié d'une entité :

```typescript
@Entity()
export class Athlete {
  @PrimaryKey()
  id: string;

  @Property()
  name: string;

  @ManyToOne(() => Coach)
  coach: Coach;

  @OneToMany(() => Training, training => training.athlete)
  trainings = new Collection<Training>(this);
}
```

### Repositories personnalisés

Les repositories dans MikroORM servent uniquement à l'accès aux données, suivant le pattern Repository. Leur rôle est de fournir une abstraction pour les opérations de base de données, sans inclure de logique métier. Par exemple :

```typescript
@Repository(Athlete)
export class AthleteRepository extends EntityRepository<Athlete> {
  async findByCoachId(coachId: string): Promise<Athlete[]> {
    return this.find({ coach: coachId });
  }
}
```

La logique métier, elle, appartient aux services. Voici un exemple de service utilisant le repository :

```typescript
@Injectable()
export class AthleteService {
  constructor(private readonly athleteRepository: AthleteRepository) {}

  async getActiveAthletesByCoach(coachId: string): Promise<Athlete[]> {
    const athletes = await this.athleteRepository.findByCoachId(coachId);
    // Logique métier pour filtrer les athlètes actifs
    return athletes.filter(athlete => athlete.isActive);
  }
}
```

## Gestion des transactions

MikroORM, intégré à NestJS via le package `@mikro-orm/nestjs`, gère automatiquement les transactions pour chaque requête HTTP grâce au pattern Unit of Work. Cela signifie que toutes les modifications d'entités sont suivies et persistées de manière cohérente à la fin de chaque requête.

Il est toutefois possible de gérer explicitement les transactions pour des cas plus complexes. Par exemple :

```typescript
@InjectEntityManager()
private readonly em: EntityManager;

async createTrainingProgram(data: TrainingProgramDto) {
  try {
    // Toutes les opérations dans une même transaction
    await em.transactional(async () => {
      // Création du programme
      // Ajout des exercices
      // Mise à jour des relations
    });
  } catch (error) {
    // Gestion des erreurs
  }
}
```

Cette gestion explicite des transactions est particulièrement utile lorsqu'on doit s'assurer que plusieurs opérations sont exécutées de manière atomique, comme la création d'un programme d'entraînement avec ses exercices associés.

## Cache et performances

### Utilisation de Redis

Pour optimiser les performances, certaines données fréquemment accédées sont mises en cache dans Redis :
- Les programmes d'entraînement du jour
- Les maximums des athlètes
- Les données de référence (types d'exercices, etc.)

### Stratégies de chargement

J'ai mis en place différentes stratégies de chargement selon les besoins :
- Chargement eager pour les relations essentielles
- Chargement lazy pour les données volumineuses
- Pagination pour les listes longues

## Migrations

La gestion des évolutions de la base de données est automatisée via le système de migrations de MikroORM :
- Génération automatique des migrations à partir des changements d'entités
- Vérification de la cohérence avant application
- Possibilité de revenir en arrière si nécessaire

## Tests

Les repositories et les services d'accès aux données sont couverts par des tests unitaires et d'intégration, détaillés dans la section [Plans de tests](/tests/plans).

