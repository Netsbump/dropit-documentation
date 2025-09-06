---
title: Base de données
description: Conception et modélisation de la base de données
---

## Approche de conception

Pour concevoir la base de données de DropIt, j'ai choisi d'utiliser la méthode Merise, approche méthodologique française que j'ai étudiée dans ma formation et qui s'avère particulièrement adaptée aux projets avec des relations complexes entre entités.

Cette méthode structure la conception en trois niveaux d'abstraction successifs : conceptuel (MCD), logique (MLD) et physique (MPD). Cette progression méthodique m'a permis de partir des besoins métier exprimés lors de l'analyse fonctionnelle pour arriver progressivement à une structure de base de données optimisée pour PostgreSQL.

Merise me convenait pour structurer les relations métier de DropIt. Les principales interactions sont assez simples : un coach assigne des programmes à ses athlètes, ces programmes composent des exercices avec des paramètres spécifiques (séries, répétitions, charges). La méthode Merise m'aide à organiser ces données sans redondance.

## Modèle Conceptuel de Données (MCD)

Le MCD constitue la première étape de ma démarche de modélisation, où je me concentre exclusivement sur les concepts métier de l'haltérophilie sans considération technique. Cette approche m'a permis d'identifier et de structurer les entités fondamentales du domaine ainsi que leurs interactions.

![Modèle Conceptuel de Données DropIt](../../../assets/mcd-dropit.png)

### Entités principales identifiées

L'analyse des besoins métier m'a conduit à identifier plusieurs entités centrales :

**Athlete** : Représente les pratiquants d'haltérophilie qui utilisent l'application mobile. Cette entité centralise les informations personnelles (nom, prenom) et les caractéristiques sportives (niveau, spécialité) nécessaires à la personnalisation des programmes.

**Exercise** : Catalogue des mouvements d'haltérophilie (épaulé-jeté, arraché, squat, etc.). Chaque exercice comporte des métadonnées spécifiques : nom, description, groupe musculaire ciblé.

**Complex** : Catalogue d'ensemble d'exercices ordonnés, utilisé pour travailler un mouvement spécifique en haltérophilie. Un complex enchaîne plusieurs exercices sans repos (par exemple : power clean + front squat + push press). Cette composition nécessite au minimum deux exercices pour constituer une séquence cohérente.

**Workout** : Programme d'entraînement structuré créé par un coach. Un workout définit une séquence d'exercices et ou de complex avec leurs paramètres spécifiques (séries, répétitions, charges, temps de repos).

**TrainingSession** : Séance d'entraînement réalisée par un athlète à partir d'un workout. Cette entité capture la date d'entrainement ainsi que des notes que l'athlète peut communiquer à l'entraineur afin d'ajuster les futurs entrainements ou permettre le suivi de la progression.

**PersonalRecord** : Permet d'enregistrer la performance maximal d'un athlète lié à un exercice existant. Ce record permet ensuite de calculer automatiquement les charges que l'athlete doit mettre sur sa barre pour les différents entrainement que le coach établira. 

### Relations métier

La spécificité de mon application réside dans ses relations many-to-many qui nécessitent des paramètres contextuels :

**Athlete ↔ Workout** : Un athlète peut se voir assigner plusieurs programmes par son coach selon la périodisation de son entraînement. Un même programme peut être réutilisé pour différents athlètes en adaptant les charges selon leur niveau individuel.

**Exercise ↔ Workout** : Un exercice peut apparaître dans de nombreux programmes avec des paramètres variables (3x5 à 80% pour la force vs 5x2 à 90% pour la puissance). Cette relation nécessite une table de jonction enrichie.

### Simplification volontaire du périmètre

Dans ce MCD, j'ai volontairement omis les entités liées à l'authentification et aux autorisations (User, Organization, Role, Permission) qui seront détaillées dans la section [sécurité](/securite/conception). Cette approche me permet de me concentrer sur le cœur métier de l'application tout en maintenant la lisibilité du schéma conceptuel.

## Modèle Logique de Données (MLD)

Le passage du MCD au MLD constitue une étape cruciale où je traduis les concepts métier en structures relationnelles concrètes. Cette transformation implique la résolution des relations many-to-many et l'introduction des clés étrangères nécessaires à l'intégrité référentielle.

![Modèle Logique de Données DropIt](../../../assets/mld-dropit.png)

### Transformation des relations

Le passage au MLD m'a demandé de résoudre plusieurs types de relations selon les besoins métier :

**Relations many-to-many avec attributs :**

**AthleteTrainingSession** : Lie un athlète à une session d'entraînement avec des informations contextuelles comme le statut de la session et des notes personnelles. Cette table capture la réalisation effective d'un entraînement par un athlète.

