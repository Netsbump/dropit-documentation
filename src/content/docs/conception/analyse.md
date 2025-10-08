---
title: Analyse des besoins fonctionnels
description: Analyse des besoins utilisateurs et conception des interactions pour DropIt
---

## Méthodologie d'analyse

Ma démarche s'articule autour d'une approche centrée utilisateur :  les échanges informels avec les membres du club lors des entraînements m'ont permis de recueillir des retours spontanés sur leurs difficultés actuelles et leurs attentes concernant un outil numérique.

Ces retours ont révélé deux profils d'utilisateurs aux besoins bien distincts : les athlètes, qui recherchent un accès simplifié à leurs programmes, et les coachs, qui ont besoin d'outils de planification et de suivi.

## Besoins utilisateurs et parcours

### Les athlètes

L'application s'adresse principalement aux membres du club qui ont besoin d'accéder facilement à leurs programmes d'entraînement personnalisés, de suivre leurs progressions et de rester informés des actualités importantes du club.

L'accès au programme du jour constitue leur besoin prioritaire. Entre chaque série, l'athlète doit pouvoir visualiser immédiatement l'exercice suivant et la charge à utiliser sur sa barre. Le support mobile s'impose naturellement par sa praticité dans l'environnement de la salle de sport.

Le suivi de progression représente un aspect motivationnel crucial pour maintenir l'engagement des pratiquants. Cette fonctionnalité doit permettre une visualisation claire des améliorations sans complexité excessive d'usage.

**Principaux parcours identifiés** :
- **Accès à l'entraînement personnalisé** : Consultation du programme du jour avec calcul automatique des charges
- **Gestion des maximums** : Enregistrement et mise à jour des records personnels
- **Visualisation du calendrier** : Vue d'ensemble de la programmation globale
- **Gestion du profil** : Informations personnelles et catégories de compétition

### Les coachs

Les entraîneurs expriment des besoins différents, centrés sur l'efficacité de leur travail de programmation et de suivi.

La création et la gestion efficaces des programmes d'entraînement constituent leur besoin principal. L'outil doit leur faire gagner du temps dans ces tâches administratives pour qu'ils puissent se concentrer sur l'accompagnement technique des athlètes.

Le suivi des performances de leurs athlètes nécessite des outils de visualisation et d'analyse adaptés à la planification des cycles d'entraînement.

La communication avec l'ensemble du groupe doit être simplifiée et ciblée, évitant la dispersion actuelle de l'information.

**Principaux parcours identifiés** :
- **Gestion des entraînements** : Création d'exercices, blocs et programmes complets
- **Planification** : Assignation des programmes aux athlètes via interface calendaire
- **Gestion des athlètes** : Suivi individualisé et consultation des profils

### Besoins communs

Certaines fonctionnalités concernent les deux profils d'utilisateurs :
- **Gestion du profil** : Informations personnelles et paramètres de compte
- **Communication vie du club** : Actualités et informations importantes

> **Détail complet des flux d'interactions** : Voir l'annexe [Analyses des besoins](/annexes/analyses-besoins/)

## Identification et priorisation des fonctionnalités

L'analyse des dysfonctionnements actuels a révélé un périmètre fonctionnel conséquent pour répondre aux problèmes les plus critiques : accès difficile aux programmes, dispersion de l'information, absence de suivi structuré des progressions.

Face à cette ampleur et aux contraintes de mon projet de formation, j'ai choisi d'adopter une approche MVP (Minimum Viable Product). Cette stratégie me permet de valider rapidement la pertinence des fonctionnalités essentielles auprès des utilisateurs de mon club, tout en créant une alternative fonctionnelle immédiate à la messagerie instantanée actuelle. Dans un second temps, l'application évoluera selon les retours d'usage réels pour intégrer progressivement les fonctionnalités complémentaires.

### Périmètre retenu pour le MVP

