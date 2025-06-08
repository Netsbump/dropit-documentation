---
title: Architecture logicielle et choix technologiques
description: Conception technique de DropIt - justifications et mise en œuvre de l'architecture
---

## Introduction : de l'analyse fonctionnelle aux choix techniques

La conception de l'architecture logicielle de DropIt constitue pour moi une étape charnière où les besoins fonctionnels identifiés se traduisent en décisions techniques concrètes. Cette démarche m'amène à confronter mes connaissances théoriques aux contraintes pratiques du développement, tout en explorant de nouvelles technologies dans un contexte d'apprentissage contrôlé.

Ma stratégie architecturale s'appuie sur un équilibre entre familiarité technique et découverte de nouveaux outils. J'ai privilégié des technologies que je maîtrise déjà pour les composants critiques, tout en intégrant des solutions nouvelles pour enrichir mon apprentissage sans compromettre la viabilité du projet.

Cette approche me permet d'approfondir ma compréhension des enjeux d'architecture distribuée tout en maintenant un niveau de risque technique maîtrisable dans le cadre de ma formation.

## Vue d'ensemble architecturale

Suite à l'analyse des besoins, j'ai choisi de structurer l'application selon une architecture distribuée séparant clairement les différentes parties : une interface web pour les coachs, une application mobile pour les athlètes, et un backend centralisé. Cette séparation permet de développer et maintenir chaque partie indépendamment, facilitant ainsi l'évolution future de l'application.

Le diagramme ci-dessous présente les différents composants de l'application et leurs interactions :

![Architecture technique](../../../assets/concept-dropit.png)

Cette architecture répond aux contraintes identifiées lors de l'analyse des besoins : séparation des contextes d'usage (mobile pour les athlètes, web pour les coachs), centralisation des données pour assurer la cohérence, et modularité pour faciliter la maintenance et l'évolution.

## Analyse détaillée des composants principaux

### Client Web (Back Office) : React et TypeScript

Pour le back office destiné aux coachs, j'ai choisi React associé à TypeScript. Ce choix s'appuie sur plusieurs facteurs que j'ai soigneusement évalués : la maturité de l'écosystème React, la fiabilité apportée par le typage statique de TypeScript, et ma propre expérience de deux ans avec ces technologies.

Cette familiarité me permet de me concentrer sur les enjeux métier spécifiques à l'haltérophilie plutôt que sur l'apprentissage des fondamentaux du framework. L'écosystème React offre également une richesse de composants et d'outils (React Router, React Hook Form, Material-UI) qui accélèrent le développement d'interfaces complexes comme celles nécessaires à la gestion des programmes d'entraînement.

L'interface a été pensée pour être responsive et intuitive, permettant aux coachs de gérer efficacement les programmes d'entraînement et le suivi des athlètes. TypeScript apporte une sécurité supplémentaire particulièrement appréciable lors de la manipulation des données d'entraînement où les erreurs de typage pourraient avoir des conséquences sur la sécurité des pratiquants.

### Application Mobile (Front Office) : React Native et Expo

L'application mobile, développée avec React Native et Expo, constitue le point d'accès principal pour les athlètes. N'ayant aucune expérience en développement mobile natif, React Native s'est présenté comme une solution pertinente pour transposer mes compétences React vers le développement mobile.

Cette technologie me permet de produire des applications natives pour iOS et Android à partir d'une base de code unique, tout en capitalisant sur mes connaissances existantes de React. Ce choix représente également une opportunité d'apprentissage du développement mobile dans un contexte réel, élargissant significativement mon champ de compétences.

Expo simplifie considérablement le processus de développement et de déploiement en automatisant de nombreuses tâches complexes (gestion des certificats, build automatisés, over-the-air updates). Cette plateforme me permet de me concentrer sur le développement des fonctionnalités plutôt que sur la configuration de l'environnement de développement mobile.

