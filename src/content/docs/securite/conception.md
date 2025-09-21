---
title: Conception
description: Analyse des besoins sécuritaires et choix d'architecture d'authentification pour DropIt
---

## Introduction

Après avoir défini l'architecture globale de DropIt, j'aborde maintenant la conception de la sécurité applicative. Cette réflexion m'a amenée à analyser les besoins d'authentification et d'autorisation de l'application, puis à choisir une stratégie technique adaptée aux contraintes du projet.

## Analyse des besoins d'authentification

L'architecture multi-plateforme de DropIt impose de gérer trois profils d'utilisateurs distincts : les administrateurs depuis le backoffice web, les coachs depuis l'interface de gestion, et les athlètes via l'application mobile React Native.

Cette configuration m'amène à concevoir un système de permissions granulaire. Un coach doit pouvoir consulter et modifier les données des athlètes de son groupe, tandis qu'un athlète accède uniquement à ses propres informations d'entraînement. Cette séparation des accès constitue le fondement de ma stratégie d'autorisation.

## Contraintes réglementaires et techniques

Mon approche de la sécurité intègre d'abord les obligations légales liées au traitement des données personnelles. Le RGPD impose une protection rigoureuse des informations collectées : performances personnelles, historiques d'entraînement, et données de profil utilisateur.

Au-delà de la conformité réglementaire, j'ai identifié des besoins opérationnels spécifiques à l'application : révocation immédiate des droits d'accès lors du départ d'un utilisateur, gestion des changements de rôle (passage d'athlète à coach), et traçabilité des accès aux données pour les audits de sécurité.

Ces contraintes m'orientent vers une solution d'authentification qui offre à la fois la flexibilité nécessaire pour les évolutions fonctionnelles et la robustesse requise pour la protection des données.

## Solutions envisagées

Pour l'implémentation de l'authentification et de l'autorisation dans DropIt, trois approches principales s'offraient à moi : développer un système from scratch, utiliser une librairie externe, ou déléguer ce système à un identity provider externe.

Chaque solution présente des avantages et inconvénients spécifiques dans le contexte de mon application. J'ai mené une analyse comparative détaillée de ces trois approches en évaluant leurs forces et faiblesses par rapport aux besoins de DropIt. Cette étude complète est disponible en annexe dans la section [Choix authentification](/annexes/authentifications/).

Cette analyse m'a orienté vers l'utilisation d'une librairie externe, et plus spécifiquement vers Better-Auth.

## Solution retenue : Better-Auth

J'ai choisi Better-Auth comme solution d'authentification après analyse comparative des alternatives disponibles. Cette décision s'appuie sur plusieurs critères qui correspondent directement aux besoins de DropIt.

Better-Auth propose une implémentation hybride combinant JWT et sessions persistantes, ce qui répond à ma contrainte de révocation immédiate des droits. Les JWT me donnent les performances nécessaires pour l'API REST, tandis que les sessions en base permettent d'invalider instantanément l'accès d'un utilisateur sans attendre l'expiration du token.

Le système de plugins de Better-Auth me permet d'ajouter progressivement des fonctionnalités selon l'évolution du projet. Le plugin d'autorisation génère automatiquement les tables nécessaires avec une structure optimisée pour l'authentification, garantissant la cohérence entre le système d'auth et la gestion des droits.

Cette librairie s'intègre naturellement dans la stack TypeScript/NestJS que j'ai choisie pour l'API. Cette cohérence technologique me permet de me concentrer sur l'implémentation de la logique métier plutôt que sur la configuration d'un système d'authentification externe.

Better-Auth implémente nativement plusieurs mécanismes de sécurité essentiels pour DropIt. Le système de rate-limiting configure automatiquement des limites par IP (5 tentatives de connexion par minute) qui protègent l'API contre les attaques par force brute sans nécessiter de configuration manuelle.

La protection CSRF utilise des tokens double-submit pour sécuriser les requêtes d'écriture. Chaque requête POST/PUT/DELETE inclut un token généré côté serveur et vérifié à la réception, empêchant l'exécution de requêtes non autorisées depuis des sites tiers.

Les cookies de session sont automatiquement configurés avec les flags sécurisés appropriés : `SameSite=Lax` pour limiter l'envoi aux requêtes same-origin, `HttpOnly` pour prévenir l'accès via JavaScript, et `Secure` en production pour forcer HTTPS.

Ces configurations par défaut peuvent être ajustées selon l'évolution des besoins sécuritaires du projet.

Better-Auth intègre des fonctionnalités de conformité RGPD essentielles pour DropIt. L'endpoint `/api/auth/user/export` génère automatiquement une archive contenant toutes les données utilisateur au format JSON, répondant aux **obligations de portabilité** (Article 20 RGPD) : performances d'entraînement, historiques de blessures, données de profil.

Le système d'audit trace chaque action dans une table dédiée, servant trois objectifs RGPD cruciaux : **preuve d'accès** (qui a consulté quelles données et quand), **détection d'anomalies** (accès non autorisés), et **preuve de suppression** (enregistrement de l'effacement des données utilisateur lors du départ d'un athlète). Cette traçabilité est particulièrement importante pour les données de santé stockées dans DropIt (blessures, limitations physiques).

La librairie expose également les standards d'authentification modernes : l'endpoint JWKS (`/.well-known/jwks.json`) publie les clés publiques permettant la vérification des JWT par des services externes, tandis qu'OIDC Discovery (`/.well-known/openid-configuration`) standardise la découverte des endpoints d'authentification.

### Évolutions envisagées

L'architecture retenue me permet d'envisager plusieurs améliorations sécuritaires futures. L'authentification à deux facteurs (2FA) représente une priorité pour les comptes administrateurs, Better-Auth proposant un plugin dédié qui gère nativement la génération de QR codes et la validation des codes temporaires via des applications comme Google Authenticator.

L'ajout de providers OAuth (Google, Apple) pourrait faciliter l'onboarding des utilisateurs mobiles grâce aux plugins sociaux de Better-Auth. Cette intégration nécessitera toutefois une évaluation des implications RGPD liées au partage de données avec des tiers.

## Conclusion

Le choix de Better-Auth comme solution d'authentification répond aux exigences techniques et réglementaires de DropIt : gestion granulaire des permissions, révocation immédiate des droits, conformité RGPD, et extensibilité via le système de plugins.

La section suivante présente l'implémentation concrète de cette librairie dans le projet, détaillant l'architecture hybride JWT/sessions, les entités générées, et les mécanismes de protection des routes API.