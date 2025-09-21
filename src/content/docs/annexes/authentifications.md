---
title: Annexes Authentification
description: Détails techniques et comparatifs pour l'authentification dans DropIt
---

## Analyse comparative détaillée des solutions d'authentification

Cette annexe détaille l'analyse comparative mentionnée dans la section conception, justifiant le choix de Better-Auth pour DropIt.

### Contexte et contraintes du projet

L'architecture multi-plateforme de DropIt impose des exigences spécifiques. Le backoffice web nécessite une authentification par cookies HttpOnly pour la sécurité, tandis que l'application mobile React Native requiert un stockage sécurisé natif (Keychain iOS/EncryptedSharedPreferences Android). Cette dualité technique m'a orienté vers une solution capable de gérer nativement ces deux environnements.

La contrainte de révocation immédiate constitue un besoin métier essentiel. Un coach doit pouvoir suspendre instantanément l'accès d'un athlète qui quitte le club, sans attendre l'expiration d'un token. Cette exigence élimine d'emblée les solutions purement basées sur des JWT non révocables.

La perspective d'évolution vers plusieurs clubs influence également mes choix architecturaux. Bien que DropIt démarre avec un seul club, la solution d'authentification doit pouvoir gérer une montée en charge sans refonte majeure.

### Analyse comparative des solutions

#### Solution 1 : Développement from scratch

**Analyse technique détaillée :**

Cette approche nécessiterait d'implémenter manuellement :
- **Hachage sécurisé des mots de passe** : choix et configuration d'Argon2 ou PBKDF2, gestion du salage
- **Génération et validation de tokens** : algorithmes de signature (HMAC-SHA256, RSA), rotation de clés
- **Gestion des sessions** : stockage sécurisé, nettoyage automatique des sessions expirées
- **Protection CSRF/XSS** : implémentation des tokens double-submit, headers de sécurité
- **Rate limiting** : prévention des attaques par force brute
- **Audit et logs** : traçabilité des actions pour conformité RGPD

**Évaluation pour DropIt :**
- ✅ **Contrôle total** : adaptation précise aux besoins métier du club
- ✅ **Aucune dépendance** : pas de risque de discontinuité de service tiers
- ❌ **Expertise sécurité requise** : risque de vulnérabilités par méconnaissance des bonnes pratiques
- ❌ **Temps de développement** : 3-4 semaines estimées vs 1 semaine avec librairie
- ❌ **Maintenance continue** : veille sécuritaire et mises à jour à ma charge


#### Solution 2 : Librairie externe (Better-Auth)

**Analyse technique détaillée :**

Better-Auth propose une architecture hybride qui résout les limitations des approches pures :
- **Sessions + JWT** : révocation immédiate via sessions en base + performance des JWT
- **Multi-plateforme natif** : plugins dédiés pour React (web) et Expo (mobile)
- **Sécurité intégrée** : rate limiting, protection CSRF, cookies sécurisés configurés par défaut
- **Extensibilité** : système de plugins pour ajouter des fonctionnalités (2FA, OAuth, audit)
- **TypeScript first** : intégration native avec NestJS, types générés automatiquement

**Évaluation pour DropIt :**
- ✅ **Réponse aux contraintes** : révocation immédiate + multi-plateforme
- ✅ **Sécurité éprouvée** : protection contre les vulnérabilités courantes (injection, XSS, CSRF), communauté active
- ✅ **Productivité** : 1 semaine d'implémentation vs 3-4 semaines from scratch
- ✅ **Évolutivité** : plugins pour futures fonctionnalités (OAuth, 2FA)
- ⚠️ **Dépendance externe** : mais librairie open-source avec communauté active
- ⚠️ **Courbe d'apprentissage** : 2-3 jours pour maîtriser l'API


#### Solution 3 : Identity Provider externe (Auth0, Firebase, etc.)

**Analyse technique détaillée :**

Les IdP externes offrent des solutions clés en main de niveau enterprise :
- **Sécurité mature** : audits de sécurité réguliers, conformité RGPD intégrée
- **Fonctionnalités avancées** : connexion unique entre applications, authentification à deux facteurs, connexion via Google/Facebook
- **Scalabilité garantie** : infrastructure distribuée, engagement de disponibilité 99.9%
- **Maintenance déléguée** : mises à jour sécurité automatiques, monitoring proactif, support technique