L'architecture React Native facilite également le partage de logique métier avec l'application web via des modules TypeScript communs, optimisant ainsi le temps de développement et garantissant la cohérence des règles de calcul entre les plateformes.

### API REST (NestJS) : Architecture modulaire et robustesse

Le backend repose sur NestJS, un framework Node.js que j'ai déjà eu l'occasion d'utiliser dans des projets précédents. Cette familiarité avec l'outil permet un développement plus efficace tout en m'offrant l'opportunité d'explorer des fonctionnalités plus avancées que je n'avais pas encore maîtrisées.

Son architecture modulaire inspirée d'Angular et sa documentation complète en font un excellent choix pour structurer une API REST complexe. La philosophie de NestJS, qui privilégie la séparation des responsabilités et l'injection de dépendances, correspond parfaitement aux besoins d'une application métier comme DropIt où la logique de gestion des entraînements nécessite une organisation rigoureuse du code.

#### Choix de l'ORM : MikroORM pour la performance et la sécurité de type

Pour la couche d'accès aux données, j'ai choisi MikroORM plutôt que TypeORM, plus couramment utilisé avec NestJS. Ce choix s'explique par plusieurs avantages techniques que j'ai identifiés lors de mes recherches :

- **Pattern Unit of Work** : MikroORM implémente nativement ce pattern qui optimise les performances en regroupant les opérations de base de données et en gérant automatiquement l'ordre des transactions
- **Gestion des transactions** : La gestion plus cohérente des transactions réduit les risques de corruption de données, aspect crucial pour les données d'entraînement
- **Typage TypeScript strict** : Le typage plus rigoureux aide à détecter les erreurs de manipulation des entités dès la compilation

Bien que ce soit une nouvelle technologie pour moi, sa documentation détaillée et sa compatibilité native avec NestJS en font un choix pertinent pour ce projet d'apprentissage. Cette exploration me permet d'approfondir ma compréhension des ORM modernes et des patterns de gestion de données.

L'API est documentée automatiquement via Swagger, facilitant ainsi son utilisation et son évolution. Les principes REST sont suivis pour assurer une interface cohérente et prévisible, facilitant l'intégration future d'autres clients si le besoin se présente.

## Écosystème de services spécialisés

### Stratégie de cache et gestion de sessions : Redis

Redis constitue la pierre angulaire de ma stratégie de performance et de gestion des sessions. Ce choix repose sur plusieurs considérations techniques spécifiques aux besoins de DropIt :

**Performance en environnement mobile** : Les athlètes consultent fréquemment leurs programmes pendant l'entraînement, souvent dans des conditions de réseau instables. Redis me permet de mettre en cache les données d'entraînement les plus consultées, réduisant significativement les temps de réponse et améliorant l'expérience utilisateur en salle de sport.

**Gestion des sessions d'authentification** : L'architecture d'authentification hybride choisie (JWT + sessions révocables) nécessite un stockage performant pour les métadonnées de sessions. Redis excelle dans ce domaine grâce à ses structures de données spécialisées et ses capacités d'expiration automatique.

**Simplicité d'intégration** : Sa simplicité d'utilisation et ses performances éprouvées en font un excellent choix pour le stockage temporaire des données fréquemment accédées. L'intégration avec NestJS est native et bien documentée, facilitant l'implémentation.

Cette exploration de Redis me permet également d'acquérir une compétence précieuse sur les bases de données NoSQL et les stratégies de cache, aspects essentiels du développement d'applications modernes.

### Stockage de médias : MinIO et stratégie S3-compatible

Pour le stockage des médias, notamment les vidéos de démonstration d'exercices, j'ai opté pour MinIO, une alternative open-source compatible avec l'API S3 d'Amazon. Cette décision s'appuie sur une analyse coût-bénéfice adaptée au contexte du projet :

**Flexibilité de déploiement** : MinIO peut être déployé localement en développement et facilement migré vers des solutions cloud en production, offrant une transition progressive selon l'évolution du projet.

