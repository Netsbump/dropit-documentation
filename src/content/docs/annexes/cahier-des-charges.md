---
title: Résumé du cahier des charges - DropIt
description: Document de synthèse présentant le cahier des charges du projet DropIt pour la certification Concepteur Développeur d'Applications
---

# CAHIER DES CHARGES
Concepteur Développeur d'Application

## CONTEXTE ET OBJECTIFS

La gestion des entraînements dans les clubs d'haltérophilie repose souvent sur des applications de messagerie instantanée, générant une dispersion de l'information et des inefficacités dans le suivi des programmes. Les athlètes peinent à retrouver leurs programmes personnalisés dans les conversations, et les coachs consacrent un temps considérable à répéter les mêmes informations.

DropIt est une application web et mobile qui numérise la gestion d'un club d'haltérophilie. Elle permet aux coachs de créer des programmes d'entraînement personnalisés via une interface web complète, tandis que les athlètes accèdent facilement à leurs séances via une application mobile optimisée pour la salle de sport.

Cette double approche, interface web pour la gestion administrative et mobile pour la consultation terrain, répond aux besoins spécifiques de chaque utilisateur dans leur contexte d'usage.

## PUBLIC CIBLE

Coachs d'haltérophilie : entraîneurs souhaitant optimiser la programmation et le suivi de leurs athlètes.
Athlètes pratiquants : membres de clubs cherchant un accès simple à leurs programmes personnalisés.
Clubs sportifs : structures désirant moderniser leur organisation et améliorer leur communication interne.

L'application vise des utilisateurs de tous niveaux techniques, avec une interface web pour les coachs et une application mobile pour les athlètes.

## FONCTIONNALITÉS PRINCIPALES (MVP)

- **Gestion des comptes utilisateurs** : inscription par invitation, authentification sécurisée via Better-Auth, gestion des organisations (clubs).
- **Bibliothèque d'exercices** : création et gestion d'exercices d'haltérophilie avec catégorisation, complexes d'exercices enchaînés.
- **Création de programmes** : composition d'entraînements avec exercices et complexes, paramétrage des séries/répétitions/charges en pourcentage.
- **Interface web coachs** : back-office complet pour la gestion des exercices, complexes et programmes d'entraînement.
- **Consultation mobile** : application React Native basique pour visualiser les programmes assignés (interface simplifiée pour le MVP).

## CONTRAINTES ET PÉRIMÈTRE

- **Sécurité** : authentification hybride JWT + sessions via Better-Auth, contrôle d'accès par rôles (member/admin/owner), conformité RGPD.
- **Périmètre MVP** : gestion des exercices, complexes et programmes côté web, consultation basique côté mobile. Pas d'analytics, de planification calendaire ou de gestion avancée des records personnels.
- **Spécificités métier** : adaptation aux besoins de l'haltérophilie (catégories d'exercices, complexes techniques, paramétrage en pourcentages).

## CHOIX TECHNIQUES

- **Front-end Web** : React 18, TypeScript, Tanstack Router, Shadcn/UI pour le back-office coachs.
- **Front-end Mobile** : React Native, Expo SDK pour l'application athlètes (MVP basique).
- **Back-end** : NestJS, MikroORM avec pattern Unit of Work, validation Zod, Better-Auth pour l'authentification.
- **Base de données** : PostgreSQL pour la fiabilité et les capacités relationnelles.
- **Infrastructure** : VPS Infomaniak, Dokploy pour la conteneurisation Docker et le déploiement.
- **Organisation** : Monorepo avec packages partagés (contrats API ts-rest, schémas Zod, permissions).

## LIEU ET DURÉE

Développement et déploiement réalisés en alternance chez Lonestone sur VPS personnel accessible en ligne.
Projet mené sur une durée de 9 mois, avec une première version utilisable par le club d'haltérophilie prévue avant la session d'examen.
Validation continue avec les utilisateurs réels du club pour ajuster l'expérience utilisateur.