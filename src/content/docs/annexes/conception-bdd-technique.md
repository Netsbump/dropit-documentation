---
title: Conception technique de la base de données
description: Détails techniques et décisions d'implémentation pour la base de données DropIt
---

## Introduction

Cette annexe présente les détails techniques de la conception de la base de données DropIt, incluant les décisions de normalisation, la gestion des clés et contraintes, les choix d'optimisation et les extensions métier envisagées.

## Décisions de normalisation

La normalisation consiste à organiser les données pour éviter les redondances et garantir la cohérence. J'ai appliqué la **troisième forme normale (3NF)**, qui élimine les dépendances transitives entre les données.

### Principe appliqué

Chaque information n'est stockée qu'à un seul endroit. Les caractéristiques d'un exercice (nom, description, catégorie) sont uniquement dans la table `Exercise`, et les autres tables y font simplement référence via `exercise_id`. Cette approche évite les incohérences et facilite les modifications.

### Exceptions pour l'optimisation des performances

J'ai accepté quelques exceptions pour optimiser les performances :

- Les `PersonalRecord` stockent directement la référence vers l'exercice ET l'athlète, ce qui évite des jointures complexes lors du calcul automatique des charges d'entraînement
- Cette duplication contrôlée accélère une opération critique : quand un coach crée un programme, l'application peut immédiatement calculer les charges recommandées sans requête supplémentaire

Les informations de base restent centralisées (un exercice = une seule définition), mais les données de performance sont optimisées pour un accès rapide lors de l'utilisation quotidienne de l'application.

## Gestion des clés et contraintes

### Choix des clés primaires UUID

J'ai opté pour des clés primaires UUID plutôt que des entiers auto-incrémentés pour des raisons pratiques liées au développement et au déploiement.

**Avantages des UUID :**
- Facilitent les opérations de développement en évitant les conflits d'identifiants lors de la synchronisation entre les environnements de développement, test et production
- Quand plusieurs développeurs créent des données de test, les UUID évitent naturellement les collisions d'identifiants
- Simplifient les opérations de migration et d'import de données
- Lors de la fusion de données de test ou de l'import de catalogues d'exercices externes, je n'ai pas à me soucier des conflits d'identifiants numériques

**Inconvénients :**
- Espace de stockage plus important (16 bytes vs 4 bytes pour un integer)
- Dans le contexte d'un club d'haltérophilie avec quelques centaines d'utilisateurs maximum, cet overhead reste négligeable face à la simplicité opérationnelle

### Stratégies de suppression

Pour l'intégrité référentielle, j'ai identifié les stratégies de suppression nécessaires selon les types de relations :

- **Relations de composition** : Comportement CASCADE - si un workout est supprimé, ses éléments doivent l'être automatiquement puisqu'ils n'ont pas de sens sans leur parent
- **Relations de référence** : Comportement RESTRICT - empêche la suppression accidentelle d'un exercice encore utilisé dans des programmes actifs

## Choix des types de données PostgreSQL

Ma sélection des types de données s'appuie sur les spécificités de PostgreSQL et les besoins métier de l'haltérophilie :

### Types principaux

**UUID pour les identifiants** : Comme évoqué précédemment, ce choix facilite la distribution et évite les conflits d'identifiants.

**VARCHAR avec contraintes de longueur** : Pour les champs textuels (noms, descriptions, titres), j'ai défini des longueurs appropriées plutôt que d'utiliser TEXT illimité. Les catégories restent extensibles par les coachs selon leurs besoins spécifiques.

**TIMESTAMP** : Pour toutes les dates de création, modification et d'enregistrement. PostgreSQL offre une gestion native des fuseaux horaires.

**INTEGER** : Pour les valeurs numériques comme les séries, répétitions, temps de repos, ordres de séquence.

**DECIMAL** : Pour les charges, poids et valeurs de performance, garantissant une précision exacte nécessaire aux calculs de pourcentages et progressions.

**BOOLEAN** : Pour les flags et statuts binaires présents dans le modèle.

