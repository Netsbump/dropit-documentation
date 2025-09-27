---
title: Accès aux données
description: Implémentation de la couche d'accès aux données avec MikroORM
---

## Approches d'implémentation de la couche de données

Après avoir établi le modèle conceptuel avec la méthode Merise, plusieurs approches s'offraient à moi pour implémenter la couche d'accès aux données dans DropIt : Database First, Schema First et Code First.

J'ai retenu l'approche **Code First** qui définit les entités directement en TypeScript avec les décorateurs MikroORM. Cette méthode s'intègre nativement dans l'écosystème du monorepo, permet la génération automatique des migrations et tire parti de l'auto-complétion TypeScript.

> **Analyse détaillée des approches** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/)

## Définition des entités MikroORM

Les entités constituent la traduction directe du modèle logique de données en classes TypeScript annotées. Chaque entité encapsule à la fois la structure des données et les relations métier.

### Patterns adoptés

J'ai adopté plusieurs patterns systématiquement :
- **Identifiants UUID** : Évite les conflits lors des synchronisations entre environnements
- **Relations typées** : Décorateurs `@ManyToOne` et `@OneToMany` avec typage strict TypeScript
- **Collections MikroORM** : Type `Collection<T>` pour le chargement paresseux et les relations bidirectionnelles
- **Timestamps automatiques** : Propriétés `createdAt` et `updatedAt` avec callbacks automatiques

### Gestion des relations polymorphes

L'entité `WorkoutElement` illustre la résolution du pattern polymorphe avec un discriminant `element_type` et deux clés étrangères optionnelles. Le décorateur `@Check` garantit l'intégrité référentielle au niveau PostgreSQL.

> **Exemples complets d'entités** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/)

## Architecture en couches et pattern Repository

L'accès aux données dans DropIt respecte une séparation stricte des responsabilités via le pattern Repository et l'architecture hexagonale adoptée dans l'API NestJS.

### Séparation des responsabilités

L'architecture respecte une séparation stricte en quatre couches distinctes :

- **Interface Layer** : Controllers REST, Guards, DTOs et Validators
- **Application Layer** : Use Cases et Services applicatifs  
- **Domain Layer** : Entités métier, règles business et ports/interfaces
- **Infrastructure Layer** : Repositories MikroORM, services externes et adaptateurs

Cette approche donne la flexibilité de changer d'ORM, de base de données ou de services externes sans impacter la logique métier centrale.

> **Architecture détaillée avec exemples** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/)

### Interface Layer : exposition HTTP

Les **Controllers** gèrent le protocole HTTP et orchestrent les vérifications de sécurité : authentification, isolation organisationnelle, permissions granulaires et respect du contrat ts-rest. 
Les **Mappers** transforment les entités en DTO pour l'API. 
Enfin les **Presenters** standardisent le formatage des réponses et sécurisent les messages d'erreur.

> **Exemples détaillés d'implémentation** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/)


### Application Layer : orchestration métier

**Use Cases** concentrent la logique applicative et les règles métier spécifiques à l'haltérophilie. Ils orchestrent les repositories en appliquant des vérifications métier critiques : autorisations organisationnelles, validation de l'existence des ressources, intégrité référentielle et combinaison de règles d'autorisation.

> **Exemple complet de Use Case** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/)

### Domain Layer : modèle métier

Les entités représentent les concepts métier avec leurs règles et contraintes, utilisant les décorateurs MikroORM (`@Entity()`, `@Property()`, `@ManyToOne()`, `@Check()`) pour le mapping vers PostgreSQL. Cette approche offre un bon compromis entre simplicité et maintenabilité.
Cette approche présente une limitation par rapport à l'architecture hexagonale pure, mais offre un bon compromis entre simplicité et maintenabilité.

### Infrastructure Layer : accès aux données

L'Infrastructure Layer contient les **Repositories** qui assurent la persistance des données. MikroORM propose nativement des repositories automatiques pour chaque entité, accessibles via l'injection de dépendance.

Pour certains cas spécifiques, j'étends ces repositories automatiques avec des méthodes spécialisées comme `getOneWithDetails` qui nécessite un populate profond sur plusieurs niveaux de relations avec des conditions de filtrage organisationnel.

Cette approche hybride conserve l'accès aux méthodes MikroORM optimisées tout en respectant les contrats métier définis dans l'Application Layer.

> **Exemples de Repositories personnalisés** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/)

> **Structure complète de l'API** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/)

### Gestion du multi-tenancy

DropIt présente une particularité importante : chaque coach possède son propre catalogue d'exercices personnalisés qu'il développe au fil du temps. Cette logique crée une double isolation : les données d'organisation (athlètes) et les données personnelles de coach (catalogue d'exercices, complexes, programmes).

J'ai opté pour une approche de "row-level security" logicielle via les `CoachFilterConditions` plutôt qu'une base de données séparée par organisation. Cette approche offre plus de flexibilité et évite les problèmes de scalabilité et de maintenance.

Chaque entité possède un champ `createdBy` qui référence l'utilisateur créateur. Les conditions de filtrage appliquent automatiquement les règles d'isolation organisationnelle, garantissant une défense en profondeur au niveau de la persistance des données.

