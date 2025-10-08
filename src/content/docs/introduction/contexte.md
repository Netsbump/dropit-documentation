---
title: Analyse technique et enjeux du projet
description: Diagnostic technique, stratégie de développement et défis du projet DropIt
---

## Diagnostic de l'existant

Au sein de mon club d'haltérophilie, la gestion des entraînements repose actuellement sur l'utilisation d'une application de messagerie instantanée. Cette solution simple, bien que pratique à première vue, révèle des dysfonctionnements significatifs dans la pratique quotidienne que j'ai pu observer et analyser pendant mes années de pratique.

Les programmes d'entraînement se retrouvent rapidement noyés dans le flux des conversations, rendant leur consultation difficile pour les athlètes. Cette dispersion de l'information génère régulièrement des incompréhensions sur les séances à réaliser, obligeant les coachs à répéter les mêmes informations à plusieurs reprises.

Cette situation impacte le travail des coachs, qui doivent consacrer un temps considérable à la gestion et à la communication des programmes d'entraînement. L'absence d'un outil dédié complique le suivi personnalisé des athlètes et la planification des cycles d'entraînement.

Cette observation du terrain m'a amené à m'interroger sur la possibilité de développer une solution plus adaptée aux besoins spécifiques de la gestion d'un club d'haltérophilie, en tirant parti de ma position de pratiquant pour mieux comprendre les enjeux utilisateur.

## Compétences du titre professionnel

Le développement de DropIt s'inscrit dans le cadre des compétences attendues pour l'obtention du titre professionnel "Concepteur Développeur d'Applications".

Le projet couvre l'ensemble des aspects techniques suivants :

- **Conception et développement d'une application multicouche** : Cette compétence est explorée à travers l'architecture monorepo avec packages partagés et la séparation des responsabilités entre API, interface web et application mobile. Le détail sera développé dans la partie [Architecture logicielle](/conception/architecture)

- **Mise en place d'une architecture moderne et évolutive** : Cette approche tend vers les principes du Domain-Driven Design et de l'architecture hexagonale côté API, et une organisation par features côté frontend. L'implémentation technique sera détaillée dans les sections [Accès aux données](/conception/acces-donnees) et [Présentations](/conception/presentations)

- **Développement d'interfaces utilisateur responsives et accessibles** : Cette compétence s'applique par la conception d'interfaces respectant les critères RGAA et adaptées aux contextes d'usage spécifiques des coachs et athlètes. La démarche sera présentée dans la partie [Interfaces utilisateur](/conception/interfaces)

- **Création et gestion d'une base de données** : Cette compétence est abordée par le biais de la méthode Merise pour la partie conception, et mise en place au sein de l'application via une approche Code First avec un ORM et une base de données relationnelle. Le détail sera défini dans la partie [Base de données](/conception/base-donnees)

- **Développement de fonctionnalités back-end sécurisées** : Cette dimension couvre l'authentification, la gestion des autorisations, la protection des données personnelles et la prévention des attaques (injections SQL, XSS, CSRF). L'implémentation sera détaillée dans les sections [Sécurité](/securite/conception/) et [Accès aux données](/conception/acces-donnees)

- **Déploiement et maintenance d'une application en production** : Cette compétence sera illustrée par la mise en place de CI/CD, l'utilisation d'un VPS avec Dokploy, et l'application des bonnes pratiques de maintenance. Les détails seront présentés dans la partie [Déploiement](/deploiement/preparation/)

## Public cible

L'application s'adresse à deux profils d'utilisateurs distincts au sein du club d'haltérophilie : les athlètes, qui ont besoin d'accéder à leurs programmes d'entraînement, et les coachs, qui doivent créer et gérer ces programmes de manière efficace.

L'analyse détaillée de leurs besoins respectifs et des parcours utilisateur est présentée dans la section [Analyse des besoins fonctionnels](/conception/analyse/).

## Stratégie de développement

Le développement suivra une approche itérative, en commençant par un MVP (Minimum Viable Product) centré sur les fonctionnalités essentielles, puis en enrichissant l'application selon les retours d'usage des membres du club. Les choix de priorisation sont détaillés dans la partie [MVP](/conception/analyse/#mvp).

## Perspectives d'évolution

La conception de l'application devra permettre son évolution future selon les besoins exprimés par les utilisateurs.