**Compatibilité S3** : L'API compatible S3 garantit la portabilité vers AWS, Google Cloud Storage ou Azure si les besoins de scalabilité l'exigent, évitant le vendor lock-in.

**Solution économique** : Pour un projet de formation avec des contraintes budgétaires, MinIO offre une solution complète sans coûts de stockage externes, tout en me permettant d'apprendre les principes du stockage objet.

En production, cette architecture facilite l'évolution vers des solutions managées (AWS S3, Cloudflare R2) sans modification du code applicatif, grâce à la standardisation de l'API S3.

### Base de données principale : PostgreSQL et fiabilité éprouvée

PostgreSQL a été choisi comme base de données principale pour plusieurs raisons que j'ai soigneusement évaluées :

**Fiabilité dans le contexte métier** : Les données d'entraînement et de progression des athlètes nécessitent une fiabilité absolue. PostgreSQL offre des garanties ACID strictes et une robustesse éprouvée dans des contextes de production critiques.

**Capacités relationnelles avancées** : La modélisation des relations complexes entre athlètes, coachs, exercices, et programmes d'entraînement bénéficie des capacités relationnelles avancées de PostgreSQL (contraintes de clés étrangères, triggers, vues matérialisées).

**Familiarité technique** : Ma maîtrise préalable de PostgreSQL me permet de me concentrer sur les aspects métier de la modélisation plutôt que sur l'apprentissage de la base de données, optimisant ainsi le temps disponible pour explorer d'autres technologies.

**Écosystème et performances** : L'excellent support de PostgreSQL dans l'écosystème Node.js et ses performances pour les applications transactionnelles en font un choix sûr pour l'infrastructure de données.

## Architecture de déploiement et monitoring

### Stratégie de déploiement : Dokploy et containerisation

Pour le déploiement, j'ai choisi Dokploy sur un VPS personnel, solution qui répond aux contraintes budgétaires du projet tout en m'offrant une expérience complète de déploiement d'applications modernes :

**Containerisation avec Docker** : Dokploy s'appuie sur Docker, me permettant d'apprendre les bonnes pratiques de containerisation tout en garantissant la reproductibilité des déploiements entre les environnements de développement et de production.

**Simplicité de gestion** : Cette plateforme simplifie la gestion de l'infrastructure tout en conservant un contrôle suffisant pour comprendre les mécanismes sous-jacents, équilibre idéal dans un contexte d'apprentissage.

**Évolutivité future** : L'expérience acquise avec Dokploy facilitera une migration future vers des solutions cloud plus complexes (Kubernetes, services managés) si les besoins l'exigent.

### Monitoring et observabilité : Sentry

L'intégration de Sentry pour le monitoring répond à un besoin crucial de visibilité sur le comportement de l'application en production :

**Détection proactive des erreurs** : Sentry permet d'identifier rapidement les problèmes rencontrés par les utilisateurs, aspect particulièrement important pour une application mobile utilisée en conditions réelles d'entraînement.

**Apprentissage de l'observabilité** : Cette intégration me familiarise avec les concepts d'observabilité et de monitoring, compétences essentielles pour le développement d'applications professionnelles.

**Tableaux de bord et métriques** : Les capacités de reporting de Sentry m'aident à comprendre les patterns d'usage et à identifier les axes d'amélioration de l'application.

## Communication inter-composants et protocoles

La communication entre les différents composants s'effectue via des protocoles standardisés que j'ai choisis pour leur fiabilité et leur simplicité d'implémentation :

```mermaid
sequenceDiagram
    participant Mobile as App Mobile
    participant Web as Interface Web
    participant API as API REST
    participant Cache as Redis
    participant DB as PostgreSQL
    
    Mobile->>API: HTTPS Request
    Web->>API: HTTPS Request
    API->>Cache: Vérification cache
    alt Cache miss
        API->>DB: Requête SQL
        DB-->>API: Données
        API->>Cache: Mise en cache
    else Cache hit
        Cache-->>API: Données cachées
    end
    API-->>Mobile: JSON Response
    API-->>Web: JSON Response
```

