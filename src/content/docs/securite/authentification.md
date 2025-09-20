---
title: Implémentation de l'authentification
description: Mise en œuvre pratique du système d'authentification dans DropIt
---

## Introduction

Après avoir justifié le choix de Better-Auth comme solution d'authentification, je détaille ici son implémentation concrète dans DropIt. Cette librairie m'offre une approche hybride combinant JWT et sessions révocables, répondant parfaitement aux besoins identifiés.

L'implémentation de Better-Auth dans mon projet s'articule autour de plusieurs composants : la génération automatique d'entités de base de données, l'exposition d'endpoints d'authentification prêts à l'emploi, la protection des routes via un système de guards, et la configuration d'un middleware pour déléguer les requêtes d'authentification à la librairie.

## Organisation modulaire de l'authentification

Dans mon API NestJS, j'ai choisi d'isoler tout ce qui concerne l'authentification au sein d'un module dédié. Cette approche me permet de maintenir une séparation claire des responsabilités et facilite la maintenance du code d'authentification.

```
modules/auth/
├── auth.decorator.ts  # Décorateurs pour l'authentification
├── auth.entity.ts     # Entités complémentaires 
├── auth.guard.ts      # Guard de protection des routes
├── auth.module.ts     # Configuration du module
├── auth.service.ts    # Service principal Better-Auth
└── README.md          # Documentation technique
```

## Entités générées par Better-Auth

Better-Auth impose un schéma de base de données spécifique que j'ai dû intégrer dans mon système existant. Cette librairie génère automatiquement quatre entités principales : User, Session, Account, et Verification.

L'intégration de ces entités dans mon architecture existante s'est révélée simple. Seule la table User nécessitait une attention particulière car elle devait s'harmoniser avec mon modèle utilisateur existant. Les autres tables (Session, Account, Verification) sont autonomes et n'ont posé aucune difficulté d'implémentation.

Les schémas détaillés de ces entités (MCD, MLD, MPD) sont disponibles dans la section [Annexes authentification](/annexes/authentifications/) pour une vision complète de l'architecture de données.

### Entités clés : Session et Verification

L'entité **Session** gère les sessions actives des utilisateurs en stockant les métadonnées essentielles : ID utilisateur, token de session, date d'expiration, ainsi que l'adresse IP et le User-Agent pour le monitoring de sécurité. Cette approche me permet de détecter facilement les activités suspectes.

L'entité **Verification** s'occupe des tokens temporaires utilisés pour la vérification d'email et la réinitialisation de mot de passe. Chaque token a une durée de vie limitée, gérant automatiquement l'expiration pour renforcer la sécurité.

Dans mon implémentation, j'utilise l'approche code-first de NestJS avec MikroORM pour générer automatiquement ces entités. Il est aussi possible de les créer manuellement, mais il faut respecter scrupuleusement le schéma requis par Better-Auth. 

## Endpoints d'authentification automatiques

L'un des avantages majeurs de Better-Auth est l'exposition automatique d'endpoints d'authentification complets sur le préfixe `/auth`. Cette fonctionnalité me fait gagner un temps considérable en évitant le développement manuel de ces routes critiques.

| Route | Méthode | Description | Usage dans DropIt |
|-------|---------|-------------|-------------------|
| `/auth/signup` | POST | Inscription utilisateur | Création comptes coachs/athlètes |
| `/auth/login` | POST | Connexion | Accès quotidien à l'application |
| `/auth/logout` | POST | Déconnexion | Sécurisation des sessions |
| `/auth/me` | GET | Profil utilisateur | Données session courante |
| `/auth/refresh` | POST | Renouvellement token | Maintien des sessions longues |
| `/auth/verify` | GET | Vérification email | Sécurisation des comptes |
| `/auth/reset-password` | POST | Réinitialisation | Récupération comptes oubliés |

Cette standardisation me garantit l'implémentation des bonnes pratiques de sécurité sans effort supplémentaire. J'ai ajouté le plugin openAPI() à ma configuration Better-Auth, ce qui génère automatiquement la documentation Swagger de tous ces endpoints pour faciliter le développement côté client. 

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

Voici la configuration dans le point d'entrée de mon application : 

