---
title: Outils et technologies
description: Description des outils et technologies utilisés
---

### Environnement de développement containerisé

En environnement de développement, PostgreSQL s'exécute dans un conteneur Docker configuré via docker-compose, solution que je détaillerai dans la section dédiée aux services d'infrastructure. Cette approche containerisée garantit la reproductibilité de l'environnement entre les différents postes de développement et facilite l'onboarding de nouveaux développeurs sur le projet.

Le volume Docker persistent assure la conservation des données entre les redémarrages du conteneur, évitant la perte des données de développement et des jeux d'essai. Cette configuration simplifie également la gestion des versions de PostgreSQL et permet de tester facilement différentes configurations sans impacter l'environnement système local.

Cette infrastructure de développement containerisée facilite le passage en production et garantit la cohérence des environnements tout au long du cycle de développement, aspect crucial pour maintenir la stabilité d'une application manipulant des données sensibles d'entraînement.

TODO: Parler de docker compose, des seeds ? de l'env de dev d'une maniere générale. 