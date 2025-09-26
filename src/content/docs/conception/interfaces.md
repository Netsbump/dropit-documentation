---
title: Interfaces utilisateur
description: De l'analyse des besoins aux wireframes - conception centrée utilisateur
---

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

## Conception des wireframes

Pour la conception des interfaces, j'ai choisi de commencer par des wireframes basse fidélité qui se concentrent sur la structure informationnelle et les flux utilisateurs, sans me préoccuper des aspects visuels. Cette phase me permet de valider l'organisation de l'information et les flux utilisateurs avant de passer aux aspects visuels.

L'architecture de DropIt se décline en deux interfaces distinctes : une application web pour les coachs (back office) et une application mobile pour les athlètes (front office), chacune adaptée à son contexte d'usage spécifique.

### Wireframe web coach (Back office)

#### Page de bibliothèque d'entrainement

<img src="/src/assets/wireframe-web-prog.png" alt="Wireframe vue générale bibliothèque" width="800" />

La vue générale présente l'interface globale avec une navigation latérale permanente donnant accès aux trois catalogues : exercices, complexes et programmes d'entraînement. Cette organisation facilite la navigation entre les différents types de contenus que le coach manipule quotidiennement.

#### Page de formulaire de création d'un entrainement

<img src="/src/assets/wireframe-web-form-training.png" alt="Wireframe page création exercice" width="800" />

Le wireframe révèle les éléments structurants :
- Etape du formulaire dans lequel on peut composer l'entrainement avec un des exercices et/ou des complexS
- **Sidebar gauche** : catalogue d'exercices et complexes avec recherche
- **Zone centrale** : programme en construction avec éléments drag-and-drop

#### Contraintes responsive

Dans le MVP, j'ai fait le choix de ne pas optimiser l'interface web pour les mobiles. Les coachs utilisent principalement des ordinateurs de bureau ou tablettes pour créer leurs programmes, contexte qui permet une interface riche en interactions complexes. Cette décision me permet de concentrer l'effort sur une expérience optimale desktop plutôt que de multiplier les compromis.

### Wireframe mobile athlète (Front office)

#### Page d'accueil

<img src="/src/assets/wireframe-mobile-dashboard.png" alt="Wireframe page accueil mobile" width="300" />

Carousel pour visualiser l'entrainement, l'actualité du club et l'hitorique d'entrainement + menubottom avec acceuil au milieu (le caroussel), a droite navigation vers account, a gauche le bouton de navigation vers l'enristrement des record de l'athlète.

#### Page de visualisation d'entraînement

<img src="/src/assets/wireframe-mobile-training.png" alt="Wireframe visualisation programme mobile" width="300" />

L'interface mobile présente les exercices de manière séquentielle, avec les infos les importantes, au click sur un des éléments on aura une navigation vers le détails de l'exercice/complex

#### Page de visualisation détaillée d'un exercice

<img src="/src/assets/wireframe-mobile-training-detail.png" alt="Wireframe visualisation détail exercice mobile" width="300" />

## Design system

Pour le design system, j'ai choisi Shadcn/ui (pour l'interface web) après avoir analysé les enjeux d'accessibilité et de maintenabilité que présentait DropIt. Cette décision s'appuie sur plusieurs arguments techniques décisifs pour un projet professionnel détaillés dans la partie [présentations](/conception/presentations).

## Conclusion

Ces wireframes achèvent la conception technique de DropIt. L'ensemble de cette démarche établit les fondations nécessaires à l'implémentation de l'application.

La section suivante aborde les aspects sécuritaires, avec un zoom sur l'accès aux données (authentification et autorisation).