---
title: Annexes Authentification
description: Détails techniques et comparatifs pour l'authentification dans DropIt
---

L'architecture multi-plateforme de DropIt impose des contraintes spécifiques : cookies HttpOnly pour le web et stockage sécurisé natif pour mobile. La contrainte de révocation immédiate constitue un besoin métier essentiel: un coach doit pouvoir suspendre instantanément l'accès d'un athlète sans attendre l'expiration d'un token.

## Analyse comparative des solutions

### Solution 1 : Développement from scratch

**Analyse technique détaillée :**

Cette approche nécessiterait d'implémenter manuellement le hachage sécurisé, la génération de tokens, la gestion des sessions, les protections CSRF/XSS et le rate limiting.

**Évaluation pour DropIt :**

**Avantages :**
- **Contrôle total** : adaptation précise aux besoins métier du club
- **Aucune dépendance** : pas de risque de discontinuité de service tiers

**Inconvénients :**
- **Expertise sécurité requise** : risque de vulnérabilités par méconnaissance des bonnes pratiques
- **Temps de développement** : 3-4 semaines estimées vs 1 semaine avec librairie
- **Maintenance continue** : veille sécuritaire et mises à jour à ma charge

### Solution 2 : Librairie (Better-Auth)

**Analyse technique détaillée :**

Better-Auth implémente une gestion de sessions persistantes en base de données, répondant directement au besoin de révocation immédiate. La librairie s'adapte automatiquement aux plateformes (cookies pour web, bearer tokens pour mobile) tout en maintenant les sessions en base PostgreSQL. Cette approche garantit qu'une session supprimée invalide instantanément l'accès, sans délai d'expiration.

Better-Auth propose également des fonctionnalités avancées optionnelles (plugin JWT pour authentification stateless, cookie cache pour optimiser les performances) mais l'implémentation par défaut avec sessions en base suffit aux besoins de DropIt.

**Évaluation pour DropIt :**

**Avantages :**
- **Réponse aux contraintes** : révocation immédiate via sessions en base + support multi-plateforme natif
- **Sécurité éprouvée** : protection contre les vulnérabilités courantes (injection, XSS, CSRF), communauté active
- **Productivité** : 1 semaine d'implémentation vs 3-4 semaines from scratch
- **Évolutivité** : plugins pour futures fonctionnalités (OAuth, 2FA, JWT si besoin)

**Points d'attention :**
- **Dépendance externe** : mais librairie open-source avec communauté active
- **Courbe d'apprentissage** : 2-3 jours pour maîtriser l'API

### Solution 3 : Identity Provider externe (Auth0, Firebase, etc.)

**Analyse technique détaillée :**

Les IdP externes offrent sécurité enterprise, fonctionnalités avancées et scalabilité garantie avec maintenance déléguée.

**Évaluation pour DropIt :**

**Avantages :**
- **Sécurité enterprise** : niveau de sécurité maximal
- **Zéro maintenance** : pas de gestion technique côté développeur

**Inconvénients :**
- **Coût prohibitif** : ~50€/mois pour 100 utilisateurs vs gratuit avec Better-Auth
- **Vendor lock-in** : migration complexe en cas de changement
- **Surdimensionné** : fonctionnalités enterprise non nécessaires pour un club
- **Complexité d'intégration** : configuration OAuth, gestion des redirections

### Décision retenue

Au regard de l'analyse comparative, Better-Auth répond aux contraintes spécifiques de DropIt. La solution from scratch présenterait des risques sécuritaires importants et un coût de développement disproportionné pour un projet de cette envergure. Les Identity Providers externes, bien que techniquement excellents, introduisent des coûts récurrents incompatibles avec le budget d'un club de sport et des fonctionnalités surdimensionnées.