**Évaluation pour DropIt :**
- ✅ **Sécurité enterprise** : niveau de sécurité maximal
- ✅ **Zéro maintenance** : pas de gestion technique côté développeur
- ❌ **Coût prohibitif** : ~50€/mois pour 100 utilisateurs vs gratuit avec Better-Auth
- ❌ **Vendor lock-in** : migration complexe en cas de changement
- ❌ **Surdimensionné** : fonctionnalités enterprise non nécessaires pour un club
- ❌ **Complexité d'intégration** : configuration OAuth, gestion des redirections


### Décision retenue et justification

Au regard de l'analyse comparative, Better-Auth répond de manière optimale aux contraintes spécifiques de DropIt. La solution from scratch présenterait des risques sécuritaires importants et un coût de développement disproportionné pour un projet de cette envergure. Les Identity Providers externes, bien que techniquement excellents, introduisent des coûts récurrents incompatibles avec le budget d'un club de sport et des fonctionnalités surdimensionnées.

Better-Auth offre le niveau de sécurité requis tout en répondant précisément aux contraintes identifiées : révocation immédiate via l'architecture hybride, support natif multi-plateforme pour React et React Native, et extensibilité via le système de plugins pour les évolutions futures (2FA, OAuth). Le temps d'implémentation réduit (1 semaine) me permet de me concentrer sur la valeur métier de l'application plutôt que sur l'infrastructure d'authentification.

Cette décision s'appuie sur une évaluation pragmatique du rapport bénéfice/coût/risque dans le contexte spécifique de DropIt, privilégiant la sécurité et la productivité sans sur-ingénierie.

---

## Étude comparative des solutions d'authentification

Cette section détaille la comparaison technique JWT vs Sessions mentionnée dans la page d'implémentation. Bien que Better-Auth impose une architecture hybride, cette analyse démontre ma compréhension des différentes approches d'authentification moderne et justifie pourquoi l'hybride constitue la meilleure solution.

### Sessions

L'authentification par sessions constitue l'approche classique où le serveur maintient l'état de connexion de chaque utilisateur. Cette méthode **stateful** implique que le serveur stocke les informations de session en mémoire ou en base de données, créant un état persistant côté serveur.

```mermaid
sequenceDiagram
    participant C as Client (Web/Mobile)
    participant S as Serveur DropIt
    participant DB as Base de données

    C->>S: 1. Connexion (email/mot de passe)
    S->>DB: 2. Vérification identifiants
    DB-->>S: 3. Validation utilisateur
    S->>DB: 4. Création session
    S-->>C: 5. Cookie de session
    C->>S: 6. Requête avec cookie
    S->>DB: 7. Validation session
    S-->>C: 8. Réponse autorisée
```

**Analyse technique détaillée :**

**Avantages :**
- **Révocation immédiate** : suppression de la session en base = déconnexion instantanée
- **Sécurité renforcée** : les données sensibles restent côté serveur
- **Contrôle total** : gestion fine des sessions actives, détection d'activités suspectes
- **Simplicité conceptuelle** : mécanisme bien maîtrisé et documenté

**Limitations pour DropIt :**

L'architecture multi-plateforme pose un défi majeur car React Native ne gère pas nativement les cookies HttpOnly, rendant difficile la sécurisation des sessions mobiles.

La scalabilité horizontale nécessite de résoudre le problème du partage d'état entre serveurs. Deux solutions existent : les "sticky sessions" qui forcent un utilisateur à toujours utiliser le même serveur (créant un point de défaillance unique), ou un stockage de sessions partagé comme Redis (ajoutant une couche d'infrastructure).

Les performances sont impactées par la nécessité de vérifier chaque session en base de données à chaque requête, contrairement aux JWT qui se valident localement. Enfin, la gestion des sessions expirées requiert un mécanisme de nettoyage automatique pour éviter l'accumulation de données obsolètes.

### JWT

Les JSON Web Tokens représentent une approche **stateless** où le serveur ne stocke aucune information de session. Chaque token contient toutes les données nécessaires à sa validation, signées cryptographiquement pour garantir leur intégrité.

**Structure technique d'un JWT :**
Un JWT se compose de trois parties séparées par des points :
- **Header** : algorithme de signature (HMAC SHA256, RSA256)
- **Payload** : données utilisateur (userId, rôles, expiration)
- **Signature** : hash cryptographique pour vérifier l'intégrité 

