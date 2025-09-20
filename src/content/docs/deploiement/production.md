---
title: Mise en production
description: Processus de mise en production de l'application
---

# 7. Déploiement et Maintenance

## Location d'un VPS 

Explication de la location d'un VPS chez Infomaniak + DNS ? Installations ouverture des ports, configuration d'un user avec droit root level, securité dans 1password, acces SSH & co 

## Installation Dokploy et configuration

installation de dokploy comment ça marche, docker, docker swarm, installation des différent service via dockerfile de mon app. 

## Processus de Déploiement : 
  - CI/CD : Mise en place d'un pipeline d'intégration continue et de déploiement continu avec GitHub Actions.

  Branche dev et main (main pour la prod => quand je merge dev sur main ça deploie automatiquement sur dokploy)

## Environnements de Staging : 

Pas encore implémenter mais ça pourrai etre interressant pour eventuellement ajouter des tests de charge et de performance, et des tests d'acceptation utilisateur. (beta testeur)

## Monitoring et Logging : 

  - [ ] Systèmes de monitoring et de logging mis en place. logs dokploy de chaque service

  - [ ] Stratégies pour surveiller la santé de l'application et détecter rapidement les problèmes. (Alertes mails/SMS) => revoir si je peux configurer ça dans dokploy en attendant d'ajouter un service dédié type Signoz 

## Backups et Restauration

  - [ ] Planification des sauvegardes de données. => voir ce que je raconte dans architecture, on peut définir des backup dans dokploy et les faire heberger ailleurs genre dans un bucket S3 je crois
  - [ ] Procédures de restauration en cas de défaillance. (Secure emergency truc) => pareil dire quel est le plan dans ce cas là

## Schema final du deploiement de l'app

Todo : a ajouter avec les différentes couches, client, serveur, db, vps, http/https, proxy & co 

## Evolutions a prevoir 

Approches a envisager si besoin de scaling horizontal, replicas & co 