---
title: Analyse technique et enjeux du projet
description: Diagnostic technique, stratégie de développement et défis du projet DropIt
---

## Diagnostic de l'existant

Au sein de mon club, l'ensemble de la vie associative et sportive transite par une application de messagerie instantanée : actualités, programmation et visualisation des entraînements, échanges entre adhérents, partage de médias... Cette centralisation, bien que pratique à première vue, génère une confusion dans l'accès à l'information que j'ai pu observer pendant mes années de pratique. Rechercher un programme d'entraînement spécifique ou retrouver une annonce importante devient rapidement frustrant, chaque type de contenu se retrouvant noyé dans un flux continu de messages.

C'est à partir de ce constat que j'ai cherché dans quelle direction je pouvais proposer une solution pour fluidifier l'accès à l'information et mieux structurer la gestion quotidienne du club.

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

L'application s'adresse aux adhérents du club d'haltérophilie. L'identification des différents profils utilisateurs et l'analyse détaillée de leurs besoins respectifs sont présentées dans la section [Analyse des besoins fonctionnels](/conception/analyse/).