**Relations one-to-many enrichies :**

**WorkoutElement** : Chaque élément d'un workout (exercise ou complex) nécessite des paramètres spécifiques :
- `type` : Indique si l'élément est un exercice simple ou un complexe
- `sets`, `reps` : Paramètres de volume d'entraînement
- `weight` : Charge prévue (peut être un pourcentage du record personnel)
- `restTime` : Temps de récupération entre séries
- `orderInWorkout` : Position dans la séquence du programme
- `notes` : Instructions techniques spécifiques

**PersonalRecord** : Chaque exercice peut avoir plusieurs records personnels pour un athlète (1RM, 3RM, 5RM). Ces records servent ensuite au calcul automatique des charges d'entraînement.

**Exercise_Complex** : Table de jonction qui définit quels exercices composent un complexe et dans quel ordre ils doivent être exécutés.

**Relations de référence simples :**

Les entités de catégorisation (ExerciseCategory, WorkoutCategory, ComplexCategory) utilisent des relations one-to-many classiques pour organiser les données sans attributs supplémentaires.

### Décisions de normalisation

La normalisation consiste à organiser les données pour éviter les redondances et garantir la cohérence. J'ai appliqué la **troisième forme normale (3NF)**, qui élimine les dépendances transitives entre les données.

**Principe appliqué** : Chaque information n'est stockée qu'à un seul endroit. Les caractéristiques d'un exercice (nom, description, catégorie) sont uniquement dans la table `Exercise`, et les autres tables y font simplement référence via `exercise_id`. Cette approche évite les incohérences et facilite les modifications.

J'ai accepté quelques exceptions pour optimiser les performances :
- Les `PersonalRecord` stockent directement la référence vers l'exercice ET l'athlète, ce qui évite des jointures complexes lors du calcul automatique des charges d'entraînement
- Cette duplication contrôlée accélère une opération critique : quand un coach crée un programme, l'application peut immédiatement calculer les charges recommandées sans requête supplémentaire

Les informations de base restent centralisées (un exercice = une seule définition), mais les données de performance sont optimisées pour un accès rapide lors de l'utilisation quotidienne de l'application.

### Gestion des clés et contraintes

J'ai opté pour des clés primaires UUID plutôt que des entiers auto-incrémentés pour des raisons pratiques liées au développement et au déploiement.

Les UUID facilitent les opérations de développement en évitant les conflits d'identifiants lors de la synchronisation entre les environnements de développement, test et production. Quand plusieurs développeurs créent des données de test, les UUID évitent naturellement les collisions d'identifiants.

Cette approche simplifie également les opérations de migration et d'import de données. Lors de la fusion de données de test ou de l'import de catalogues d'exercices externes, je n'ai pas à me soucier des conflits d'identifiants numériques.

Le principal inconvénient reste l'espace de stockage plus important (16 bytes vs 4 bytes pour un integer), mais dans le contexte d'un club d'haltérophilie avec quelques centaines d'utilisateurs maximum, cet overhead reste négligeable face à la simplicité opérationnelle.

Pour l'intégrité référentielle, j'ai identifié les stratégies de suppression nécessaires selon les types de relations. Les relations de composition nécessitent un comportement CASCADE : si un workout est supprimé, ses éléments doivent l'être automatiquement puisqu'ils n'ont pas de sens sans leur parent. À l'inverse, les relations de référence requièrent RESTRICT pour empêcher la suppression accidentelle d'un exercice encore utilisé dans des programmes actifs.

## Modèle Physique de Données (MPD)

Le MPD constitue l'aboutissement de ma démarche de modélisation, traduisant le modèle logique en structure PostgreSQL optimisée. Cette étape implique des choix techniques précis sur les types de données, les contraintes d'intégrité et les optimisations de performance.

![Modèle Physique de Données DropIt](../../../assets/mpd-dropit.png)

### Choix des types de données PostgreSQL

Ma sélection des types de données s'appuie sur les spécificités de PostgreSQL et les besoins métier de l'haltérophilie :

**UUID pour les identifiants** : Comme évoqué précédemment, ce choix facilite la distribution et évite les conflits d'identifiants.

**VARCHAR avec contraintes de longueur** : Pour les champs textuels (noms, descriptions, titres), j'ai défini des longueurs appropriées plutôt que d'utiliser TEXT illimité. Les catégories restent extensibles par les coachs selon leurs besoins spécifiques.

**TIMESTAMP** : Pour toutes les dates de création, modification et d'enregistrement. PostgreSQL offre une gestion native des fuseaux horaires.

**INTEGER** : Pour les valeurs numériques comme les séries, répétitions, temps de repos, ordres de séquence.

