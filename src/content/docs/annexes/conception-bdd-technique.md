---
title: Conception technique de la base de données
description: Détails techniques et décisions d'implémentation pour la base de données DropIt
---

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

J'ai opté pour des clés primaires UUID plutôt que des entiers auto-incrémentés pour faciliter le développement : éviter les conflits d'identifiants lors de la synchronisation entre environnements (dev, test, prod) et simplifier les imports de données de test. L'overhead de stockage (16 vs 4 bytes) reste négligeable pour un club avec quelques centaines d'utilisateurs maximum.

### Stratégies de suppression

Pour l'intégrité référentielle, j'ai identifié les stratégies de suppression nécessaires selon les types de relations :

- **Relations de composition** : Comportement CASCADE - si un workout est supprimé, ses éléments doivent l'être automatiquement puisqu'ils n'ont pas de sens sans leur parent
- **Relations de référence** : Comportement RESTRICT - empêche la suppression accidentelle d'un exercice encore utilisé dans des programmes actifs

## Pattern de référence polymorphe

Pour permettre aux programmes d'entraînement d'inclure à la fois des exercices simples et des complexes, j'ai choisi un pattern de référence polymorphe dans la table `WorkoutElement`.

Une table unique avec un discriminant `element_type` et deux clés étrangères optionnelles (`exercise_id` et `complex_id`). Une contrainte CHECK garantit qu'exactement une des deux références est remplie selon le type.

### Alternative considérée

**Tables séparées** (`WorkoutExercise` et `WorkoutComplex`) : Structure plus claire mais duplication des colonnes communes (sets, reps, weight) et du code applicatif, plus complexité pour l'affichage ordonné d'éléments mixtes.

Le pattern polymorphe choisi mutualise les colonnes communes dans `WorkoutElement` et facilite l'affichage ordonné. Le polymorphisme est contrôlé par une contrainte CHECK garantissant qu'exactement une référence est renseignée selon le type.

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

Les avantages de cette approche sont la validation immédiate côté client et serveur, des messages d'erreur clairs pour les utilisateurs et une évolutivité sans migration de base de données.

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

Les données qui bénéficieraient le plus de cette optimisation sont potentiellement les catalogue d'exercices et complex complets qui changent rarement ou encore les records personnels récents utilisés pour calculer les charges d'entraînement

### Stratégie évolutive

Cette approche évolutive me convient parfaitement : commencer avec PostgreSQL seul pour le MVP, puis ajouter Redis si les métriques de performance le justifient en production.

## Stratégie de migration

L'évolution de ce modèle de données nécessitera une approche méthodique pour préserver l'intégrité des données existantes. J'ai prévu d'utiliser le système de migrations de MikroORM pour gérer ces évolutions de schéma de façon sécurisée.

Cette stratégie inclut le versioning des modifications avec historique complet, la possibilité de rollback en cas de problème, la validation des migrations avant déploiement en production, et la migration des données existantes lors des changements de structure, garantissant ainsi la continuité du service et la préservation des données utilisateur.
