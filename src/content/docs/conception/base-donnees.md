---
title: Base de données
description: Conception et modélisation de la base de données
---

## Approche de conception

Pour concevoir la base de données de l'application, j'ai choisi d'utiliser la méthode Merise. Cette méthode, que j'ai apprise durant ma formation, offre une approche structurée pour passer des besoins métier à un modèle de données concret. Elle permet notamment de visualiser clairement les relations entre les différentes entités du système.

## Modèle Conceptuel de Données (MCD)

Le MCD représente la première étape de la modélisation. Il m'a permis de représenter les données de manière abstraite, en me concentrant sur les concepts métier plutôt que sur les aspects techniques. J'ai identifié les principales entités comme les athlètes, les coachs, les exercices et les programmes d'entraînement, ainsi que leurs relations.

[Insérer schéma MCD]

### Entités principales
Dans ce modèle, on retrouve les éléments essentiels identifiés lors de l'analyse des besoins. Par exemple, la relation entre un coach et ses athlètes, ou encore la composition des programmes d'entraînement à partir d'exercices.

## Modèle Logique de Données (MLD)

Le passage au MLD a permis de transformer les concepts abstraits en une structure plus proche de la base de données, en tenant compte des contraintes techniques. Cette étape a notamment impliqué la gestion des clés étrangères et la résolution des relations plusieurs à plusieurs.

[Insérer schéma MLD]

### Transformation des relations
J'ai dû prendre plusieurs décisions techniques lors de cette transformation, comme la création de tables de jonction pour gérer les relations complexes entre les exercices et les programmes.

## Modèle Physique de Données (MPD)

Le MPD représente la structure finale de la base de données telle qu'elle est implémentée dans PostgreSQL. À cette étape, j'ai défini les types de données précis, les contraintes d'intégrité et les index pour optimiser les performances.

[Insérer schéma MPD]

### Choix techniques
Pour chaque champ, j'ai choisi les types de données les plus appropriés en tenant compte des besoins de l'application. Par exemple, l'utilisation de UUID pour les identifiants plutôt que des entiers auto-incrémentés, ou encore le choix d'énumérations pour certains champs aux valeurs prédéfinies.

## Évolution du modèle

La structure de la base de données n'est pas figée. L'utilisation de MikroORM avec ses migrations permet de faire évoluer le schéma de manière contrôlée. J'ai prévu plusieurs évolutions possibles, notamment pour :
- L'ajout de nouvelles métriques pour le suivi des athlètes
- L'extension du système de gestion des exercices
- L'amélioration du système de notifications

## Optimisations

Bien que les performances ne soient pas un enjeu critique dans un premier temps vu le volume de données attendu, j'ai tout de même mis en place quelques optimisations :
- Création d'index sur les champs fréquemment recherchés
- Utilisation appropriée des types de données pour optimiser le stockage
- Structure permettant une mise en cache efficace avec Redis

La section suivante sur l'[accès aux données](/conception/acces-donnees) détaille l'utilisation de ces modèles dans le code de l'application.

