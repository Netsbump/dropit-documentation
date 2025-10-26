---
title: Préparation au déploiement
description: Analyse comparative des stratégies de déploiement et choix technique
---

## Analyse des stratégies de déploiement

Le déploiement de DropIt impose deux contraintes principales : un budget limité (contexte étudiant) et un objectif d'apprentissage des pratiques DevOps modernes. J'ai comparé trois approches pour identifier celle qui répond le mieux à ces besoins : déploiement manuel sur VPS, solutions cloud managées, et PaaS auto-hébergé.

## VPS traditionnel avec PM2

Le déploiement manuel sur VPS offre un contrôle total et un coût prévisible (environ 5-10€/mois). Cette approche consiste à installer directement Node.js, PostgreSQL et les dépendances système, puis utiliser PM2 pour gérer les processus et le restart automatique. Cependant, cette méthode implique une responsabilité complète sur la maintenance système (sécurité, mises à jour, monitoring) et nécessite une expertise DevOps significative. La configuration manuelle présente aussi des risques : non-reproductibilité entre environnements, absence d'isolation des services, et difficulté de rollback en cas de problème.

## PaaS commerciales (Vercel, Railway, Render)

Les solutions cloud managées simplifient radicalement le déploiement : quelques clics suffisent, avec HTTPS automatique et monitoring intégré. Cette approche permet de se concentrer exclusivement sur le développement applicatif. Toutefois, les coûts récurrents (50-100€/mois pour un usage modéré) sont incompatibles avec un budget étudiant. Ces plateformes introduisent aussi une dépendance à un fournisseur externe et masquent les mécanismes de déploiement, limitant l'apprentissage des concepts d'infrastructure et d'orchestration.

## PaaS auto-hébergé : Dokploy

Dokploy représente un compromis entre les deux approches : la simplicité d'un PaaS avec le contrôle économique d'un VPS auto-géré. Cette solution s'appuie sur Docker et Docker Swarm pour proposer une approche conteneurisée facilitant déploiements, rollbacks, et gestion multi-environnements via une interface web moderne. L'isolation des services via conteneurs élimine les conflits de dépendances et garantit la reproductibilité entre développement et production. Cette approche permet d'acquérir une compréhension pratique des concepts DevOps modernes (conteneurisation, orchestration, CI/CD) sans la complexité de Kubernetes.

## Solution retenue

J'ai donc déployé DropIt sur un VPS Infomaniak avec Dokploy, combinant contrôle technique et simplicité de gestion pour un coût limité (environ 10€/mois). Cette approche me permet d'expérimenter l'ensemble de la chaîne de déploiement : configuration serveur, orchestration des services, monitoring et sauvegardes. La section suivante détaille l'implémentation concrète de cette infrastructure.