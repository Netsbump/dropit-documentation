---
title: Interfaces
description: Conception d'interfaces - wireframe, design system
---

Après avoir défini l'architecture technique de DropIt et détaillé l'accès aux données via l'API NestJS, cette section se concentre sur la traduction concrète des besoins utilisateurs en interfaces fonctionnelles. 

L'approche que j'ai suivie consiste à partir de l'[analyse des besoins fonctionnels](/conception/analyse) déjà établie, à la synthétiser sous forme de personas pour guider la conception, puis à implémenter les interfaces correspondantes avec React et TypeScript.

## Personas utilisateurs

L'analyse fonctionnelle détaillée précédemment m'a permis d'identifier deux profils utilisateurs distincts que je synthétise ici sous forme de personas pour guider mes choix d'interface :

**Le coach** utilise principalement l'interface web depuis son bureau ou à domicile pour :
- Créer et gérer le catalogue d'exercices personnalisé
- Composer des programmes d'entraînement
- Planifier les séances
- Analyser les performances et ajuster les programmations

**L'athlète** utilise exclusivement l'application mobile en salle de sport pour :
- Consulter son programme du jour
- Enregistrer ses records personnels
- Communiquer avec son coach via des notes sur les entrainements

## Conception des interfaces

### Approche wireframes basse fidélité

Mes wireframes se concentrent sur la structure informationnelle et les interactions essentielles, sans considération visuelle. Cette phase me permet de valider l'organisation de l'information et les flux utilisateurs avant de passer aux aspects visuels.

L'architecture de DropIt se décline en deux interfaces distinctes : une application web pour les coachs (back office) et une application mobile pour les athlètes (front office), chacune adaptée à son contexte d'usage spécifique.

### Interface web coach (Back office)

#### Page de bibliothèque d'exercices

<!-- TODO: Insérer wireframe vue générale bibliothèque -->

La vue générale présente l'interface globale avec une navigation latérale permanente donnant accès aux trois catalogues : exercices, complexes et programmes d'entraînement. Cette organisation facilite la navigation entre les différents types de contenus que le coach manipule quotidiennement.

#### Page de création d'exercice

<!-- TODO: Insérer wireframe page création exercice -->

Le wireframe révèle les éléments structurants :
- Zone principale de saisie (nom, description, catégorie)
- Section d'upload de médias (photos, vidéos de démonstration)
- Barre d'actions (sauvegarder, annuler, prévisualiser)
- Navigation de retour vers le catalogue

#### Page de création d'entraînement

<!-- TODO: Insérer wireframe composition programme multi-étapes -->

L'interface s'organise autour de trois zones distinctes :
- **Sidebar gauche** : catalogue d'exercices et complexes avec recherche
- **Zone centrale** : programme en construction avec éléments drag-and-drop
- **Panel droit** : paramètres détaillés de l'élément sélectionné

#### Contraintes responsive

Dans le MVP, j'ai fait le choix de ne pas optimiser l'interface web pour les mobiles. Les coachs utilisent principalement des ordinateurs de bureau ou tablettes pour créer leurs programmes, contexte qui permet une interface riche en interactions complexes. Cette décision me permet de concentrer l'effort sur une expérience optimale desktop plutôt que de multiplier les compromis.

### Interface mobile athlète (Front office)

#### Page d'accueil

<!-- TODO: Insérer wireframe page accueil mobile -->

L'écran d'accueil mobile privilégie l'accès rapide aux fonctionnalités essentielles : consultation du programme du jour, visualisation des records personnels, et navigation vers l'historique des entraînements.

#### Page de visualisation d'entraînement

<!-- TODO: Insérer wireframe visualisation programme mobile -->

L'interface mobile présente les exercices de manière séquentielle, optimisée pour la consultation en salle de sport avec des zones tactiles larges et une lisibilité maximale des informations critiques (charges, répétitions, temps de repos).

## Design system et cohérence visuelle

### Fondations techniques

