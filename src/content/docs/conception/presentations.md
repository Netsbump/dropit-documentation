
---
title: Couches de présentations
description: Architectures web et mobile
---

## Introduction

Après avoir détaillé l'implémentation de la [couche d'accès aux données](/conception/acces-donnees) avec son architecture en couches et ses repositories, il convient maintenant de s'intéresser aux couches de présentation qui consomment ces données. Les clients web et mobile constituent les points d'entrée des utilisateurs vers l'application, nécessitant une architecture frontend robuste capable de gérer les spécificités de chaque plateforme.

Cette section détaille l'organisation architecturale des clients frontend, en s'appuyant sur l'[architecture logicielle](/conception/architecture) définie précédemment et les patterns établis côté backend. L'approche par features adoptée reflète la même logique de séparation des domaines métier, créant une cohérence architecturale entre toutes les couches de l'application. 

## Stratégie d'architecture frontend

### Choix d'organisation modulaire

Ma stratégie d'architecture frontend s'appuie sur une organisation par features qui traduit directement les domaines métier identifiés lors de l'analyse des besoins. Cette approche m'a semblé plus naturelle que l'organisation traditionnelle par types techniques (composants, services, utils) car elle reflète la façon dont les coachs pensent leur travail.

```
apps/web/src/
├── features/              # Modules métier isolés
│   ├── athletes/          # Gestion des athlètes
│   ├── exercises/         # Catalogue d'exercices  
│   ├── workout/           # Création et édition programmes
│   ├── planning/          # Interface calendaire
│   └── complex/           # Gestion des complexes
├── shared/                # Composants et logique partagés
│   ├── components/ui/     # Design system Shadcn/ui
│   ├── hooks/             # Hooks React réutilisables
│   └── utils/             # Utilitaires communs
└── routes/                # Structure de routage Tanstack Router
```

Cette organisation présente plusieurs avantages que j'ai découverts au fil du développement. D'abord, elle facilite considérablement le développement parallèle : je peux travailler sur la gestion des exercices sans impacter les fonctionnalités de planification. Ensuite, elle respecte le principe de responsabilité unique au niveau des modules, chaque feature encapsulant sa logique métier spécifique.

L'isolation des domaines métier s'avère bénéfique dans le contexte de DropIt où les règles business diffèrent significativement entre la gestion des athlètes et la création d'exercices. Cette séparation me permet d'appliquer des validations et des règles spécifiques sans créer de couplage entre les modules. TODO: Exemple ?

### Intégration de la validation Zod partagée

L'un des aspects les plus enrichissants de cette implémentation a été l'intégration des schémas Zod définis dans le package partagé `@dropit/schemas`. Cette approche résout une problématique récurrente que j'avais rencontrée dans mes projets précédents : maintenir la cohérence des règles de validation entre le frontend et le backend.

```typescript
// Réutilisation des schémas définis dans @dropit/schemas
import { CreateExercise, createExerciseSchema } from '@dropit/schemas';

export function ExerciseCreationForm() {
  const form = useForm<CreateExercise>({
    resolver: zodResolver(createExerciseSchema), // Validation automatique
    defaultValues: {
      name: '',
      description: '',
      category: undefined,
    },
  });

  const { mutateAsync: createExercise } = useMutation({
    mutationFn: async (data: CreateExercise) => {
      // Le schéma Zod valide côté client AVANT l'envoi
      const response = await api.exercise.createExercise({ body: data });
      if (response.status !== 201) throw new Error('Creation failed');
      return response.body;
    },
  });
}
```

Cette intégration m'a permis de découvrir les subtilités de React Hook Form avec Zod. Le `zodResolver` transforme automatiquement les erreurs de validation Zod en messages d'erreur appropriés pour les composants de formulaire, créant une expérience utilisateur fluide où les erreurs apparaissent en temps réel pendant la saisie.

L'avantage le plus significatif réside dans l'élimination des divergences de validation. Dans mes projets précédents, il m'arrivait de définir des règles de validation différentes côté client et serveur, créant des incohérences frustrantes pour l'utilisateur. Avec cette approche centralisée, je garantis qu'un exercice respectant les contraintes côté client sera nécessairement accepté par l'API, réduisant drastiquement les erreurs d'intégration.