```mermaid
sequenceDiagram
    participant C as Client (Web/Mobile)
    participant S as Serveur DropIt
    participant DB as Base de données

    C->>S: 1. Connexion (email/mot de passe)
    S->>DB: 2. Vérification identifiants
    DB-->>S: 3. Validation utilisateur
    S->>S: 4. Génération JWT signé
    S-->>C: 5. Token JWT
    C->>S: 6. Requête avec Bearer token
    S->>S: 7. Validation signature JWT
    S-->>C: 8. Réponse autorisée
```

**Analyse technique détaillée :**

**Avantages :**
- **Performance optimale** : validation locale sans requête en base de données
- **Scalabilité horizontale** : aucun état partagé entre serveurs
- **Multi-plateforme natif** : compatible web et mobile via header Authorization
- **Transport d'informations** : payload inclut rôles et permissions, réduisant les appels API
- **Standard ouvert** : RFC 7519, interopérabilité garantie

**Exemple de payload DropIt :**
```json
{
  "userId": "123",
  "role": "coach",
  "organizationId": "club-paris",
  "permissions": ["read:workouts", "write:athletes"],
  "exp": 1609459200,
  "iat": 1609455600
}
```

**Limitations :**

Le problème majeur des JWT réside dans l'impossibilité de révocation avant l'expiration naturelle. Une fois émis, un token reste valide même si l'utilisateur doit être immédiatement déconnecté, ce qui pose un risque sécuritaire inacceptable pour DropIt.

Le stockage côté client introduit des vulnérabilités : localStorage expose les tokens aux attaques XSS, tandis que les cookies sans HttpOnly restent accessibles au JavaScript malveillant. La taille des tokens peut également impacter les performances réseau, particulièrement sur mobile avec des payloads volumineux contenant de nombreuses permissions.

Enfin, la rotation des clés de signature nécessite une infrastructure complexe pour maintenir la compatibilité avec les tokens existants tout en renouvelant régulièrement les secrets cryptographiques.

### Architecture hybride JWT/Sessions

L'architecture hybride de Better-Auth combine intelligemment les avantages des deux approches pour résoudre leurs limitations respectives. Cette solution constitue l'évolution logique des systèmes d'authentification modernes.

Better-Auth génère simultanément :
1. **Un JWT** pour la validation rapide des requêtes API
2. **Une session en base** pour permettre la révocation immédiate

Le JWT contient les informations nécessaires à l'autorisation (rôles, permissions) tandis que la session en base maintient l'état de validité du token. À chaque requête, le serveur vérifie d'abord la signature JWT puis contrôle l'existence de la session associée.

Better-Auth optimise les performances en ne vérifiant pas systématiquement la session en base à chaque requête. La vérification s'effectue selon plusieurs critères configurables :

**Critères de vérification en base :**
- **Intervalle temporel** : par défaut toutes les 5 minutes depuis la dernière vérification
- **Actions sensibles** : changement de mot de passe, modification de permissions
- **Premier accès** : à la connexion initiale pour valider l'existence de la session

**Implémentation dans Better-Auth :**
```typescript
// Configuration de la fréquence de vérification
export const auth = betterAuth({
  session: {
    maxAge: 7 * 24 * 60 * 60, // 7 jours
    updateAge: 5 * 60, // Vérification DB toutes les 5 minutes
  }
});

// Dans le Guard NestJS
const session = await this.authService.api.getSession({
  headers: fromNodeHeaders(request.headers),
  // Better-Auth vérifie automatiquement selon updateAge
});
```

Cette approche combine la rapidité des JWT (validation locale de la signature) avec la sécurité des sessions (vérification périodique en base). Entre les vérifications, seule la signature cryptographique est contrôlée, garantissant des performances optimales tout en conservant la capacité de révocation.

### Séquences d'authentification Better-Auth

**1. Processus de connexion (Login)**

![Diagramme de séquence Better Auth Login](../../../assets/better-auth-login.png)

Ce diagramme illustre la génération simultanée du JWT et de la session en base. Better-Auth gère automatiquement la vérification des credentials, la création de la session en PostgreSQL, et la génération du token signé renvoyé au client. L'architecture hybride se met en place dès cette étape.

**2. Processus de déconnexion (Logout)**

![Diagramme de séquence Better Auth Logout](../../../assets/better-auth-logout.png)

La déconnexion démontre l'avantage de l'architecture hybride : la suppression de la session en base invalide immédiatement l'accès, même si le JWT reste techniquement valide côté client. Cette révocation immédiate répond à l'exigence critique identifiée pour DropIt.

