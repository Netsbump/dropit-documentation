---
title: Implémentation de l'authentification avec Better-Auth
description: Mise en œuvre pratique du système d'authentification hybride dans DropIt
---

## Introduction : de la conception à l'implémentation

Le choix de Better-Auth permet une approche hybride combinant JWT et sessions révocables.
Cette implémentation s'articule autour de plusieurs composants interdépendants: la configuration du service d'authentification, la gestion des entités de données, la protection des routes via des guards, et l'exposition d'une API cohérente pour les applications clientes.

## Vue d'ensemble de l'architecture d'authentification

### Schema Better Auth

Better auth propose des packages pour l'api et les différents clients web et mobile. 
Pour la partie backend, y a un schema a respecter, donc les entités etc a présenter qu'il a fallu intégrer dans mon systeme déjà existant. Hormis la table User, les autres tables sont autonomes et ne représente pas de difficulté particulière dans l'implémentation. 
Pour bien visualiser les tables généré par le package je les ai representer sous forme de méthode merise ci dessous 

TODO: Schema MCD 

TODO: Schema MLD

TODO: Schema MPD

Bien évidemment on utilera plutot un script pour les généré directement en code first coté api. Il est aussi possible de les créer à la main entité par entité dans nest.js en faisant bien attention de respecter scrupuleursement le schema de bdd requis par Better auth. 

### Architecture modulaire adoptée

J'ai structuré l'implémentation selon une architecture modulaire qui sépare clairement les responsabilités et facilite la maintenance.

```
modules/auth/
├── auth.decorator.ts  # Décorateurs pour l'authentification
├── auth.entity.ts     # Entités complémentaires 
├── auth.guard.ts      # Guard de protection des routes
├── auth.module.ts     # Configuration du module
├── auth.service.ts    # Service principal Better-Auth
└── README.md          # Documentation technique
```

## Configuration et service principal

### Implémentation du service Better-Auth

Le cœur du système d'authentification réside dans le service Better-Auth que j'ai configuré pour répondre aux besoins spécifiques de DropIt. Cette configuration m'a demandé d'approfondir ma compréhension des enjeux de sécurité web et de découvrir les subtilités d'une authentification multi-plateforme.

```typescript
// Configuration Better-Auth adaptée à DropIt
this._auth = betterAuth({
  secret: config.betterAuth.secret,
  trustedOrigins: config.betterAuth.trustedOrigins,
  
  // Authentification email/password adaptée au contexte club
  emailAndPassword: {
    enabled: true,
    sendResetPassword: async (data) => {
      // Intégration avec le service email pour réinitialisation
      await this.emailService.sendPasswordReset(data);
    },
  },
  
  // Vérification email pour sécuriser les comptes
  emailVerification: {
    sendOnSignUp: true,
    expiresIn: 60 * 60 * 24 * 10, // 10 jours - adapté aux habitudes utilisateur
    sendVerificationEmail: async (data) => {
      await this.emailService.sendVerificationEmail(data);
    },
  },
  
  // Connexion PostgreSQL pour cohérence avec l'architecture
  database: new Pool({
    connectionString: config.database.connectionString,
  }),
  
  // Configuration rate limiting pour protection DDoS
  rateLimit: {
    window: 50,
    max: 100,
  },
  
  // Hooks personnalisés pour logique métier DropIt
  hooks: {
    before: createAuthMiddleware(async (ctx) => {
      // Hook de pré-traitement pour logs et validation
    }),
  },
  
  plugins: [openAPI()], // Documentation automatique des endpoints
});
```

Cette configuration illustre ma démarche d'adaptation d'un outil générique aux besoins spécifiques de DropIt. L'intégration du service email et la définition des paramètres de sécurité reflètent ma compréhension progressive des enjeux de production.

### Intégration avec l'écosystème NestJS

L'intégration de Better-Auth dans l'architecture NestJS m'a permis d'explorer les patterns d'injection de dépendances et de découverte de modules. Cette approche facilite la testabilité et la maintenance du code :

```typescript
// auth.service.ts - Service principal
@Injectable()
export class AuthService implements OnModuleInit {
  private _auth: BetterAuth;

  constructor(
    @Inject('EMAIL_SERVICE') private emailService: EmailService,
    @Inject('CONFIG') private config: Config,
  ) {}

  async onModuleInit() {
    // Initialisation différée pour gestion des dépendances
    await this.initialize();
  }

  get auth(): BetterAuth {
    return this._auth;
  }
}
```

## Gestion des entités et persistance des données

