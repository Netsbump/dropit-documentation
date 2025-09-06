---
title: Analyse des besoins fonctionnels
description: Analyse détaillée des besoins utilisateurs et conception des interactions pour DropIt
---

## Introduction

Ma position d'utilisateur final présente l'avantage de faciliter cette analyse, mais elle comporte aussi le risque de projeter mes propres habitudes sur l'ensemble des utilisateurs. J'ai donc veillé à multiplier les échanges avec les autres membres du club pour valider mes hypothèses et enrichir ma compréhension des besoins diversifiés selon les profils d'utilisateurs.

## Méthodologie d'analyse et validation des besoins

### Approche centrée utilisateur

Ma démarche d'analyse s'articule autour d'une approche centrée utilisateur que j'ai adaptée aux contraintes de mon projet de formation. Les échanges informels avec les membres du club lors des entraînements m'ont permis de recueillir des retours spontanés sur leurs difficultés actuelles et leurs attentes concernant un outil numérique.

J'ai organisé ces retours autour de deux profils principaux d'utilisateurs dont les besoins diffèrent significativement : les athlètes, focalisés sur l'efficacité d'accès à l'information pendant l'entraînement, et les coachs, orientés vers l'efficacité de gestion et de suivi des programmes. Cette segmentation m'aide à prioriser les fonctionnalités selon leur impact sur l'expérience utilisateur de chaque groupe. Chaque fonctionnalité répond à un besoin concret exprimé par les utilisateurs, évitant ainsi le développement de fonctionnalités superflues qui complexifieraient inutilement l'interface.

### Identification des fonctionnalités prioritaires

L'analyse des dysfonctionnements actuels m'a conduit à identifier les fonctionnalités qui constituent le socle minimal viable de l'application. Ces fonctionnalités répondent directement aux problèmes les plus critiques observés : accès difficile aux programmes, dispersion de l'information, absence de suivi structuré des progressions.

```mermaid
graph TD
    A[Observation terrain] --> B[Identification des problèmes]
    B --> C{Analyse d'impact}
    C -->|Impact élevé| D[Fonctionnalité prioritaire]
    C -->|Impact moyen| E[Fonctionnalité secondaire]
    C -->|Impact faible| F[Fonctionnalité future]
    
    D --> G[Spécification détaillée]
    E --> H[Analyse complémentaire]
    F --> I[Backlog d'évolution]
    
    style D fill:#1b5e20
    style E fill:#e65100
    style F fill:#0d47a1
```

## Diagramme des cas d'usage et architecture fonctionnelle

Le diagramme ci-dessous présente une vue synthétique des principales interactions entre les utilisateurs (athlètes et coachs) et le système. Il met en évidence les différentes fonctionnalités accessibles selon le rôle de l'utilisateur.

