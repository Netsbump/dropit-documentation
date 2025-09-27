---
title: Implémentation de l'authentification
description: Mise en œuvre pratique du système d'authentification dans DropIt
---

## Organisation modulaire de l'authentification

J'ai isolé l'authentification dans un module NestJS dédié pour séparer les responsabilités et centraliser la configuration Better-Auth.

```markdown
modules/auth/
├── auth.decorator.ts  # Décorateurs pour l'authentification
├── auth.entity.ts     # Entités complémentaires 
├── auth.guard.ts      # Guard de protection des routes
├── auth.module.ts     # Configuration du module
├── auth.service.ts    # Service principal Better-Auth
└── README.md          # Documentation technique
```

## Entités générées par Better-Auth

Better-Auth impose un schéma de base de données spécifique avec quatre entités principales : `User`, `Session`, `Account`, et `Verification`. L'implémentation peut se faire manuellement selon la documentation ou via les scripts de génération fournis par la librairie.

L'intégration dans mon architecture existante s'est concentrée sur la table `User` qui devait s'harmoniser avec mon modèle utilisateur, les autres tables (`Session`, `Account`, `Verification`) étant autonomes.

Le schéma détaillé de ces entités est disponible dans la section [Modèle Logique de Données Better-Auth](/annexes/authentifications/#modèle-logique-de-données-better-auth) pour une vision complète de l'architecture de données.

### Entités clés : Session et Verification

L'entité **Session** gère les sessions actives des utilisateurs en stockant les métadonnées essentielles : ID utilisateur, token de session, date d'expiration, ainsi que l'adresse IP et le User-Agent pour le monitoring de sécurité. Cette approche me permet de détecter facilement les activités suspectes.

L'entité **Verification** s'occupe des tokens temporaires utilisés pour la vérification d'email et la réinitialisation de mot de passe. Chaque token a une durée de vie limitée, gérant automatiquement l'expiration pour renforcer la sécurité.

## Endpoints d'authentification

Better-Auth expose automatiquement des endpoints d'authentification complets sur le préfixe `/auth`, évitant l'implémentation manuelle de ces routes critiques.

```html
|       Route             | Méthode |        Description      |       Usage dans DropIt         |
|------------------------ |---------|-------------------------|---------------------------------|
| `/auth/signup`          | POST    | Inscription utilisateur | Création comptes coachs/athlètes|
| `/auth/login`           | POST    | Connexion               | Accès quotidien à l'application |
| `/auth/logout`          | POST    | Déconnexion             | Sécurisation des sessions       |
| `/auth/me`              | GET     | Profil utilisateur      | Données session courante        |
| `/auth/refresh`         | POST    | Renouvellement token    | Maintien des sessions longues   |
| `/auth/verify`          | GET     | Vérification email      | Sécurisation des comptes        |
| `/auth/reset-password`  | POST    | Réinitialisation        | Récupération comptes oubliés    |
```

Cette standardisation garantit l'implémentation native des bonnes pratiques de sécurité. J'ai ajouté le plugin openAPI() à ma configuration Better-Auth, ce qui génère automatiquement la documentation Swagger de tous ces endpoints pour faciliter le développement côté client. 

## Configuration du middleware d'authentification

Pour intégrer Better-Auth dans mon API NestJS, j'ai configuré un middleware qui redirige automatiquement toutes les requêtes commençant par `/auth` vers les routes gérées par Better-Auth. Cette approche me permet de déléguer complètement la gestion de l'authentification à la librairie.

```mermaid
sequenceDiagram
    participant Client
    participant NestJS
    participant BetterAuth
    participant Database

    Client->>NestJS: POST /api/auth/login
    NestJS->>NestJS: Détection préfixe /auth
    NestJS->>BetterAuth: Délégation à Better-Auth
    BetterAuth->>Database: Vérification credentials
    Database-->>BetterAuth: User data
    BetterAuth-->>NestJS: Session + JWT
    NestJS-->>Client: 200 + cookies
```

La configuration se fait dans le point d'entrée de l'API via un middleware conditionnel qui détecte les requêtes commençant par `/api/auth` et les délègue directement à Better-Auth.

## Protection des routes

### Décorateurs

Un décorateur en TypeScript est une fonction qui permet d'annoter et de modifier des classes, méthodes ou propriétés. Dans le contexte de NestJS, les décorateurs me permettent d'ajouter des métadonnées à mes routes pour indiquer leur niveau de sécurité.

Concrètement, au lieu d'écrire de la logique conditionnelle dans chaque contrôleur, j'annote simplement mes routes avec `@Public()` ou `@Optional()` pour indiquer leur niveau de sécurité. Je peux aussi injecter directement l'utilisateur connecté ou sa session dans les paramètres de mes méthodes.

Dans mon projet, j'ai configuré l'authentification comme étant globale : par défaut, toutes les routes nécessitent une authentification, sauf si je les marque explicitement avec `@Public()`. Cette configuration se fait via un système de Guards que je vais présenter juste après.

> **Exemple d'implémentation des décorateurs** : Voir l'[Annexe - Authentifications](/annexes/authentifications/#implémentation-des-décorateurs)

Ces décorateurs me permettent d'annoter mes routes avec des métadonnées de sécurité (`@Public()`, `@Optional()`) et d'injecter directement les données d'authentification dans les paramètres de méthode (`@CurrentUser()`, `@Session()`).

### Guards

Les Guards sont des classes qui implémentent une logique de sécurité dans NestJS. Un Guard s'exécute avant chaque route pour déterminer si la requête peut y accéder. Dans le contexte de l'authentification, le Guard vérifie si l'utilisateur est connecté et dispose des droits nécessaires.

Le Guard utilise le service `Reflector` de NestJS pour lire les métadonnées ajoutées par les décorateurs et adapter son comportement. Par exemple, si une route est marquée `@Public()`, le Guard autorisera l'accès même sans authentification. 

> **Exemple d'implémentation du Guard** : Voir l'[Annexe - Authentifications](/annexes/authentifications/#implémentation-du-guard)

### Exemple d'utilisation concrète

L'utilisation concrète de ces décorateurs et Guards dans un contrôleur illustre comment l'`AuthGuard` global vérifie l'authentification, comment le décorateur `@CurrentUser()` injecte l'utilisateur connecté, et comment l'absence de `@Public()` rend l'authentification obligatoire.

> **Exemple d'implémentation** : Voir l'[Annexe - Authentifications](/annexes/authentifications/#exemple-dusage-concret)

## Gestion des sessions et sécurité

Better-Auth implémente une approche hybride combinant JWT et sessions persistantes, répondant au besoin de révocation immédiate identifié dans mes contraintes.

Lors de la connexion, Better-Auth génère un JWT pour la validation rapide côté serveur et enregistre une session en base de données pour permettre la révocation instantanée (départ d'un utilisateur, changement de rôle).

Cette architecture combine la performance des tokens stateless avec la flexibilité des sessions traditionnelles. Les détails techniques et la comparaison JWT vs Sessions sont disponibles dans la section [Étude comparative des solutions d'authentification](/annexes/authentifications/#étude-comparative-des-solutions-dauthentification).

## Stratégie de sécurisation côté client

### Stockage sécurisé selon la plateforme

La sécurisation du stockage des tokens varie selon la plateforme d'accès. Pour le backoffice web, j'utilise les cookies HttpOnly qui protègent contre les attaques XSS (vulnérabilité permettant l'injection de code JavaScript malveillant). Cette protection est cruciale car les coachs accèdent parfois au backoffice depuis des postes partagés.

Pour l'application mobile, Better-Auth utilise automatiquement le stockage sécurisé natif via `expo-secure-store` : Keychain sur iOS et EncryptedSharedPreferences sur Android. Le plugin gère aussi le deep linking (redirection automatique vers l'app après authentification externe) pour les eventuelles futures intégrations OAuth.

### Configuration des sessions

J'ai adapté la durée des sessions selon les habitudes d'usage : 7 jours pour le web avec renouvellement automatique, et 30 jours pour le mobile pour éviter les reconnexions fréquentes. Cette configuration équilibre sécurité et expérience utilisateur.

Les détails d'implémentation et les spécificités techniques sont disponibles dans les sections [Configuration côté clients](/annexes/authentifications/#configuration-côté-clients-de-better-auth) et [Mécanismes de sécurité avancés](/annexes/authentifications/#mécanismes-de-sécurité-avancés).

## Implémentation côté clients

### Protection unifiée API et interface

L'un des avantages de Better-Auth est sa capacité à sécuriser à la fois l'accès aux APIs et le rendu conditionnel des interfaces utilisateur. Cette approche unifiée permet de maintenir une cohérence de sécurité entre le backend et le frontend.

Côté backend, mes APIs sont protégées par les Guards comme nous l'avons vu. Côté frontend, Better-Auth fournit des hooks React pour conditionner l'affichage des composants selon l'état d'authentification :

```typescript
// Exemple d'usage côté client web/mobile
import { useSession } from "@better-auth/react";

function WorkoutForm() {
  const { data: session, isPending } = useSession();

  if (isPending) return <LoadingSpinner />;
  if (!session) return <LoginPrompt />;

  // Composant accessible uniquement aux utilisateurs connectés
  return <CreateWorkoutForm user={session.user} />;
}
```

### Configuration multi-plateforme

Better-Auth s'adapte automatiquement aux spécificités de chaque plateforme. Pour l'application mobile Expo, j'utilise le plugin dédié qui gère le stockage sécurisé et les redirections. Pour le backoffice web, la configuration standard avec cookies HttpOnly suffit.

Cette approche unifie l'expérience de sécurité entre web et mobile tout en respectant les bonnes pratiques spécifiques à chaque plateforme. Les détails de configuration sont disponibles dans la section [Configuration côté clients de Better-Auth](/annexes/authentifications/#configuration-côté-clients-de-better-auth).

## Conclusion

L'implémentation de Better-Auth répond aux contraintes identifiées : révocation immédiate, architecture multi-plateforme, et conformité RGPD. Cette base d'authentification me permet de me concentrer sur la couche d'autorisation.

La section suivante présente l'implémentation via le plugin Organization de Better-Auth des permissions granulaires entre administrateurs, coachs et athlètes selon leur périmètre d'action.


