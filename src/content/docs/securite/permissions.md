---
title: Implémentation des autorisations
description: Mise en œuvre du système de permissions granulaires dans DropIt
---

## Introduction

Après avoir établi une base d'authentification solide avec Better-Auth, je me concentre maintenant sur la couche d'autorisation dans l'application. Cette étape transforme l'identification des utilisateurs en contrôle d'accès granulaire aux ressources.

Dans DropIt, chaque utilisateur évolue au sein d'une organisation (club de sport) avec un rôle spécifique : coach, administrateur ou athlète. Ces rôles déterminent les actions autorisées sur chaque ressource métier. 

## Organisation modulaire des permissions

Dans mon API NestJS, j'ai choisi d'intégrer la gestion des permissions au sein du module d'identité existant, aux côtés de l'authentification. Cette approche me permet de maintenir une cohérence architecturale et de centraliser toutes les préoccupations liées à la sécurité.

```
modules/identity/
├── domain/
│   ├── auth/                    # Entités d'authentification
│   │   ├── user.entity.ts
│   │   ├── session.entity.ts
│   │   └── verification.entity.ts
│   └── organization/            # Entités d'organisation
│       ├── organization.entity.ts
│       ├── member.entity.ts
│       └── invitation.entity.ts
├── infrastructure/
│   ├── guards/                  # Guards de sécurité
│   │   ├── auth.guard.ts
│   │   └── permissions.guard.ts
│   └── decorators/              # Décorateurs
│       ├── auth.decorator.ts
│       ├── permissions.decorator.ts
│       └── organization.decorator.ts
├── application/
│   └── auth.service.ts          # Service Better-Auth
└── identity.module.ts           # Configuration du module
```

Cette organisation modulaire reflète la séparation des responsabilités : l'authentification gère l'identité, tandis que les permissions contrôlent l'autorisation basée sur les rôles d'organisation.

## Entités générées par Better Auth Organizations

### Plugin Organization

Mon système s'appuie sur le plugin Organization de Better-Auth qui étend l'infrastructure d'authentification avec la gestion native des organisations multi-utilisateurs. Cette extension se configure simplement en ajoutant le plugin à ma configuration Better-Auth existante :

```typescript
// Configuration Better-Auth avec plugin Organization
export const auth = betterAuth({
  // ... configuration de base
  plugins: [
    organization(), // Plugin pour les organisations
    // ... autres plugins
  ],
});
```

Le plugin génère automatiquement trois nouvelles entités qui s'intègrent harmonieusement avec les entités d'authentification :

- **Organization** : Représente le club de sport avec ses métadonnées
- **Member** : Lie un utilisateur à une organisation avec un rôle spécifique
- **Invitation** : Gère le processus d'ajout de nouveaux membres

### Adaptation du modèle métier

L'intégration de ce plugin a nécessité une évolution significative de mon modèle de données initial. Initialement, j'avais conçu une relation directe coach-athlète, mais l'approche organisationnelle m'a conduit à repenser cette architecture.

Plutôt que d'avoir des relations individuelles entre coachs et athlètes, j'ai restructuré le modèle autour du concept d'organisation (club). Cette approche présente plusieurs avantages :

- **Scalabilité** : Un club peut avoir plusieurs coachs et de nombreux athlètes
- **Flexibilité** : Les rôles peuvent évoluer (un athlète peut devenir coach)
- **Isolation** : Chaque club fonctionne de manière autonome
- **Collaboration** : Plusieurs coachs peuvent collaborer au sein du même club

Cette refactorisation a permis de passer d'un modèle rigide à une architecture flexible qui correspond mieux à la réalité organisationnelle des clubs de sport.

Les schémas détaillés de ces entités (MCD, MLD, MPD) et leurs relations sont disponibles dans la section [Annexes permissions](/annexes/permissions/) pour une vision complète de l'architecture de données.

## Endpoints d'autorisation automatiques

Comme pour l'authentification, Better-Auth expose automatiquement des endpoints dédiés à la gestion des organisations et permissions sur le préfixe `/auth/organization`. Cette fonctionnalité me fait gagner un temps considérable en évitant le développement manuel de ces routes critiques.

| Route | Méthode | Description | Usage dans DropIt |
|-------|---------|-------------|-------------------|
| `/auth/organization/create` | POST | Création d'organisation | Nouveau club de sport |
| `/auth/organization/invite-member` | POST | Invitation de membre | Ajout d'athlètes/coachs |
| `/auth/organization/accept-invitation` | POST | Acceptation d'invitation | Adhésion au club |
| `/auth/organization/get-invitations` | GET | Liste des invitations | Gestion des demandes |
| `/auth/organization/remove-member` | POST | Exclusion de membre | Gestion des départs |
| `/auth/organization/update-member-role` | POST | Modification de rôle | Promotion coach/admin |
| `/auth/organization/set-active` | POST | Organisation active | Changement de club actif |