![Diagramme des cas d'usage](../../../assets/diagram-use-cases.png)

Ce diagramme illustre la séparation claire entre les fonctionnalités destinées aux athlètes (consultation des entraînements, gestion des maxima) et celles réservées aux coachs (gestion des entraînements, gestion des athlètes). Certaines fonctionnalités, comme la gestion du profil et la communication, sont communes aux deux types d'utilisateurs.

## Analyse détaillée des parcours utilisateur

Le but de DropIt étant d'intégrer les spécificités techniques de l'haltérophilie, les fonctionnalités de l'application sont adaptées aux méthodes d'entraînement de cette discipline.

Le système de calcul automatique des charges basé sur les pourcentages des maximums illustre cette intégration. Plutôt que de laisser les athlètes calculer manuellement leurs charges d'entraînement, l'application automatise cette tâche en s'appuyant sur les données de leurs maximums et les pourcentages définis par le coach. Cette automatisation répond à un besoin récurrent exprimé par les membres de mon club qui actuellement doivent calculer ces charges de tête au moment de l'exercice.

```mermaid
sequenceDiagram
    participant A as Athlète
    participant S as Système DropIt
    participant C as Coach
    
    C->>S: Définit programme (exercice + % du max)
    S->>S: Enregistre programmation
    A->>S: Consulte entraînement du jour
    S->>S: Récupère max de l'athlète pour l'exercice
    S->>S: Calcule charge = max × pourcentage
    S->>A: Affiche charge en kilos à utiliser
    
    Note over A,S: Automatisation du calcul<br/>évitant les erreurs manuelles
```

## Flux d'interactions

### 1. <ins>Accéder à son entraînement personnalisé (Athlète)</ins>

Ce flux répond au besoin prioritaire identifié : l'accès rapide et fiable au programme du jour. L'optimisation de ce parcours constitue un enjeu crucial pour l'adoption de l'application.

- L'**athlète** ouvre l'application et accède à la section des **entraînements**
- Le système affiche une liste **d'entrainements** disponibles pour l'athlète classés par **date**.
- L'**athlète** sélectionne un **entrainement**
- Le système récupère **l'entraînement** correspondant à la **date choisie**
- Le système charge le détail des éléments de **l'entraînement** (**répétitions**, **charges**, **temps de repos**, etc.)
- Le système affiche pour chaque **exercice** ou **bloc d'exercices** les charges en kilos que l'**athlète** doit utiliser basées sur le **pourcentage** du **maximum** souhaité par le **coach**

### 2. <ins>Gestion des maximums (Athlète)</ins>

La gestion des maximums constitue un aspect fondamental de l'entraînement en haltérophilie. Cette fonctionnalité permet aux athlètes de maintenir leurs données à jour, garantissant la précision des calculs de charges.

- L'**athlète** accède à la section des **maximums**
- Le système affiche la liste des **exercices** pour lesquels l'**athlète** a des **maximums** enregistrés
- Si l'**athlète** souhaite modifier **maximums** : 
  - L'**athlète** sélectionne un **exercice** à mettre à jour
  - L'**athlète** entre la nouvelle valeur du Maximum pour cet **exercice**
  - Le système enregistre le nouveau **maximums** avec la **date actuelle**
  - Le système met à jour l'historique des **maximums** pour cet **exercice**
- Si l'**athlète** souhaite ajouter un nouveau **maximum** pour un **exercice** : 
  - L'**athlète** sélectionne l'ajout d'un nouveau **maximum**
  - Le système propose de choisir l'**exercice** parmi la liste disponible
  - L'**athlète** sélectionne l'**exercice** et saisit le **maximum** en kilos
  - Le système enregistre le nouveau **maximum** avec contrainte de validation métier
  - Le système horodate l'enregistrement

### 3. <ins>Visualisation du calendrier de la programmation globale (Athlète)</ins>

Cette fonctionnalité répond au besoin de vision d'ensemble sur la planification des entraînements, permettant aux athlètes d'anticiper leurs séances et de mieux organiser leur emploi du temps.

- L'**athlète** accède à la section **programmation**
- Le système récupère la **programmation** actuelle de l'**athlète**
- Le système affiche un **calendrier** avec les **entraînements** prévus par le **coach**
- L'**athlète** peut naviguer entre les semaines/mois/année
- Pour chaque jour, le système affiche un résumé de l'**entraînement** (**type d'entrainements** et/ou **description**)
- L'**athlète**  peut sélectionner une **date spécifique** pour voir les **détails de l'entraînement**

### 4. <ins>Gestion du profil (Athlète et Coach)</ins>

La gestion du profil intègre les spécificités de l'haltérophilie, notamment les catégories de compétition et les mesures physiques qui influencent la programmation des entraînements.

- L'**utilisateur** (**athlète** ou **coach**) se connecte à l'application
- L'**utilisateur** accède à la section de la gestion du **profil**
- Le système affiche les informations actuelles du **profil** :
  - Informations de base (nom, prénom, date de naissance)
  - Club affilié
  - Pays
  - Avatar (image)
- Si l'utilisateur est un **athlète**, le système affiche également :
  - **Niveau de l'athlète** (niveau : régional, national, rookie)
  - **Catégorie de sexe** pour la compétition
  - **Catégorie de poids** pour la compétition
  - **Mesures physiques** (poids, taille, etc.)
  - Nom du **coach** associé
- L'utilisateur peut modifier ses informations personnelles
- Si l'utilisateur est un **coach**, il peut :
  - Voir la liste de ses **athlètes** associés
  - Ajouter ou retirer des **athlètes** de sa liste

### 5. <ins>Communication vie du club (Athlète et Coach)</ins>

Cette fonctionnalité vise à centraliser les communications du club, répondant directement au problème de dispersion de l'information dans les messageries instantanées.

- **Athlètes** : consultation des actualités non lues avec notifications optionnelles par email
- **Coachs** : publication d'actualités du club (compétitions, informations importantes)

### 6. <ins>Gestion des entraînement (Coach)</ins>

Cette fonctionnalité constitue le cœur de l'application côté coach. Sa conception s'appuie sur l'observation des méthodes de travail des entraîneurs de mon club et vise à optimiser leur productivité.

```mermaid
graph TD
    A[Coach accède gestion entraînements] --> B{Choix d'action}
    B -->|Bibliothèque| C[Gestion des éléments]
    B -->|Planification| D[Calendrier d'entraînements]
    
    C --> E[Exercices]
    C --> F[Blocs d'exercices]
    C --> G[Entraînements complets]
    
    E --> H[Créer/Modifier/Supprimer exercice]
    F --> I[Créer/Modifier/Supprimer bloc]
    G --> J[Créer/Modifier/Supprimer entraînement]
    
    D --> K[Assigner entraînement à une date et aux athlètes]
    D --> L[Visualiser planning athlète]
    
    style C fill:#1976d2
    style D fill:#7b1fa2
```

