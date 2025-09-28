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

- **Développement de fonctionnalités back-end sécurisées** : Cette dimension couvre l'authentification, la gestion des autorisations, la protection des données personnelles et la prévention des attaques OWASP (injections SQL, XSS, CSRF). L'implémentation sera détaillée dans les sections [Sécurité](/securite/conception/) et [Accès aux données](/conception/acces-donnees)

- **Déploiement et maintenance d'une application en production** : Cette compétence sera illustrée par la mise en place de CI/CD, l'utilisation d'un VPS avec Dokploy, et l'application des bonnes pratiques de maintenance. Les détails seront présentés dans la partie [Déploiement](/deploiement/preparation/)

## Public cible et de ses besoins

### Les pratiquants

L'application s'adresse principalement aux membres du club qui ont besoin d'accéder facilement à leurs programmes d'entraînement personnalisés, de suivre leurs progressions et de rester informés des actualités importantes du club.

L'accès au programme du jour constitue leur besoin prioritaire. Entre chaque série, l'athlète doit pouvoir visualiser immédiatement l'exercice suivant et la charge à utiliser sur sa barre. Le support mobile s'impose naturellement par sa praticité dans l'environnement de la salle de sport.

Le suivi de progression représente un aspect motivationnel crucial pour maintenir l'engagement des pratiquants. Cette fonctionnalité doit permettre une visualisation claire des améliorations sans complexité excessive d'usage.

### Les coachs

Les entraîneurs expriment des besoins différents, centrés sur l'efficacité de leur travail de programmation et de suivi.

La création et la gestion efficaces des programmes d'entraînement constituent leur besoin principal. L'outil doit leur faire gagner du temps dans ces tâches administratives pour qu'ils puissent se concentrer sur l'accompagnement technique des athlètes.

Le suivi des performances de leurs athlètes nécessite des outils de visualisation et d'analyse adaptés à la planification des cycles d'entraînement.

La communication avec l'ensemble du groupe doit être simplifiée et ciblée, évitant la dispersion actuelle de l'information.

## Stratégie de développement

La première version se concentrera sur les fonctionnalités essentielles : la gestion des programmes d'entraînement pour les coachs et leur consultation par les athlètes via l'application mobile. Cette approche MVP (Minimum Viable Product) me permet de créer rapidement une alternative fonctionnelle à la messagerie instantanée actuelle.

Dans un second temps, l'application évoluera en fonction des retours d'usage réels des membres de mon club. Cette phase d'enrichissement intégrera le suivi des progressions, un mode hors ligne pour l'application mobile, et diverses améliorations de l'expérience utilisateur basées sur l'observation des comportements d'utilisation.

## Défis techniques

L'interface doit être accessible sur différents supports, avec une version mobile pour les athlètes et une interface web pour les coachs.

La protection des données personnelles constitue un enjeu majeur. L'application devra respecter les normes RGPD et intégrer des mesures de sécurité robustes, particulièrement importantes dans le contexte de données de performance sportive qui peuvent révéler des informations sensibles sur les données de santé des utilisateurs.

## Perspectives d'évolution

La conception de l'application devra permettre son évolution future selon les besoins exprimés par les utilisateurs.