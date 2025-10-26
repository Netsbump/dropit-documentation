---
title: Mise en production
description: Infrastructure de production et processus de déploiement
---

## Infrastructure VPS

### Configuration Infomaniak

J'ai choisi Infomaniak pour leur engagement écologique et infrastructure européenne, garantissant le respect du RGPD. La configuration comprend un serveur Debian Bookworm avec 4 vCPU, 8 GB RAM, et 160 GB SSD, dimensionné pour les besoins initiaux.

Le domaine `dropit-app.fr` est géré chez le même fournisseur, simplifiant la configuration DNS et centralisant la gestion des services.

### Sécurisation

La sécurisation suit les bonnes pratiques DevSecOps : utilisateur non-root avec sudo, authentification par clés SSH uniquement, firewall restrictif autorisant les ports nécessaires (22, 80/443 et 3000 pour le panel admin de Dokploy).

### Sécurisation des secrets

La gestion des credentials critiques suit une approche centralisée via 1Password Business, permettant partage sécurisé et rotation des clés avec traçabilité des accès. Cette solution garantit que les secrets de production (tokens API, mots de passe base de données, clés SSL) ne sont jamais stockés en dur dans le code.

Les variables d'environnement sensibles sont injectées au runtime via Dokploy, évitant l'exposition des secrets dans les images Docker.

## Installation Dokploy

### Architecture Docker Swarm

Dokploy est une plateforme open-source qui transforme un VPS en environnement de déploiement moderne, similaire à Vercel ou Netlify mais pouvant être hébergé sur mon propre serveur. L'installation de Dokploy configure automatiquement Docker Swarm comme orchestrateur de conteneurs et déploie Traefik comme reverse proxy, créant un environnement complet et fonctionnel en une seule commande.

Concrètement, Dokploy fonctionne comme une image Docker d'administration qui s'exécute sur le port 3000 du serveur. Cette interface web permet de gérer les déploiements, déclencher des builds, configurer les domaines et surveiller les services. Chaque action effectuée via l'interface génère automatiquement les configurations appropriées dans Traefik pour le routage des requêtes et dans Docker Swarm pour l'orchestration des conteneurs.

### Services séparés

J'ai opté pour des services Dokploy indépendants plutôt qu'un stack unique, offrant une meilleure granularité :

- **PostgreSQL** : Service natif Dokploy optimisé, évitant les rate limits Docker Hub
- **API Backend** : Service Docker avec Dockerfile multi-stage optimisé
- **Frontend** : Service Docker avec Dockerfile multi-stage (build Vite + Nginx pour servir les fichiers statiques)
- **Reverse Proxy** : Traefik intégré avec SSL automatique Let's Encrypt

Cette architecture permet de gérer chaque composant indépendamment, facilitant debugging, monitoring, et scalabilité. L'absence de dépendances simplifie déploiements et rollbacks.

### Optimisations Dockerfile

Le Dockerfile multi-stage intègre plusieurs optimisations pour la production :

**Build multi-stage** : Le premier stage contient tous les outils de compilation TypeScript et devDependencies (~800MB), le stage final ne conserve que le runtime et dépendances de production (~200MB). Cette séparation réduit drastiquement la taille de l'image finale, améliorant les performances de déploiement.

**Cache BuildKit pour pnpm** : L'utilisation de cache mounts accélère les rebuilds de 2-3 minutes à 30 secondes en réutilisant le store pnpm entre builds. Cette optimisation s'avère cruciale pour les itérations de développement et CI/CD.

**Déploiement optimisé avec pnpm deploy** : La commande `pnpm deploy` crée un dossier de déploiement contenant uniquement les dépendances de production nécessaires, réduisant encore la taille de l'image finale et éliminant les packages de développement inutiles.

**Synchronisation automatique de la base** : La commande de démarrage exécute `db:sync` qui synchronise automatiquement le schéma de base de données depuis les entités TypeScript. Cette approche convient à la phase actuelle du projet (pré-production, données de test), mais sera remplacée par le système de migrations versionnées de MikroORM avant le passage en production pour garantir un contrôle précis des changements de schéma et éviter toute perte de données. Un système de seeding optionnel (via `SEED_DB=true`) permet d'initialiser les données si nécessaire.

## Pipeline CI/CD

### Stratégie de branches

Ma stratégie Git repose sur un workflow GitFlow à deux branches : `develop` pour l'intégration continue des fonctionnalités et `main` pour la production.