### Génération automatique des requêtes

MikroORM s'appuie sur Knex.js pour transformer les opérations TypeScript en requêtes PostgreSQL optimisées. L'option `populate` génère automatiquement toutes les jointures nécessaires en une seule requête, évitant le "problème N+1" et améliorant les performances.

Cette couche Infrastructure isole complètement la logique métier des détails techniques de persistence, permettant de changer d'ORM ou de base de données sans impacter les Use Cases.

### Bénéfices de l'architecture en couches

Cette séparation résout plusieurs problèmes : testabilité améliorée (chaque couche testable indépendamment), évolutivité naturelle (modification d'une couche n'impacte pas les autres), et réutilisabilité (Use Cases réutilisables par différentes interfaces d'exposition).

### Flux de données

Le trajet d'une requête illustre comment chaque couche a sa responsabilité spécifique : le Controller gère le protocole HTTP, le UseCase orchestre la logique métier et les permissions, le Repository abstrait l'accès aux données, et le Mapper/Presenter formatent les données pour le client.

Cette approche technique avec MikroORM privilégie la productivité de développement et la sécurité du typage strict, tout en restant flexible pour des optimisations spécifiques via l'EntityManager.

## Pattern Unit of Work et gestion transactionnelle

### Le pattern Unit of Work

Le pattern Unit of Work consiste à maintenir une liste de tous les objets modifiés pendant une transaction et à coordonner leur écriture en base de données en une seule fois. MikroORM implémente nativement ce pattern : les entités modifiées sont marquées comme "dirty" et synchronisées lors du `flush()`.

### Transactions et propriétés ACID

Les transactions garantissent les propriétés ACID essentielles pour l'intégrité des données : atomicité, cohérence, isolation et durabilité. Dans le contexte de DropIt, cela signifie qu'un workout ne peut pas être créé avec des éléments orphelins.

### Fonctionnement automatique avec NestJS

MikroORM s'intègre avec le système d'intercepteurs de NestJS pour fournir automatiquement une transaction par requête HTTP. L'`EntityManager` suit automatiquement les modifications et génère les requêtes SQL optimales lors du flush.

### Gestion des suppressions en cascade

La suppression d'entités avec des relations nécessite une gestion particulière pour respecter l'intégrité référentielle. J'ai opté pour une approche explicite qui donne le contrôle total sur l'ordre des opérations, permettant d'ajouter des logs, valider des règles métier ou implémenter une suppression "soft".

## Sécurité applicative et protection OWASP

L'architecture intègre des mesures de sécurité spécifiques pour contrer les principales vulnérabilités répertoriées par l'OWASP :

- **OWASP A03 (Injection SQL)** : MikroORM avec requêtes paramétrées + validation Zod
- **OWASP A01 (Contrôle d'accès)** : Guards NestJS + isolation par organisation
- **OWASP A04 (Validation)** : Schémas Zod stricts dans `@dropit/schemas`

Cette approche centralisée évite les disparités de validation qui pourraient créer des failles de sécurité.

## Configuration et optimisations

### Configuration MikroORM adaptée aux environnements

La configuration centralisée dans `mikro-orm.config.ts` s'adapte selon l'environnement d'exécution avec plusieurs optimisations importantes :

- **Découverte automatique des entités** : Via l'analyse des patterns de fichiers
- **Analyse statique performante** : Le `TsMorphMetadataProvider` analyse le code TypeScript à la compilation
- **Cohérence temporelle** : `forceUtcTimezone: true` garantit que toutes les dates sont en UTC

### Gestion des migrations en production

La stratégie de migration privilégie la sécurité et la traçabilité :

- **Génération automatique** : Le processus `pnpm run db:migration:create` génère automatiquement les fichiers
- **Application atomique** : `allOrNothing: true` encapsule toutes les migrations en attente dans une transaction unique
- **Préservation des contraintes** : `disableForeignKeys: false` maintient l'intégrité référentielle
- **Traçabilité complète** : Chaque migration appliquée est enregistrée dans une table système

> **Exemple de migration** : Voir l'[Annexe - Implémentation accès aux données](/annexes/implementation-acces-donnees/Exemple-de-migration-générée)

### Stratégie différenciée selon l'environnement

En développement, j'ai privilégié une approche de reconstruction complète via les seeders pour tester rapidement les modifications de schéma. En production, le système de migrations devient indispensable pour faire évoluer le schéma tout en préservant l'intégrité des données.

## Seeders et données de test

J'ai implémenté un système de seeders servant un double objectif : environnement de développement reproductible et catalogue commun d'exercices d'haltérophilie. Les ressources partagées (`createdBy = null`) constituent un socle d'exercices officiels accessible à tous les clubs, évitant la duplication des données de base.

## Conclusion

Cette implémentation de la couche d'accès aux données avec Nest.js et MikroORM résout les défis spécifiques de DropIt tout en posant les bases d'une architecture évolutive.

La section suivante sur les [couches de présentation](/conception/presentations) présente comment ces données sont consommées et présentées aux utilisateurs via les clients web et mobile.