### Modélisation des données d'authentification

L'implémentation de Better-Auth nécessite plusieurs entités complémentaires à l'entité `User` existante. Cette modélisation m'a aidé à comprendre la complexité de la gestion des sessions modernes et des systèmes d'authentification distribués.

#### Entité AuthSession : Gestion des sessions actives

```typescript
@Entity('auth_session')
export class AuthSession {
  @PrimaryKey()
  id!: string;

  @Property()
  userId!: string;

  @Property({ type: 'text', nullable: true })
  impersonatedBy?: string;

  @Property()
  token!: string;

  @Property()
  expiresAt!: Date;

  @Property()
  ipAddress?: string;

  @Property()
  userAgent?: string;

  @Property()
  createdAt = new Date();

  @Property({ onUpdate: () => new Date() })
  updatedAt = new Date();
}
```

Cette entité me permet de gérer les sessions actives avec un contrôle granulaire sur les métadonnées de connexion. L'intégration des informations d'IP et User-Agent facilite le monitoring et la détection d'activités suspectes.

#### Entité AuthAccount : Support OAuth futur

```typescript
@Entity('auth_account')
export class AuthAccount {
  @PrimaryKey()
  id!: string;

  @Property()
  userId!: string;

  @Property()
  accountId!: string;

  @Property()
  providerId!: string;

  @Property({ type: 'json', nullable: true })
  accessToken?: string;

  @Property({ type: 'json', nullable: true })
  refreshToken?: string;

  @Property()
  expiresAt?: Date;

  @Property()
  scope?: string;

  @Property({ type: 'json', nullable: true })
  idToken?: string;

  @Property()
  createdAt = new Date();

  @Property({ onUpdate: () => new Date() })
  updatedAt = new Date();
}
```

Bien que non utilisée dans la version initiale de DropIt, cette entité prépare l'évolution future vers l'authentification OAuth (Google, Apple), répondant aux demandes potentielles d'amélioration de l'expérience utilisateur.

#### Entité AuthVerification : Tokens temporaires

```typescript
@Entity('auth_verification')
export class AuthVerification {
  @PrimaryKey()
  id!: string;

  @Property()
  identifier!: string;

  @Property()
  value!: string;

  @Property()
  expiresAt!: Date;

  @Property()
  createdAt = new Date();

  @Property({ onUpdate: () => new Date() })
  updatedAt = new Date();
}
```

Cette entité gère les tokens de vérification temporaires (email, réinitialisation de mot de passe), avec gestion automatique de l'expiration pour la sécurité.

## Protection des routes et système de guards

### Implémentation du AuthGuard

Le guard d'authentification constitue le point d'entrée de la sécurisation des routes dans DropIt. Son implémentation m'a permis d'approfondir ma compréhension des intercepteurs NestJS et du cycle de vie des requêtes :

```typescript
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private reflector: Reflector, private authService: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    
    // Vérification des métadonnées de route (@Public, @Optional)
    const isPublic = this.reflector.getAllAndOverride<boolean>('isPublic', [
      context.getHandler(),
      context.getClass(),
    ]);

    const isOptional = this.reflector.getAllAndOverride<boolean>('isOptional', [
      context.getHandler(),
      context.getClass(),
    ]);

    try {
      // Récupération de la session via Better-Auth
      const session = await this.authService.auth.api.getSession({
        headers: request.headers,
      });

      if (session) {
        // Enrichissement de la requête avec les données utilisateur
        request.user = session.user;
        request.session = session.session;
        return true;
      }

      // Gestion des routes publiques et optionnelles
      return isPublic || isOptional || false;
    } catch (error) {
      return isPublic || isOptional || false;
    }
  }
}
```

Cette implémentation illustre ma compréhension de l'équilibre entre sécurité et flexibilité d'usage, permettant différents niveaux de protection selon les besoins de chaque route.

### Décorateurs pour la flexibilité d'usage

L'implémentation de décorateurs personnalisés me permet de simplifier la gestion de l'authentification dans les contrôleurs tout en maintenant une approche déclarative claire :

```typescript
// auth.decorator.ts - Décorateurs personnalisés

// Marquer une route comme publique
export const Public = () => SetMetadata('isPublic', true);

// Authentification optionnelle
export const Optional = () => SetMetadata('isOptional', true);

// Injection de la session dans les paramètres
export const Session = createParamDecorator(
  (data: unknown, ctx: ExecutionContext) => {
    const request = ctx.switchToHttp().getRequest();
    return data ? request.session?.[data] : request.session;
  },
);

// Hooks pour logique personnalisée
export const BeforeHook = (hookFn: Function) => SetMetadata('beforeHook', hookFn);
export const AfterHook = (hookFn: Function) => SetMetadata('afterHook', hookFn);
```