Better-Auth offre le niveau de sécurité requis tout en répondant précisément aux contraintes identifiées : révocation immédiate via les sessions en base PostgreSQL, support natif multi-plateforme pour React et React Native, et extensibilité via le système de plugins pour les évolutions futures (2FA, OAuth). Le temps d'implémentation réduit (1 semaine) me permet de me concentrer sur la valeur métier de l'application plutôt que sur l'infrastructure d'authentification.

Cette décision s'appuie sur une évaluation pragmatique du rapport bénéfice/coût/risque dans le contexte spécifique de DropIt, privilégiant la sécurité et la productivité sans sur-ingénierie.

---

### Implémentation DropIt : Sessions persistantes

Dans l'implémentation actuelle de DropIt, j'utilise l'approche par défaut de Better-Auth : des **sessions persistantes stockées en base**. À chaque requête, le serveur interroge la base de données pour vérifier la validité de la session, garantissant qu'une session supprimée invalide instantanément l'accès.

**Configuration dans DropIt :**
```typescript
export const auth = betterAuth({
  cookies: {
    enabled: true,
    httpOnly: true, // Protection XSS
    secure: config.env === "production",
    maxAge: 60 * 60 * 24 * 7, // 7 jours
  },
  bearerToken: {
    enabled: true, // Pour l'application mobile
  },
  session: {
    // Configuration par défaut : vérification DB à chaque requête
  }
});
```

Cette approche répond directement au besoin de révocation immédiate identifié pour DropIt : un coach doit pouvoir suspendre instantanément l'accès d'un athlète. Le coût de vérification en base est acceptable dans le contexte d'un club de sport (nombre d'utilisateurs limité, volume de requêtes modéré).

**Alternatives disponibles dans Better-Auth :**

