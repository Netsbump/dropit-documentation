---
title: Conception technique de la base de données
description: Détails techniques et décisions d'implémentation pour la base de données DropIt
---

## Décisions de normalisation

Dans la conception de la base de données, j'ai cherché à éviter un problème classique : imaginez qu'un coach renomme l'exercice "Squat" en "Back Squat" pour plus de précision. Si le nom de l'exercice était dupliqué dans chaque programme d'entraînement qui l'utilise, il faudrait modifier toutes ces occurrences manuellement, avec le risque d'oublier certaines entrées et de créer des incohérences dans les données historiques.

Pour résoudre ce problème, j'ai appliqué la **troisième forme normale (3NF)**, un principe de structuration qui garantit que chaque donnée n'existe qu'à un seul endroit dans la base. Concrètement, cela signifie que les informations descriptives d'un exercice (son nom, sa description, sa catégorie) sont stockées uniquement dans la table `Exercise`. Les autres tables comme `WorkoutElement` ou `PersonalRecord` ne contiennent que la référence à cet exercice via `exercise_id`, sans dupliquer ses caractéristiques.

### Bénéfices dans mon contexte

D'abord, la maintenance devient plus simple : modifier un exercice se fait en un seul endroit et se répercute automatiquement partout où il est utilisé. Ensuite, l'intégrité des données est garantie : impossible d'avoir des versions contradictoires du même exercice dans différentes parties de l'application.

## Gestion des clés et contraintes

### Choix des clés primaires UUID

J'ai choisi d'utiliser des identifiants UUID (comme `a3bb189e-8bf9-3888-9912-ace4e6543002`) plutôt que de simples numéros incrémentés pour une raison de sécurité : les IDs séquentiels facilitent les attaques par énumération. Un utilisateur malveillant repérant une faille peut facilement avoir accès à des informations en essayant les différents incréments. Les UUID rendent ce type d'attaque difficile en utilisant des identifiants imprévisibles. Le surcoût en stockage reste négligeable pour un club de cette taille.

### Stratégies de suppression

Pour l'intégrité référentielle, j'ai identifié les stratégies de suppression nécessaires selon les types de relations :

- **Relations de composition** : Comportement CASCADE - si un workout est supprimé, ses éléments doivent l'être automatiquement puisqu'ils n'ont pas de sens sans leur parent
- **Relations de référence** : Comportement RESTRICT - empêche la suppression accidentelle d'un exercice encore utilisé dans des programmes actifs

## Pattern de référence polymorphe

Pour permettre aux programmes d'entraînement d'inclure à la fois des exercices simples et des complexes, j'ai choisi un pattern de référence polymorphe dans la table `WorkoutElement`.

Une table unique avec un discriminant `element_type` et deux clés étrangères optionnelles (`exercise_id` et `complex_id`). Une contrainte CHECK garantit qu'exactement une des deux références est remplie selon le type.

### Alternative considérée

**Tables séparées** (`WorkoutElementExercise` et `WorkoutElementComplex`) : Structure plus claire mais duplication de certaines colonnes communes (sets, reps, etc...).

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

```typescript
// Exemple concret de validation Zod pour WorkoutElement
const WorkoutElementSchema = z.object({
  sets: z.number().min(1, "Au moins 1 série requise").max(10, "Maximum 30 séries"),
  reps: z.number().min(1, "Au moins 1 répétition").max(50, "Maximum 50 répétitions"),
  weight: z.number().min(0, "Le poids ne peut être négatif").max(300, "Poids maximum 300kg"),
});
```

Les avantages de cette approche sont la validation immédiate côté client et serveur et des messages d'erreur clairs pour les utilisateurs.

**Contraintes temporelles dans les use cases** :

Les contraintes temporelles comme `recorded_at <= NOW()` pour l'entité `PersonalRecord` sont gérées dans les uses cases qui contrôlent le contexte métier de création et modification des enregistrements. Cette logique appartient naturellement à la couche applicative qui maîtrise les règles business.

Cette stratification respecte le principe de défense en profondeur : validation early avec Zod pour l'expérience utilisateur, validation métier dans les uses cases, contraintes structurelles en base pour l'intégrité finale des données.

## Stratégie d'optimisation par indexation

Dans l'état actuel du MVP, je me contente des index automatiques sur les clés primaires et étrangères. Cette approche volontairement minimaliste évite l'optimisation prématurée et me permet de démarrer avec une base de données simple.

### Principe de base

Un index accélère les requêtes de lecture mais ralentit les écritures : chaque fois qu'une donnée est ajoutée, modifiée ou supprimée, la base de données doit mettre à jour l'index en plus de la table principale, ce qui représente un travail supplémentaire. Pour un club avec quelques dizaines d'athlètes, ce compromis n'est pas nécessaire au lancement.

### Requêtes identifiées pour optimisation future

J'ai identifié les requêtes qui pourraient devenir problématiques si le volume augmente :

- **Consultation des séances d'un athlète** : Un coach consulte régulièrement l'historique des séances de ses athlètes
- **Calcul des charges d'entraînement** : L'application récupère le record personnel le plus récent pour un exercice donné lors de la création d'un programme
- **Liste des programmes publiés** : Les athlètes consultent leurs programmes actifs depuis l'application mobile

Si les temps de réponse deviennent problématiques, j'ajouterai les index correspondants en me basant sur les requêtes lentes identifiées.

## Préparation pour la mise en cache

La structure que j'ai conçue anticipe l'intégration future de Redis comme système de cache. Cette solution me permettra d'améliorer les temps de réponse lorsque le nombre d'utilisateurs augmentera, sans modifier l'architecture de base de données existante.

Les données qui bénéficieraient le plus de cette optimisation sont potentiellement les catalogue d'exercices et complexes qui changent rarement.

## Stratégie de migration

Le modèle de données évoluera nécessairement au fil du projet : ajout de nouvelles fonctionnalités, modification de contraintes, optimisations. Pour gérer ces changements sans casser les données existantes, j'utilise le système de migrations de MikroORM.

Chaque modification du schéma sera versionnée et historisée, ce qui me permet de savoir précisément quels changements ont été appliqués à chaque environnement. Si une migration pose problème en production, je peux revenir en arrière (rollback) vers l'état précédent. Avant tout déploiement, je teste les migrations sur des copies de la base de données pour vérifier qu'elles fonctionnent correctement et préservent les données utilisateur.