**3. Accès à une ressource protégée**

![Diagramme de séquence Accès Ressource Protégée](../../../assets/better-auth-ressource-prot.png)

Ce diagramme illustre l'optimisation des performances : Better-Auth vérifie d'abord la signature JWT (rapide, local) puis contrôle la session en base uniquement selon les critères configurés (intervalle de 5 minutes, actions sensibles). Cette approche combine rapidité et sécurité.

--- 

## Schémas de base de données détaillés

Cette section présente les schémas détaillés des entités Better-Auth mentionnés dans la page d'implémentation. Bien que Better-Auth génère automatiquement ces structures, cette modélisation selon la méthode Merise démontre ma compréhension de l'architecture de données et ma capacité à concevoir des schémas relationnels cohérents.

### Entités d'authentification

#### Modèle Conceptuel de Données (MCD)

Modélisation Merise des entités d'authentification si j'avais dû les concevoir manuellement :

![Modèle Conceptuel de Données](../../../assets/mcd-authentication.png)

**Analyse des relations identifiées :**

- **User** : Entité centrale stockant identifiants et données de profil utilisateur
- **Session** : Une session appartient à un utilisateur (1,n), stocke token, expiration et métadonnées de sécurité (IP, User-Agent)
- **Verification** : Tokens temporaires liés à un utilisateur (1,n) pour vérification email et réinitialisation mot de passe
- **Account** : Support des providers OAuth futurs, relation (0,n) avec User pour l'authentification sociale

#### Modèle Logique de Données (MLD)

Transformation des associations en clés étrangères selon les règles Merise :

![Modèle Logique de Données](../../../assets/mld-authentication.png)

Les associations One-to-Many deviennent des clés étrangères dans les tables "côté many". La contrainte d'intégrité référentielle assure la cohérence des données entre User et ses entités dépendantes.

#### Modèle Physique de Données (MPD)

Implémentation PostgreSQL avec types de données optimisés et index de performance :

![Modèle Physique de Données](../../../assets/mpd-authentication.png)

Les choix techniques incluent UUID pour les identifiants (sécurité), TIMESTAMP WITH TIME ZONE pour les dates (gestion multi-timezone), et TEXT pour la flexibilité des tokens de taille variable.

---

### Entités d'autorisation (Plugin Organization)

Le plugin Organization de Better-Auth ajoute la gestion des permissions granulaires via un système RBAC (Role-Based Access Control). Cette modélisation démontre ma compréhension des patterns d'autorisation complexes.

#### Modèle Conceptuel de Données (MCD)

Modélisation Merise du système RBAC si j'avais dû le concevoir manuellement :

![Modèle Conceptuel de Données](../../../assets/mcd-autorization.png)

**Analyse des relations RBAC :**
- **User** appartient à une **Organization** (1,n)
- **User** peut avoir plusieurs **Roles** via l'association **Member** (n,n)
- **Role** dispose de plusieurs **Permissions** (n,n)
- Relations many-to-many nécessitant des tables d'association pour la normalisation

#### Modèle Logique de Données (MLD)

Résolution des associations many-to-many par des tables intermédiaires :

![Modèle Logique de Données](../../../assets/mld-autorization.png)

Les tables `Member` et `RolePermission` matérialisent les associations many-to-many, respectant les règles de normalisation pour éviter les redondances.

#### Modèle Physique de Données (MPD)

Implémentation optimisée avec contraintes et index pour les performances des requêtes d'autorisation :

![Modèle Physique de Données](../../../assets/mpd-autorization.png)

Index composites sur (`userId`, `organizationId`) et (`roleId`, `permissionId`) pour optimiser les vérifications de permissions fréquentes dans l'application.

--- 

## Configuration côté clients de Better-Auth

Cette section détaille les configurations multi-plateforme mentionnées dans la page d'implémentation. Les exemples concrets montrent comment Better-Auth s'adapte automatiquement aux spécificités de chaque environnement (cookies HttpOnly pour le web, stockage sécurisé pour mobile) tout en maintenant une API unifiée.

### Client web (React)

```typescript
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

**Configuration web spécifique :**
La configuration web utilise `credentials: 'include'` pour permettre l'envoi automatique des cookies HttpOnly entre le client et l'API. Better-Auth gère automatiquement la sécurisation des cookies avec les flags appropriés (Secure, SameSite).

### Client mobile (Expo)

```typescript
// Configuration client mobile
import { createAuthClient } from "@better-auth/react";
import { expoClient } from "@better-auth/expo/client";
import * as SecureStore from "expo-secure-store";