Branche `develop` - Intégration continue :
Chaque pull request déclenche automatiquement un workflow CI complet : linting avec Biome, build du monorepo, puis exécution des tests unitaires et d'intégration sur une base PostgreSQL de test. La CI vérifie également la présence de migrations MikroORM et les applique si elles existent, mais cette étape est actuellement skippée (phase de prototypage avec `db:sync`). Cette validation systématique garantit que `develop` reste toujours stable et déployable.

Branche `main` - Livraison continue :
Le merge manuel de `develop` vers `main` active un webhook GitHub qui notifie Dokploy. La plateforme orchestre alors le déploiement complet : build des images Docker, déploiement avec rolling updates Docker Swarm pour un zero-downtime, et conservation automatique des versions précédentes permettant un rollback manuel via l'interface si nécessaire. Les health checks HTTP post-déploiement garantissent le bon fonctionnement avant de router le trafic utilisateur.

Cette approche automatise les vérifications et le déploiement tout en maintenant un contrôle explicite sur le passage en production.

## Monitoring et observabilité

### Logging centralisé

Dokploy agrège automatiquement les logs de tous les services dans son interface, facilitant le debugging et la surveillance. Cette solution basique suffit pour l'instant, mais l'intégration future d'outils comme SignOz permettrait un monitoring plus avancé avec métriques et alertes automatisées.

### Surveillance performances

Le monitoring s'appuie sur les métriques système Dokploy (CPU, mémoire, disque) et health checks applicatifs. Cette approche permet de détecter rapidement les problèmes et d'ajuster les ressources.

L'implémentation d'alertes email est prévue pour les événements critiques, garantissant une réaction rapide même hors heures de travail.

## Sauvegardes et continuité

### Stratégie backup

En phase de prototypage, l'application utilise des données de démonstration qui ne requièrent pas de système de sauvegarde critique. La mise en place d'une architecture de backup robuste est planifiée pour le passage en production avec de vraies données utilisateur.
 
La stratégie de sauvegarde suivra la règle 3-2-1, standard de l'industrie pour assurer la résilience des données : trois copies des données (originale et deux backups), stockées sur deux types de supports différents, avec une copie conservée hors-site pour se prémunir d'une défaillance du datacenter principal.

L'implémentation reposera sur les fonctionnalités natives de Dokploy pour générer des dumps SQL quotidiens de PostgreSQL, stockés initialement sur le VPS avec une rétention de 7 jours. Ces sauvegardes locales seront ensuite automatiquement exportées vers un stockage distant compatible S3, tel qu'Infomaniak Swiss Backup, avec une rétention longue durée d'au moins 30 jours.

### Plan de continuité

En cas d'incident majeur, le plan prévoit la reconstruction complète sur un nouveau VPS incluant restauration des données et redirection DNS. Les objectifs de continuité sont un RTO (Recovery Time Objective) de 4 heures maximum et un RPO (Recovery Point Objective) de 1 heure maximum, adaptés aux contraintes opérationnelles d'un club sportif.

L'anonymisation des données sensibles respectera les obligations RGPD en situation de crise. La procédure complète est documentée dans le code source de l'application.

### Configuration DNS

La configuration DNS pour `dropit-app.fr` structure l'infrastructure :

**Enregistrements configurés** :
- `dropit-app.fr` (A) → Frontend statique Nginx
- `api.dropit-app.fr` (A) → API NestJS containerisée
- `dokploy.dropit-app.fr` (A) → Interface d'administration

Cette segmentation facilite la gestion des certificats SSL automatiques et prépare l'évolution architecturale.

## Architecture de production déployée

![Schema déploiement Dropit](../../../assets/schema-architecture-vps.png)

Cette architecture VPS avec services containerisés (API NestJS, Frontend Nginx, PostgreSQL, Dokploy) garantit la maintenabilité et la simplicité de gestion tout en conservant les performances et la sécurité nécessaires pour l'application DropIt.

## Perspectives d'évolution

### Scaling horizontal

Si la charge augmente, l'architecture conteneurisée permet de facilement répliquer les services (API, base de données) via l'interface Dokploy. Docker Swarm gère automatiquement la répartition de ces réplicas, permettant d'absorber plus de trafic sans reconfiguration complexe.

### Optimisations futures

Des optimisations comme l'ajout d'un système de cache (Redis) ou d'un CDN pour accélérer le chargement des fichiers statiques pourraient être ajoutées si le besoin se présente avec l'augmentation du trafic.
