---
title: Conception
description: Analyse des besoins sécuritaires et choix d'architecture d'authentification pour DropIt
---

## Introduction

Après avoir défini l'architecture globale de DropIt, j'ai souhaité approfondir un aspect crucial qui me préoccupait particulièrement : la sécurisation de l'accès aux données dans le contexte spécifique d'un club d'haltérophilie. Cette réflexion m'a menée à concevoir une stratégie d'authentification et d'autorisation qui réponde aux défis techniques et réglementaires de ce domaine.

## Analyse du contexte sécuritaire de DropIt

### Identification des enjeux spécifiques

L'analyse du contexte métier de DropIt m'a révélé des défis sécuritaires particuliers que je n'avais pas immédiatement anticipés. Dans le contexte d'un club d'haltérophilie, je dois gérer trois profils d'utilisateurs aux besoins radicalement différents : les administrateurs qui supervisent l'ensemble du système, les coachs qui accèdent quotidiennement aux données d'entraînement depuis le backoffice web, et les athlètes qui consultent leurs performances via l'application mobile.

Cette diversité d'accès m'a fait prendre conscience de la complexité de la gestion des droits dans une application multi-plateforme. Chaque profil nécessite un niveau de granularité différent : un coach doit pouvoir consulter les données de ses athlètes mais pas celles d'un autre groupe, tandis qu'un athlète ne devrait accéder qu'à ses propres informations.

### Contraintes réglementaires et techniques

Mon approche de la sécurité s'appuie d'abord sur mes obligations légales en tant que développeur manipulant des données personnelles. Le RGPD impose une protection rigoureuse des données personnelles, mais le contexte spécifique d'un club d'haltérophilie ajoute des exigences supplémentaires que j'ai dû identifier et intégrer dans ma conception.

La particularité du secteur sportif réside dans la sensibilité des données collectées : performances personnelles, évolution physique, historiques d'entraînement, parfois même des informations liées à la santé. Ces informations requièrent un niveau de protection élevé, non seulement pour respecter la réglementation, mais aussi pour maintenir la confiance des utilisateurs dans l'application.

J'ai également identifié des besoins opérationnels spécifiques au contexte sportif : la révocation immédiate des droits d'accès lorsqu'un athlète quitte le club, la gestion des changements de rôle (un athlète qui devient coach), ou encore la nécessité de tracer précisément qui accède à quelles données pour des raisons de conformité.

## Solutions envisagées

Pour l'implémentation de l'authentification et de l'autorisation dans DropIt, trois approches principales s'offraient à moi : développer un système from scratch, utiliser une librairie externe, ou déléguer ce système à un identity provider externe.

Chaque solution présente des avantages et inconvénients spécifiques dans le contexte de mon application. J'ai mené une analyse comparative détaillée de ces trois approches en évaluant leurs forces et faiblesses par rapport aux besoins de DropIt. Cette étude complète est disponible en annexe dans la section [Choix authentification](/annexes/authentifications/).

Cette analyse m'a orienté vers l'utilisation d'une librairie externe, et plus spécifiquement vers Better-Auth.

## Solution retenue

Better-Auth s'est imposé comme la solution la plus adaptée à mon contexte pour plusieurs raisons concrètes.

Cette librairie me fournit une authentification prête à l'emploi avec des endpoints clés en main et une gestion complète des données en base. Plus intéressant encore, Better-Auth propose une implémentation hybride combinant JWT et sessions persistantes, ce qui me permet d'avoir à la fois les performances des JWT et la possibilité de révocation immédiate des droits via les sessions stockées en base.

Le système de plugins de Better-Auth répond parfaitement à mes besoins évolutifs. J'utilise notamment le plugin d'autorisation qui génère automatiquement les tables de gestion des rôles et expose des endpoints pour administrer facilement les permissions utilisateur dans mon application.

L'intégration naturelle avec l'écosystème TypeScript/Node.js que j'ai choisi pour DropIt facilite la maintenance et réduit ma courbe d'apprentissage, me permettant de me concentrer sur la logique métier plutôt que sur l'implémentation des mécanismes de sécurité.

Better-Auth implémente nativement de nombreuses bonnes pratiques de sécurité qui m'auraient demandé un travail considérable à développer manuellement. Ces fonctionnalités couvrent les aspects essentiels de la protection applicative.

Le système de rate-limiting intégré me protège contre les attaques par force brute en limitant les tentatives de connexion (par exemple 5 tentatives par minute) et prévient le spam d'endpoints coûteux. La protection CSRF via des tokens double-submit sécurise automatiquement mes requêtes POST/PUT/DELETE en ajoutant un token aléatoire qu'un site tiers ne peut pas deviner.

Les cookies configurés avec le flag SameSite=Lax réduisent les risques d'attaques CSRF en s'assurant que les cookies ne sont envoyés que depuis mon domaine. Cette configuration par défaut me fait gagner du temps tout en renforçant la sécurité.

Better-Auth fournit également des fonctionnalités de conformité RGPD que j'apprécie particulièrement. L'export automatique des données utilisateur génère un fichier JSON/ZIP conforme aux obligations légales de portabilité. La table audit_log trace automatiquement qui fait quoi et quand, ce qui me permet de prouver la conformité RGPD et facilite les enquêtes en cas d'incident de sécurité.

La librairie expose aussi des standards modernes comme JWKS (l'annuaire public des clés) qui permet à n'importe quel service de vérifier mes JWT sans échange manuel de clés, et OIDC discovery qui standardise les endpoints d'authentification pour faciliter l'intégration future avec d'autres systèmes.

### Évolutions envisagées

L'architecture mise en place ouvre plusieurs perspectives d'évolution que je compte explorer dans la suite du développement de DropIt. L'implémentation de l'authentification à deux facteurs (2FA) constitue une priorité, particulièrement pour les comptes administrateurs qui disposent d'accès privilégiés.

De même, l'intégration de Better-Auth avec les providers OAuth (Google, Apple) pourrait simplifier l'onboarding des athlètes, tout en maintenant le niveau de sécurité requis. Cette évolution nécessitera cependant une analyse approfondie des implications en termes de protection des données personnelles.

## Conclusion

Cette analyse m'a permis de poser les fondations conceptuelles de la sécurité dans DropIt. Le choix de Better-Auth comme solution d'authentification répond aux contraintes techniques et réglementaires identifiées, tout en offrant la flexibilité nécessaire pour les évolutions futures.

La section suivante détaille comment j'ai implémenté cette librairie au sein de mon projet, notamment le fonctionnement de l'architecture hybride JWT/sessions, les entités générées automatiquement par Better-Auth et le système de guards et décorateurs mis à disposition pour sécuriser les routes.