Ces décorateurs reflètent ma volonté de créer une API développeur intuitive et maintenable, facilitant l'évolution future du système d'authentification.

## Endpoints et API d'authentification

### Routes automatiquement exposées par Better-Auth

Better-Auth expose automatiquement plusieurs endpoints sur le préfixe `/auth`, réduisant significativement le code à maintenir. Cette approche convention-over-configuration m'a fait apprécier les avantages des frameworks opinionated :

| Route | Méthode | Description | Usage dans DropIt |
|-------|---------|-------------|-------------------|
| `/auth/signup` | POST | Inscription utilisateur | Création comptes coachs/athlètes |
| `/auth/login` | POST | Connexion | Accès quotidien à l'application |
| `/auth/logout` | POST | Déconnexion | Sécurisation des sessions |
| `/auth/me` | GET | Profil utilisateur | Données session courante |
| `/auth/refresh` | POST | Renouvellement token | Maintien des sessions longues |
| `/auth/verify` | GET | Vérification email | Sécurisation des comptes |
| `/auth/reset-password` | POST | Réinitialisation | Récupération comptes oubliés |

Cette standardisation facilite l'intégration côté client et garantit la cohérence des réponses API.

### Intégration avec le système d'email

L'intégration du système d'email avec Better-Auth m'a demandé de comprendre l'architecture asynchrone des notifications utilisateur. Cette implémentation prépare l'évolution vers des communications plus riches (notifications push, SMS) :

```mermaid
sequenceDiagram
    participant Client
    participant API
    participant BetterAuth
    participant Database
    participant EmailService

    Client->>API: POST /auth/signup
    API->>BetterAuth: Process signup
    BetterAuth->>Database: Create user
    Database-->>BetterAuth: User created
    
    alt Email verification enabled
        BetterAuth->>EmailService: Send verification email
        EmailService->>EmailService: Generate email template
        EmailService-->>Client: Email avec lien de vérification
    end
    
    BetterAuth-->>API: User created
    API-->>Client: 201 Created
    
    Note over Client,EmailService: Processus asynchrone<br/>pour performance optimale
```

## Patterns d'utilisation dans les contrôleurs

### Protection complète d'un contrôleur

L'application du guard au niveau du contrôleur simplifie la sécurisation de l'ensemble des routes d'un module métier :

```typescript
@Controller('athlete')
@UseGuards(AuthGuard)  // Protection globale du contrôleur
export class AthleteController {
  @Get('profile')
  getProfile(@Session() session) {
    // Accès automatique aux données de session
    return {
      user: session.user,
      lastLogin: session.session.createdAt,
    };
  }
  
  @Get('public-stats')
  @Public()  // Exception pour route publique
  getPublicStats() {
    // Statistiques publiques du club
    return this.athleteService.getPublicStats();
  }
}
```

### Authentification optionnelle pour contenu personnalisé

Certaines fonctionnalités de DropIt bénéficient d'une personnalisation selon l'état d'authentification, sans l'exiger absolument :

```typescript
@Controller('content')
@UseGuards(AuthGuard)
export class ContentController {
  @Get('articles')
  @Optional()  // Authentification optionnelle
  getArticles(@Session() session) {
    if (session) {
      // Contenu personnalisé pour utilisateur authentifié
      return this.contentService.getPersonalizedContent(session.user);
    } else {
      // Contenu public pour visiteur anonyme
      return this.contentService.getPublicContent();
    }
  }
}
```

## Gestion des sessions et sécurité

### Cycle de vie des sessions

L'implémentation de Better-Auth me permet de gérer finement le cycle de vie des sessions utilisateur, aspect crucial pour la sécurité d'une application de gestion sportive :

```mermaid
sequenceDiagram
    participant Client
    participant AuthGuard
    participant AuthService
    participant Database
    participant Redis

    Client->>AuthGuard: Requête avec token
    AuthGuard->>AuthService: getSession()
    AuthService->>Redis: Vérification cache session
    
    alt Session en cache
        Redis-->>AuthService: Session valide
    else Cache miss
        AuthService->>Database: Requête session
        Database-->>AuthService: Session data
        AuthService->>Redis: Mise en cache
    end
    
    AuthService-->>AuthGuard: Session enrichie
    AuthGuard->>AuthGuard: Validation autorisation
    AuthGuard-->>Client: Accès autorisé/refusé
```

