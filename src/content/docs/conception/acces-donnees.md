---
title: Accès aux données
description: Implémentation de la couche d'accès aux données avec MikroORM
---

Après avoir établi le modèle conceptuel avec la méthode Merise, plusieurs approches s'offraient à moi pour implémenter la couche d'accès aux données: Database First, Schema First ou Code First.

J'ai retenu l'approche **Code First** qui définit les entités directement en TypeScript avec les décorateurs MikroORM. Cette méthode s'intègre nativement dans l'écosystème du monorepo, permet la génération automatique des migrations et tire parti de l'auto-complétion TypeScript.

> **Analyse détaillée des approches** : Voir l'annexe [Comparaison des approches d'implémentation](/annexes/implementation-acces-donnees/#comparaison-des-approches-dimplémentation)

## Définition des entités MikroORM

Les entités constituent la traduction directe du modèle de données en classes TypeScript annotées. Chaque entité encapsule à la fois la structure des données et les relations métier.

### Traduction du modèle en code TypeScript

MikroORM utilise un système de décorateurs pour traduire mon modèle de données directement dans le code TypeScript. Chaque table devient une classe, et les relations entre tables sont définies avec des décorateurs comme `@ManyToOne` ou `@OneToMany` qui reflètent exactement les liens définis dans le MLD.

Cette approche me permet de garder une cohérence totale entre ma conception et l'implémentation réelle. Le code TypeScript devient la source de vérité, et MikroORM génère automatiquement les requêtes SQL correspondantes.

> **Exemple d'entité** : Voir l'annexe [Exemple d'entité MikroORM](/annexes/implementation-acces-donnees/#exemple-dentité-mikroorm)

## Architecture en couches

L'accès aux données respecte une séparation stricte des responsabilités en organisant le code en couches distinctes. Cette approche s'inspire de l'architecture hexagonale sans l'implémenter de manière puriste, privilégiant un compromis pragmatique entre les principes théoriques et les contraintes du projet.

### Séparation des responsabilités

L'architecture respecte une séparation en quatre couches distinctes :

- **Interface Layer** : Controllers REST, Guards, Mappers, Presenters
- **Application Layer** : Use Cases et ports/interfaces
- **Domain Layer** : Entités métier
- **Infrastructure Layer** : Repositories MikroORM

Cette séparation améliore l'organisation du code et facilite les tests en isolant les différentes responsabilités.

> **Architecture détaillée** : Voir l'annexe [Architecture en couches détaillée](/annexes/implementation-acces-donnees/#architecture-en-couches-détaillée)

### Interface Layer : exposition HTTP

Les **Controllers** orchestrent toute la couche HTTP : vérifications de sécurité (authentification, isolation organisationnelle, permissions granulaires), respect du contrat ts-rest, transformation des entités en DTO via les **Mappers**, et formatage des réponses HTTP via les **Presenters**. Cette couche fait le pont entre le protocole HTTP et la logique métier pure.

> **Exemple détaillé d'implémentation** : Voir l'annexe [Interface Layer : exposition HTTP](/annexes/implementation-acces-donnees/#interface-layer--exposition-http)


### Application Layer : orchestration métier

Les **Use Cases** concentrent la logique applicative et les règles métier spécifiques en pur TypeScript, sans dépendance au framework web. Ils orchestrent les repositories en appliquant des vérifications métier critiques (autorisations organisationnelles, validation de l'existence des ressources, intégrité référentielle) et retournent des entités de domaine.

> **Exemple de Use Case** : Voir l'annexe [Exemple de Use Cases](/annexes/implementation-acces-donnees/#application-layer--orchestration-métier)

### Domain Layer : modèle métier

Les entités représentent les concepts métier avec leurs règles et contraintes, utilisant les décorateurs MikroORM (`@Entity()`, `@Property()`, `@ManyToOne()`, `@Check()`) pour le mapping vers PostgreSQL.
Cette approche présente une limitation par rapport à l'architecture hexagonale pure, mais offre un bon compromis entre simplicité et maintenabilité.

### Infrastructure Layer : accès aux données

L'Infrastructure Layer contient les **Repositories** qui assurent la persistance des données. MikroORM fournit automatiquement des repositories de base avec les opérations CRUD standard (find, save, delete) pour chaque entité.

Pour des besoins métier spécifiques, je crée des repositories personnalisés qui héritent du repository de base et ajoutent des méthodes spécialisées. Par exemple, `getOneWithDetails` charge un workout avec toutes ses relations imbriquées (exercices, complexes, catégories) en une seule requête optimisée, tout en appliquant les filtres d'isolation organisationnelle.

Cette approche hybride me permet de conserver toutes les méthodes optimisées de MikroORM pour les cas simples, tout en ajoutant des méthodes métier pour les cas complexes.

> **Exemple de Repository personnalisé** : Voir l'annexe [Repository personnalisé](/annexes/implementation-acces-donnees/#repository-personnalisé)

### Isolation des données

DropIt nécessite deux niveaux d'isolation des données distincts :

**Isolation organisationnelle (multi-tenancy)** : Les clubs utilisent la même application mais ne doivent jamais voir les données des autres clubs. J'ai choisi une approche avec une base de données partagée où chaque requête filtre automatiquement les données selon l'organisation de l'utilisateur connecté.

**Isolation par propriétaire** : Au sein d'un même club, chaque coach développe son propre catalogue d'exercices et de programmes personnalisés. Pour cela, j'utilise un champ `createdBy` sur les entités concernées (Exercise, Complex, Workout) qui référence le coach créateur.

Les `CoachFilterConditions` combinent ces deux niveaux : elles filtrent d'abord par organisation, puis permettent l'accès aux ressources soit créées par le coach, soit partagées (exercices officiels avec `createdBy = null`). Cette approche logicielle offre plus de flexibilité qu'une séparation physique des données tout en garantissant l'isolation au niveau de la persistance.q

## Pattern Unit of Work et gestion transactionnelle

### Le pattern Unit of Work

Le pattern Unit of Work consiste à maintenir une liste de tous les objets modifiés pendant une transaction et à coordonner leur écriture en base de données en une seule fois. MikroORM implémente nativement ce pattern : les entités modifiées sont marquées comme "dirty" et synchronisées lors du `flush()`.

### Transactions et propriétés ACID

Les transactions garantissent les propriétés ACID essentielles pour l'intégrité des données : atomicité, cohérence, isolation et durabilité. Dans le contexte de DropIt, cela signifie qu'un workout ne peut pas être créé avec des éléments orphelins.

### Fonctionnement automatique avec NestJS

MikroORM s'intègre avec le système d'intercepteurs de NestJS pour fournir automatiquement une transaction par requête HTTP. L'`EntityManager` suit automatiquement les modifications et génère les requêtes SQL optimales lors du flush.

### Gestion des suppressions en cascade

La suppression d'entités avec des relations nécessite une gestion particulière pour respecter l'intégrité référentielle. J'ai configuré les relations avec `deleteRule: 'cascade'` au niveau de MikroORM pour que les suppressions se propagent automatiquement selon les règles métier identifiées (cf. [Stratégies de suppression](/annexes/conception-bdd-technique/#stratégies-de-suppression)). Cette approche garantit l'intégrité des données sans nécessiter de logique manuelle dans les use cases.

## Sécurité applicative et protection OWASP

L'architecture intègre des mesures de sécurité spécifiques pour contrer les principales vulnérabilités répertoriées par l'OWASP :

- **OWASP A03 (Injection SQL)** : MikroORM avec requêtes paramétrées + validation Zod
- **OWASP A01 (Contrôle d'accès)** : Guards NestJS + isolation par organisation
- **OWASP A04 (Validation)** : Schémas Zod stricts dans `@dropit/schemas`

Cette approche centralisée évite les disparités de validation qui pourraient créer des failles de sécurité.

## Seeders et données de test

J'ai implémenté un système de seeders qui crée automatiquement des données de test lors du démarrage en développement. Ces seeders servent un double objectif : me fournir un environnement de développement reproductible avec des données cohérentes (utilisateurs, exercices, programmes), et créer un catalogue commun d'exercices officiels d'haltérophilie.

Les ressources partagées utilisent `createdBy = null` pour indiquer qu'elles sont accessibles à tous les clubs, évitant ainsi que chaque coach doive recréer les exercices de base (arraché, épaulé-jeté, squat, etc.).

## Évolution du schéma de base de données

Pour l'instant, j'utilise la synchronisation automatique de MikroORM en développement : quand je modifie une entité, le schéma de la base est automatiquement mis à jour. Cette approche accélère le développement, mais elle n'est pas viable en production car elle pourrait écraser des données utilisateurs.

Avant le passage en production, je migrerai vers le système de migrations de MikroORM, même en développement. Chaque modification du schéma générera un fichier de migration versionné qui transforme le schéma existant sans perdre les données. Cette approche garantit la traçabilité des changements et permet de les appliquer de manière contrôlée en production.

> **Exemple de migration** : Voir l'annexe [Exemple de migration générée](/annexes/implementation-acces-donnees/#exemple-de-migration-générée)