Better-Auth propose des optimisations pour des contextes nécessitant de meilleures performances :
- **Cookie Cache** : stocke les données de session dans un cookie signé, réduisant les appels DB
- **Plugin JWT** : génère des tokens stateless (15 min d'expiration) pour services externes

Ces fonctionnalités ne sont pas activées dans l'implémentation actuelle car les sessions pures suffisent aux besoins de DropIt. L'activation future du cookie cache pourrait améliorer les performances si le nombre d'utilisateurs augmente significativement.

---

## Modèle Logique de Données Better-Auth

Bien que Better-Auth génère automatiquement ses structures de base de données, cette modélisation MLD selon la méthode Merise démontre ma compréhension de l'architecture relationnelle sous-jacente et ma capacité à analyser un schéma existant.

![Modèle Logique de Données](../../../assets/mld-authentication.png)

**Analyse des relations :**
- **User** : Entité centrale stockant identifiants et données de profil
- **Session** : Relation (1,n) avec User, stocke token, expiration et métadonnées de sécurité
- **Verification** : Tokens temporaires (1,n) pour vérification email et réinitialisation
- **Account** : Support OAuth futurs, relation (0,n) avec User

--- 

## Implémentation des décorateurs

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

Ces décorateurs permettent d'annoter les routes avec des métadonnées de sécurité (`@Public()`, `@Optional()`) et d'injecter directement les données d'authentification dans les paramètres de méthode (`@CurrentUser()`, `@Session()`).

---

## Implémentation du Guard

Le Guard AuthGuard implémente la logique de sécurité qui s'exécute avant chaque route pour valider l'authentification selon les métadonnées définies par les décorateurs.

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

Le Guard utilise le service `Reflector` de NestJS pour lire les métadonnées ajoutées par les décorateurs et adapter son comportement selon le niveau de sécurité requis pour chaque route.

--- 

## Exemple d'usage concret

Cet exemple illustre l'utilisation concrète des décorateurs et Guards dans un contrôleur de l'API DropIt.

```typescript
@Controller()
export class WorkoutController {
  constructor(
    private readonly workoutUseCases: WorkoutUseCases
  ) {}

  getWorkouts(@CurrentUser() user: AuthenticatedUser) {
    return this.workoutUseCases.getWorkouts(organizationId, user.id);
  }
}
```

Cet exemple montre l'`AuthGuard` global vérifiant l'authentification, le décorateur `@CurrentUser()` injectant l'utilisateur connecté, et l'absence de `@Public()` rendant l'authentification obligatoire pour cette route.

---

## Configuration côté clients de Better-Auth

Cette section détaille les configurations multi-plateforme mentionnées dans la page d'implémentation. Les exemples concrets montrent comment Better-Auth s'adapte automatiquement aux spécificités de chaque environnement (cookies HttpOnly pour le web, stockage sécurisé pour mobile) tout en maintenant une API unifiée.

### Client web (React)

```tsx
// Configuration client web
import { createAuthClient } from "@better-auth/react";

export const authClient = createAuthClient({
  baseURL: process.env.NEXT_PUBLIC_API_URL,

  // Configuration cookies automatique
  fetchOptions: {
    credentials: 'include',
  },
});

// Hook d'usage
export function useAuth() {
  const { data: session, isPending } = useSession();

  return {
    user: session?.user,
    isAuthenticated: !!session,
    isLoading: isPending,
  };
}
```

**Configuration web :** `credentials: 'include'` pour l'envoi automatique des cookies HttpOnly. Better-Auth sécurise automatiquement les cookies (Secure, SameSite).

### Client mobile (React Native)

```typescript
// Configuration client mobile
import { createAuthClient } from 'better-auth/react';
import AsyncStorage from '@react-native-async-storage/async-storage';

export const authClient = createAuthClient({
  baseURL: process.env.EXPO_PUBLIC_API_URL,

  // Configuration AsyncStorage pour React Native
  storage: {
    get: async (key: string) => {
      const value = await AsyncStorage.getItem(key);
      return value ? JSON.parse(value) : null;
    },
    set: async (key: string, value: any) => {
      await AsyncStorage.setItem(key, JSON.stringify(value));
    },
    remove: async (key: string) => {
      await AsyncStorage.removeItem(key);
    },
  },

  fetchOptions: {
    credentials: 'include',
  },
});
```

**Configuration mobile :** Utilise AsyncStorage pour la persistance du token. Les données sont protégées par le sandboxing de l'OS (isolation par application). Une amélioration future serait de migrer vers `expo-secure-store` pour ajouter un chiffrement matériel (Keychain iOS / EncryptedSharedPreferences Android).

---

## Mécanismes de sécurité avancés

Better-Auth implémente automatiquement plusieurs protections essentielles pour sécuriser l'authentification dans DropIt.

### Protection CSRF (Cross-Site Request Forgery)

Better-Auth génère automatiquement des tokens double-submit pour chaque requête POST/PUT/DELETE. Un token est envoyé dans le cookie HttpOnly (inaccessible au JavaScript), et un autre dans le header de la requête. Le serveur valide que les deux correspondent, empêchant un site malveillant de forger des requêtes au nom de l'utilisateur.

### Protection XSS (Cross-Site Scripting)

Les cookies HttpOnly rendent le token de session inaccessible au JavaScript côté client. Même si un attaquant injecte du code malveillant dans la page, il ne peut pas voler le token de session.

### Headers de sécurité

Better-Auth configure automatiquement les cookies avec les flags de sécurité appropriés :
- **`HttpOnly`** : empêche l'accès JavaScript au cookie
- **`Secure`** : transmission uniquement en HTTPS en production
- **`SameSite=Lax`** : protection de base contre CSRF

Des headers HTTP complémentaires renforcent la sécurité :
- **`X-Frame-Options: DENY`** : empêche l'intégration dans une iframe (prévient le clickjacking)
- **`X-Content-Type-Options: nosniff`** : force le respect du Content-Type (prévient l'injection de contenu malveillant)

### Métadonnées de session

Chaque session stocke automatiquement l'adresse IP, le User-Agent, et les timestamps de création/expiration. Ces métadonnées constituent une base pour implémenter du monitoring de sécurité : détection de connexions depuis une nouvelle localisation, nouveau navigateur, ou patterns suspects.