- Le **coach** accède à la page permettant de gérer les **entraînements**
- Le système présente le choix entre une vue proposant un choix entre la bibliothèques des éléments liés aux **entrainements** ou la **planification** des **entrainements** des **athlètes** : 
  - Si le **coach** souhaite accéder à la vue de la bibliothèque des **entrainements** : 
    - Le système lui présente des listes d'**exercices**, **bloc d'exercices** et **entrainements** sous forme d'onglets.
    - Pour chaque onglets il peut sélectionner un élément de la liste pour le modifier ou le supprimer ou créer un élément.
    - Si le **coach** souhaite créer des éléments d'**entraînement** : 
      - Si le **coach** crée un **exercice** : 
        - Le système présente une interface de création d'**exercice**
        - Il saisi le nom de l'**exercice**
        - Il choisi le type d'**exercice** parmi une liste de type d'**exercice** possibles (ex: haltérophilie, musculation, cardio...)
        - Il peut ajouter une description spécifique à l'**exercice**
        - Il peut ajouter le nom anglais de l'**exercice** s'il y a lieu d'être
        - Il peut ajouter une abréviation à ce nom d'exercice s'il le souhaite 
        - Il peut ajouter une **vidéo** de démonstration de **exercice**
        - Il valide la création de l'**exercice**
        - Le système enregistre le nouvel **exercice** avec la **date actuelle** de création
      - Si le **coach** crée un **bloc d'exercices** : 
        - Le système présente une interface de création d'un **bloc d'exercices**
        - Il choisi le type de **bloc d'exercices** à réaliser parmi une liste de **type de blocs d'exercice** possibles (ex: Renforcement, Complex d'arraché, Complex epaulé-jetté, AMRAP, TABATA, etc.).
        - Il choisi au minimum deux **exercices** parmi la liste des **exercices** existants dans la bibliothèque d'**exercice**.
        - Il choisi l'ordre d'exécution des **exercices**.
        - Il peut ajouter une description pour la réalisation du **bloc d'exercices**. (ex: commentaire, point d'attention, objectif du bloc)
        - Il valide la création du **bloc d'exercices**
        - Le système enregistre le nouveau **bloc d'exercices** avec la **date actuelle** de création
      - Si le **coach** crée un **entrainement** :
        - Le système présente une interface de création d'un **entrainement**
        - Il choisi d'ajouter un ou plusieurs **exercices** combiné ou non à un ou plusieurs **bloc d'exercices** parmi les listes des éléments de chaque déjà créé
        - Le système propose également un raccourci vers la création d'un **exercice** ou d'un **bloc d'exercices** dans les listes des éléments proposés
        - Pour chaque élément de l'**entraînement**, le **coach** saisie :
          - Le nombre de répétitions
          - Le nombre de séries
          - Le pourcentage de charge (basé sur le **maximum** de l'**athlète** pour l'**exercice** défini)
          - Le temps de repos (si applicable)
          - La durée (si applicable)
        - Le **coach** peut réordonner les éléments d'**entraînement**
        - Le système enregistre l'**entraînement** dans la bibliothèque des **entrainements**
  - Si le **coach** souhaite accéder à la **planification** des **entraînements** : 
    - Le système présente un **calendrier**
    - Le **calendrier** comprend différents mode d'affichage par semaine/mois/année
    - Le **coach** peut visualiser ou ajouter des **entrainements** en sélectionnant un jour sur le calendrier

### 7. <ins>Gestion des athlètes (Coach)</ins>

Cette fonctionnalité s'inspire directement des besoins exprimés par les coachs de mon club concernant le suivi individualisé de leurs athlètes.

- Le **coach** accède à la page permettant de gérer les **athlètes**
- Le système présente sa liste d'**athlètes** sous forme de grid ou cards avec le **nom**, **prénom**, **pays**, **catégorie**, **poids de l'athlète**, **année de naissance**, niveau de l'**athlète** et son **maximum** sur les deux mouvements de l'haltérophilie
- La liste d'**athlètes** peut être filtré par recherche (**nom, prénom**), par **catégorie de poids** (compétition), par **catégorie de sexe** (compétition) ou par **niveau** des **athlètes** (rookie, national, regional)
- Le **coach** peut accéder au **détail** de la fiche d'un **athlète** en cliquant dessus afin de visualiser des informations supplémentaire ou d'effectuer des modification sur celle ci (niveau par exemple)

## Validation et perspectives d'amélioration

Cette analyse des besoins constitue une première itération que j'envisage d'affiner en continu grâce aux retours des utilisateurs finaux.

Les fonctionnalités décrites ci-dessus représentent le périmètre fonctionnel minimal viable que je souhaite implémenter dans la première version de DropIt.

Parmi les évolutions que j'envisage d'explorer : l'intégration d'analyses statistiques de progression, le développement d'un mode hors ligne pour l'application mobile, ou encore l'ajout d'un chronomètre pour les exercices qui le necessite.