### Révocation et invalidation

L'architecture hybride choisie facilite la révocation immédiate des sessions, fonctionnalité particulièrement importante dans un contexte où les coachs peuvent avoir besoin de suspendre l'accès d'un athlète :

```typescript
// Révocation de session - exemple d'usage
async revokeUserSession(userId: string, sessionId?: string) {
  if (sessionId) {
    // Révocation d'une session spécifique
    await this.authService.auth.api.revokeSession({ sessionId });
  } else {
    // Révocation de toutes les sessions utilisateur
    await this.authService.auth.api.revokeUserSessions({ userId });
  }
}
```

## Monitoring et observabilité

### Hooks pour traçabilité

L'implémentation de hooks me permet d'ajouter des capacités de monitoring et de traçabilité sans altérer la logique core de Better-Auth :

```typescript
hooks: {
  before: createAuthMiddleware(async (ctx) => {
    // Log des tentatives d'authentification
    this.logger.log(`Auth attempt: ${ctx.request.method} ${ctx.request.url}`);
  }),
  after: createAuthMiddleware(async (ctx) => {
    // Log des authentifications réussies
    this.logger.log(`Auth success: ${ctx.user?.email}`);
  }),
}
```

Cette approche facilite le debugging et le monitoring de la sécurité en production.

## Perspectives d'évolution et apprentissages

### Défis rencontrés et solutions

L'implémentation de Better-Auth m'a confronté à plusieurs défis techniques qui ont enrichi ma compréhension du développement backend :

**Intégration multi-plateforme** : La gestion des cookies et tokens entre web et mobile m'a demandé d'approfondir ma compréhension des mécanismes d'authentification cross-platform.

**Gestion des erreurs** : La mise en place d'une gestion d'erreurs robuste m'a sensibilisé à l'importance de l'expérience utilisateur lors des échecs d'authentification.

**Performance** : L'optimisation des requêtes d'authentification via Redis m'a fait découvrir les enjeux de performance dans les systèmes à forte charge.

### Évolutions envisagées

Cette implémentation ouvre plusieurs perspectives d'amélioration que je compte explorer dans l'évolution de DropIt :

- **Authentification à deux facteurs** : Integration des TOTP pour les comptes administrateurs
- **OAuth providers** : Support Google/Apple pour simplifier l'onboarding
- **Session analytics** : Tableaux de bord d'usage pour les administrateurs club

### Impact sur ma montée en compétences

Cette implémentation m'a permis de développer une vision pratique de la sécurité applicative, complétant ma formation théorique par une expérience concrète de mise en œuvre. La maîtrise de Better-Auth enrichit mon portfolio technique et me prépare à aborder les enjeux d'authentification dans mes futurs projets professionnels.

## Conclusion et transition vers la gestion des autorisations

L'implémentation du système d'authentification de DropIt illustre la complexité pratique de la sécurisation d'une application moderne. Cette base solide prépare maintenant l'étape suivante : la mise en œuvre d'un système de gestion des autorisations granulaire adapté aux rôles spécifiques de l'écosystème haltérophilie.

La section suivante détaillera comment cette fondation d'authentification s'enrichit d'un système RBAC (Role-Based Access Control) permettant de gérer finement les permissions entre coachs, athlètes, et administrateurs, garantissant ainsi que chaque utilisateur accède uniquement aux fonctionnalités et données qui lui sont destinées.


TODO : spécificité mobile app
### Adaptations spécifiques au mobile

L'interface mobile privilégie une approche offline-first avec stockage local via AsyncStorage pour maintenir la continuité d'usage en salle de sport. Les données critiques (programmes, exercices, performances en cours) sont synchronisées automatiquement lorsque la connectivité le permet :

```typescript
// Stratégie de cache hybride mobile
const syncWithServer = async () => {
  try {
    // Synchronisation ascendante : envoi des données locales
    const localData = await AsyncStorage.getItem('pending-performances');
    if (localData) {
      await api.performance.batchCreate({ body: JSON.parse(localData) });
      await AsyncStorage.removeItem('pending-performances');
    }
    
    // Synchronisation descendante : récupération des nouvelles données
    const workouts = await api.workout.getMyWorkouts();
    await AsyncStorage.setItem('workouts', JSON.stringify(workouts));
  } catch (error) {
    // Gestion gracieuse des erreurs de connectivité
    console.warn('Sync failed, will retry later:', error);
  }
};
```