### Stratégie de synchronisation des données avec Tanstack Query

Le choix de Tanstack Query pour la gestion de l'état serveur s'est imposé face aux défis spécifiques de synchronisation que présentait DropIt. Dans une application de gestion d'entraînements, les données évoluent constamment : les coachs modifient leurs programmes, les athlètes enregistrent de nouveaux records, les planifications changent. Cette dynamique nécessitait une stratégie robuste de synchronisation entre le client et le serveur. => un peu pédant les "défis spécifiques de synchronisation que présentait DropIt" , non c'est juste des problématique classique de contexte d'une SPA frontend. Il faut parler des alternatives, state react, context, lib externe zustand, redux, et pourquoi finalement j'ai choisi une stratégie de cache de requete http plutot qu'un state ? 

```typescript
// Récupération et cache des catégories d'exercices
const { data: exerciseCategories, isLoading } = useQuery({
  queryKey: ['exercise-categories'],
  queryFn: async () => {
    const response = await api.exerciseCategory.getExerciseCategories();
    if (response.status !== 200) throw new Error('Failed to load categories');
    return response.body;
  },
  staleTime: 1000 * 60 * 5, // Cache pendant 5 minutes
  retry: 3, // 3 tentatives en cas d'échec
});

// Mutation avec invalidation automatique du cache
const { mutateAsync: createExercise } = useMutation({
  mutationFn: createExerciseRequest,
  onSuccess: () => {
    // Revalidation automatique des listes d'exercices
    queryClient.invalidateQueries({ queryKey: ['exercises'] });
    toast.success('Exercice créé avec succès');
  },
  onError: (error) => {
    toast.error(`Erreur: ${error.message}`);
  },
});
```

L'implémentation de cette stratégie de cache m'a fait découvrir la puissance de l'invalidation automatique. Lorsqu'un coach crée un nouvel exercice, Tanstack Query invalide automatiquement toutes les requêtes liées aux exercices, forçant leur rechargement la prochaine fois qu'un composant en aura besoin. Cette synchronisation transparente garantit que les coachs travaillent toujours avec des données à jour, aspect critique pour la cohérence des programmes d'entraînement.

Cette approche me libère également de la gestion manuelle des états de loading et d'erreur que je devais implémenter systématiquement dans mes projets précédents. (c'est a dire ?)

## Implémentation des fonctionnalités

### Stepper de création de programme

Pour la création de programmes d'entraînement, j'ai naturellement opté pour une interface multi-étapes (stepper) qui segmente logiquement le processus : informations générales, composition des exercices, puis planification. Ce pattern UX classique évite de surcharger l'utilisateur d'informations en une seule fois.

L'implémentation s'appuie sur un formulaire unique React Hook Form qui gère toutes les étapes, permettant une validation cohérente sur l'ensemble des données :

```typescript
// Extension du schéma base pour inclure la planification
const extendedWorkoutSchema = createWorkoutSchema.extend({
  trainingSession: z.object({
    athleteIds: z.array(z.string()),
    scheduledDate: z.string(),
  }).optional(),
});

type ExtendedWorkoutSchema = z.infer<typeof extendedWorkoutSchema>;

const steps = [
  { id: 'info', name: 'Description' },
  { id: 'elements', name: 'Construction' }, 
  { id: 'planning', name: 'Planification' },
];

export function WorkoutCreationStepper() {
  const [currentStep, setCurrentStep] = useState(0);
  
  // Formulaire unique pour toutes les étapes
  const form = useForm<ExtendedWorkoutSchema>({
    resolver: zodResolver(extendedWorkoutSchema),
    mode: 'onChange', // Validation temps réel
  });

  const nextStep = async () => {
    // Validation de l'étape courante avant progression
    const isValid = await form.trigger();
    if (isValid) setCurrentStep(prev => prev + 1);
  };
}
```

L'intérêt de cette approche réside dans la cohérence de validation entre les étapes et la persistance automatique des données saisies. L'extension du schéma Zod me permet d'ajouter les champs spécifiques à la planification sans remettre en cause la structure de base définie dans le package partagé.

### Interface drag-and-drop pour la composition