Les retours des utilisateurs de mon club m'ont permis d'identifier les fonctionnalités qui résolvent 80% des problèmes quotidiens observés :

**Pour les coachs** :
- Création et gestion du catalogue d'exercices personnalisé
- Composition de programmes d'entraînement avec paramètres (séries, répétitions, charges)
- Planification basique des séances via interface calendaire
- Assignation des programmes aux athlètes
 - Consultation des profils des athlètes

**Pour les athlètes** :
- Consultation des programmes du jour avec calcul automatique des charges
- Enregistrement et visualisation des records personnels

### Fonctionnalités reportées en versions ultérieures

Plusieurs fonctionnalités identifiées restent pertinentes mais ne constituent pas des éléments bloquants pour l'usage quotidien :

**Visualisation de la programmation globale** : La vue calendaire complète permettant aux athlètes de consulter l'ensemble de leur programmation sur plusieurs semaines apporterait une vision long terme mais n'est pas essentielle pour l'usage quotidien.

**Suivi avancé des progressions** : Mode hors ligne pour l'application mobile et améliorations de l'expérience utilisateur basées sur l'observation des comportements d'utilisation.

**Communication vie du club** : Bien que la dispersion des informations dans les messageries soit problématique, cette fonctionnalité peut être temporairement compensée par les outils existants du club.

**Gestion fine des profils** : Les informations détaillées (catégories de compétition, mesures physiques) enrichiraient l'expérience mais ne conditionnent pas l'utilisation de base de l'application.

**Analytics avancées** : Les analyses statistiques de progression et comparaisons entre athlètes apporteraient une valeur ajoutée significative mais peuvent être développées une fois l'usage établi.

Cette approche me permet de concentrer mes efforts sur un cœur fonctionnel robuste qui démontre la valeur métier de DropIt. L'architecture technique décrite dans la suite du projet reste conçue pour supporter ces évolutions futures.

## Diagramme des cas d'usage du MVP

Le diagramme ci-dessous présente une vue synthétique des interactions retenues pour le MVP entre les utilisateurs et le système.

```mermaid
graph TB
    subgraph Système
        UC1[Accéder à son<br/>entraînement<br/>personnalisé]
        UC2[Calcul automatique<br/>des charges]
        UC3[Gestion des<br/>maxima]
        UC4[Saisie des<br/>maxima]
        UC5[Visualisation<br/>des maxima]
        UC6[Créer une<br/>bibliothèque<br/>d'exercices]
        UC7[Gestion des<br/>entraînements]
        UC8[Planifier les<br/>entraînements]
        UC9[Gestion des<br/>athlètes]
        UC10[Consultation des<br/>profils des athlètes]
        UC11[Gestion du<br/>profil]
    end

    ATHLETE((ATHLÈTE))
    COACH((COACH))

    ATHLETE --> UC1
    ATHLETE --> UC3
    ATHLETE --> UC11

    COACH --> UC6
    COACH --> UC7
    COACH --> UC8
    COACH --> UC9
    COACH --> UC11

    UC1 -.->|include| UC2
    UC3 --> UC4
    UC3 --> UC5
    UC7 -.->|include| UC6
    UC8 -.->|include| UC7
    UC9 -.->|include| UC10

    classDef actor fill:#fff,stroke:#333,stroke-width:2px
    classDef usecase fill:#4A90E2,stroke:#2E5C8A,stroke-width:2px,color:#fff

    class ATHLETE,COACH actor
    class UC1,UC2,UC3,UC4,UC5,UC6,UC7,UC8,UC9,UC10,UC11 usecase
```

Ce diagramme illustre la séparation claire entre les fonctionnalités destinées aux athlètes et celles réservées aux coachs. La gestion du profil est commune aux deux types d'utilisateurs.

![Diagramme des cas d'usage](../../../assets/diagram-use-cases.png)

> Voir le détail du [système de calcul automatique des charges](/annexes/analyses-besoins/#système-de-calcul-automatique-des-charges) en annexe.
