---
title: Conception
description: Analyse des besoins sécuritaires et choix d'architecture d'authentification pour DropIt
---

DropIt distingue trois profils d'utilisateurs : un compte administrateur pour la maintenance technique de l'application, les coachs qui supervisent les entraînements, et les athlètes qui suivent leurs performances.

Cette hiérarchie m'amène à concevoir un système de permissions granulaire. Un coach doit pouvoir consulter et modifier les données des athlètes de son groupe, tandis qu'un athlète accède uniquement à ses propres informations. L'architecture multi-plateforme (web pour les coachs, mobile pour les athlètes) impose une contrainte supplémentaire : adapter l'authentification aux spécificités de chaque plateforme.

## Contraintes réglementaires et techniques

Mon approche de la sécurité intègre d'abord les obligations légales liées au traitement des données personnelles. Le RGPD impose une protection rigoureuse des informations collectées : performances personnelles, historiques d'entraînement, et données de profil utilisateur.

Au-delà de la conformité réglementaire, j'ai identifié des besoins opérationnels spécifiques à l'application : révocation immédiate des droits d'accès lors du départ d'un utilisateur et gestion des changements de rôle (passage d'athlète à coach).

Ces contraintes m'orientent vers une solution d'authentification qui offre à la fois la flexibilité nécessaire pour les évolutions fonctionnelles et la robustesse requise pour la protection des données.

## Solutions envisagées

Pour l'implémentation de l'authentification et de l'autorisation dans DropIt, trois approches principales s'offraient à moi : développer un système from scratch, utiliser une librairie, ou déléguer ce système à un identity provider externe.

Chaque solution présente des avantages et inconvénients spécifiques dans le contexte de mon application. J'ai mené une analyse comparative de ces trois approches en évaluant leurs forces et faiblesses par rapport aux besoins de DropIt. Cette étude est disponible en annexe dans la section [Analyse comparative des solutions](/annexes/authentifications/#analyse-comparative-des-solutions).

Cette analyse m'a orienté vers l'utilisation d'une librairie, et plus spécifiquement vers Better-Auth.

## Better-Auth

Better-Auth implémente une gestion de sessions classiques stockées en base, permettant la révocation immédiate des droits d'accès. Le système s'adapte automatiquement aux plateformes : cookies HttpOnly pour l'application web et bearer tokens pour l'application mobile. Dans les deux cas, chaque requête vérifie la validité de la session en base de données, garantissant qu'une session supprimée invalide instantanément l'accès.

> **Détails techniques** : La configuration complète des sessions est disponible dans l'annexe [Implémentation DropIt : Sessions persistantes](/annexes/authentifications/#implémentation-dropit--sessions-persistantes).

Better-Auth propose également un plugin JWT optionnel pour des cas d'usage spécifiques nécessitant une authentification stateless (services externes, microservices), mais cette fonctionnalité n'est pas activée dans l'implémentation actuelle de DropIt.

Le système de plugins permet d'ajouter progressivement des fonctionnalités selon l'évolution du projet. Le plugin d'autorisation génère automatiquement les tables nécessaires avec une structure optimisée, garantissant la cohérence entre le système d'auth et la gestion des droits.

Better-Auth implémente nativement plusieurs mécanismes de sécurité essentiels : le rate-limiting configure automatiquement des limites par IP (5 tentatives de connexion par minute) protégeant contre les attaques par force brute ; la protection CSRF utilise des tokens double-submit pour sécuriser les requêtes d'écriture ; les cookies de session sont automatiquement configurés avec les flags sécurisés appropriés (`SameSite=Lax`, `HttpOnly`, `Secure` en production).
> **Détails techniques** : Les mécanismes de protection CSRF, XSS, headers de sécurité et métadonnées de session sont détaillés dans l'annexe [Mécanismes de sécurité avancés](/annexes/authentifications/#mécanismes-de-sécurité-avancés).

La section suivante présente l'implémentation concrète de cette librairie dans le projet Dropit.