Pour la réorganisation des exercices dans un programme, j'ai choisi d'implémenter une interface drag-and-drop avec dnd-kit. J'aurais pu opter pour une approche plus classique avec des champs numériques permettant de modifier manuellement l'ordre des exercices, mais le drag-and-drop m'a semblé offrir une expérience utilisateur plus moderne et intuitive pour réarranger facilement l'ordre des éléments :

```typescript
import { useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';

interface SortableWorkoutElementProps {
  element: WorkoutElement;
  index: number;
  onRemove: (index: number) => void;
}

export function SortableWorkoutElement({ element, index, onRemove }: SortableWorkoutElementProps) {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: element.id });

  const style = {
    transform: CSS.Transform.toString(transform),
    transition,
    opacity: isDragging ? 0.5 : 1,
  };

  return (
    <Card ref={setNodeRef} style={style} className="relative">
      <CardContent className="flex items-center gap-4 p-4">
        {/* Handle de drag */}
        <div {...attributes} {...listeners} className="cursor-grab">
          <GripVertical className="h-4 w-4 text-muted-foreground" />
        </div>
        
        {/* Contenu de l'exercice */}
        <div className="flex-1">
          <h4>{element.name}</h4>
          <p className="text-sm text-muted-foreground">
            {element.sets} × {element.reps} @ {element.weight}kg
          </p>
        </div>
        
        {/* Action de suppression */}
        <Button variant="ghost" size="sm" onClick={() => onRemove(index)}>
          <Trash2 className="h-4 w-4" />
        </Button>
      </CardContent>
    </Card>
  );
}
```

### Synthèse des concepts appliqués

L'architecture des couches de présentation que j'ai détaillée dans cette section illustre concrètement l'application des patterns architecturaux décrits : organisation par features (workout, exercises, athletes), validation Zod partagée, gestion d'état avec Tanstack Query, et composants Shadcn/ui avec drag-and-drop.

Cette approche met en œuvre plusieurs éléments clés :
- **Validation centralisée** : Les schémas Zod partagés garantissent la cohérence entre client et serveur
- **Gestion d'état optimisée** : Tanstack Query coordonne la synchronisation des données serveur
- **Composants réutilisables** : Le design system Shadcn/ui s'intègre avec les interactions métier
- **Communication typée** : Les contrats ts-rest sécurisent les échanges avec l'API