**TEXT** : Pour les URLs des fichiers média stockés en externe (photos d'exercices, vidéos de démonstration).

Cette approche me permet de bénéficier des optimisations PostgreSQL tout en maintenant une flexibilité pour les évolutions futures du modèle.

## Pattern de référence polymorphe

Pour permettre aux programmes d'entraînement d'inclure à la fois des exercices simples et des complexes, j'ai choisi un pattern de référence polymorphe dans la table `WorkoutElement`.

### Principe retenu

Une table unique avec un discriminant `element_type` et deux clés étrangères optionnelles (`exercise_id` et `complex_id`). Une contrainte CHECK garantit qu'exactement une des deux références est remplie selon le type.

### Alternatives considérées

**Option 1 - Tables séparées** : Créer `WorkoutExercise` et `WorkoutComplex` distinctes.

✅ **Avantages** :
- Structure plus claire
- Pas de colonnes NULL
- Contraintes d'intégrité simples

❌ **Inconvénients** :
- Duplication des colonnes communes (sets, reps, weight, rest_time, order_index) dans chaque table
- Duplication du code applicatif (2 repositories, 2 DTOs)
- Complexité pour afficher une séquence ordonnée d'éléments mixtes

**Option 2 - Table d'union** : Une table `WorkoutElement` générique pointant vers une table `TrainingElement` qui fait le lien.

✅ **Avantages** :
- Extensibilité maximale

❌ **Inconvénients** :
- Sur-ingénierie pour mon cas d'usage
- Jointures supplémentaires

### Justification du choix

Le pattern polymorphe mutualise les colonnes communes (sets, reps, weight, etc.) qui s'appliquent aussi bien aux exercices qu'aux complexes, évite la duplication de code, et facilite l'affichage ordonné des programmes. Les contraintes CHECK compensent la flexibilité par la rigueur des validations.

Le polymorphisme est contrôlé par une contrainte CHECK qui garantit qu'exactement une des deux références est renseignée selon le type déclaré, évitant ainsi les incohérences de données.

## Contraintes d'intégrité spécifiques

J'ai réfléchi à la répartition des contraintes entre la validation Zod (early validation) et les contraintes de base de données selon leur nature.

### Contraintes structurelles en base de données

Les contraintes qui garantissent la cohérence structurelle restent au niveau base de données car elles constituent le dernier rempart contre l'incohérence :

```sql
-- Garantit l'intégrité référentielle polymorphe
ALTER TABLE workout_element ADD CONSTRAINT valid_element_reference 
  CHECK ((element_type = 'exercise' AND exercise_id IS NOT NULL AND complex_id IS NULL) 
      OR (element_type = 'complex' AND complex_id IS NOT NULL AND exercise_id IS NULL));
```

### Contraintes métier déportées vers les couches applicatives

J'ai réparti les autres contraintes selon leur nature entre Zod et les use cases pour optimiser l'expérience utilisateur et les performances.

**Validations de bornes métier gérées par Zod** :

```typescript
// Exemple concret de validation Zod pour WorkoutElement
const WorkoutElementSchema = z.object({
  sets: z.number().min(1, "Au moins 1 série requise").max(10, "Maximum 30 séries"),
  reps: z.number().min(1, "Au moins 1 répétition").max(50, "Maximum 50 répétitions"),
  weight: z.number().min(0, "Le poids ne peut être négatif").max(300, "Poids maximum 300kg"),
});
```

**Avantages de cette approche** :
- Validation immédiate côté client et serveur
- Messages d'erreur clairs pour les utilisateurs
- Évolutivité sans migration de base de données

**Contraintes temporelles dans les use cases** :

Les contraintes temporelles comme `recorded_at <= NOW()` pour l'entité `PersonalRecord` sont gérées dans les use cases qui contrôlent le contexte métier de création et modification des enregistrements. Cette logique appartient naturellement à la couche applicative qui maîtrise les règles business.

Cette stratification respecte le principe de défense en profondeur : validation early avec Zod pour l'expérience utilisateur, validation métier dans les use cases, contraintes structurelles en base pour l'intégrité finale des données.

## Stratégie d'optimisation par indexation

Dans l'état actuel du MVP, je me contente des index automatiques sur les clés primaires et étrangères. Cette approche volontairement minimaliste évite l'optimisation prématurée et me permet de démarrer avec une base de données simple.

### Principe de base

Un index accélère les requêtes SELECT mais ralentit les écritures (INSERT, UPDATE, DELETE) car il doit être maintenu à jour. Pour un club avec quelques dizaines d'athlètes, cette optimisation n'est pas nécessaire au lancement.

### Requêtes identifiées pour optimisation future

J'ai identifié les requêtes qui pourraient devenir problématiques si le volume augmente :

- **Consultation des séances d'un athlète** : Un coach consulte régulièrement l'historique des séances de ses athlètes
- **Calcul des charges d'entraînement** : L'application récupère le record personnel le plus récent pour un exercice donné lors de la création d'un programme
- **Liste des programmes publiés** : Les athlètes consultent leurs programmes actifs depuis l'application mobile

Si les temps de réponse deviennent problématiques, j'ajouterai les index correspondants en me basant sur les requêtes lentes identifiées via les logs PostgreSQL.

Cette approche pragmatique privilégie la simplicité initiale avec une possibilité d'optimisation guidée par les métriques réelles.

## Préparation pour la mise en cache

La structure que j'ai conçue anticipe l'intégration future de Redis comme système de cache. Cette solution me permettra d'améliorer les temps de réponse lorsque le nombre d'utilisateurs augmentera, sans modifier l'architecture de base de données existante.

### Données candidates pour la mise en cache

J'ai identifié les données qui bénéficieraient le plus de cette optimisation :

- **Catalogue d'exercices et complex complets** : Données qui changent rarement
- **Programmes d'entraînement consultés quotidiennement** : Par les athlètes
- **Records personnels récents** : Utilisés pour calculer les charges d'entraînement
- **Compositions des complex les plus populaires** : Auprès des coachs

### Stratégie évolutive

Cette approche évolutive me convient parfaitement : commencer avec PostgreSQL seul pour le MVP, puis ajouter Redis si les métriques de performance le justifient en production.

## Extensions métier envisagées

Dans ma conception de la base de données, j'ai réfléchi aux fonctionnalités qui pourraient émerger après le lancement du MVP. Plutôt que de tout implémenter dès le départ, j'ai préféré identifier les extensions logiques que les retours utilisateurs du club pourraient justifier.

### Messages du coach

Une entité `CoachMessage` permettrait de diffuser des annonces générales (événements particuliers, rappels globaux) aux athlètes d'une organisation. Cette table pourrait inclure :

- Système de priorité pour gérer l'importance des messages
- Date d'expiration pour gérer automatiquement la visibilité des messages
- Statut de lecture pour chaque athlète

### Système de notifications

Une entité `Notification` centralisée gérerait les alertes push vers les applications mobiles :

- Nouveaux programmes assignés
- Rappels de séances
- Félicitations pour les records
- Historique des notifications
- Gestion des préférences utilisateur

### Catégorisation enrichie des exercices

L'ajout d'entités `MuscleGroup` et `Equipment` structurerait mieux le catalogue d'exercices :

- **MuscleGroup** : Faciliterait les recherches avancées (exercices pour les jambes)
- **Equipment** : Exercices nécessitant des haltères, barres, etc.
- Ces références faciliteraient l'élaboration de programmes équilibrés

### Indicateurs de difficulté

Une extension de `Workout` avec un champ difficulté aiderait les coachs à graduer leurs programmes selon le niveau des athlètes. Cette information pourrait également alimenter des statistiques de progression.

### Gestion des tempos avancés

Pour les coachs expérimentés, deux niveaux de tempo enrichiraient la programmation :

**Macro tempo** au niveau des `Complex` :
- EMOM (Every Minute On the Minute)
- TABATA (20s travail / 10s repos)
- AMRAP (As Many Rounds As Possible)

**Micro tempo** au niveau des `WorkoutElement` :
- Tempo 2-2-1 (2s excentrique, 2s isométrique, 1s concentrique)
- Tempo 3-0-1 (3s excentrique, pas de pause, 1s concentrique)

Ces extensions s'intègrent naturellement dans l'architecture existante sans remettre en cause les relations fondamentales.

## Stratégie de migration

L'évolution de ce modèle de données nécessitera une approche méthodique pour préserver l'intégrité des données existantes. J'ai prévu d'utiliser le système de migrations de MikroORM pour gérer ces évolutions de schéma de façon sécurisée.

### Fonctionnalités de migration

Cette stratégie inclut :

- **Versioning des modifications** : Historique complet des changements de schéma
- **Possibilité de rollback** : Retour en arrière en cas de problème
- **Validation des migrations** : Tests avant déploiement en production
- **Migration des données** : Transformation des données existantes lors des changements de structure

Cette approche garantit la continuité du service et la préservation des données utilisateur lors des évolutions du modèle.