Ces endpoints intègrent automatiquement les vérifications de permissions : seuls les utilisateurs autorisés peuvent effectuer ces actions selon leur rôle dans l'organisation. La documentation complète de ces APIs est générée automatiquement via le plugin openAPI() de Better-Auth.

### Définition des permissions métier

Pour structurer efficacement les permissions de DropIt, j'ai profité de l'architecture monorepo pour créer un package dédié `@dropit/permissions` qui centralise toute la logique d'autorisation. Cette décision architecturale répond à un besoin crucial : maintenir la cohérence des permissions entre l'API backend et les interfaces client (web et mobile).

Dans un système multi-plateforme comme DropIt, il est essentiel que les règles d'autorisation soient identiques partout. Un athlète qui ne peut pas créer d'entraînement côté API ne doit pas voir le bouton "Créer" dans l'interface mobile. Cette cohérence était auparavant difficile à maintenir avec des logiques de permissions dispersées.

Le package définit de manière déclarative les ressources disponibles (workout, exercise, athlete...), les actions possibles sur chaque ressource (read, create, update, delete), et les permissions accordées à chaque rôle organisationnel. Cette approche me permet de structurer les autorisations selon une hiérarchie claire qui reflète la réalité des clubs de sport.

### Package @dropit/permissions

Le cœur de mon système repose sur ce package qui structure les permissions selon le domaine métier de l'application. J'ai défini les ressources principales correspondant aux entités manipulées dans un club de sport :

```typescript
const statement = {
  // Ressources métier DropIt
  workout: ["read", "create", "update", "delete"],
  exercise: ["read", "create", "update", "delete"],
  complex: ["read", "create", "update", "delete"],
  athlete: ["read", "create", "update", "delete"],
  session: ["read", "create", "update", "delete"],
  personalRecord: ["read", "create", "update", "delete"],
  // ... autres ressources
} as const;
```

Cette définition statique me permet de bénéficier du typage TypeScript tout en maintenant une source unique de vérité pour toutes les permissions de l'application.

### Mapping des rôles aux permissions

J'ai configuré trois rôles principaux correspondant aux besoins identifiés dans le contexte des clubs de sport :

**Member (Athlète)** : Accès limité en lecture seule avec création de records personnels
```typescript
export const member = ac.newRole({
  workout: ["read"],
  exercise: ["read"],
  athlete: ["read", "create", "update", "delete"], // Gestion de son profil
  personalRecord: ["read", "create"], // Saisie de ses performances
  // ...
});
```

**Admin (Coach)** : Gestion complète des ressources d'entraînement
```typescript
export const admin = ac.newRole({
  workout: ["read", "create", "update", "delete"],
  exercise: ["read", "create", "update", "delete"],
  athlete: ["read", "create", "update", "delete"], // Gestion des athlètes
  // ... toutes permissions métier
});
```

**Owner (Propriétaire)** : Accès total incluant la gestion administrative
```typescript
export const owner = ac.newRole({
  // Hérite de toutes les permissions admin
  // Plus gestion organisation, facturation, etc.
});
```

Cette hiérarchie reflète la réalité organisationnelle des clubs où les propriétaires supervisent l'ensemble, les coachs gèrent l'entraînement, et les athlètes consultent leurs programmes.

Cette approche centralisée présente un avantage majeur : toute modification de permissions se répercute automatiquement sur tous les clients lors de la mise à jour du package, évitant définitivement les incohérences entre les différentes parties de l'application.

Cette façon de définir les permissions s'appelle un modèle RBAC (Role-Based Access Control) et correspond aux besoins d'organisation structurée dont j'avais besoin. Les détails sur les autres modèles de permissions évalués (ACL, ABAC, Scopes OAuth) et les stratégies de contrôle d'accès alternatives (API Gateway, Row Level Security, moteurs dédiés) sont développés dans les [Annexes permissions](/annexes/permissions/).

## Implémentation côté serveur

Comme pour l'authentification, j'ai adopté une approche déclarative en créant des décorateurs spécifiques aux permissions. Cette cohérence architecturale facilite la compréhension et la maintenance du code d'autorisation.

#### Décorateurs de permissions

```typescript
/**
 * Décorateur pour spécifier les permissions requises
 */
export const RequirePermissions = (...permissions: string[]) =>
  SetMetadata('REQUIRED_PERMISSIONS', permissions);

/**
 * Décorateur pour les actions sans organisation
 */
export const NoOrganization = () =>
  SetMetadata(NO_ORGANIZATION, true);
```

Ces décorateurs me permettent d'adopter une approche déclarative où les permissions sont explicitement définies au niveau de chaque route, facilitant la lecture et la maintenance du code.

#### PermissionsGuard

Le PermissionsGuard constitue le point d'entrée principal pour la vérification des permissions. Cette classe s'exécute après l'AuthGuard et effectue les contrôles d'autorisation basés sur le rôle d'organisation de l'utilisateur.