Le [flow d'interaction détaillé](/conception/interfaces#flow-dinteraction--création-dun-programme) dans la section interfaces montre comment ces éléments architecturaux s'articulent pour former une expérience utilisateur cohérente.


### Routage typé avec Tanstack Router

Pour le routage, j'ai choisi Tanstack Router plutôt que React Router (l'alternative la plus populaire dans l'ecosysteme react) principalement pour sa type safety. Cette caractéristique détecte les erreurs de navigation directement à la compilation, évitant les liens cassés qui peuvent survenir lors de refactoring.

```typescript
// Routes organisées hiérarchiquement
├── __home.tsx                    # Layout principal authentifié
│   ├── __home.dashboard.tsx      # Page d'accueil
│   ├── __home.programs.tsx       # Layout des programmes
│   │   ├── exercises.tsx         # Catalogue d'exercices
│   │   ├── workouts.tsx          # Liste des programmes
│   │   └── complex.tsx           # Gestion des complexes
│   ├── __home.athletes.tsx       # Gestion des athlètes
│   │   └── $athleteId.tsx        # Détail d'un athlète
│   └── __home.planning.tsx       # Interface calendaire
```

Cette structure hiérarchique reflète l'organisation logique de l'application et facilite la gestion des layouts imbriqués. Le préfixe `__home` indique les routes protégées par authentification, simplifiant la logique de protection des pages.

## Stratégie de design system et accessibilité

### Choix de Shadcn/ui : accessibilité et extensibilité

Todo : Shadcn a déjà été présenté dans la page précédente donc ici dire juste une intro pour montrer un peu le code d'un composant shadcnS

```typescript
// Composant Button avec variants typés et accessibilité intégrée
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'destructive' | 'outline' | 'secondary' | 'ghost' | 'link'
  size?: 'default' | 'sm' | 'lg' | 'icon'
  asChild?: boolean
}

// Usage avec accessibilité automatique
<Button 
  variant="outline" 
  size="sm" 
  onClick={handleCreate}
  aria-label="Créer un nouvel exercice"
>
  <Plus className="h-4 w-4 mr-2" aria-hidden="true" />
  Nouvel exercice
</Button>
```

Cette approche me donne des composants robustes avec une base solide que je peux faire évoluer selon les retours utilisateurs, tout en garantissant le respect des standards web modernes.

### Extension avec des composants métier

La fondation Shadcn/ui me permet de créer des composants métier qui étendent les composants de base tout en héritant de leur accessibilité. Ces composants encapsulent la logique métier spécifique à l'application :

```typescript
// Composant de saisie de charge avec calcul automatique de pourcentages
interface WeightInputProps {
  personalRecord?: number;
  value: number;
  onChange: (weight: number, percentage?: number) => void;
}

export function WeightInput({ personalRecord, value, onChange }: WeightInputProps) {
  const [inputMode, setInputMode] = useState<'weight' | 'percentage'>('weight');
  
  const handleWeightChange = (weight: number) => {
    const percentage = personalRecord ? (weight / personalRecord) * 100 : undefined;
    onChange(weight, percentage);
  };
  
  return (
    <div className="flex items-center gap-2">
      <Input 
        type="number" 
        value={value} 
        onChange={(e) => handleWeightChange(Number(e.target.value))}
      />
      {personalRecord && (
        <Badge variant="secondary">
          {Math.round((value / personalRecord) * 100)}% RM
        </Badge>
      )}
    </div>
  );
}
```
Ce composant illustre l'avantage de l'extensibilité : il réutilise les composants `Input` et `Badge` de base avec leur accessibilité native, tout en ajoutant la logique métier nécessaire. Cette approche me permet de construire une bibliothèque de composants cohérente adaptée aux besoins de l'application.

## Considérations de performance

### Optimisations mises en place

Dans un contexte d'apprentissage, j'ai appliqué plusieurs optimisations classiques du développement React moderne, sans tomber dans l'optimisation prématurée qui peut nuire à la lisibilité du code :

```typescript
// Lazy loading des composants volumineux
const WorkoutEditor = lazy(() => import('./workout-editor'));

// Memoization des calculs coûteux
const calculatedWorkoutStats = useMemo(() => {
  return workoutElements.reduce((stats, element) => {
    stats.totalVolume += element.sets * element.reps * element.weight;
    stats.totalDuration += element.sets * element.restTime;
    return stats;
  }, { totalVolume: 0, totalDuration: 0 });
}, [workoutElements]);

// Debouncing des recherches
const debouncedSearch = useDebounce(searchTerm, 300);
```

Ces optimisations ciblent les problématiques de performance les plus courantes : chargement différé des composants lourds, évitement des calculs redondants, et limitation des appels réseau excessifs lors des recherches. Dans le contexte d'usage de DropIt (quelques dizaines d'utilisateurs par club), ces optimisations suffisent largement.

### Optimisations du build avec Vite

L'utilisation de Vite comme bundler apporte des optimisations automatiques que je n'ai pas eu à configurer manuellement :
- **Code splitting** : Chargement à la demande des modules par feature
- **Tree shaking** : Élimination du code non utilisé lors de la production
- **Compression** : Réduction significative de la taille des assets

Cette approche me permet de bénéficier d'optimisations modernes sans configuration complexe, aspect appréciable dans un contexte de formation où je préfère me concentrer sur les aspects métier plutôt que sur l'optimisation fine du bundling.

## Bilan de l'implémentation frontend

Cette implémentation frontend m'a permis de concrétiser les wireframes définis précédemment en interface fonctionnelle. Les choix techniques réalisés - architecture par features, validation Zod partagée, design system accessible avec Shadcn/ui - créent une base solide pour l'évolution future de l'application.

L'approche progressive que j'ai adoptée, partant des besoins utilisateurs vers l'implémentation technique, s'est révélée efficace pour maintenir la cohérence entre les différentes couches de l'application. L'intégration avec le monorepo et les packages partagés garantit la synchronisation avec l'API backend, aspect crucial pour la fiabilité de l'ensemble du système.

La prochaine section aborde les aspects sécuritaires de DropIt, domaine fondamental pour une application gérant des données personnelles d'athlètes. 