<!-- TODO: Insérer maquette design system (colors, typography, components) -->

Mon design system s'appuie sur les composants Shadcn/ui, eux-mêmes construits sur Radix UI. Cette base garantit plusieurs aspects essentiels :

- **Accessibilité native** : Radix UI implémente les standards WCAG AA avec support des lecteurs d'écran, navigation clavier complète, et gestion des focus
- **Cohérence visuelle** : tokens de design réutilisables pour espacements, couleurs, et typographie via CSS variables
- **Composants robustes** : states management intégré, animations fluides, et API cohérente

### Adaptation responsive mobile

L'interface mobile utilise Tailwind CSS pour une adaptation fluide aux différentes tailles d'écran, en privilégiant une approche mobile-first pour garantir la performance sur les appareils des athlètes.

## Implémentations visuelles finales

Cette section présente le rendu final des interfaces après itération sur les wireframes et intégration du design system. L'évolution de la conception vers l'implémentation révèle les ajustements nécessaires entre les concepts théoriques et la réalité technique.

### Interface de dashboard coach

<!-- TODO: Insérer screenshot dashboard principal coach -->

Le dashboard centralise les informations critiques dans une vue d'ensemble :
- Widget calendrier avec aperçu des séances planifiées
- Statistiques d'activité des athlètes (programmes actifs, dernières performances)  
- Accès rapide aux actions fréquentes via des boutons d'action principaux
- Zone de notifications pour les nouveaux records et demandes d'athlètes

### Interface de création de programme

<!-- TODO: Insérer screenshot stepper création programme -->

L'interface multi-étapes guide le coach dans la composition avec un workflow intuitif :
- **Étape 1** : Informations générales avec validation Zod temps réel
- **Étape 2** : Construction du programme via drag-and-drop dnd-kit
- **Étape 3** : Planification et assignation aux athlètes avec sélection multiple

### Interface mobile de consultation

<!-- TODO: Insérer screenshots interface mobile -->

L'application mobile présente une navigation optimisée tactile avec :
- Bottom navigation pour l'accès rapide aux sections principales
- Cartes d'exercices avec informations essentielles (charges calculées, répétitions)
- Interface de saisie des performances réalisées avec clavier numérique optimisé

## Validation et tests utilisateurs

### Tests d'utilisabilité avec les coachs

J'ai organisé des sessions de test avec trois coachs de différents clubs pour valider l'interface de création de programme :

**Retours positifs** :
- "C'est pratique de centraliser un catalogue d'entrainement, d'exercices et de pouvoir les réutiliser"
- "La validation en temps réel évite les erreurs de saisie"
- "Je peux me concentrer sur la technique des Athlètes pendant les entrainements et moins sur un rappel permanent du nombre de répétion, des charges sur chaque exercices"

**Points d'amélioration identifiés** :
- Ajout d'un mode "duplication" pour créer des variantes de programmes existants
- Amélioration des filtres dans le catalogue d'exercices
- Import de programme au format Excel.

### Tests avec les athlètes

Les tests de l'application mobile ont révélé :

**Satisfactions** :
- "Plus besoin de calculer de tête les charges à mettre sur ma barre"
- "Pratique de pouvoir consulter directement sur téléphone plutôt que devoir se déplacer au tableau pour se rappeler les exercices à faire"

**Axes d'amélioration** :
- Timer intégré pour les temps de repos
- Notifications de rappel pour les séances planifiées

## Évolutions futures des interfaces

### Extensions prévues

L'architecture modulaire facilite l'ajout de nouvelles fonctionnalités :

**Dashboard avancé** : Graphiques de progression, comparaisons entre athlètes, analyses statistiques approfondies.

**Interface de planification** : Vue calendaire avec drag-and-drop, gestion des créneaux récurrents, synchronisation avec calendriers externes.

**Mode collaboratif** : Système de commentaires sur les séances, annonces d'évenèment du club.

## Conclusion

message de conclusion avant de passer a la suite dans l'implémentation frontend 