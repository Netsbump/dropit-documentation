---
title: Architecture logicielle
description: Architecture technique et choix technologiques du projet
---

## Vue d'ensemble

Suite à l'analyse des besoins, j'ai choisi de structurer l'application en séparant clairement les différentes parties : une interface web pour les coachs, une application mobile pour les athlètes, et un backend centralisé. Cette séparation permet de développer et maintenir chaque partie indépendamment. Le diagramme ci-dessous présente les différents composants de l'application et leurs interactions :

![Architecture technique](../../../assets/concept-dropit.png)

## Composants principaux

### Client Web (Back Office)

Pour le back office destiné aux coachs, j'ai choisi React associé à TypeScript. Ce choix s'appuie sur plusieurs facteurs : la maturité de l'écosystème React, la fiabilité apportée par le typage statique de TypeScript, et ma propre expérience avec ces technologies. L'interface a été pensée pour être responsive et intuitive, permettant aux coachs de gérer efficacement les programmes d'entraînement et le suivi des athlètes.

### Application Mobile (Front Office)

L'application mobile, développée avec React Native, constitue le point d'accès principal pour les athlètes. N'ayant aucune expérience en développement mobile natif, React Native s'est présenté comme une solution pertinente pour transposer mes compétences React vers le développement mobile. Cette technologie permet de produire des applications natives pour iOS et Android à partir d'une base de code unique, tout en capitalisant sur mes connaissances existantes de React. Ce choix représente également une opportunité d'apprentissage du développement mobile dans un contexte réel.

### API REST (NestJS)

Le backend repose sur NestJS, un framework Node.js que j'ai déjà eu l'occasion d'utiliser dans des projets précédents. Cette familiarité avec l'outil permet un développement plus efficace tout en explorant des fonctionnalités plus avancées. Son architecture modulaire inspirée d'Angular et sa documentation complète en font un excellent choix pour structurer une API REST.

Pour la couche d'accès aux données, j'ai choisi MikroORM plutôt que TypeORM, plus couramment utilisé avec NestJS. Ce choix s'explique par plusieurs avantages : une meilleure intégration du pattern Unit of Work, une gestion plus cohérente des transactions, et un typage TypeScript plus strict. Bien que ce soit une nouvelle technologie pour moi, sa documentation détaillée et sa compatibilité native avec NestJS en font un choix pertinent pour ce projet.

L'API est documentée automatiquement via Swagger, facilitant ainsi son utilisation et son évolution. Les principes REST sont suivis pour assurer une interface cohérente et prévisible.

### Services externes

L'application s'appuie sur plusieurs services spécialisés, chacun choisi pour répondre à des besoins spécifiques :

Redis a été choisi comme solution de cache et de gestion de sessions. Ce choix m'a permis d'explorer l'utilisation d'une base de données NoSQL dans un contexte réel, compétence importante dans le cadre du titre professionnel. Sa simplicité d'utilisation et ses performances en font un excellent choix pour le stockage temporaire des données fréquemment accédées.

TypeSense a été intégré comme moteur de recherche, bien que son utilisation reste à approfondir. Il pourrait permettre une recherche efficace dans la bibliothèque d'exercices et de programmes, avec des fonctionnalités comme la recherche approximative ou les suggestions. Ce choix représente également une opportunité d'apprentissage d'une technologie de recherche moderne.

Pour le stockage des médias, notamment les vidéos d'exercices, j'ai opté pour MinIO, une alternative open-source compatible S3, offrant une solution flexible et économique.

PostgreSQL a été choisi comme base de données principale pour plusieurs raisons : sa fiabilité éprouvée, sa nature open-source, et surtout ma familiarité avec cet outil. Cette expérience préalable permet de se concentrer sur d'autres aspects techniques du projet tout en garantissant une gestion robuste des données.

## Communication entre les composants

La communication entre les différents composants s'effectue via différents protocoles. Les interactions client-serveur utilisent le protocole HTTP/HTTPS, qui repose lui-même sur TCP/IP, assurant ainsi une communication fiable et sécurisée. Pour les bases de données, PostgreSQL utilise son propre protocole de communication construit sur TCP/IP, tandis que Redis communique également via TCP avec un protocole spécifique. Cette standardisation des protocoles de communication garantit une interopérabilité et une maintenance simplifiée de l'ensemble du système.

## Sécurité

La sécurité a été intégrée dès la conception de l'architecture. L'authentification repose sur les tokens JWT, offrant une solution stateless et sécurisée. Toutes les communications sont chiffrées via HTTPS, et un système d'autorisation granulaire contrôle l'accès aux différentes fonctionnalités. Une description détaillée des mécanismes de sécurité mis en place est disponible dans la section [Conception sécurisée](/securite/conception).

## Perspectives d'évolution

La séparation des différentes parties de l'application devrait faciliter l'ajout de futures fonctionnalités. Par exemple, il sera possible d'enrichir l'application mobile avec de nouvelles fonctionnalités sans avoir à modifier le back office des coachs. De même, l'utilisation de services indépendants comme Redis ou TypeSense permettra d'étendre les capacités de l'application selon les besoins qui émergeront avec l'usage.
