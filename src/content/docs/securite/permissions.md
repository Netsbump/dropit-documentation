---
title: Implémentation des autorisations
description: Mise en œuvre du système de permissions granulaires dans DropIt
---

## Introduction

Après avoir établi une base d'authentification solide avec Better-Auth, je me concentre maintenant sur la couche d'autorisation dans l'application. Cette étape transforme l'identification des utilisateurs en contrôle d'accès granulaire aux ressources.

Dans DropIt, chaque utilisateur évolue au sein d'une organisation (club de sport) avec un rôle spécifique : coach, administrateur ou athlète. Ces rôles déterminent les actions autorisées sur chaque ressource métier. 

## Organisation modulaire des permissions

montrer la structure de dossier (dans le meme module d'auth que pour better auth pour isoler les responsabilité ?) => voir dans Dropit

## Entités générées par Better Auth

Mon système s'appuie sur le plugin Organization de Better-Auth qui gère nativement les concepts d'organisations et de membres. Cette intégration me permet de bénéficier des fonctionnalités avancées (invitations, gestion des rôles, sessions par organisation) tout en conservant un contrôle fin sur les permissions métier.

Comme pour l'auth, via un system de plugin organizations qu'on peut ajouter dans la configuration de better auth
Lister les tables et dire de consulter les annexes pour le détail et les MCD MPD MLD liés. 

Dire que ça a necessité un peu d'adaptation de mon modele existant pour permettre de définir les relations coach athlete par le bias d'une organization (club) plutot que comme une relation directement coach athlete

## Endpoints d'autorisation automatique 

de la meme façon que pour l'auth y a des endoint dispo pour les actions lié aux permissions

### Définition des permissions métier

afin de définir les permission, j'ai profiter de mon monorepo pour centralise la source de vérité dans un package dédié `@dropit/permissions` qui centralise toute la logique de permissions. Cette approche me garantit la cohérence entre l'API backend et les interfaces client (web et mobile). Le package définit les ressources disponibles, les actions possibles sur chaque ressource, et les permissions accordées à chaque rôle.

Cette centralisation présente un avantage majeur : toute modification de permissions se répercute automatiquement sur tous les clients, évitant les incohérences entre les différentes parties de l'application.

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

### Définition des différente possibilité de gesion des permissions : 
Evoquer tout ça mais le définir dans les annexes 

définir rapidement les diffentes possibilité et dire que j'ai choisi RBAC (pourquoi ? je crois que c'est mieux pour mon besoin ? Approche spécifique à better auth ou pas forcément ?)
- RBAC
- ACL 
- Policies / ABAC 
- Scopes quand on utilise un IDP ? 

### Comment controler l'acces en fonction du role ? 
Evoquer tout ça mais le définir dans les annexes
Expliquer les différentes approches possibles de façon détaillé dans les annexes mais dire que que moi j'ai choisi l'approche guard qui est prévu par Better Auth et qui s'integre bien avec mon auth mise en place précédemment 
- Backend (middleware, guard, interceptors)
- API gateway (Kong, Traeffik, Envoy -policies en edge)
- Base de données : Row Level Security (PostgreSQL)
- Moteur dédié: OPA, Casbin, policy engine central 


## Implémentation côté serveur

### Decorateur & Guards 

De la meme façon que pour l'authentification, j'ai défini des décorateur spécifique aux permission et des guard

### Exemples Decorateurs

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

### Exemples Guard

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

### Exemple complet 

controlleur workout

## Sécurisation côté client

### Protection unifiée des interfaces

Comme pour l'authentification, le système de permissions s'étend naturellement aux interfaces utilisateur. J'utilise le même package `@dropit/permissions` côté client pour conditionner l'affichage des éléments selon les droits de l'utilisateur connecté.

```typescript
import { usePermissions } from '@dropit/permissions/react';

function WorkoutManagement() {
  const { canCreate, canUpdate, canDelete } = usePermissions('workout');

  return (
    <div>
      {canCreate && <CreateWorkoutButton />}
      {canUpdate && <EditWorkoutButton />}
      {canDelete && <DeleteWorkoutButton />}
    </div>
  );
}
```

Cette approche garantit que les utilisateurs ne voient que les actions qu'ils sont autorisés à effectuer, améliorant l'expérience utilisateur tout en renforçant la sécurité.

## Conclusion

L'implémentation du système de permissions dans DropIt complète la couche d'authentification en ajoutant un contrôle d'accès granulaire et contextuel. Cette architecture RBAC basée sur les rôles d'organisation me permet de gérer finement les droits d'accès tout en maintenant la simplicité d'utilisation.

La centralisation dans le package `@dropit/permissions` assure la cohérence entre l'API et les clients, tandis que l'intégration avec Better-Auth Organizations fournit les mécanismes techniques robustes nécessaires à la gestion des organisations multi-utilisateurs.

Cette fondation solide me permet maintenant de me concentrer sur les aspects métier de l'application, avec la certitude que chaque action est correctement autorisée selon le contexte organisationnel de l'utilisateur.

---

*Note : Les détails techniques d'implémentation, les configurations avancées et les exemples d'utilisation client sont disponibles dans les [Annexes permissions](/annexes/permissions/).*

