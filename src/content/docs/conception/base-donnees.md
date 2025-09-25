---
title: Base de données
description: Conception et modélisation de la base de données
---

## Approche de conception

Pour concevoir la base de données de DropIt, j'ai choisi d'utiliser la méthode Merise, approche méthodologique française que j'ai étudiée dans ma formation et qui s'avère adaptée aux projets avec des relations complexes entre entités.

Cette méthode structure la conception en trois niveaux d'abstraction successifs : conceptuel (MCD), logique (MLD) et physique (MPD). Cette méthodologie m'a permis de partir des besoins métier exprimés lors de l'analyse fonctionnelle pour arriver progressivement à une structure de base de données optimisée pour PostgreSQL.

Les principales interactions sont assez simples : un coach assigne des programmes à ses athlètes, ces programmes composent des exercices avec des paramètres spécifiques (séries, répétitions, charges).

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

> **Détails techniques** : Voir l'[Annexe - Conception technique de la base de données](/annexes/conception-bdd-technique/)

## Modèle Physique de Données (MPD)

Le MPD constitue l'aboutissement de ma démarche de modélisation, traduisant le modèle logique en structure PostgreSQL optimisée. Cette étape implique des choix techniques précis sur les types de données, les contraintes d'intégrité et les optimisations de performance.

![Modèle Physique de Données DropIt](../../../assets/mpd-dropit.png)

### Choix techniques essentiels

**Types de données PostgreSQL** : J'ai sélectionné des types adaptés aux besoins métier de l'haltérophilie : UUID pour les identifiants (facilite la distribution), VARCHAR avec contraintes pour les textes, TIMESTAMP pour les dates, INTEGER pour les valeurs numériques, DECIMAL pour les charges et poids (précision exacte nécessaire aux calculs).

**Gestion des médias** : Les ressources visuelles (photos, vidéos d'exercices) sont stockées sur un service externe (Cloudinary) et référencées par URL dans la base de données, optimisant les performances et simplifiant les sauvegardes.

**Pattern de référence polymorphe** : Pour permettre aux programmes d'inclure exercices simples et complexes, j'utilise une table `WorkoutElement` avec un discriminant `element_type` et deux clés étrangères optionnelles. Une contrainte CHECK garantit l'intégrité référentielle.

### Contraintes d'intégrité

J'ai réparti les contraintes entre validation Zod (early validation) et contraintes de base de données selon leur nature :

- **Contraintes structurelles** : En base de données pour garantir la cohérence (intégrité référentielle polymorphe)
- **Contraintes métier** : En Zod pour l'expérience utilisateur (bornes de valeurs, messages d'erreur clairs)
- **Contraintes temporelles** : Dans les use cases pour le contexte métier

Cette stratification respecte le principe de défense en profondeur.

## Stratégie d'évolution

L'architecture actuelle facilite l'ajout de nouvelles fonctionnalités selon les retours d'usage du club. J'ai identifié plusieurs extensions logiques qui pourraient émerger après le lancement du MVP : système de messages du coach, notifications push, catégorisation enrichie des exercices, indicateurs de difficulté, gestion des tempos avancés.

Ces extensions s'intègrent naturellement dans l'architecture existante sans remettre en cause les relations fondamentales. L'évolution du modèle utilisera le système de migrations de MikroORM pour préserver l'intégrité des données existantes.

> **Extensions détaillées** : Voir l'[Annexe - Conception technique de la base de données](/annexes/conception-bdd-technique/)

La section suivante sur l'[accès aux données](/conception/acces-donnees) détaille l'implémentation de ces modèles avec MikroORM et les patterns de développement adoptés.