```ts
import { NestFactory } from '@nestjs/core';
import { SwaggerModule } from '@nestjs/swagger';
import * as dotenv from 'dotenv';
import * as express from 'express';
import { AppModule } from './app.module';
import { config } from './config/env.config';
import { openApiDocument } from './config/swagger.config';

dotenv.config();

const PREFIX = '/api';
const PORT = process.env.API_PORT || 3000;

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    bodyParser: false,
  });

  // Conditional middleware for better auth
  app.use(
    (
      req: express.Request,
      res: express.Response,
      next: express.NextFunction
    ) => {
      // If is routes of better auth, next
      if (req.originalUrl.startsWith(`${PREFIX}/auth`)) {
        return next();
      }
      // Else, apply the express json middleware
      express.json()(req, res, next);
    }
  );

  await app.listen(PORT, '0.0.0.0');
}

bootstrap();
```

## Protection des routes

### Décorateurs

Un décorateur en TypeScript est une fonction qui permet d'annoter et de modifier des classes, méthodes ou propriétés. Dans le contexte de NestJS, les décorateurs me permettent d'ajouter des métadonnées à mes routes pour indiquer leur niveau de sécurité.

Concrètement, au lieu d'écrire de la logique conditionnelle dans chaque contrôleur, j'annote simplement mes routes avec `@Public()` ou `@Optional()` pour indiquer leur niveau de sécurité. Je peux aussi injecter directement l'utilisateur connecté ou sa session dans les paramètres de mes méthodes.

Dans mon projet, j'ai configuré l'authentification comme étant globale : par défaut, toutes les routes nécessitent une authentification, sauf si je les marque explicitement avec `@Public()`. Cette configuration se fait via un système de Guards que je vais présenter juste après.

Voici une version simplifiée de mes décorateurs principaux :

```typescript
/**
 * Décorateur pour marquer une route comme publique (accessible sans authentification)
 */
export const Public = () => SetMetadata('PUBLIC', true);

/**
 * Décorateur pour marquer une route comme optionnelle (accessible avec ou sans authentification)
 */
export const Optional = () => SetMetadata('OPTIONAL', true);

/**
 * Décorateur pour injecter la session dans un contrôleur
 */
export const Session = createParamDecorator(
  (_data: unknown, context: ExecutionContext) => {
    const request = context.switchToHttp().getRequest();
    return request.session;
  }
);

/**
 * Décorateur pour injecter l'utilisateur connecté dans un contrôleur
 */
export const CurrentUser = createParamDecorator(
  (_data: unknown, context: ExecutionContext) => {
    const request = context.switchToHttp().getRequest();
    return request.user;
  }
);
```

Ces décorateurs me permettent d'annoter facilement mes routes selon leur niveau de sécurité et d'injecter automatiquement les données de session dans mes contrôleurs.

### Guards

Les Guards sont des classes qui implémentent une logique de sécurité dans NestJS. Un Guard s'exécute avant chaque route pour déterminer si la requête peut y accéder. Dans le contexte de l'authentification, le Guard vérifie si l'utilisateur est connecté et dispose des droits nécessaires.

Le Guard lit les métadonnées ajoutées par les décorateurs pour adapter son comportement. Par exemple, si une route est marquée `@Public()`, le Guard autorisera l'accès même sans authentification. 

Voici une version allégée de mon AuthGuard qui montre la logique principale :

```typescript
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly authService: AuthService
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    
    try {
      // Récupération de la session via Better-Auth
      const session = await this.authService.api.getSession({
        headers: fromNodeHeaders(request.headers),
      });

      // Injection session et utilisateur dans la requête
      request.session = session;
      request.user = session?.user ?? null;

      // Vérification des métadonnées de route
      const isPublic = this.reflector.get('PUBLIC', context.getHandler());
      const isOptional = this.reflector.get('OPTIONAL', context.getHandler());

      if (isPublic) return true;
      if (isOptional && !session) return true;
      
      if (!session) {
        throw new UnauthorizedException('You must be logged in to access this resource');
      }

      return true;
    } catch (error) {
      throw new UnauthorizedException('Authentication failed');
    }
  }
}
```

### Exemple d'utilisation concrète

Pour illustrer l'usage pratique de ces décorateurs et du système de Guards, voici un extrait simplifié de mon `WorkoutController`:

```typescript
@UseGuards(PermissionsGuard)
@Controller()
export class WorkoutController {
  constructor(
    private readonly workoutUseCases: WorkoutUseCases
  ) {}

  getWorkouts(@CurrentUser() user: AuthenticatedUser) {
    return tsRestHandler(c.getWorkouts, async () => {
      return await this.workoutUseCases.getWorkouts(organizationId, user.id);
    });
  }
}
```

