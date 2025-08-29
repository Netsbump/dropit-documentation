---
title: Résumé du cahier des charges - DropIt
description: Document de synthèse présentant le cahier des charges du projet DropIt pour la certification Concepteur Développeur d'Applications
---

# CAHIER DES CHARGES
**Concepteur Développeur d'Application**

## CONTEXTE ET OBJECTIFS

La gestion des entraînements dans les clubs d'haltérophilie repose souvent sur des applications de messagerie instantanée, générant une dispersion de l'information et des inefficacités dans le suivi des programmes. Les athlètes peinent à retrouver leurs programmes personnalisés dans les conversations, et les coachs consacrent un temps considérable à répéter les mêmes informations.

DropIt est une application web et mobile qui digitalise la gestion d'un club d'haltérophilie. Elle permet aux coachs de créer des programmes d'entraînement personnalisés via une interface web complète, tandis que les athlètes accèdent facilement à leurs séances via une application mobile optimisée pour la salle de sport.

Cette double approche - interface web pour la gestion administrative et mobile pour la consultation terrain - répond aux besoins spécifiques de chaque utilisateur dans leur contexte d'usage.

## PUBLIC CIBLE

● **Coachs d'haltérophilie** : entraîneurs souhaitant optimiser la programmation et le suivi de leurs athlètes.
● **Athlètes pratiquants** : membres de clubs cherchant un accès simple à leurs programmes personnalisés.
● **Clubs sportifs** : structures désirant moderniser leur organisation et améliorer leur communication interne.

L'application vise des utilisateurs de tous niveaux techniques, avec une interface web riche pour les coachs et une application mobile intuitive pour les athlètes.

## FONCTIONNALITÉS PRINCIPALES (MVC)

● **Gestion des comptes utilisateurs** : inscription, authentification sécurisée, profils sportifs (catégories, niveaux, mesures physiques).
● **Bibliothèque d'entraînements** : création d'exercices, blocs d'exercices et programmes complets réutilisables.
● **Planification intelligente** : attribution d'entraînements aux athlètes via interface calendaire avec calcul automatique des charges basé sur les pourcentages des maximums.
● **Application mobile athlètes** : consultation des programmes, gestion des records personnels (maximums), visualisation du calendrier.
● **Interface web coachs** : gestion complète des programmes, suivi des athlètes avec filtres par critères sportifs, communication du club.
● **Calculs métier spécialisés** : automatisation des charges d'entraînement selon les méthodes de l'haltérophilie (pourcentages des maximums).

## CONTRAINTES ET PÉRIMÈTRE

● **Sécurité** : authentification hybride JWT + sessions, contrôle d'accès granulaire par rôles, conformité RGPD pour les données de performance.
● **Performance** : application mobile réactive en conditions de salle de sport, cache Redis pour les données fréquentes.
● **Périmètre initial** : gestion des programmes et consultation mobile, sans fonctionnalités avancées (analytics, intégrations externes).
● **Spécificités métier** : intégration des catégories de compétition, types d'exercices spécialisés, programmation par cycles.

## CHOIX TECHNIQUES

● **Front-end Web** : React 18, TypeScript, Tanstack Router, Shadcn/UI.
● **Front-end Mobile** : React Native, Expo SDK pour déploiement iOS/Android.
● **Back-end** : NestJS, MikroORM (pattern Unit of Work), validation Zod.
● **Base de données** : PostgreSQL (fiabilité, capacités relationnelles).
● **Infrastructure** : Redis (cache), MinIO (stockage S3-compatible), Dokploy (containerisation Docker).
● **Organisation** : Monorepo avec packages partagés (contrats API, schémas, permissions).
● **Monitoring** : Sentry pour l'observabilité et la détection d'erreurs.

## LIEU ET DURÉE

● **Développement et déploiement** réalisés en alternance chez Lonestone sur VPS personnel accessible en ligne.
● **Projet mené sur une durée de 9 mois**, avec une première version utilisable par le club d'haltérophilie prévue avant la session d'examen.
● **Validation continue** avec les utilisateurs réels du club pour ajuster l'expérience utilisateur.