**HTTP/HTTPS pour les interactions client-serveur** : Ce protocole standardisé assure une communication fiable et sécurisée entre les applications frontend et l'API. Le chiffrement HTTPS garantit la confidentialité des données d'entraînement et d'authentification.

**Protocoles natifs pour les bases de données** : PostgreSQL utilise son protocole optimisé construit sur TCP/IP, tandis que Redis communique via son protocole spécifique également basé sur TCP. Cette standardisation garantit une interopérabilité et une maintenance simplifiée de l'ensemble du système.

**Format JSON pour les échanges de données** : Le format JSON assure une interopérabilité maximale entre les différents clients et facilite le débogage et la maintenance.

## Sécurité architecturale intégrée

La sécurité a été intégrée dès la conception de l'architecture plutôt que d'être ajoutée a posteriori. Cette approche "security by design" influence tous les choix techniques :

**Authentification hybride** : L'authentification repose sur une architecture hybride combinant les avantages des tokens JWT (performance, stateless) avec la sécurité des sessions révocables (contrôle granulaire, révocation immédiate).

**Chiffrement bout en bout** : Toutes les communications sont chiffrées via HTTPS, et un système d'autorisation granulaire contrôle l'accès aux différentes fonctionnalités selon le rôle utilisateur.

**Isolation des services** : La séparation des responsabilités entre les différents services (authentification, cache, stockage) limite la surface d'attaque et facilite l'application de mesures de sécurité spécifiques à chaque composant.

Une description détaillée des mécanismes de sécurité mis en place est disponible dans la section [Conception sécurisée](/securite/conception).

## Perspectives d'évolution et scalabilité

### Architecture évolutive et patterns de croissance

La séparation des différentes parties de l'application facilite l'évolution future selon plusieurs axes que j'ai anticipés :

**Évolution fonctionnelle** : Il sera possible d'enrichir l'application mobile avec de nouvelles fonctionnalités sans modifier le back office des coachs, et vice versa. Cette indépendance des clients facilite l'innovation sur chaque plateforme.

**Scalabilité horizontale** : L'architecture stateless de l'API facilite l'ajout de nouvelles instances selon les besoins de charge. Redis et PostgreSQL supportent nativement les configurations haute disponibilité.

**Migration cloud progressive** : Les choix technologiques (protocoles standardisés, API S3-compatible, containerisation) facilitent une migration progressive vers des solutions cloud managées selon l'évolution des besoins.

### Intégration de nouvelles technologies

L'utilisation de services indépendants comme Redis ou MinIO permet d'étendre les capacités de l'application selon les besoins qui émergeront avec l'usage :

- **Intelligence artificielle** : L'accumulation de données d'entraînement ouvre des perspectives d'analyse prédictive et d'optimisation automatique des programmes
- **IoT et objets connectés** : L'architecture API-first facilite l'intégration future de capteurs ou d'équipements connectés
- **Collaboration étendue** : La modularité architecturale permet d'envisager l'extension à d'autres clubs ou disciplines sportives

## Conclusion : une architecture d'apprentissage et de production

Cette architecture répond aux exigences contradictoires de mon projet : servir d'outil d'apprentissage tout en constituant une solution viable pour mon club d'haltérophilie. Les choix techniques reflètent cette double contrainte en combinant des technologies maîtrisées pour les aspects critiques et des explorations encadrées pour enrichir mes compétences.

La progression de cette conception technique vers l'implémentation d'interfaces utilisateur concrètes constitue la prochaine étape de ce mémoire, où ces choix architecturaux se concrétiseront en expériences utilisateur tangibles pour les coachs et les athlètes.