Dans cet exemple, on voit comment :
- L'`AuthGuard` global vérifie automatiquement l'authentification avant d'arriver au contrôleur
- Le décorateur `@CurrentUser()` injecte automatiquement l'utilisateur connecté dans les paramètres
- Aucune route n'est marquée `@Public()` donc toutes nécessitent une authentification
- Le `@UseGuards(PermissionsGuard)` ajoute une couche de vérification des permissions (système qui sera détaillé dans la section suivante)

## Gestion des sessions et sécurité

### Architecture hybride JWT/Sessions

Better-Auth implémente une approche hybride qui combine les avantages des JWT et des sessions persistantes. Cette architecture répond parfaitement au besoin de révocation immédiate que j'ai identifié dans mes contraintes.

Concrètement, lors de la connexion, Better-Auth génère à la fois un JWT et enregistre une session en base de données. Le JWT permet une validation rapide côté serveur, tandis que la session en base permet la révocation instantanée si nécessaire (athlète quittant le club, changement de rôle).

Cette approche me donne la performance des tokens stateless avec la flexibilité de gestion des sessions traditionnelles. Les détails techniques de cette implémentation et la comparaison complète JWT vs Sessions sont disponibles dans les [Annexes authentification](/annexes/authentifications/).

## Stratégie de sécurisation côté client

### Stockage sécurisé selon la plateforme

La sécurisation du stockage des tokens varie selon la plateforme d'accès. Pour le backoffice web, j'utilise les cookies HttpOnly qui protègent contre les attaques XSS (vulnérabilité permettant l'injection de code JavaScript malveillant). Cette protection est cruciale car les coachs accèdent parfois au backoffice depuis des postes partagés.

Pour l'application mobile, Better-Auth utilise automatiquement le stockage sécurisé natif via `expo-secure-store` : Keychain sur iOS et EncryptedSharedPreferences sur Android. Le plugin gère aussi le deep linking (redirection automatique vers l'app après authentification externe) pour les futures intégrations OAuth.

### Configuration des sessions

J'ai adapté la durée des sessions selon les habitudes d'usage : 7 jours pour le web avec renouvellement automatique, et 30 jours pour le mobile pour éviter les reconnexions fréquentes. Cette configuration équilibre sécurité et expérience utilisateur.

Les détails d'implémentation, la configuration complète des tokens et les spécificités techniques sont disponibles dans les [Annexes authentification](/annexes/authentifications/).

## Implémentation côté clients

### Protection unifiée API et interface

L'un des avantages majeurs de Better-Auth est sa capacité à sécuriser à la fois l'accès aux APIs et le rendu conditionnel des interfaces utilisateur. Cette approche unifiée me permet de maintenir une cohérence de sécurité entre le backend et le frontend.

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

Better-Auth s'adapte automatiquement aux spécificités de chaque plateforme. Pour l'application mobile Expo, j'utilise le plugin dédié qui gère automatiquement le stockage sécurisé et les redirections. Pour le backoffice web, la configuration standard avec cookies HttpOnly suffit.

Cette approche unifiée me garantit une expérience de sécurité cohérente entre le web et le mobile, tout en respectant les bonnes pratiques spécifiques à chaque plateforme. Les détails de configuration et exemples d'implémentation sont disponibles dans les [Annexes authentification](/annexes/authentifications/).

## Conclusion

L'implémentation de Better-Auth dans DropIt me fournit une base d'authentification solide qui répond aux contraintes identifiées : révocation immédiate, architecture multi-plateforme, et conformité RGPD. Cette fondation technique me permet maintenant de me concentrer sur la couche d'autorisation.

La section suivante détaille comment j'enrichis cette base avec le plugin Organization de Better-Auth pour implémenter un système de permissions granulaire. Ce système RBAC (Role-Based Access Control) me permet de gérer finement les droits d'accès entre administrateurs, coachs et athlètes, garantissant que chaque utilisateur accède uniquement aux données et fonctionnalités de son périmètre d'action dans le club.

---

*Note : L'intégration avec le système d'email, les configurations avancées et les détails d'implémentation techniques sont disponibles dans les [Annexes authentification](/annexes/authentifications/).*