```typescript
@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly em: EntityManager
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const session = request.session;
    const user = session?.user;

    // 1. Récupération des permissions requises
    const requiredPermissions = this.reflector.get<string[]>(
      'REQUIRED_PERMISSIONS',
      context.getHandler()
    );

    // 2. Détermination de la ressource depuis le controller
    const controllerName = context.getClass().name;
    const resource = this.extractResourceFromController(controllerName);

    // 3. Vérification du rôle d'organisation
    const organizationId = session?.session?.activeOrganizationId;
    const memberRecord = await this.em.findOne(Member, {
      user: { id: user.id },
      organization: { id: organizationId },
    });

    // 4. Validation des permissions
    return this.checkUserRolePermissions(
      memberRecord.role,
      resource,
      requiredPermissions
    );
  }
}
```

L'élément clé de cette implémentation est l'utilisation du rôle d'organisation (`Member.role`) plutôt qu'un rôle global utilisateur. Cette approche me permet de gérer des utilisateurs ayant des rôles différents dans différentes organisations, cas d'usage courant où un coach peut être simple membre dans un autre club.

### Exemple d'utilisation complète

Voici comment j'applique concrètement ce système dans le `WorkoutController`, illustrant l'intégration entre authentification et permissions :

```typescript
@UseGuards(PermissionsGuard) // 🔒 Protection globale du contrôleur
@Controller('workouts')
export class WorkoutController {
  //...

  @RequirePermissions('read') // 👁️ Lecture : accessible à tous les rôles
  getWorkouts(
    @CurrentOrganization() organizationId: string,
    @CurrentUser() user: AuthenticatedUser
  ) {
    return tsRestHandler(c.getWorkouts, async () => {
      return await this.workoutUseCase.getAll(organizationId, user.id);
    });
  }

  @RequirePermissions('create') // ✍️ Création : admin et owner uniquement
  createWorkout(
    @CurrentOrganization() organizationId: string,
    @CurrentUser() user: AuthenticatedUser
  ) {
    return tsRestHandler(c.createWorkout, async ({ body }) => {
      return await this.workoutUseCase.create(body, organizationId, user.id);
    });
  }
}
```

Cet exemple illustre plusieurs concepts clés :

- **Protection globale** : `@UseGuards(PermissionsGuard)` applique la vérification à toutes les routes
- **Permissions granulaires** : Chaque action spécifie ses besoins via `@RequirePermissions`
- **Injection contextuelle** : `@CurrentOrganization()` et `@CurrentUser()` fournissent le contexte
- **Détermination automatique** : La ressource `workout` est extraite du nom `WorkoutController`
- **Cohérence** : Même pattern pour tous les contrôleurs de l'application

Le système vérifie automatiquement que l'utilisateur a le rôle approprié dans l'organisation active avant d'autoriser l'accès à chaque méthode.

## Perspectives d'évolution côté client

### Protection des interfaces utilisateur

L'architecture centralisée du package `@dropit/permissions` ouvre la voie à une extension naturelle vers les interfaces utilisateur. Bien que cette fonctionnalité ne soit pas encore implémentée dans DropIt, elle représente une évolution logique du système de permissions.

L'idée serait d'utiliser le même package côté client pour conditionner l'affichage des éléments selon les droits de l'utilisateur connecté, garantissant ainsi une cohérence parfaite entre les autorisations backend et l'expérience utilisateur frontend.

Cette approche permettrait de masquer ou désactiver automatiquement les actions non autorisées, transformant les erreurs de permissions en prévention d'interface. Un athlète ne verrait jamais un bouton "Créer un entraînement" qu'il ne peut pas utiliser, améliorant significativement l'expérience utilisateur.

L'implémentation technique de cette fonctionnalité sera considérée lors des prochaines itérations du projet, si le besoin se présente.

## Conclusion

L'implémentation du système de permissions dans DropIt complète la couche d'authentification en ajoutant un contrôle d'accès granulaire et contextuel. Cette architecture basée sur les rôles d'organisation me permet de gérer les droits d'accès tout en maintenant la simplicité d'utilisation.

La centralisation dans le package `@dropit/permissions` assure la cohérence entre l'API et les clients, tandis que l'intégration avec Better-Auth Organizations fournit les mécanismes techniques robustes nécessaires à la gestion des organisations multi-utilisateurs.

Cette fondation me permet maintenant de me concentrer sur les aspects métier de l'application, avec la certitude que chaque action est correctement autorisée selon le contexte organisationnel de l'utilisateur.

Dans la section suivante, j'aborderai les différentes stratégies de tests mises en place dans DropIt pour garantir la fiabilité de cette infrastructure de sécurité, depuis les tests unitaires des Guards d'authentification et d'autorisation jusqu'aux tests d'intégration des flux métier complets impliquant les ressources protégées.