**DECIMAL** : Pour les charges, poids et valeurs de performance, garantissant une précision exacte nécessaire aux calculs de pourcentages et progressions.

**BOOLEAN** : Pour les flags et statuts binaires présents dans le modèle.

**TEXT** : Pour les URLs des fichiers média stockés en externe (photos d'exercices, vidéos de démonstration).

Cette approche me permet de bénéficier des optimisations PostgreSQL tout en maintenant une flexibilité pour les évolutions futures du modèle.

### Gestion des médias

L'entité `Media` visible dans le MPD gère les ressources visuelles associées aux exercices : photos de démonstration, vidéos d'exécution correcte, schémas anatomiques. Ces médias sont stockés sur un service externe (Cloudinary ou similaire) et référencés par leur URL dans la base de données.

Cette séparation entre données structurées (PostgreSQL) et fichiers média (service spécialisé) optimise les performances et simplifie la gestion des sauvegardes.

### Pattern de référence polymorphe

Pour permettre aux programmes d'entraînement d'inclure à la fois des exercices simples et des complexes, j'ai choisi un pattern de référence polymorphe dans la table `WorkoutElement`.

**Principe retenu** : Une table unique avec un discriminant `element_type` et deux clés étrangères optionnelles (`exercise_id` et `complex_id`). Une contrainte CHECK garantit qu'exactement une des deux références est remplie selon le type.

**Alternatives considérées** :

*Option 1 - Tables séparées* : Créer `WorkoutExercise` et `WorkoutComplex` distinctes.
- ✅ Avantages : Structure plus claire, pas de colonnes NULL, contraintes d'intégrité simples
- ❌ Inconvénients : Duplication des colonnes communes (sets, reps, weight, rest_time, order_index) dans chaque table, duplication du code applicatif (2 repositories, 2 DTOs), complexité pour afficher une séquence ordonnée d'éléments mixtes

*Option 2 - Table d'union* : Une table `WorkoutElement` générique pointant vers une table `TrainingElement` qui fait le lien.
- ✅ Avantages : Extensibilité maximale  
- ❌ Inconvénients : Sur-ingénierie pour mon cas d'usage, jointures supplémentaires

**Justification du choix** : Le pattern polymorphe mutualise les colonnes communes (sets, reps, weight, etc.) qui s'appliquent aussi bien aux exercices qu'aux complexes, évite la duplication de code, et facilite l'affichage ordonné des programmes. Les contraintes CHECK compensent la flexibilité par la rigueur des validations.

Le polymorphisme est contrôlé par une contrainte CHECK qui garantit qu'exactement une des deux références est renseignée selon le type déclaré, évitant ainsi les incohérences de données.

### Contraintes d'intégrité spécifiques

J'ai réfléchi à la répartition des contraintes entre la validation Zod (early validation) et les contraintes de base de données selon leur nature.

**Contraintes structurelles en base de données** :
Les contraintes qui garantissent la cohérence structurelle restent au niveau base de données car elles constituent le dernier rempart contre l'incohérence :

```sql
-- Garantit l'intégrité référentielle polymorphe
ALTER TABLE workout_element ADD CONSTRAINT valid_element_reference 
  CHECK ((element_type = 'exercise' AND exercise_id IS NOT NULL AND complex_id IS NULL) 
      OR (element_type = 'complex' AND complex_id IS NOT NULL AND exercise_id IS NULL));
```

**Contraintes métier déportées vers les couches applicatives** :

J'ai réparti les autres contraintes selon leur nature entre Zod et les use cases pour optimiser l'expérience utilisateur et les performances.

Les validations de bornes métier sont gérées par Zod dans les schémas partagés :

```typescript
// Exemple concret de validation Zod pour WorkoutElement
const WorkoutElementSchema = z.object({
  sets: z.number().min(1, "Au moins 1 série requise").max(10, "Maximum 30 séries"),
  reps: z.number().min(1, "Au moins 1 répétition").max(50, "Maximum 50 répétitions"),
  weight: z.number().min(0, "Le poids ne peut être négatif").max(300, "Poids maximum 300kg"),
});
```

Cette approche présente plusieurs avantages :
- Validation immédiate côté client et serveur
- Messages d'erreur clairs pour les utilisateurs
- Évolutivité sans migration de base de données

Les contraintes temporelles comme `recorded_at <= NOW()` pour l'entité `PersonalRecord` sont quant à elles gérées dans les use cases qui contrôlent le contexte métier de création et modification des enregistrements. Cette logique appartient naturellement à la couche applicative qui maîtrise les règles business.

Cette stratification respecte le principe de défense en profondeur : validation early avec Zod pour l'expérience utilisateur, validation métier dans les use cases, contraintes structurelles en base pour l'intégrité finale des données.

### Stratégie d'optimisation par indexation

Dans l'état actuel du MVP, je me contente des index automatiques sur les clés primaires et étrangères. Cette approche volontairement minimaliste évite l'optimisation prématurée et me permet de démarrer avec une base de données simple.

Un index accélère les requêtes SELECT mais ralentit les écritures (INSERT, UPDATE, DELETE) car il doit être maintenu à jour. Pour un club avec quelques dizaines d'athlètes, cette optimisation n'est pas nécessaire au lancement.

Cependant, j'ai identifié les requêtes qui pourraient devenir problématiques si le volume augmente :

- **Consultation des séances d'un athlète** : Un coach consulte régulièrement l'historique des séances de ses athlètes
- **Calcul des charges d'entraînement** : L'application récupère le record personnel le plus récent pour un exercice donné lors de la création d'un programme
- **Liste des programmes publiés** : Les athlètes consultent leurs programmes actifs depuis l'application mobile

Si les temps de réponse deviennent problématiques, j'ajouterai les index correspondants en me basant sur les requêtes lentes identifiées via les logs PostgreSQL.

Cette approche pragmatique privilégie la simplicité initiale avec une possibilité d'optimisation guidée par les métriques réelles.

### Préparation pour la mise en cache

La structure que j'ai conçue anticipe l'intégration future de Redis comme système de cache. Cette solution me permettra d'améliorer les temps de réponse lorsque le nombre d'utilisateurs augmentera, sans modifier l'architecture de base de données existante.

J'ai identifié les données qui bénéficieraient le plus de cette optimisation :
- Catalogue d'exercices et complex complets (données qui changent rarement)
- Programmes d'entraînement consultés quotidiennement par les athlètes  
- Records personnels récents utilisés pour calculer les charges d'entraînement
- Compositions des complex les plus populaires auprès des coachs

Cette approche évolutive me convient parfaitement : commencer avec PostgreSQL seul pour le MVP, puis ajouter Redis si les métriques de performance le justifient en production.

## Stratégie d'évolution

Dans ma conception de la base de données, j'ai réfléchi aux fonctionnalités qui pourraient émerger après le lancement du MVP. Plutôt que de tout implémenter dès le départ, j'ai préféré identifier les extensions logiques que les retours utilisateurs du club pourraient justifier.

### Extensions métier envisagées

L'architecture actuelle facilite l'ajout de nouvelles fonctionnalités selon les retours d'usage du club :

**Messages du coach** : Une entité `CoachMessage` permettrait de diffuser des annonces générales (événements particuliers, rappels globaux) aux athlètes d'une organisation. Cette table pourrait inclure un système de priorité et une date d'expiration pour gérer automatiquement la visibilité des messages.

**Système de notifications** : Une entité `Notification` centralisée gérerait les alertés push vers les applications mobiles (nouveaux programmes assignés, rappels de séances, félicitations pour les records). Cette approche permettrait un historique des notifications et la gestion des préférences utilisateur.

**Catégorisation enrichie des exercices** : L'ajout d'entités `MuscleGroup` et `Equipment` structurerait mieux le catalogue d'exercices. Ces références faciliteraient les recherches avancées (exercices pour les jambes, exercices nécessitant des haltères) et l'élaboration de programmes équilibrés.

**Indicateurs de difficulté** : Une extension de `Workout` avec un champ difficulté aiderait les coachs à graduer leurs programmes selon le niveau des athlètes. Cette information pourrait également alimenter des statistiques de progression.

**Gestion des tempos avancés** : Pour les coachs expérimentés, deux niveaux de tempo enrichiraient la programmation :
- Macro tempo (EMOM, TABATA, AMRAP) au niveau des `Complex` pour structurer les séquences d'exercices
- Micro tempo (2-2-1, 3-0-1) au niveau des `WorkoutElement` pour contrôler le rythme d'exécution de chaque exercice

Ces extensions s'intègrent naturellement dans l'architecture existante sans remettre en cause les relations fondamentales.

### Stratégie de migration

L'évolution de ce modèle de données nécessitera une approche méthodique pour préserver l'intégrité des données existantes. J'ai prévu d'utiliser le système de migrations de MikroORM pour gérer ces évolutions de schéma de façon sécurisée.

Cette stratégie inclut le versioning des modifications, la possibilité de rollback, et la validation des migrations avant déploiement en production.

La section suivante sur l'[accès aux données](/conception/acces-donnees) détaille l'implémentation de ces modèles avec MikroORM et les patterns de développement adoptés.