export const authClient = createAuthClient({
  baseURL: process.env.EXPO_PUBLIC_API_URL,

  plugins: [
    expoClient({
      scheme: "dropit",
      storagePrefix: "dropit-auth",
      storage: SecureStore,

      // Configuration deep linking
      linking: {
        prefixes: ["dropit://"],
        config: {
          screens: {
            AuthCallback: "auth/callback",
          },
        },
      },
    }),
  ],
});
```

**Configuration mobile spécifique :**
Le plugin `expoClient` configure automatiquement le stockage sécurisé via `expo-secure-store` (Keychain iOS/EncryptedSharedPreferences Android). Le deep linking avec le scheme `dropit://` permet les redirections OAuth futures. Cette configuration illustre l'adaptabilité de Better-Auth aux contraintes mobiles tout en maintenant un niveau de sécurité équivalent au web.

---

## Mécanismes de sécurité avancés

Cette section détaille les mécanismes de protection CSRF/XSS et d'audit mentionnés dans les pages conception et implémentation. Ces fonctionnalités automatiques de Better-Auth répondent aux exigences de sécurité et de conformité RGPD de DropIt.

### Protection CSRF et XSS automatique

```typescript
// Middleware de sécurité personnalisé
const securityMiddleware = createAuthMiddleware(async (ctx) => {
  // Vérification origin pour CSRF
  const origin = ctx.headers.get('origin');
  const referer = ctx.headers.get('referer');

  if (origin && !config.betterAuth.trustedOrigins.includes(origin)) {
    throw new Error('Invalid origin');
  }

  // Headers de sécurité
  ctx.responseHeaders.set('X-Content-Type-Options', 'nosniff');
  ctx.responseHeaders.set('X-Frame-Options', 'DENY');
  ctx.responseHeaders.set('X-XSS-Protection', '1; mode=block');
});
```

**Détail des protections implémentées :**

**Protection CSRF automatique :** Better-Auth génère automatiquement des tokens double-submit pour chaque requête POST/PUT/DELETE. Un token est envoyé dans le cookie (inaccessible en JavaScript grâce à HttpOnly) et un autre dans le header de la requête. Le serveur valide que les deux tokens correspondent, empêchant un site malveillant de forger des requêtes au nom de l'utilisateur.

**Protection XSS via cookies HttpOnly :** Les tokens de session ne sont accessibles qu'au serveur, pas au JavaScript côté client. Même si un attaquant injecte du code malveillant dans la page, il ne peut pas voler le token de session.

**Headers de sécurité complémentaires :**
- `X-Frame-Options: DENY` prévient le **clickjacking** : empêche l'intégration de DropIt dans une iframe malveillante où l'attaquant pourrait superposer des éléments invisibles pour tromper l'utilisateur
- `X-Content-Type-Options: nosniff` empêche l'**injection de contenu** : force le navigateur à respecter le Content-Type déclaré et bloque l'exécution de fichiers JavaScript déguisés en images
- `X-XSS-Protection: 1; mode=block` active la protection XSS native du navigateur qui bloque l'exécution de scripts suspects

### Audit et conformité RGPD

```typescript
// Table d'audit automatique
@Entity('auth_audit_log')
export class AuthAuditLog {
  @PrimaryKey()
  id!: string;

  @Property()
  userId?: string;

  @Property()
  action!: string; // login, logout, signup, etc.

  @Property()
  ipAddress!: string;

  @Property()
  userAgent!: string;

  @Property()
  success!: boolean;

  @Property()
  createdAt = new Date();
}
```

**Fonctionnalités d'audit automatique :**

**Traçabilité RGPD :** Better-Auth enregistre automatiquement chaque action d'authentification (connexion, déconnexion, changement de mot de passe, modification de permissions) avec l'horodatage, l'adresse IP et le User-Agent. Cette traçabilité répond aux obligations RGPD de preuve de consentement et facilite les enquêtes de sécurité.

**Détection d'anomalies :** Les métadonnées IP/User-Agent permettent d'identifier des connexions suspectes (nouvelle localisation, nouveau navigateur) pour alerter l'utilisateur ou déclencher des vérifications additionnelles.

**Conformité légale :** En cas d'audit de sécurité ou de demande RGPD, ces logs fournissent une preuve documentée de qui a accédé à quelles données et quand, respectant les obligations de transparence. 




