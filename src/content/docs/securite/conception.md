---
title: Conception
description: Analyse des besoins sécuritaires et choix d'architecture d'authentification pour DropIt
---

## Analyse des besoins d'authentification

L'architecture multi-plateforme de DropIt impose de gérer trois profils d'utilisateurs distincts : les administrateurs depuis le backoffice web, les coachs depuis l'interface de gestion, et les athlètes via l'application mobile React Native.

Cette configuration m'amène à concevoir un système de permissions granulaire. Un coach doit pouvoir consulter et modifier les données des athlètes de son groupe, tandis qu'un athlète accède uniquement à ses propres informations d'entraînement. Cette séparation des accès constitue le fondement de ma stratégie d'autorisation.

## Contraintes réglementaires et techniques

Mon approche de la sécurité intègre d'abord les obligations légales liées au traitement des données personnelles. Le RGPD impose une protection rigoureuse des informations collectées : performances personnelles, historiques d'entraînement, et données de profil utilisateur.

Au-delà de la conformité réglementaire, j'ai identifié des besoins opérationnels spécifiques à l'application : révocation immédiate des droits d'accès lors du départ d'un utilisateur, gestion des changements de rôle (passage d'athlète à coach), et traçabilité des accès aux données pour les audits de sécurité.

Ces contraintes m'orientent vers une solution d'authentification qui offre à la fois la flexibilité nécessaire pour les évolutions fonctionnelles et la robustesse requise pour la protection des données.

## Solutions envisagées

Pour l'implémentation de l'authentification et de l'autorisation dans DropIt, trois approches principales s'offraient à moi : développer un système from scratch, utiliser une librairie externe, ou déléguer ce système à un identity provider externe.

Chaque solution présente des avantages et inconvénients spécifiques dans le contexte de mon application. J'ai mené une analyse comparative de ces trois approches en évaluant leurs forces et faiblesses par rapport aux besoins de DropIt. Cette étude est disponible en annexe dans la section [Analyse comparative des solutions](/annexes/authentifications/#analyse-comparative-des-solutions).

Cette analyse m'a orienté vers l'utilisation d'une librairie externe, et plus spécifiquement vers Better-Auth.

## Solution retenue : Better-Auth

Better-Auth propose une implémentation hybride combinant JWT et sessions persistantes, répondant à la contrainte de révocation immédiate des droits. Les JWT assurent les performances nécessaires pour l'API REST, tandis que les sessions en base permettent d'invalider instantanément l'accès d'un utilisateur sans attendre l'expiration du token.

Le système de plugins permet d'ajouter progressivement des fonctionnalités selon l'évolution du projet. Le plugin d'autorisation génère automatiquement les tables nécessaires avec une structure optimisée, garantissant la cohérence entre le système d'auth et la gestion des droits.

Better-Auth implémente nativement plusieurs mécanismes de sécurité essentiels : le rate-limiting configure automatiquement des limites par IP (5 tentatives de connexion par minute) protégeant contre les attaques par force brute ; la protection CSRF utilise des tokens double-submit pour sécuriser les requêtes d'écriture ; les cookies de session sont automatiquement configurés avec les flags sécurisés appropriés (`SameSite=Lax`, `HttpOnly`, `Secure` en production).

La librairie intègre des fonctionnalités de conformité RGPD essentielles : l'endpoint `/api/auth/user/export` génère automatiquement une archive contenant toutes les données utilisateur au format JSON, répondant aux obligations de portabilité (Article 20 RGPD) ; le système d'audit trace chaque action dans une table dédiée, servant trois objectifs RGPD cruciaux : preuve d'accès, détection d'anomalies, et preuve de suppression, particulièrement important pour les données de santé stockées dans DropIt.

Better-Auth expose également les standards d'authentification modernes : l'endpoint JWKS (`/.well-known/jwks.json`) publie les clés publiques permettant la vérification des JWT par des services externes, tandis qu'OIDC Discovery (`/.well-known/openid-configuration`) standardise la découverte des endpoints d'authentification.

### Évolutions envisagées

L'architecture retenue me permet d'envisager plusieurs améliorations sécuritaires futures. L'authentification à deux facteurs (2FA) représente une priorité pour les comptes administrateurs, Better-Auth proposant un plugin dédié qui gère nativement la génération de QR codes et la validation des codes temporaires via des applications comme Google Authenticator.

L'ajout de providers OAuth (Google, Apple) pourrait faciliter l'onboarding des utilisateurs mobiles grâce aux plugins sociaux de Better-Auth. Cette intégration nécessitera toutefois une évaluation des implications RGPD liées au partage de données avec des tiers.

## Conclusion

Le choix de Better-Auth comme solution d'authentification répond aux exigences techniques et réglementaires de mon application : gestion granulaire des permissions, révocation immédiate des droits, conformité RGPD, et extensibilité via le système de plugins.

La section suivante présente l'implémentation concrète de cette librairie dans le projet Dropit.